import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/constants/category_colors.dart';
import '../../../core/utils/bidi_utils.dart';
import '../../../core/utils/note_clipboard.dart';
import '../../../core/utils/paragraph_spacing_controller.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/checklist_item.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/tier_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/tier_provider.dart';
import '../../providers/widget_sync_provider.dart';
import '../../widgets/bidi_aware_text_field.dart';
import '../../widgets/category_color_picker.dart';
import '../../widgets/checklist_note_view.dart';
import '../../widgets/memory_help_dialog.dart';
import '../../widgets/reminder_button.dart';
import '_ai_search_widgets.dart' show SttMixin;

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String? noteId;
  final bool returnToAllNotesOnBack;

  const NoteEditorScreen({
    super.key,
    required this.categoryId,
    this.noteId,
    this.returnToAllNotesOnBack = false,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen>
    with SttMixin {
  late final TextEditingController _titleCtrl;
  late final ParagraphSpacingController _bodyCtrl;
  final FocusNode _bodyFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  Timer? _debounce;

  String? _noteId;
  String? _currentCategoryId;
  bool _isPrivate = false;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _saveInProgress = false;
  int _editRevision = 0;
  DateTime? _lastSaved;
  NoteType _noteType = NoteType.text;
  List<ChecklistRowData> _checklistRows = const [];

  // True for an existing note before the user taps the body to edit; false
  // for new notes (start in edit mode) and after the user enters edit mode.
  late bool _isReadMode;

  // Edit-mode body direction. Locked once on enter-edit so the field doesn't
  // flip mid-typing if the user deletes the first strong character. Stays
  // null while in read mode for an existing note.
  TextDirection? _lockedDir;

  // Cached text used to filter out selection-only listener events.
  // Without this, a tap that only moves the caret rebuilds the editor mid-tap
  // (because the listener flips _isDirty) which can let Flutter's default
  // word-select gesture run instead of the cursor-position gesture.
  String _lastTitleText = '';
  String _lastBodyText = '';

  // RTL cursor-position correction. Flutter's text engine misplaces the cursor
  // at the start of the next line when the user taps in empty space at the end
  // of an RTL line. We intercept the raw pointer position, then compare the
  // cursor's visual Y with the tap Y and correct when they diverge.
  Offset? _lastBodyTapGlobal;
  bool _suppressRtlCorrection = false;

  List<ChecklistRowData> _rowsFromItemsPreservingDrafts(
    List<ChecklistItem> items, {
    List<ChecklistRowData>? sourceRows,
  }) {
    final rows = sourceRows ?? _checklistRows;
    final existingById = {
      for (final row in rows)
        if (row.id != null) row.id!: row,
    };
    final draftRows = rows
        .where((row) => row.id == null && row.text.trim().isNotEmpty)
        .toList();
    final blankDrafts = rows.where((row) => row.text.trim().isEmpty).toList();
    final mapped = <ChecklistRowData>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final base =
          existingById[item.id] ?? (i < draftRows.length ? draftRows[i] : null);
      mapped.add(ChecklistRowData(
        id: item.id,
        text: item.text,
        isCompleted: item.isCompleted,
        localId: base?.localId,
      ));
    }
    return [...mapped, ...blankDrafts];
  }

  List<ChecklistRowData> _mergeSavedChecklistIdsIntoCurrentRows(
    List<ChecklistRowData> savedSnapshotRows,
    List<ChecklistItem> savedItems,
  ) {
    final snapshotNonEmpty = savedSnapshotRows
        .where((row) => row.text.trim().isNotEmpty)
        .toList(growable: false);
    final savedByLocalId = <String, ChecklistItem>{};
    for (var i = 0; i < savedItems.length && i < snapshotNonEmpty.length; i++) {
      savedByLocalId[snapshotNonEmpty[i].localId] = savedItems[i];
    }
    return _checklistRows.map((row) {
      if (row.id != null) return row;
      final saved = savedByLocalId[row.localId];
      if (saved == null) return row;
      return row.copyWith(id: saved.id);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _noteId = widget.noteId;
    _currentCategoryId = widget.categoryId;
    _titleCtrl = TextEditingController();
    _bodyCtrl = ParagraphSpacingController();
    _titleCtrl.addListener(_onTitleChanged);
    _bodyCtrl.addListener(_onBodyChanged);
    _isReadMode = widget.noteId != null;

    if (widget.noteId != null) _loadNote();
    initStt();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // For new notes (start in edit mode without going through _enterEditMode),
    // initialize the locked body direction from the device locale.
    if (_lockedDir == null && !_isReadMode) {
      _lockedDir =
          lockedBodyDirection(_bodyCtrl.text, Directionality.of(context));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    stopStt();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onSttResult(String text) {
    final insertText = '${text.trim()} ';
    final useTitle = _titleFocusNode.hasFocus;
    final ctrl = useTitle ? _titleCtrl : _bodyCtrl;

    if (_isReadMode) {
      _enterEditMode();
      final existing = _bodyCtrl.text;
      _bodyCtrl.text = existing.isEmpty
          ? insertText.trim()
          : '$existing\n${insertText.trim()}';
      _markDirty();
      return;
    }

    final sel = ctrl.selection;
    if (sel.isValid) {
      final raw = ctrl.text;
      final newText = raw.replaceRange(
        sel.start.clamp(0, raw.length),
        sel.end.clamp(0, raw.length),
        insertText,
      );
      ctrl.value = ctrl.value.copyWith(
        text: newText,
        selection:
            TextSelection.collapsed(offset: sel.start + insertText.length),
      );
    } else {
      ctrl.text = '${ctrl.text}$insertText';
    }
    _markDirty();
  }

  void _enterEditMode() {
    if (!_isReadMode) return;
    _lockedDir =
        lockedBodyDirection(_bodyCtrl.text, Directionality.of(context));
    setState(() => _isReadMode = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bodyFocusNode.requestFocus();
      _bodyCtrl.selection =
          TextSelection.collapsed(offset: _bodyCtrl.text.length);
    });
  }

  Widget _buildBodyContextMenu(
      BuildContext context, EditableTextState editableTextState) {
    final l = AppStrings.of(context);
    // Replace the built-in Copy button with one that reads the selection
    // directly from the controller's raw text. ParagraphSpacingController
    // splits spans with elevated heights for paragraph gaps, which can shift
    // the \n character into the visual gap region and cause the default
    // copySelection() to produce an offset range that excludes it.
    final items = editableTextState.contextMenuButtonItems.map((item) {
      if (item.type == ContextMenuButtonType.copy) {
        return ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {
            ContextMenuController.removeAny();
            final sel = _bodyCtrl.selection;
            if (sel.isValid && !sel.isCollapsed) {
              final raw = _bodyCtrl.text;
              Clipboard.setData(ClipboardData(
                text: raw.substring(
                  sel.start.clamp(0, raw.length),
                  sel.end.clamp(0, raw.length),
                ),
              ));
            }
          },
        );
      }
      return item;
    }).toList();

    if (_bodyCtrl.text.isNotEmpty) {
      items.add(ContextMenuButtonItem(
        label: l.editorCopyMenuItem,
        onPressed: () {
          ContextMenuController.removeAny();
          copyNoteBody(context, _bodyCtrl.text);
        },
      ));
    }
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Future<void> _loadNote() async {
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) return;
    final note = await repo.getNoteById(widget.noteId!);
    if (note != null && mounted) {
      _titleCtrl.text = note.title;
      _bodyCtrl.text = note.body;
      _lastTitleText = note.title;
      _lastBodyText = note.body;
      setState(() {
        _isPrivate = note.isPrivate;
        _currentCategoryId = note.categoryId;
        _noteType = note.noteType;
      });
      if (note.noteType == NoteType.checklist) {
        final items = await repo.getChecklistItems(note.id);
        if (mounted) {
          setState(() => _checklistRows = items
              .map((item) => ChecklistRowData(
                    id: item.id,
                    text: item.text,
                    isCompleted: item.isCompleted,
                  ))
              .toList());
        }
      }
    }
    await repo.markNoteOpened(widget.noteId!);
    if (note != null && mounted) {
      final cats = ref.read(categoriesProvider).valueOrNull ?? const [];
      await ref
          .read(widgetDataServiceProvider)
          .patchNoteOpened(note: note, categories: cats);
    }
  }

  void _onTitleChanged() {
    if (_titleCtrl.text == _lastTitleText) return;
    _lastTitleText = _titleCtrl.text;
    _markDirty();
  }

  void _onBodyChanged() {
    if (_bodyCtrl.text == _lastBodyText) {
      _correctRtlEndOfLineCursor();
      return;
    }
    _lastBodyText = _bodyCtrl.text;
    _markDirty();
  }

  void _correctRtlEndOfLineCursor() {
    if (_suppressRtlCorrection) {
      _suppressRtlCorrection = false;
      _lastBodyTapGlobal = null;
      return;
    }
    final tapGlobal = _lastBodyTapGlobal;
    _lastBodyTapGlobal = null;
    if (_lockedDir != TextDirection.rtl) return;
    if (tapGlobal == null) return;

    final sel = _bodyCtrl.selection;
    if (!sel.isCollapsed) return;

    final pos = sel.baseOffset;
    final text = _bodyCtrl.text;
    if (pos <= 0 || pos > text.length || text[pos - 1] != '\n') return;

    // Find the RenderEditable inside the body TextField's render tree.
    final ctx = _bodyFocusNode.context;
    if (ctx == null) return;
    RenderEditable? re;
    void visit(RenderObject o) {
      if (re != null) return;
      if (o is RenderEditable) {
        re = o;
        return;
      }
      o.visitChildren(visit);
    }

    final root = ctx.findRenderObject();
    if (root is RenderEditable) {
      re = root;
    } else if (root != null) {
      root.visitChildren(visit);
    }
    if (re == null) return;

    // If the cursor's visual centre is significantly below the tap, it landed
    // on the wrong line due to the RTL empty-space bug.
    final caretRect = re!.getLocalRectForCaret(TextPosition(offset: pos));
    final caretGlobalY = re!.localToGlobal(caretRect.center).dy;
    if (caretGlobalY <= tapGlobal.dy + 8.0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_bodyCtrl.selection.isCollapsed &&
          _bodyCtrl.selection.baseOffset == pos) {
        _suppressRtlCorrection = true;
        _bodyCtrl.selection = TextSelection.collapsed(offset: pos - 1);
      }
    });
  }

  void _markDirty() {
    _editRevision++;
    _isDirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save({bool allowDeleteEmptyUntitled = false}) async {
    if (_saveInProgress) return;
    final saveRevision = _editRevision;
    final title = _titleCtrl.text.trim();
    final checklistRowsSnapshot = List<ChecklistRowData>.of(_checklistRows);
    final checklistTexts = checklistRowsSnapshot
        .map((row) => row.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final rawChecklistTexts =
        checklistRowsSnapshot.map((row) => row.text).toList();
    final rawChecklistStates =
        checklistRowsSnapshot.map((row) => row.isCompleted).toList();
    final rawChecklistIds = checklistRowsSnapshot.map((row) => row.id).toList();
    final body = _noteType == NoteType.checklist
        ? checklistTexts.join('\n')
        : _bodyCtrl.text.trim();
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) return;
    if (title.isEmpty && body.isEmpty) {
      if (allowDeleteEmptyUntitled) {
        final existingId = _noteId;
        if (existingId != null) {
          await _deleteEmptyUntitledNote(existingId);
        }
      }
      return;
    }

    _saveInProgress = true;
    if (mounted) setState(() => _isSaving = true);
    try {
      Note saved;
      if (_noteId == null) {
        saved = await repo.createNote(
          categoryId: _currentCategoryId ?? widget.categoryId,
          title: title,
          body: body,
          isPrivate: _isPrivate,
          noteType: _noteType,
        );
        _noteId = saved.id;
      } else {
        saved = await repo.updateNote(
          id: _noteId!,
          title: title,
          body: body,
          isPrivate: _isPrivate,
          categoryId: _currentCategoryId,
          noteType: _noteType,
        );
      }
      if (_noteType == NoteType.checklist) {
        final items = await repo.replaceChecklistItems(
          noteId: saved.id,
          texts: rawChecklistTexts,
          completionStates: rawChecklistStates,
          rowIds: rawChecklistIds,
        );
        if (_editRevision == saveRevision) {
          _checklistRows = _rowsFromItemsPreservingDrafts(
            items,
            sourceRows: checklistRowsSnapshot,
          );
        } else {
          _checklistRows = _mergeSavedChecklistIdsIntoCurrentRows(
            checklistRowsSnapshot,
            items,
          );
        }
      }
      // Push the new state to the home widget directly. The shared
      // `widgetSyncProvider` only fires while HomeShell is mounted, and the
      // editor lives on a route outside the shell — so without this, edits
      // (e.g. flipping a note from private to public) do not reach the widget
      // until the user returns to the home tab.
      if (mounted) {
        final cats = ref.read(categoriesProvider).valueOrNull ?? const [];
        await ref
            .read(widgetDataServiceProvider)
            .patchWithUpsertedNote(note: saved, categories: cats);
      }
      if (mounted) {
        setState(() {
          if (_editRevision == saveRevision) _isDirty = false;
          _lastSaved = DateTime.now();
        });
      }
    } finally {
      _saveInProgress = false;
      if (mounted) setState(() => _isSaving = false);
      // If new changes arrived while saving, schedule a follow-up save.
      if (_isDirty && mounted) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), _save);
      }
    }
  }

  Future<void> _deleteEmptyUntitledNote(String noteId) async {
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) return;
    await repo.deleteNote(noteId);
    await ref.read(widgetDataServiceProvider).patchNoteRemoved(noteId: noteId);
    _noteId = null;
    _isDirty = false;
  }

  Future<void> _showCategoryPicker(
      BuildContext context, List<Category> categories) async {
    final l = AppStrings.of(context);
    const kNew = '__new__';
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.editorChangeCategory),
        children: [
          ...categories.map((c) {
            final color = categoryColor(c.color);
            final isSelected = c.id == _currentCategoryId;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, c.id),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(c.name)),
                  if (isSelected) const Icon(Icons.check, size: 16),
                ],
              ),
            );
          }),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, kNew),
            child: Row(
              children: [
                const Icon(Icons.add, size: 16),
                const SizedBox(width: 12),
                Text(l.editorNewCategoryEntry),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (picked == kNew) {
      await _showNewCategoryDialog(context);
      return;
    }
    if (picked != null && picked != _currentCategoryId) {
      setState(() => _currentCategoryId = picked);
      _isDirty = true;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), _save);
    }
  }

  Future<void> _changeNoteType(NoteType next) async {
    if (next == _noteType) return;
    final repo = ref.read(noteRepositoryProvider);
    final id = _noteId;
    if (id == null || repo == null) {
      setState(() {
        if (next == NoteType.checklist) {
          final lines = _bodyCtrl.text
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
          _checklistRows = lines
              .map((line) =>
                  ChecklistRowData(id: null, text: line, isCompleted: false))
              .toList();
        } else {
          _bodyCtrl.text = _checklistRows
              .map((row) => row.text.trim())
              .where((text) => text.isNotEmpty)
              .join('\n');
          _checklistRows = const [];
        }
        _noteType = next;
        _isDirty = true;
      });
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), _save);
      return;
    }

    await repo.convertNoteType(noteId: id, noteType: next);
    final note = await repo.getNoteById(id);
    final items = next == NoteType.checklist
        ? await repo.getChecklistItems(id)
        : const [];
    if (!mounted) return;
    setState(() {
      _noteType = next;
      if (note != null) _bodyCtrl.text = note.body;
      _checklistRows = items
          .map((item) => ChecklistRowData(
                id: item.id,
                text: item.text,
                isCompleted: item.isCompleted,
              ))
          .toList();
    });
  }

  Future<void> _showNewCategoryDialog(BuildContext context) async {
    final l = AppStrings.of(context);
    final controller = TextEditingController();
    String selectedColor = kCategoryColors.first;
    String? nameError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.newCategoryDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l.categoryNameHint,
                  errorText: nameError,
                ),
                autofocus: true,
                maxLength: 20,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
              ),
              const SizedBox(height: 16),
              Text(l.categoryColorLabel,
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              CategoryColorPicker(
                selected: selectedColor,
                onChanged: (c) => setDialogState(() => selectedColor = c),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final cats = ref.read(categoriesProvider).valueOrNull ?? [];
                if (cats
                    .any((c) => c.name.toLowerCase() == name.toLowerCase())) {
                  setDialogState(() => nameError = l.categoryNameInUse);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(l.actionCreate),
            ),
          ],
        ),
      ),
    );

    final name = controller.text.trim();
    controller.dispose();
    if (confirmed == true && name.isNotEmpty && mounted) {
      final id = await ref
          .read(categoriesProvider.notifier)
          .createCategory(name, color: selectedColor);
      if (id != null && mounted) {
        setState(() => _currentCategoryId = id);
        _isDirty = true;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 200), _save);
      }
    }
  }

  Future<bool> _onPop() async {
    _debounce?.cancel();
    final shouldDeleteEmptyChecklist = _noteType == NoteType.checklist &&
        _titleCtrl.text.trim().isEmpty &&
        _checklistRows.every((row) => row.text.trim().isEmpty);
    // Wait for any in-flight save to finish before popping.
    while (_saveInProgress) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    if (_isDirty) {
      try {
        await _save(allowDeleteEmptyUntitled: shouldDeleteEmptyChecklist);
      } catch (_) {
        // Save failed (e.g. category deleted); pop anyway so user isn't stuck.
      }
    } else if (shouldDeleteEmptyChecklist && _noteId != null) {
      await _deleteEmptyUntitledNote(_noteId!);
    }
    return true;
  }

  Future<void> _finishAndLeaveEditor() async {
    await _onPop();
    if (!mounted) return;
    if (widget.returnToAllNotesOnBack || !context.canPop()) {
      context.go('/home/archive');
    } else {
      context.pop();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteNoteTitle),
        content: Text(l.deleteNoteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _debounce?.cancel();
    final id = _noteId;
    if (id != null) {
      final repo = ref.read(noteRepositoryProvider);
      await ref.read(reminderRepositoryProvider)?.removeReminder(id);
      await ref.read(reminderSchedulerProvider).cancel(id);
      await repo?.deleteNote(id);
      await ref.read(widgetDataServiceProvider).patchNoteRemoved(noteId: id);
    }
    if (mounted) {
      if (widget.returnToAllNotesOnBack) {
        context.go('/home/archive');
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home/archive');
      }
    }
  }

  Future<Note?> _loadOrCreateNoteForReminder() async {
    _debounce?.cancel();
    final existingId = _noteId;
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) return null;
    if (existingId != null) return repo.getNoteById(existingId);

    final hasContent = _titleCtrl.text.trim().isNotEmpty ||
        (_noteType == NoteType.checklist
            ? _checklistRows.any((row) => row.text.trim().isNotEmpty)
            : _bodyCtrl.text.trim().isNotEmpty);
    if (!hasContent) return null;
    await _save();
    final id = _noteId;
    return id == null ? null : repo.getNoteById(id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final tier = ref.watch(tierProvider).valueOrNull ?? TierLimits.free();
    final bodyLen = _bodyCtrl.text.length;
    final isOverLimit = bodyLen > tier.maxCharsPerNote;
    final currentCatId = _currentCategoryId ?? widget.categoryId;
    final catMatches = categories.where((c) => c.id == currentCatId);
    final currentCat = catMatches.isEmpty ? null : catMatches.first;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _finishAndLeaveEditor();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.returnToAllNotesOnBack
              ? IconButton(
                  tooltip: l.navAllNotes,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _finishAndLeaveEditor,
                )
              : null,
          actions: [
            IconButton(
              tooltip: l.memoryHelpTooltip,
              icon: const Icon(
                Icons.help_outline,
                textDirection: TextDirection.ltr,
              ),
              onPressed: () => showMemoryHelpDialog(context),
            ),
            if (_isReadMode)
              IconButton(
                tooltip: l.editorTooltipEdit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: _enterEditMode,
              ),
            if (sttAvailable)
              IconButton(
                tooltip: listening ? l.editorSttStop : l.editorSttRecord,
                icon: Icon(listening ? Icons.mic : Icons.mic_none),
                color: listening ? cs.error : null,
                onPressed: () => toggleListen(_onSttResult),
              ),
            IconButton(
              tooltip: l.editorTooltipCopy,
              icon: const Icon(Icons.copy_outlined),
              onPressed: _bodyCtrl.text.isEmpty
                  ? null
                  : () => copyNoteBody(context, _bodyCtrl.text),
            ),
            ReminderButton(
              noteId: _noteId,
              loadOrCreateNote: _loadOrCreateNoteForReminder,
            ),
            IconButton(
              tooltip:
                  _isPrivate ? l.editorTooltipPrivate : l.editorTooltipPublic,
              icon: Icon(_isPrivate ? Icons.lock : Icons.lock_open_outlined),
              onPressed: () {
                setState(() => _isPrivate = !_isPrivate);
                _isDirty = true;
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 200), _save);
              },
            ),
            if (_noteId != null)
              IconButton(
                tooltip: l.editorTooltipDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 12, 2),
              child: Row(
                children: [
                  if (_isSaving)
                    Text(l.editorSaving,
                        style: tt.labelSmall?.copyWith(color: cs.outline))
                  else if (_lastSaved != null)
                    Text(
                        l.editorSavedAt(
                            DateFormat('HH:mm').format(_lastSaved!)),
                        style: tt.labelSmall?.copyWith(color: cs.outline)),
                  const Spacer(),
                  _buildNoteTypePicker(cs, tt),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: categories.isEmpty
                        ? null
                        : () => _showCategoryPicker(context, categories),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: categoryColor(currentCat?.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            currentCat?.name ?? '',
                            style: tt.labelSmall,
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down,
                              size: 16, color: cs.onSurfaceVariant),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isReadMode ? _buildReadMode(tt) : _buildEditMode(tt, l, cs),
            ),
            if (bodyLen > tier.maxCharsPerNote * 0.8)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  '$bodyLen / ${tier.maxCharsPerNote}',
                  style: tt.labelSmall?.copyWith(
                    color: isOverLimit ? cs.error : cs.outline,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTypePicker(ColorScheme cs, TextTheme tt) {
    final l = AppStrings.of(context);
    return PopupMenuButton<NoteType>(
      tooltip: l.noteTypeLabel,
      onSelected: _changeNoteType,
      itemBuilder: (_) => [
        PopupMenuItem(value: NoteType.text, child: Text(l.noteTypeText)),
        PopupMenuItem(
            value: NoteType.checklist, child: Text(l.noteTypeChecklist)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _noteType == NoteType.checklist
                  ? Icons.check_box_outlined
                  : Icons.notes_outlined,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _noteType == NoteType.checklist
                  ? l.noteTypeChecklist
                  : l.noteTypeText,
              style: tt.labelSmall,
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildReadMode(TextTheme tt) {
    final localeDefault = Directionality.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppStrings.of(context);
    final rawTitle = _titleCtrl.text.trim();
    final body = _bodyCtrl.text;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _enterEditMode,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rawTitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Directionality(
                    textDirection: firstStrongOf(rawTitle) ?? localeDefault,
                    child: Text(
                      rawTitle,
                      style: tt.titleLarge,
                      textAlign: TextAlign.start,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    AppStrings.of(context).editorTitleHint,
                    style: tt.titleLarge?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              if (_noteType == NoteType.checklist)
                ChecklistNoteView(
                  rows: _checklistRows,
                  isEditing: false,
                  textStyle: tt.bodyLarge,
                  onRowsChanged: (rows) =>
                      setState(() => _checklistRows = rows),
                  onToggle: (id, done) async {
                    await ref
                        .read(noteRepositoryProvider)
                        ?.toggleChecklistItem(id: id, isCompleted: done);
                  },
                  onRemoveCompleted: _confirmRemoveCompleted,
                )
              else if (body.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l.widgetViewNoContent,
                    style: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ParagraphSpacingController.buildBidiAwareView(
                  body,
                  tt.bodyLarge ?? const TextStyle(),
                  localeDefault,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode(TextTheme tt, AppStrings l, ColorScheme cs) {
    final localeDefault = Directionality.of(context);
    final dir =
        _lockedDir ?? lockedBodyDirection(_bodyCtrl.text, localeDefault);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: BidiAwareTextField(
            controller: _titleCtrl,
            focusNode: _titleFocusNode,
            style: tt.titleLarge,
            autofocus: false,
            decoration: InputDecoration(
              hintText: l.editorTitleHint,
              border: InputBorder.none,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: _noteType == NoteType.checklist
                ? ChecklistNoteView(
                    rows: _checklistRows,
                    isEditing: true,
                    textStyle: tt.bodyLarge,
                    onEditFieldFocusRequested: () {
                      _titleFocusNode.unfocus();
                      _bodyFocusNode.unfocus();
                    },
                    onRowsChanged: (rows) {
                      setState(() {
                        _checklistRows = rows;
                        _isDirty = true;
                        _editRevision++;
                      });
                      _debounce?.cancel();
                      _debounce =
                          Timer(const Duration(milliseconds: 800), _save);
                    },
                    onToggle: (id, done) async {
                      await ref
                          .read(noteRepositoryProvider)
                          ?.toggleChecklistItem(id: id, isCompleted: done);
                      _editRevision++;
                      _isDirty = true;
                    },
                    onReorder: (ids) async {
                      final noteId = _noteId;
                      if (noteId != null) {
                        await ref
                            .read(noteRepositoryProvider)
                            ?.reorderChecklistItems(
                                noteId: noteId, orderedIds: ids);
                      }
                    },
                    onRemoveCompleted: _confirmRemoveCompleted,
                  )
                : Listener(
                    onPointerDown: (e) => _lastBodyTapGlobal = e.position,
                    child: Directionality(
                      textDirection: dir,
                      child: TextField(
                        controller: _bodyCtrl,
                        focusNode: _bodyFocusNode,
                        autofocus: widget.noteId == null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        textDirection: dir,
                        textAlign: TextAlign.start,
                        style: tt.bodyLarge,
                        strutStyle: const StrutStyle(forceStrutHeight: false),
                        contextMenuBuilder: _buildBodyContextMenu,
                        decoration: InputDecoration(
                          hintText: l.editorBodyHint,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRemoveCompleted() async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.removeDoneTasksTitle),
        content: Text(l.removeDoneTasksBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = _noteId;
    final repo = ref.read(noteRepositoryProvider);
    if (id == null || repo == null) {
      setState(() => _checklistRows =
          _checklistRows.where((row) => !row.isCompleted).toList());
      return;
    }
    await repo.deleteCompletedChecklistItems(id);
    final items = await repo.getChecklistItems(id);
    if (!mounted) return;
    setState(() => _checklistRows = items
        .map((item) => ChecklistRowData(
              id: item.id,
              text: item.text,
              isCompleted: item.isCompleted,
            ))
        .toList());
  }
}
