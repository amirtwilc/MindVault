import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/bidi_utils.dart';
import '../../../core/utils/note_clipboard.dart';
import '../../../core/utils/paragraph_spacing_controller.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/biometric_provider.dart';
import '../../../presentation/providers/categories_provider.dart';
import '../../../presentation/providers/database_provider.dart';
import '../../../presentation/providers/encryption_provider.dart';
import '../../../presentation/providers/notes_provider.dart';
import '../../../presentation/providers/reminder_provider.dart';
import '../../../presentation/providers/widget_sync_provider.dart';
import '../../../presentation/widgets/bidi_aware_text_field.dart';
import '../../../presentation/widgets/checklist_note_view.dart';
import '../../../presentation/widgets/reminder_button.dart';
import '../../../data/local/database/app_database.dart';
import '../home/_ai_search_widgets.dart' show SttMixin;

class WidgetNoteViewScreen extends ConsumerStatefulWidget {
  final String noteId;

  /// Pre-decoded title from the deep link URI — displayed immediately while
  /// the encrypted body is loading, eliminating the full-screen spinner.
  final String? initialTitle;

  /// When set, view-mode close paths (the X button, the not-found screen, a
  /// successful delete) call this instead of dismissing the activity — used
  /// by the categories widget's floating window so the user returns to the
  /// per-category list. Edit-mode close paths and tap-outside still dismiss
  /// the activity (entering edit mode means "I'm done with the list").
  final VoidCallback? onClose;

  const WidgetNoteViewScreen({
    super.key,
    required this.noteId,
    this.initialTitle,
    this.onClose,
  });

  @override
  ConsumerState<WidgetNoteViewScreen> createState() =>
      _WidgetNoteViewScreenState();
}

