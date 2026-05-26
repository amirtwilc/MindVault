import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/category_colors.dart';
import '../../../core/utils/note_preview.dart';
import '../../../domain/entities/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/categories_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/notes_provider.dart';
import 'widget_compose_screen.dart';
import 'widget_note_view_screen.dart';

/// Floating window opened from the home-screen Categories widget. Lists every
/// note in [categoryId] in the same order as the in-app category screen
/// (pinned first, then by recency). Tapping a note swaps in the read-mode
/// note viewer **in place** (no GoRouter push/transition — eliminates the
/// white-flash that used to appear during the route transition). The same
/// in-place swap is used for the "+ create note" button.
class WidgetCategoryNotesScreen extends ConsumerStatefulWidget {
  final String categoryId;

  /// Pre-decoded category name from the deep-link query — rendered in the
  /// header on the first frame so the user doesn't see a flash of empty title
  /// before [categoriesProvider] resolves.
  final String? initialName;

  const WidgetCategoryNotesScreen({
    super.key,
    required this.categoryId,
    this.initialName,
  });

  @override
  ConsumerState<WidgetCategoryNotesScreen> createState() =>
      _WidgetCategoryNotesScreenState();
}

enum _Mode { list, viewNote, compose }

class _WidgetCategoryNotesScreenState
    extends ConsumerState<WidgetCategoryNotesScreen> {
  _Mode _mode = _Mode.list;
  String? _viewingNoteId;
  String? _viewingNoteTitle;

  @override
  void initState() {
    super.initState();
    // Bootstrap the AES key for the compose/view child screens. The list
    // itself reads [notesByCategoryLocalProvider] and does not need the key,
    // but tapping a note (→ WidgetNoteViewScreen) or "+ create" (→
    // WidgetComposeScreen) will hit code paths that encrypt outgoing writes
    // and decrypt private-note bodies. Loading the key here means the user
    // doesn't see a spinner on their first tap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureKeyLoaded());
  }

  Future<void> _ensureKeyLoaded() async {
    if (!mounted) return;
    if (ref.read(aesKeyProvider) != null) return;
    final key = await ref.read(encryptionServiceProvider).loadKey();
    if (key != null && mounted) {
      ref.read(aesKeyProvider.notifier).state = key;
    }
  }

  void _openNote(Note note) {
    setState(() {
      _mode = _Mode.viewNote;
      _viewingNoteId = note.id;
      _viewingNoteTitle = NotePreview.displayTitle(note.title, note.body);
    });
  }

  void _openCompose() {
    setState(() => _mode = _Mode.compose);
  }

  @override
  Widget build(BuildContext context) {
    // Render the inner widget directly (its own transparent Scaffold takes
    // over). No GoRouter transition, no white frame.
    switch (_mode) {
      case _Mode.viewNote:
        return WidgetNoteViewScreen(
          // Re-key so a different noteId tears down the previous state.
          key: ValueKey('view-${_viewingNoteId!}'),
          noteId: _viewingNoteId!,
          initialTitle: _viewingNoteTitle,
          onClose: _returnToList,
        );
      case _Mode.compose:
        return WidgetComposeScreen(
          key: ValueKey('compose-${widget.categoryId}'),
          initialCategoryId: widget.categoryId,
          onClose: _returnToList,
        );
      case _Mode.list:
        return _buildList(context);
    }
  }

  void _returnToList() {
    if (!mounted) return;
    setState(() {
      _mode = _Mode.list;
      _viewingNoteId = null;
      _viewingNoteTitle = null;
    });
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final categoriesAsync = ref.watch(categoriesProvider);
    final category = categoriesAsync.valueOrNull
        ?.where((c) => c.id == widget.categoryId)
        .firstOrNull;
    final headerName = category?.name ?? widget.initialName ?? '';
    final cardAccent = categoryColor(category?.color);

    // Read directly from the local Drift DB (plaintext rows) — bypassing the
    // AES-key gate on `noteRepositoryProvider` lets the list paint as soon as
    // the engine boots, instead of after `flutter_secure_storage.read()`.
    final notesAsync =
        ref.watch(notesByCategoryLocalProvider(widget.categoryId));

    // Cap the inner list at ~60% of the viewport so the floating card stays
    // visually centered on tablets/foldables without growing edge-to-edge.
    final listMaxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => SystemNavigator.pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: GestureDetector(
              onTap: () {}, // absorb taps inside the card
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          name: headerName,
                          accent: cardAccent,
                          theme: theme,
                          onAddNote: _openCompose,
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: listMaxHeight),
                          child: notesAsync.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Padding(
                              padding: const EdgeInsets.all(16),
                              child:
                                  Text('$e', style: theme.textTheme.bodySmall),
                            ),
                            data: (notes) => notes.isEmpty
                                ? _EmptyState(theme: theme)
                                : _NoteList(
                                    notes: notes,
                                    onTap: _openNote,
                                  ),
                          ),
                        ),
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

class _Header extends StatelessWidget {
  final String name;
  final Color accent;
  final ThemeData theme;
  final VoidCallback onAddNote;

  const _Header({
    required this.name,
    required this.accent,
    required this.theme,
    required this.onAddNote,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: l.widgetAddNoteTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onAddNote,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          visualDensity: VisualDensity.compact,
          onPressed: () => SystemNavigator.pop(),
        ),
      ],
    );
  }
}

class _NoteList extends StatelessWidget {
  final List<Note> notes;
  final ValueChanged<Note> onTap;

  const _NoteList({required this.notes, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppStrings.of(context);

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: notes.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.4),
      ),
      itemBuilder: (context, i) {
        final note = notes[i];
        final title = NotePreview.displayTitle(note.title, note.body);
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          title: Text(
            title.isEmpty ? l.noteUntitled : title,
            style: tt.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.isPinned)
                Icon(Icons.push_pin,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
              if (note.isPrivate) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock,
                    size: 14,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
              ],
            ],
          ),
          onTap: () => onTap(note),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_outlined,
              size: 40, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            l.notesListEmptyTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
