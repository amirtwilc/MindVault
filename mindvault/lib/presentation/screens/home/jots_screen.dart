import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/category_defaults.dart';
import '../../../core/constants/category_colors.dart';
import '../../../core/constants/jot_constants.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/jot.dart';
import '../../../domain/entities/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/jot_action_service.dart';
import '../../../services/jots_ai_service.dart';
import '../../providers/categories_provider.dart';
import '../../providers/jots_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/category_color_picker.dart';
import '../../widgets/mindvault_nav_icons.dart';
import '../../widgets/reminder_background_permission_prompt.dart';
import '_ai_search_widgets.dart' show SttMixin;

class JotsScreen extends ConsumerStatefulWidget {
  final String? highlightJotId;

  const JotsScreen({super.key, this.highlightJotId});

  @override
  ConsumerState<JotsScreen> createState() => _JotsScreenState();
}

class _JotsScreenState extends ConsumerState<JotsScreen>
    with SttMixin<JotsScreen> {
  final Set<String> _selectedIds = {};

  bool get _selecting => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    initStt();
  }

  @override
  void dispose() {
    stopStt();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final jotsAsync = ref.watch(unhandledJotsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final notes = ref.watch(allNotesProvider).valueOrNull ?? [];
    final sortOrder = ref.watch(jotSortOrderProvider);
    final aiState = ref.watch(jotsAiControllerProvider);
    final l = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    ref.listen<JotsAiState>(jotsAiControllerProvider, (previous, next) {
      if (!mounted) return;
      switch (next) {
        case JotsAiSuccess(:final result):
          _showAiResultDialog(result);
        case JotsAiNoNewThoughts():
          _snack(l.jotsAiNoNew);
        case JotsAiRateLimited():
          _snack(l.jotsAiQuota);
        case JotsAiFailure():
          _snack(l.jotsAiFailed);
        default:
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _selecting ? l.jotsSelectedCount(_selectedIds.length) : l.navJots),
        actions: [
          if (_selecting)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.actionDelete,
              onPressed: () => _deleteSelected(),
            )
          else ...[
            IconButton(
              icon: Icon(sortOrder == JotSortOrder.oldestFirst
                  ? Icons.arrow_downward
                  : Icons.arrow_upward),
              tooltip: sortOrder == JotSortOrder.oldestFirst
                  ? l.jotsSortOldestFirst
                  : l.jotsSortNewestFirst,
              onPressed: () {
                ref.read(jotSortOrderProvider.notifier).setOrder(
                      sortOrder == JotSortOrder.oldestFirst
                          ? JotSortOrder.newestFirst
                          : JotSortOrder.oldestFirst,
                    );
              },
            ),
          ],
        ],
      ),
      body: jotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (jots) {
          final suggestionCount =
              jots.where((jot) => jot.aiSuggestion != null).length;
          if (jots.isEmpty) return _EmptyJotsState(colorScheme: cs);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: aiState is JotsAiLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(l.jotsOrganizeAi),
                        onPressed: aiState is JotsAiLoading
                            ? null
                            : () => ref
                                .read(jotsAiControllerProvider.notifier)
                                .organize(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: l.jotsAiInfoTitle,
                      onPressed: _showAiInfo,
                    ),
                  ],
                ),
              ),
              if (suggestionCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.done_all),
                      label: Text(l.jotsAcceptAll),
                      onPressed: () => _acceptSuggestions(),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  itemCount: jots.length,
                  itemBuilder: (context, index) {
                    final jot = jots[index];
                    return _JotCard(
                      jot: jot,
                      highlighted: jot.id == widget.highlightJotId,
                      selected: _selectedIds.contains(jot.id),
                      selecting: _selecting,
                      onLongPress: () => _toggleSelection(jot.id),
                      onTap: _selecting
                          ? () => _toggleSelection(jot.id)
                          : () => _openActions(jot, categories, notes),
                      onActions: () => _openActions(jot, categories, notes),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.jotsAddTooltip,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.jotsDeleteSelectedTitle),
        content: Text(l.jotsDeleteSelectedBody),
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
    if (confirmed != true) return;
    final ids = _selectedIds.toList();
    await ref.read(jotRepositoryProvider)?.deleteJots(ids);
    for (final id in ids) {
      await ref.read(jotReminderSchedulerProvider).cancel(id);
    }
    if (mounted) setState(_selectedIds.clear);
  }

  Future<void> _showAddDialog() async {
    final l = AppStrings.of(context);
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final count = controller.text.length;
          return AlertDialog(
            title: Text(l.jotAddDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: JotConstants.maxChars,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  minLines: 1,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(JotConstants.maxChars),
                  ],
                  decoration: InputDecoration(
                    hintText: l.jotInputHint,
                    counterText: '',
                    suffixIcon: sttAvailable
                        ? IconButton(
                            tooltip:
                                listening ? l.editorSttStop : l.editorSttRecord,
                            icon: Icon(listening ? Icons.mic : Icons.mic_none),
                            color: listening
                                ? Theme.of(context).colorScheme.error
                                : null,
                            onPressed: () async {
                              await toggleListen((text) {
                                _insertSparkText(controller, text);
                                setDialogState(() {});
                              });
                              setDialogState(() {});
                            },
                          )
                        : null,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setDialogState(() {}),
                  onSubmitted: (_) => Navigator.pop(ctx, true),
                ),
                if (count >= JotConstants.showCounterAtChars)
                  Text(
                    l.jotCharCounter(count, JotConstants.maxChars),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: count >= JotConstants.maxChars
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.actionCancel),
              ),
              FilledButton(
                onPressed: controller.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: Text(l.actionSave),
              ),
            ],
          );
        },
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (saved == true && text.isNotEmpty) {
      await ref.read(jotRepositoryProvider)?.createJot(text: text);
      _snack(l.jotSavedSnack);
    }
  }

  void _insertSparkText(TextEditingController controller, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final insertText = '$trimmed ';
    final sel = controller.selection;
    final raw = controller.text;
    if (sel.isValid) {
      final start = sel.start.clamp(0, raw.length);
      final end = sel.end.clamp(0, raw.length);
      final next = raw.replaceRange(start, end, insertText);
      controller.value = controller.value.copyWith(
        text: next,
        selection: TextSelection.collapsed(offset: start + insertText.length),
      );
    } else {
      controller.text = raw.isEmpty ? trimmed : '$raw $trimmed';
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);
    }
  }

  Future<void> _openActions(
    Jot jot,
    List<Category> categories,
    List<Note> notes,
  ) async {
    final result = await showModalBottomSheet<JotActionResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => JotActionSheet(
        jot: jot,
        categories: categories,
        notes: notes,
      ),
    );
    if (result == null) return;
    await _scheduleResult(result);
    if (result.handled || result.deleted || result.cancelJotReminder) {
      await ref.read(jotReminderSchedulerProvider).cancel(jot.id);
    }
  }

  Future<void> _scheduleResult(JotActionResult result) async {
    final l = AppStrings.of(context);
    if (result.noteReminder != null && result.note != null) {
      await ref.read(reminderSchedulerProvider).schedule(
            reminder: result.noteReminder!,
            note: result.note!,
            untitledFallback: l.noteUntitled,
            notificationBody: l.reminderNotificationBody,
          );
    }
    if (result.jotReminder != null) {
      await ref.read(jotReminderSchedulerProvider).schedule(
            jot: result.jotReminder!,
            notificationBody: l.jotNotificationBody,
          );
    }
    if (result.noteReminder != null || result.jotReminder != null) {
      await maybeShowReminderBackgroundPermissionPrompt(context, ref);
    }
  }

  Future<void> _showAiResultDialog(JotsAiRunResult result) async {
    final l = AppStrings.of(context);
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.jotsOrganizeAi),
        content: Text([
          l.jotsAiSuggestionsProvided(result.suggestions.length),
          if (result.limitedToThirty) l.jotsAiLimitedTo30,
        ].join('\n\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionClose),
          ),
          if (result.suggestions.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.jotsAcceptAll),
            ),
        ],
      ),
    );
    if (accept == true) {
      await _acceptSuggestions(runId: result.runId);
    }
  }

  Future<void> _acceptSuggestions({String? runId}) async {
    final jots = ref.read(unhandledJotsProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final notes = ref.read(allNotesProvider).valueOrNull ?? [];
    final service = ref.read(jotActionServiceProvider);
    final l = AppStrings.of(context);
    if (service == null || categories.isEmpty) return;
    final candidates = jots.where((jot) {
      final suggestion = jot.aiSuggestion;
      return suggestion != null &&
          (runId == null || jot.aiSuggestionRunId == runId);
    }).toList();
    if (candidates.isEmpty) return;

    if (candidates.any((j) => j.aiSuggestion?.reminderAt != null)) {
      final permission = await ref
          .read(reminderSchedulerProvider)
          .ensureSchedulingPermissionsForUserAction();
      if (!permission.notificationsAllowed) {
        _snack(l.reminderNotificationsRequired);
        return;
      }
    }

    final fallbackCategoryId = _defaultCategoryId(categories);
    for (final jot in candidates) {
      final suggestion = jot.aiSuggestion;
      if (suggestion == null) continue;
      final request = _requestFromSuggestion(
        suggestion,
        fallbackCategoryId: fallbackCategoryId,
        categories: categories,
      );
      if (request.addToNote &&
          !notes.any((note) => note.id == request.existingNoteId)) {
        continue;
      }
      final result = await service.apply(jot: jot, request: request);
      await _scheduleResult(result);
      if (result.handled || result.deleted || result.cancelJotReminder) {
        await ref.read(jotReminderSchedulerProvider).cancel(jot.id);
      }
    }
  }

  JotActionRequest _requestFromSuggestion(
    JotAiSuggestion suggestion, {
    required String fallbackCategoryId,
    required List<Category> categories,
  }) {
    final categoryId = suggestion.categoryId ??
        _categoryIdForName(categories, suggestion.categoryName) ??
        fallbackCategoryId;
    return switch (suggestion.action) {
      JotSuggestedAction.createNote => JotActionRequest(
          createNote: true,
          createAlert: suggestion.reminderAt != null,
          newNoteTitle: suggestion.title,
          newNoteCategoryId: categoryId,
          newNoteType: NoteType.fromStorage(suggestion.noteType ?? 'record'),
          newNoteLocked: suggestion.isPrivate ?? false,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
      JotSuggestedAction.addToNote => JotActionRequest(
          addToNote: true,
          createAlert: suggestion.reminderAt != null,
          existingNoteId: suggestion.noteId,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
      JotSuggestedAction.reminder => JotActionRequest(
          createAlert: true,
          reminderAt: suggestion.reminderAt,
          updatedText: suggestion.updatedText,
        ),
    };
  }

  void _showAiInfo() {
    final l = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.jotsAiInfoTitle),
        content: Text(l.jotsAiInfoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionOk),
          ),
        ],
      ),
    );
  }

  String _defaultCategoryId(List<Category> categories) {
    final general = categories
        .where((category) => isGeneralCategoryName(category.name))
        .firstOrNull;
    return (general ?? categories.first).id;
  }

  String? _categoryIdForName(List<Category> categories, String? name) {
    if (name == null) return null;
    final normalized = name.toLowerCase();
    for (final category in categories) {
      if (category.name.toLowerCase() == normalized) return category.id;
    }
    return null;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _JotCard extends StatelessWidget {
  final Jot jot;
  final bool highlighted;
  final bool selected;
  final bool selecting;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onActions;

  const _JotCard({
    required this.jot,
    required this.highlighted,
    required this.selected,
    required this.selecting,
    required this.onLongPress,
    required this.onTap,
    required this.onActions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final formatter =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();
    final suggestion = jot.aiSuggestion;
    return Card(
      color: selected ? cs.primaryContainer : null,
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: cs.primary, width: 2),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selecting)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8, top: 2),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? cs.primary : cs.outline,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(jot.text, style: tt.bodyLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l.jotCreatedAt(
                            formatter.format(jot.createdAt.toLocal()),
                          ),
                          style: tt.labelSmall?.copyWith(color: cs.outline),
                        ),
                        if (suggestion != null)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(l.jotActionSuggestedByAi),
                            avatar: const Icon(Icons.auto_awesome, size: 14),
                          ),
                        if (jot.reminderAt != null &&
                            jot.reminderAt!.isAfter(DateTime.now().toUtc()))
                          Icon(Icons.notifications_active,
                              size: 16, color: cs.primary),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.jotActionsTooltip,
                icon: const Icon(Icons.more_vert),
                onPressed: onActions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyJotsState extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyJotsState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MindVaultNavIcon(
              kind: MindVaultNavIconKind.sparks,
              size: 64,
              color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            l.jotsEmptyTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            l.jotsEmptyBody,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class JotActionSheet extends ConsumerStatefulWidget {
  final Jot jot;
  final List<Category> categories;
  final List<Note> notes;

  const JotActionSheet({
    super.key,
    required this.jot,
    required this.categories,
    required this.notes,
  });

  @override
  ConsumerState<JotActionSheet> createState() => _JotActionSheetState();
}

class _JotActionSheetState extends ConsumerState<JotActionSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _thoughtCtrl;
  bool _createNote = false;
  bool _addToNote = false;
  bool _createAlert = false;
  bool _updateThought = false;
  bool _deleteThought = false;
  bool _locked = false;
  NoteType _noteType = NoteType.text;
  String? _createCategoryId;
  String? _addCategoryId;
  String? _existingNoteId;
  DateTime? _reminderAt;
  bool _saving = false;

  JotAiSuggestion? get _suggestion => widget.jot.aiSuggestion;
  bool get _hasExistingReminder =>
      widget.jot.reminderAt?.isAfter(DateTime.now().toUtc()) == true;
  bool get _cancelsExistingReminder => _hasExistingReminder && !_createAlert;

  @override
  void initState() {
    super.initState();
    final suggestion = _suggestion;
    _titleCtrl = TextEditingController(text: suggestion?.title ?? '');
    _thoughtCtrl = TextEditingController(
      text: suggestion?.updatedText?.trim().isNotEmpty == true
          ? suggestion!.updatedText
          : widget.jot.text,
    );
    final fallback = _defaultCategoryId(widget.categories);
    final suggestedCategory =
        _categoryIdForName(widget.categories, suggestion?.categoryName);
    _existingNoteId = suggestion?.noteId;
    final suggestedNoteCategory =
        _categoryIdForNoteId(widget.notes, _existingNoteId);
    _createCategoryId = suggestion?.categoryId ?? suggestedCategory ?? fallback;
    _addCategoryId = suggestion?.action == JotSuggestedAction.addToNote
        ? suggestedNoteCategory ?? _createCategoryId
        : _createCategoryId;
    _reminderAt = (suggestion?.reminderAt ?? widget.jot.reminderAt)?.toLocal();
    _locked = suggestion?.isPrivate ?? false;
    _noteType = NoteType.fromStorage(suggestion?.noteType ?? 'record');
    if (suggestion != null) {
      _createNote = suggestion.action == JotSuggestedAction.createNote;
      _addToNote = suggestion.action == JotSuggestedAction.addToNote;
      _createAlert = suggestion.reminderAt != null ||
          suggestion.action == JotSuggestedAction.reminder;
      _updateThought = suggestion.updatedText?.trim().isNotEmpty == true;
    } else if (_hasExistingReminder) {
      _createAlert = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _thoughtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;
    final filteredNotes = _addableNotesForCategory(_addCategoryId);
    if (_existingNoteId != null &&
        !filteredNotes.any((note) => note.id == _existingNoteId)) {
      _existingNoteId = filteredNotes.firstOrNull?.id;
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.jotActionsTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.jot.text),
              if (_suggestion != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.jotActionSuggestedByAi,
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _updateThought,
                title: Text(l.jotActionUpdateThought),
                onChanged: _saving || _deleteThought
                    ? null
                    : (value) => setState(() {
                          _updateThought = value ?? false;
                          if (_updateThought &&
                              _thoughtCtrl.text.trim().isEmpty) {
                            _thoughtCtrl.text = widget.jot.text;
                          }
                        }),
              ),
              if (_updateThought) _buildUpdateThoughtField(l),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _createNote,
                title: Text(l.jotActionCreateNote),
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _createNote = value ?? false;
                          if (_createNote) {
                            _addToNote = false;
                            _deleteThought = false;
                          }
                        }),
              ),
              if (_createNote) _buildCreateNoteFields(l),
              CheckboxListTile(
                value: _addToNote,
                title: Text(l.jotActionAddToNote),
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _addToNote = value ?? false;
                          if (_addToNote) {
                            _createNote = false;
                            _deleteThought = false;
                          }
                        }),
              ),
              if (_addToNote) _buildAddToNoteFields(l, filteredNotes),
              CheckboxListTile(
                value: _createAlert,
                title: Text(l.jotActionCreateAlert),
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _createAlert = value ?? false;
                          if (_createAlert) _deleteThought = false;
                        }),
              ),
              if (_createAlert) _buildReminderField(l),
              CheckboxListTile(
                value: _deleteThought,
                title: Text(l.jotActionDeleteThought),
                onChanged: _saving
                    ? null
                    : (value) => setState(() {
                          _deleteThought = value ?? false;
                          if (_deleteThought) {
                            _createNote = false;
                            _addToNote = false;
                            _createAlert = false;
                            _updateThought = false;
                          }
                        }),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || !_isValid ? null : _accept,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.jotActionAccept),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNoteFields(AppStrings l) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
      child: Column(
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(labelText: l.jotActionNewNoteTitle),
          ),
          const SizedBox(height: 8),
          _categoryPicker(
            label: l.jotActionCategory,
            value: _createCategoryId,
            onChanged: (value) => setState(() => _createCategoryId = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<NoteType>(
            initialValue: _noteType,
            decoration: InputDecoration(labelText: l.noteTypeLabel),
            items: [
              DropdownMenuItem(
                  value: NoteType.text, child: Text(l.noteTypeText)),
              DropdownMenuItem(
                value: NoteType.checklist,
                child: Text(l.noteTypeChecklist),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _noteType = value);
            },
          ),
          SwitchListTile(
            value: _locked,
            title: Text(l.jotActionLock),
            onChanged: (value) => setState(() => _locked = value),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateThoughtField(AppStrings l) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
      child: TextField(
        controller: _thoughtCtrl,
        decoration: InputDecoration(
          labelText: l.jotActionUpdatedThoughtText,
          hintText: l.jotActionUpdatedThoughtHint,
        ),
        maxLength: JotConstants.maxChars,
        minLines: 1,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        inputFormatters: [
          LengthLimitingTextInputFormatter(JotConstants.maxChars),
        ],
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildAddToNoteFields(AppStrings l, List<Note> filteredNotes) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
      child: Column(
        children: [
          _categoryPicker(
            label: l.jotActionCategory,
            value: _addCategoryId,
            onChanged: (value) => setState(() {
              _addCategoryId = value;
              _existingNoteId = _addableNotesForCategory(value).firstOrNull?.id;
            }),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _existingNoteId,
            decoration: InputDecoration(labelText: l.jotActionNote),
            items: filteredNotes
                .map((note) => DropdownMenuItem(
                      value: note.id,
                      child: Text(
                          note.title.isEmpty ? l.noteUntitled : note.title),
                    ))
                .toList(),
            onChanged: filteredNotes.isEmpty
                ? null
                : (value) => setState(() => _existingNoteId = value),
          ),
          if (filteredNotes.isEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.jotActionNoNotes),
              ),
            ),
        ],
      ),
    );
  }

  List<Note> _addableNotesForCategory(String? categoryId) {
    return widget.notes
        .where((note) => note.categoryId == categoryId)
        .where((note) => note.title.trim().isNotEmpty)
        .toList();
  }

  Widget _buildReminderField(AppStrings l) {
    final formatter = DateFormat.yMMMd().add_jm();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.notifications_none),
        title: Text(_reminderAt == null
            ? l.jotActionPickReminder
            : l.jotActionReminderWhen(
                formatter.format(_reminderAt!.toLocal()))),
        onTap: _pickReminderTime,
      ),
    );
  }

  Widget _categoryPicker({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final l = AppStrings.of(context);
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(labelText: label),
            items: widget.categories
                .map((category) => DropdownMenuItem(
                      value: category.id,
                      child: Text(category.name),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l.jotActionNewCategory,
          icon: const Icon(Icons.create_new_folder_outlined),
          onPressed: _showNewCategoryDialog,
        ),
      ],
    );
  }

  bool get _isValid {
    if (_deleteThought) return true;
    final updatedText = _thoughtCtrl.text.trim();
    final hasUpdatedThought = _updateThought &&
        updatedText.isNotEmpty &&
        updatedText != widget.jot.text.trim();
    if (_updateThought && updatedText.isEmpty) return false;
    if (_createNote &&
        (_createCategoryId == null || _createCategoryId!.isEmpty)) {
      return false;
    }
    if (_addToNote && (_existingNoteId == null || _existingNoteId!.isEmpty)) {
      return false;
    }
    if (_createAlert && _reminderAt == null) return false;
    return hasUpdatedThought ||
        _createNote ||
        _addToNote ||
        _createAlert ||
        _cancelsExistingReminder;
  }

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();
    final seed = _reminderAt != null && _reminderAt!.isAfter(now)
        ? _reminderAt!
        : now.add(const Duration(minutes: 5));
    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null) return;
    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showNewCategoryDialog() async {
    final l = AppStrings.of(context);
    final controller = TextEditingController();
    String selectedColor = kCategoryColors.first;
    String? nameError;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                onChanged: (color) =>
                    setDialogState(() => selectedColor = color),
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
    if (confirmed == true && name.isNotEmpty) {
      final id = await ref
          .read(categoriesProvider.notifier)
          .createCategory(name, color: selectedColor);
      if (id != null && mounted) {
        setState(() {
          _createCategoryId = id;
          _addCategoryId = id;
        });
      }
    }
  }

  Future<void> _accept() async {
    final l = AppStrings.of(context);
    if (_createAlert) {
      if (_reminderAt == null || !_reminderAt!.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.jotActionChooseFuture)));
        return;
      }
      final permission = await ref
          .read(reminderSchedulerProvider)
          .ensureSchedulingPermissionsForUserAction();
      if (!permission.notificationsAllowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.reminderNotificationsRequired)),
          );
        }
        return;
      }
    }

    final service = ref.read(jotActionServiceProvider);
    if (service == null) return;
    setState(() => _saving = true);
    try {
      final result = await service.apply(
        jot: widget.jot,
        request: JotActionRequest(
          deleteThought: _deleteThought,
          createNote: _createNote,
          addToNote: _addToNote,
          createAlert: _createAlert,
          newNoteTitle: _titleCtrl.text,
          newNoteCategoryId: _createCategoryId,
          newNoteType: _noteType,
          newNoteLocked: _locked,
          existingNoteId: _existingNoteId,
          reminderAt: _reminderAt,
          updatedText: _updateThought ? _thoughtCtrl.text : null,
          cancelJotReminder: _cancelsExistingReminder,
        ),
      );
      if (mounted) Navigator.pop(context, result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _categoryIdForName(List<Category> categories, String? name) {
    if (name == null) return null;
    final normalized = name.toLowerCase();
    for (final category in categories) {
      if (category.name.toLowerCase() == normalized) return category.id;
    }
    return null;
  }

  String? _categoryIdForNoteId(List<Note> notes, String? noteId) {
    if (noteId == null) return null;
    return notes.where((note) => note.id == noteId).firstOrNull?.categoryId;
  }

  String? _defaultCategoryId(List<Category> categories) {
    if (categories.isEmpty) return null;
    final general = categories
        .where((category) => isGeneralCategoryName(category.name))
        .firstOrNull;
    return (general ?? categories.first).id;
  }
}
