import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_defaults.dart';
import '../../../core/utils/bidi_utils.dart';
import '../../../core/utils/note_clipboard.dart';
import '../../../core/utils/paragraph_spacing_controller.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/repositories/note_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/categories_provider.dart';
import '../../../presentation/providers/encryption_provider.dart';
import '../../../presentation/providers/notes_provider.dart';
import '../../../presentation/providers/widget_sync_provider.dart';
import '../../../presentation/widgets/bidi_aware_text_field.dart';
import '../home/_ai_search_widgets.dart' show SttMixin;

class WidgetComposeScreen extends ConsumerStatefulWidget {
  /// When set, the dropdown defaults to this category if it exists in the
  /// user's category list. Falls back to General (then first) if not.
  final String? initialCategoryId;

  /// When set, the X (close) button calls this instead of dismissing the
  /// activity — used by the categories widget's floating window so X returns
  /// to the per-category note list rather than exiting. Save and tap-outside
  /// always dismiss the activity (matches the user expectation that finishing
  /// the compose flow means "I'm done with the floating window").
  final VoidCallback? onClose;

  const WidgetComposeScreen({
    super.key,
    this.initialCategoryId,
    this.onClose,
  });

  @override
  ConsumerState<WidgetComposeScreen> createState() =>
      _WidgetComposeScreenState();
}

class _WidgetComposeScreenState extends ConsumerState<WidgetComposeScreen>
    with SttMixin {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = ParagraphSpacingController();
  final _bodyFocusNode = FocusNode();
  final _titleFocusNode = FocusNode();
  String? _selectedCategoryId;
  bool _saving = false;

  Offset? _lastBodyTapGlobal;
  bool _suppressRtlCorrection = false;

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

  @override
  void initState() {
    super.initState();
    // Rebuild on body changes so the Copy Note button toggles enabled state
    // as the user types (it disables when the body is empty).
    _bodyCtrl.addListener(_onBodyChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureKeyLoaded());
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
        selection: TextSelection.collapsed(offset: sel.start + insertText.length),
      );
    } else {
      ctrl.text = '${ctrl.text}$insertText';
    }
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
    if (firstStrongOf(_bodyCtrl.text) != TextDirection.rtl) return;
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
      if (o is RenderEditable) { re = o; return; }
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

  bool get _hasInput =>
      _titleCtrl.text.trim().isNotEmpty || _bodyCtrl.text.trim().isNotEmpty;

  /// Confirms a discard with the user when there's unsaved input. Returns
  /// true when the caller should proceed with closing.
  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasInput) return true;
    final l = AppStrings.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.widgetComposeDiscardTitle),
        content: Text(l.widgetComposeDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.actionDiscard),
          ),
        ],
      ),
    );
    return discard == true;
  }

  /// Tap-outside-the-card path: always dismisses the activity, even when
  /// launched inside the categories widget's floating window. This matches
  /// the existing notes-widget behavior — outside taps mean "exit".
  Future<void> _onTapOutside() async {
    if (await _confirmDiscardIfNeeded() && mounted) SystemNavigator.pop();
  }

  /// X-button path: returns to the parent screen via [onClose] when one is
  /// supplied (categories widget floating window), otherwise dismisses the
  /// activity (top-level deep link from the notes widget).
  Future<void> _onClosePressed() async {
    if (!await _confirmDiscardIfNeeded() || !mounted) return;
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
    } else {
      SystemNavigator.pop();
    }
  }

  Future<void> _save(NoteRepository repo, List<Category> categories) async {
    final rawTitle = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (rawTitle.isEmpty && body.isEmpty) return;

    final cat = categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => categories.first,
    );
    final title = rawTitle;

    setState(() => _saving = true);
    try {
      final note = await repo.createNote(
        categoryId: cat.id,
        title: title,
        body: body,
        isPrivate: false,
      );
      await ref
          .read(widgetDataServiceProvider)
          .patchWithNewNote(note: note, categories: categories);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final repo = ref.watch(noteRepositoryProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    String pickDefault(List<Category> cats) {
      final initial = widget.initialCategoryId;
      if (initial != null && cats.any((c) => c.id == initial)) return initial;
      final generalIdx = cats.indexWhere((c) => isGeneralCategoryName(c.name));
      return generalIdx >= 0 ? cats[generalIdx].id : cats.first.id;
    }

    ref.listen(categoriesProvider, (_, next) {
      final cats = next.valueOrNull ?? [];
      if (_selectedCategoryId != null && cats.any((c) => c.id == _selectedCategoryId)) {
        return;
      }
      if (cats.isEmpty) return;
      setState(() => _selectedCategoryId = pickDefault(cats));
    });

    if (_selectedCategoryId == null && categories.isNotEmpty) {
      _selectedCategoryId = pickDefault(categories);
    } else if (_selectedCategoryId != null &&
        categories.isNotEmpty &&
        !categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = pickDefault(categories);
    }

    final isReady = repo != null && categories.isNotEmpty;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l = AppStrings.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: _saving ? null : _onTapOutside,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              l.widgetComposeTitle,
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
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _saving ? null : _onClosePressed,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (categoriesAsync.isLoading && categories.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (categories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              l.widgetComposeNoCategories,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        else ...[
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: l.widgetComposeCategoryLabel,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _selectedCategoryId = v),
                          ),
                          const SizedBox(height: 16),
                          BidiAwareTextField(
                            controller: _titleCtrl,
                            focusNode: _titleFocusNode,
                            enabled: !_saving,
                            style: theme.textTheme.titleMedium,
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
                          Builder(
                            builder: (ctx) {
                              final bodyDir = lockedBodyDirection(
                                  _bodyCtrl.text, Directionality.of(ctx));
                              return ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 96, maxHeight: 200),
                                child: SingleChildScrollView(
                                  child: Listener(
                                    onPointerDown: (e) =>
                                        _lastBodyTapGlobal = e.position,
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
                                      style: theme.textTheme.bodyLarge,
                                      strutStyle:
                                          const StrutStyle(forceStrutHeight: false),
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
                            onPressed:
                                _saving || !isReady ? null : () => _save(repo, categories),
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l.actionSave),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