class _WidgetNoteViewScreenState extends ConsumerState<WidgetNoteViewScreen>
    with SttMixin {
  Note? _note;
  bool _loading = true;
  bool _isEditing = false;
  bool _saving = false;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = ParagraphSpacingController();
  final _bodyFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  // Body direction locked once when entering edit mode (matches the main
  // editor's behavior so users get the same feel in both surfaces).
  TextDirection? _lockedDir;
  String? _selectedCategoryId;
  NoteType _noteType = NoteType.text;
  List<ChecklistRowData> _checklistRows = const [];

  Offset? _lastBodyTapGlobal;
  bool _suppressRtlCorrection = false;

  List<ChecklistRowData> _mapChecklistRows(
          List<ChecklistItemsTableData> items) =>
      items
          .map((item) => ChecklistRowData(
                id: item.id,
                text: item.itemText,
                isCompleted: item.isCompleted,
              ))
          .toList();

  @override
  void initState() {
    super.initState();
    // Rebuild on body changes so the edit-mode Copy Note button toggles
    // enabled state as the user types.
    _bodyCtrl.addListener(_onBodyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
      _ensureKeyLoaded();
    });
    initStt();
  }

  @override
  void dispose() {
    _bodyCtrl.removeListener(_onBodyChanged);
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
  }

  /// Closes from a view-mode interaction (X button, delete success, not-found).
  /// Routes through [onClose] when supplied so the categories widget can
  /// drop back to its list, otherwise dismisses the activity entirely.
  void _closeFromView() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      SystemNavigator.pop();
    }
  }

  void _enterEditMode() {
    if (_isEditing) return;
    _lockedDir =
        lockedBodyDirection(_bodyCtrl.text, Directionality.of(context));
    setState(() => _isEditing = true);
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

  void _onBodyChanged() {
    _correctRtlEndOfLineCursor();
    if (mounted) setState(() {});
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

  Future<void> _ensureKeyLoaded() async {
    if (!mounted) return;
    if (ref.read(aesKeyProvider) != null) return;
    final key = await ref.read(encryptionServiceProvider).loadKey();
    if (key != null && mounted) {
      ref.read(aesKeyProvider.notifier).state = key;
    }
  }

  Future<void> _loadNote() async {
    final db = ref.read(appDatabaseProvider);
    final row = await db.getNote(widget.noteId);
    if (!mounted) return;

    final note = row == null
        ? null
        : Note(
            id: row.id,
            userId: row.userId,
            categoryId: row.categoryId,
            title: row.title,
            body: row.body,
            isPrivate: row.isPrivate,
            lastUsedAt: row.lastUsedAt,
            createdAt: row.createdAt,
            updatedAt: row.updatedAt,
            lastOpenedAt: row.lastOpenedAt,
            noteType: NoteType.fromStorage(row.noteType),
            isPinned: row.isPinned,
            pinnedAt: row.pinnedAt,
            pinOrder: row.pinOrder,
          );

    if (note != null && note.isPrivate) {
      final bio = ref.read(biometricServiceProvider);
      final ok = await bio.authenticate(
          reason: AppStrings.of(context).privateAuthReason);
      if (!mounted) return;
      if (!ok) {
        SystemNavigator.pop();
        return;
      }
    }

    if (note != null) {
      await db.setNoteLastOpenedAt(widget.noteId, DateTime.now().toUtc());
    }
    if (!mounted) return;
    setState(() {
      _note = note;
      if (note != null) {
        _titleCtrl.text = note.title;
        _bodyCtrl.text = note.body;
        _selectedCategoryId = note.categoryId;
        _noteType = note.noteType;
      }
      _loading = false;
    });
    if (note != null && note.noteType == NoteType.checklist) {
      final items = await db.getChecklistItems(note.id);
      if (mounted) {
        setState(() => _checklistRows = _mapChecklistRows(items));
      }
    }
    if (note != null && mounted) {
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      await ref.read(widgetDataServiceProvider).patchNoteOpened(
            note: note,
            categories: categories,
          );
    }
  }

  bool _hasUnsavedChanges() {
    if (_note == null) return false;
    return _titleCtrl.text.trim() != _note!.title.trim() ||
        (_noteType == NoteType.checklist
                ? _checklistRows
                    .map((row) => row.text.trim())
                    .where((text) => text.isNotEmpty)
                    .join('\n')
                : _bodyCtrl.text.trim()) !=
            _note!.body.trim() ||
        _selectedCategoryId != _note!.categoryId;
  }

  Future<void> _save(List<Category> categories, NoteRepository repo) async {
    if (_note == null) return;
    final title = _titleCtrl.text.trim();
    final checklistTexts = _checklistRows
        .map((row) => row.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final rawChecklistTexts = _checklistRows.map((row) => row.text).toList();
    final rawChecklistStates =
        _checklistRows.map((row) => row.isCompleted).toList();
    final rawChecklistIds = _checklistRows.map((row) => row.id).toList();
    final body = _noteType == NoteType.checklist
        ? checklistTexts.join('\n')
        : _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) {
      await ref
          .read(widgetDataServiceProvider)
          .patchNoteRemoved(noteId: _note!.id);
      await ref.read(reminderRepositoryProvider)?.removeReminder(_note!.id);
      await ref.read(reminderSchedulerProvider).cancel(_note!.id);
      await repo.deleteNote(_note!.id);
      if (mounted) SystemNavigator.pop();
      return;
    }
    setState(() => _saving = true);
    try {
      final updatedNote = await repo.updateNote(
        id: _note!.id,
        title: title.isEmpty ? _note!.title : title,
        body: body,
        categoryId: _selectedCategoryId,
        noteType: _noteType,
      );
      if (_noteType == NoteType.checklist) {
        await repo.replaceChecklistItems(
          noteId: _note!.id,
          texts: rawChecklistTexts,
          completionStates: rawChecklistStates,
          rowIds: rawChecklistIds,
        );
      }
      await ref
          .read(widgetDataServiceProvider)
          .patchWithUpdatedNote(note: updatedNote, categories: categories);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) SystemNavigator.pop();
  }

  Future<void> _confirmDelete(NoteRepository repo) async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteNoteTitle),
        content: Text(l.deleteNoteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref
        .read(widgetDataServiceProvider)
        .patchNoteRemoved(noteId: _note!.id);
    await ref.read(reminderRepositoryProvider)?.removeReminder(_note!.id);
    await ref.read(reminderSchedulerProvider).cancel(_note!.id);
    await repo.deleteNote(_note!.id);
    // After a successful delete the note is gone; if we're hosted by the
    // categories floating window, dropping back to the list lets the user see
    // the updated count without reopening the widget.
    if (mounted) _closeFromView();
  }

  Future<Note?> _loadNoteForReminder() async {
    final note = _note;
    if (note != null) return note;
    final row = await ref.read(appDatabaseProvider).getNote(widget.noteId);
    if (row == null) return null;
    return Note(
      id: row.id,
      userId: row.userId,
      categoryId: row.categoryId,
      title: row.title,
      body: row.body,
      isPrivate: row.isPrivate,
      lastUsedAt: row.lastUsedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastOpenedAt: row.lastOpenedAt,
      noteType: NoteType.fromStorage(row.noteType),
      isPinned: row.isPinned,
      pinnedAt: row.pinnedAt,
      pinOrder: row.pinOrder,
    );
  }

  Future<void> _confirmRemoveCompleted(NoteRepository repo) async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.removeDoneTasksTitle),
        content: Text(l.removeDoneTasksBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await repo.deleteCompletedChecklistItems(_note!.id);
    final items = await repo.getChecklistItems(_note!.id);
    if (!mounted) return;
    if (_titleCtrl.text.trim().isEmpty && items.isEmpty) {
      await ref
          .read(widgetDataServiceProvider)
          .patchNoteRemoved(noteId: _note!.id);
      await ref.read(reminderRepositoryProvider)?.removeReminder(_note!.id);
      await ref.read(reminderSchedulerProvider).cancel(_note!.id);
      await repo.deleteNote(_note!.id);
      if (mounted) _closeFromView();
      return;
    }
    setState(() {
      _checklistRows = items
          .map((item) => ChecklistRowData(
                id: item.id,
                text: item.text,
                isCompleted: item.isCompleted,
              ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(noteRepositoryProvider);
    final canEdit = repo != null;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    if (_selectedCategoryId != null &&
        categories.isNotEmpty &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = categories.first.id;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _saving
            ? null
            : () async {
                if (_isEditing && _note != null) {
                  final repo = ref.read(noteRepositoryProvider);
                  final cats = ref.read(categoriesProvider).valueOrNull ?? [];
                  if (repo != null) {
                    await _save(cats, repo);
                  } else {
                    SystemNavigator.pop();
                  }
                } else {
                  SystemNavigator.pop();
                }
              },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _loading
                        ? _buildLoadingState(theme, cs)
                        : _note == null
                            ? _buildNotFound(theme)
                            : _isEditing
                                ? _buildEditMode(theme, cs, categories, repo!)
                                : _buildViewMode(theme, cs, canEdit, repo),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme cs) {
    final title = widget.initialTitle;
    if (title == null || title.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close),
              visualDensity: VisualDensity.compact,
              onPressed: _closeFromView,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    final l = AppStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.widgetViewNotFound, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _closeFromView,
          child: Text(l.actionClose),
        ),
      ],
    );
  }

  Widget _buildViewMode(
      ThemeData theme, ColorScheme cs, bool canEdit, NoteRepository? repo) {
    final l = AppStrings.of(context);
    final removeCompletedAction = repo != null &&
            _checklistRows.where((row) => row.isCompleted).isNotEmpty
        ? () => _confirmRemoveCompleted(repo)
        : null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _note!.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: l.editorTooltipCopy,
              visualDensity: VisualDensity.compact,
              onPressed: _note!.body.isEmpty
                  ? null
                  : () => copyNoteBody(context, _note!.body),
            ),
            ReminderButton(
              noteId: _note!.id,
              loadOrCreateNote: _loadNoteForReminder,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: canEdit ? l.widgetViewEdit : l.widgetViewUnlocking,
              visualDensity: VisualDensity.compact,
              onPressed: canEdit ? _enterEditMode : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: canEdit ? l.widgetViewDelete : l.widgetViewUnlocking,
              visualDensity: VisualDensity.compact,
              onPressed:
                  (canEdit && repo != null) ? () => _confirmDelete(repo) : null,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              visualDensity: VisualDensity.compact,
              onPressed: _closeFromView,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_noteType == NoteType.checklist)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: ChecklistNoteView(
                rows: _checklistRows,
                isEditing: false,
                onRowsChanged: (rows) => setState(() => _checklistRows = rows),
                onToggle: (id, done) async {
                  await repo?.toggleChecklistItem(id: id, isCompleted: done);
                },
                onRemoveCompleted: removeCompletedAction,
              ),
            ),
          )
        else if (_note!.body.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: ParagraphSpacingController.buildBidiAwareView(
                _note!.body,
                theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ) ??
                    TextStyle(color: cs.onSurfaceVariant),
                Directionality.of(context),
              ),
            ),
          )
        else
          Text(
            l.widgetViewNoContent,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode(
    ThemeData theme,
    ColorScheme cs,
    List<Category> categories,
    NoteRepository repo,
  ) {
    final l = AppStrings.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l.widgetViewEditTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (sttAvailable)
              IconButton(
                icon: Icon(listening ? Icons.mic : Icons.mic_none),
                tooltip: listening ? l.editorSttStop : l.editorSttRecord,
                visualDensity: VisualDensity.compact,
                color: listening ? cs.error : null,
                onPressed: _saving ? null : () => toggleListen(_onSttResult),
              ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              tooltip: l.editorTooltipCopy,
              visualDensity: VisualDensity.compact,
              onPressed: _saving || _bodyCtrl.text.isEmpty
                  ? null
                  : () => copyNoteBody(context, _bodyCtrl.text),
            ),
            ReminderButton(
              noteId: _note?.id,
              loadOrCreateNote: _loadNoteForReminder,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.widgetViewDelete,
              visualDensity: VisualDensity.compact,
              onPressed: _saving ? null : () => _confirmDelete(repo),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_hasUnsavedChanges()) {
                        SystemNavigator.pop();
                        return;
                      }
                      final discard = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l.widgetViewDiscardTitle),
                          content: Text(l.widgetViewDiscardBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l.widgetViewKeepEditing),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l.actionDiscard),
                            ),
                          ],
                        ),
                      );
                      if (discard == true && mounted) SystemNavigator.pop();
                    },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (categories.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedCategoryId,
            decoration: InputDecoration(
              labelText: l.widgetComposeCategoryLabel,
              border: const OutlineInputBorder(),
            ),
            items: categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged:
                _saving ? null : (v) => setState(() => _selectedCategoryId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<NoteType>(
            initialValue: _noteType,
            decoration: InputDecoration(
              labelText: l.noteTypeLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                  value: NoteType.text, child: Text(l.noteTypeText)),
              DropdownMenuItem(
                  value: NoteType.checklist, child: Text(l.noteTypeChecklist)),
            ],
            onChanged: _saving
                ? null
                : (value) async {
                    if (value == null || value == _noteType) return;
                    if (value == NoteType.checklist) {
                      _checklistRows = _bodyCtrl.text
                          .split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .map((line) => ChecklistRowData(
                              id: null, text: line, isCompleted: false))
                          .toList();
                    } else {
                      _bodyCtrl.text = _checklistRows
                          .map((row) => row.text.trim())
                          .where((text) => text.isNotEmpty)
                          .join('\n');
                      _checklistRows = const [];
                    }
                    setState(() => _noteType = value);
                  },
          ),
          const SizedBox(height: 12),
        ],
        BidiAwareTextField(
          controller: _titleCtrl,
          focusNode: _titleFocusNode,
          enabled: !_saving,
          style: Theme.of(context).textTheme.titleMedium,
          decoration: InputDecoration(
            hintText: l.editorTitleHint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const Divider(height: 1),
        const SizedBox(height: 8),
        if (_noteType == NoteType.checklist)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80, maxHeight: 220),
            child: SingleChildScrollView(
              child: ChecklistNoteView(
                rows: _checklistRows,
                isEditing: true,
                onRowsChanged: (rows) => setState(() => _checklistRows = rows),
                onToggle: (id, done) =>
                    repo.toggleChecklistItem(id: id, isCompleted: done),
                onReorder: (ids) => repo.reorderChecklistItems(
                    noteId: _note!.id, orderedIds: ids),
                onRemoveCompleted:
                    _checklistRows.where((row) => row.isCompleted).isNotEmpty
                        ? () => _confirmRemoveCompleted(repo)
                        : null,
              ),
            ),
          )
        else
          Builder(
            builder: (ctx) {
              final bodyDir = _lockedDir ??
                  lockedBodyDirection(_bodyCtrl.text, Directionality.of(ctx));
              return ConstrainedBox(
                constraints:
                    const BoxConstraints(minHeight: 80, maxHeight: 200),
                child: SingleChildScrollView(
                  child: Listener(
                    onPointerDown: (e) => _lastBodyTapGlobal = e.position,
                    child: Directionality(
                      textDirection: bodyDir,
                      child: TextField(
                        controller: _bodyCtrl,
                        focusNode: _bodyFocusNode,
                        enabled: !_saving,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        textDirection: bodyDir,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.bodyLarge,
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
              );
            },
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : () => _save(categories, repo),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l.actionSave),
        ),
      ],
    );
  }
}
