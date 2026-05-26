import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/constants/category_colors.dart';
import '../../../core/constants/category_defaults.dart';
import '../../../core/utils/note_preview.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/widget_sync_provider.dart';

class AllNotesScreen extends ConsumerStatefulWidget {
  const AllNotesScreen({super.key});

  @override
  ConsumerState<AllNotesScreen> createState() => _AllNotesScreenState();
}

class _AllNotesScreenState extends ConsumerState<AllNotesScreen> {
  // Holds an optimistically reordered list so the stream catching up doesn't
  // cause a visible flicker back to the old order. Cleared on next stream emit.
  List<Note>? _optimisticNotes;
  bool _reorderPending = false;

  List<Note> _sorted(List<Note> notes) {
    return notes
      ..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        if (a.isPinned && b.isPinned) {
          final aOrder = a.pinOrder ?? 0;
          final bOrder = b.pinOrder ?? 0;
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        }
        final aTime =
            a.lastOpenedAt != null && a.lastOpenedAt!.isAfter(a.createdAt)
                ? a.lastOpenedAt!
                : a.createdAt;
        final bTime =
            b.lastOpenedAt != null && b.lastOpenedAt!.isAfter(b.createdAt)
                ? b.lastOpenedAt!
                : b.createdAt;
        return bTime.compareTo(aTime);
      });
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(allNotesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cs = Theme.of(context).colorScheme;
    final l = AppStrings.of(context);

    // Clear the optimistic override on the stream emission that follows a reorder.
    ref.listen(allNotesProvider, (_, next) {
      if (_reorderPending && next.hasValue) {
        setState(() {
          _optimisticNotes = null;
          _reorderPending = false;
        });
      }
    });

    final categoryMap = <String, Category>{
      for (final c in categoriesAsync.valueOrNull ?? []) c.id: c,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.navAllNotes)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final categories = categoriesAsync.valueOrNull ?? [];
          final general = categories
              .where((c) => isGeneralCategoryName(c.name))
              .firstOrNull;
          final target =
              general ?? (categories.isEmpty ? null : categories.first);
          if (target == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.allNotesCreateFirst)),
            );
            return;
          }
          context.push('/home/clusters/${target.id}/edit');
        },
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (streamNotes) {
          // Use optimistic state if a reorder just happened; fall back to stream.
          final source = _optimisticNotes ?? streamNotes;
          final valid = _sorted(source
              .where((n) =>
                  categoryMap.isEmpty || categoryMap.containsKey(n.categoryId))
              .toList());

          if (valid.isEmpty) return _EmptyState(cs: cs);

          final pinnedCount = valid.where((n) => n.isPinned).length;

          return ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: valid.length,
            onReorder: (oldIndex, newIndex) {
              if (oldIndex >= pinnedCount) return;
              if (newIndex > pinnedCount) newIndex = pinnedCount;
              if (newIndex > oldIndex) newIndex--;

              final pinned = valid.where((n) => n.isPinned).toList();
              final unpinned = valid.where((n) => !n.isPinned).toList();

              final moved = pinned.removeAt(oldIndex);
              pinned.insert(newIndex.clamp(0, pinned.length), moved);

              // Assign new pinOrder values so the sort produces the correct order.
              final reorderedPinned = pinned
                  .asMap()
                  .entries
                  .map((e) => e.value.copyWith(pinOrder: e.key))
                  .toList();

              setState(() {
                _optimisticNotes = [...reorderedPinned, ...unpinned];
                _reorderPending = true;
              });

              ref.read(noteRepositoryProvider)?.reorderPinnedNotes(
                  reorderedPinned.map((n) => n.id).toList());
            },
            itemBuilder: (context, i) => _NoteCard(
              key: ValueKey(valid[i].id),
              note: valid[i],
              index: i,
              category: categoryMap[valid[i].categoryId],
              ref: ref,
            ),
          );
        },
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final int index;
  final Category? category;
  final WidgetRef ref;
  const _NoteCard({
    required super.key,
    required this.note,
    required this.index,
    required this.category,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final bg = categoryColor(category?.color);
    final fg = categoryTextColor(bg);
    final locale = Localizations.localeOf(context).toString();
    final dateStr =
        DateFormat('MMM d', locale).format(note.updatedAt.toLocal());
    final timeStr = DateFormat('HH:mm').format(note.updatedAt.toLocal());
    final displayTitle = NotePreview.displayTitle(note.title, note.body);
    final previewBody = NotePreview.previewBody(note.title, note.body);

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final deleteAction = SwipeAction(
      performsFirstActionWithFullSwipe: true,
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      color: cs.errorContainer,
      onTap: (handler) async {
        final confirmed = await _confirmDelete(context);
        if (confirmed) {
          await handler(true);
          await _deleteNote(context);
        } else {
          await handler(false);
        }
      },
    );
    final cell = SwipeActionCell(
      key: ObjectKey(note.id),
      leadingActions: isRtl ? null : [deleteAction],
      trailingActions: isRtl ? [deleteAction] : null,
      child: Card(
        color: bg,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onTap: () => _openNote(context),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          horizontalTitleGap: 4,
          minLeadingWidth: 0,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (note.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(Icons.drag_handle,
                      size: 16, color: fg.withOpacity(0.7)),
                ),
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                  color: fg.withOpacity(note.isPinned ? 1.0 : 0.6),
                ),
                onPressed: () {
                  final repo = ref.read(noteRepositoryProvider);
                  repo?.setNotePinned(id: note.id, isPinned: !note.isPinned);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          title: Text(
            displayTitle.isEmpty ? l.noteUntitled : displayTitle,
            style: tt.titleMedium?.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: (previewBody.isEmpty || note.isPrivate)
              ? null
              : Text(
                  previewBody,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: fg.withOpacity(0.75)),
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.isPrivate) ...[
                    Icon(Icons.lock, size: 12, color: fg.withOpacity(0.9)),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    category?.name ?? '',
                    style: tt.labelSmall?.copyWith(color: fg.withOpacity(0.85)),
                  ),
                ],
              ),
              Text(
                dateStr,
                style: tt.labelSmall?.copyWith(color: fg.withOpacity(0.85)),
              ),
              Text(
                timeStr,
                style: tt.labelSmall?.copyWith(color: fg.withOpacity(0.75)),
              ),
            ],
          ),
        ),
      ),
    );

    // Pinned notes use a delayed drag (long-press) so it doesn't conflict with
    // the SwipeActionCell's horizontal swipe gesture recognizer.
    if (note.isPinned) {
      return ReorderableDelayedDragStartListener(
        index: index,
        child: cell,
      );
    }
    return cell;
  }

  Future<void> _openNote(BuildContext context) async {
    final l = AppStrings.of(context);
    if (note.isPrivate && !ref.read(privateNotesUnlockedProvider)) {
      final bio = ref.read(biometricServiceProvider);
      final ok = await bio.authenticate(reason: l.privateAuthReason);
      if (!ok) return;
      ref.read(privateNotesUnlockedProvider.notifier).state = true;
    }
    if (context.mounted) {
      context.push('/home/clusters/${note.categoryId}/edit/${note.id}');
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
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
    return confirmed ?? false;
  }

  Future<void> _deleteNote(BuildContext context) async {
    final l = AppStrings.of(context);
    final repo = ref.read(noteRepositoryProvider);
    if (repo == null) return;
    await repo.deleteNote(note.id);
    await ref.read(widgetDataServiceProvider).patchNoteRemoved(noteId: note.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noteDeletedSnack)));
    }
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyState({required this.cs});

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: cs.outlineVariant),
          const SizedBox(height: 16),
          Text(l.allNotesEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(l.allNotesEmptyBody,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }
}
