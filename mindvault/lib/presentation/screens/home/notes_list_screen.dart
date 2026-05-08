import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/constants/category_colors.dart';
import '../../../core/constants/category_defaults.dart';
import '../../../core/utils/note_preview.dart';
import '../../../domain/entities/note.dart';
import '../../../domain/entities/tier_limits.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/biometric_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tier_provider.dart';
import '../../providers/widget_sync_provider.dart';
import '../../widgets/category_color_picker.dart';

class NotesListScreen extends ConsumerWidget {
  final String categoryId;
  const NotesListScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final notesAsync = ref.watch(notesByCategoryProvider(categoryId));
    final allNotesAsync = ref.watch(allNotesProvider);
    final tier = ref.watch(tierProvider).valueOrNull ?? TierLimits.free();
    final l = AppStrings.of(context);

    final category = categoriesAsync.valueOrNull
        ?.where((c) => c.id == categoryId)
        .firstOrNull;
    final categoryName = category?.name ?? l.notesListTitleFallback;
    final bg = categoryColor(category?.color);
    final fg = categoryTextColor(bg);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: fg,
        iconTheme: IconThemeData(color: fg),
        title: Text(categoryName, style: TextStyle(color: fg)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: fg),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/home/categories'),
        ),
        actions: [
          if (!isGeneralCategoryName(categoryName))
            PopupMenuButton<String>(
              iconColor: fg,
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenameDialog(context, ref, categoryName);
                } else if (value == 'color') {
                  _showColorDialog(context, ref, category?.color);
                } else if (value == 'delete') {
                  _confirmDelete(context, ref, categoryName);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l.renameCategory),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'color',
                  child: ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(l.changeCategoryColor),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l.deleteCategoryAction),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          if (notes.isEmpty) {
            return _EmptyState(color: Theme.of(context).colorScheme);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notes.length,
            itemBuilder: (context, i) => _NoteCard(
              note: notes[i],
              categoryId: categoryId,
              cardColor: bg,
              ref: ref,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: bg,
        foregroundColor: fg,
        onPressed: () {
          final totalNotes = allNotesAsync.valueOrNull?.length ?? 0;
          if (totalNotes >= tier.maxNotes) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l.noteLimitReached(
                    tier.maxNotes,
                    tier.tier == 'free' ? l.upgradeHintFree : l.upgradeHintNone,
                  ),
                ),
              ),
            );
            return;
          }
          context.push('/home/categories/$categoryId/edit');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, String currentName) async {
    final l = AppStrings.of(context);
    final controller = TextEditingController(text: currentName);
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: currentName.length);
    String? nameError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.renameCategoryDialog),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l.categoryNameHint,
              errorText: nameError,
            ),
            autofocus: true,
            maxLength: 20,
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty || name == currentName) {
                  Navigator.pop(dialogContext, false);
                  return;
                }
                final cats = ref.read(categoriesProvider).valueOrNull ?? [];
                if (cats.any((c) =>
                    c.name.toLowerCase() == name.toLowerCase())) {
                  setDialogState(() => nameError = l.categoryNameInUse);
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(l.actionRename),
            ),
          ],
        ),
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (confirmed == true && name.isNotEmpty && name != currentName) {
      await ref
          .read(categoriesProvider.notifier)
          .renameCategory(categoryId, name);
    }
  }

  Future<void> _showColorDialog(
      BuildContext context, WidgetRef ref, String? currentColor) async {
    final l = AppStrings.of(context);
    final colorNotifier =
        ValueNotifier<String>(currentColor ?? kCategoryColors.first);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ValueListenableBuilder<String>(
        valueListenable: colorNotifier,
        builder: (_, selected, __) => AlertDialog(
          title: Text(l.categoryColorDialog),
          content: CategoryColorPicker(
            selected: selected,
            onChanged: (c) => colorNotifier.value = c,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.actionApply),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && colorNotifier.value != currentColor) {
      await ref
          .read(categoriesProvider.notifier)
          .updateCategoryColor(categoryId, colorNotifier.value);
    }
    colorNotifier.dispose();
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String name) async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteCategoryConfirmTitle(name)),
        content: Text(l.deleteCategoryConfirmBody),
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
    if (confirmed == true) {
      await ref.read(categoriesProvider.notifier).deleteCategory(categoryId);
      if (context.mounted) context.go('/home/categories');
    }
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final String categoryId;
  final Color cardColor;
  final WidgetRef ref;
  const _NoteCard({
    required this.note,
    required this.categoryId,
    required this.cardColor,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final fg = categoryTextColor(cardColor);
    final displayTitle = NotePreview.displayTitle(note.title, note.body);
    final previewBody = NotePreview.previewBody(note.title, note.body);

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Dismissible(
      key: ValueKey(note.id),
      direction: isRtl ? DismissDirection.endToStart : DismissDirection.startToEnd,
      background: Container(
        alignment: isRtl
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        padding: isRtl
            ? const EdgeInsetsDirectional.only(end: 24)
            : const EdgeInsetsDirectional.only(start: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) => _confirmNoteDelete(context),
      onDismissed: (_) => _deleteNote(context),
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onTap: () => _openNote(context),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: fg.withOpacity(0.75)),
                ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (note.isPrivate)
                Icon(Icons.lock, size: 14, color: fg.withOpacity(0.9)),
              Text(
                DateFormat('MMM d',
                        Localizations.localeOf(context).toString())
                    .format(note.updatedAt.toLocal()),
                style: tt.labelSmall?.copyWith(color: fg.withOpacity(0.75)),
              ),
              Text(
                DateFormat('HH:mm').format(note.updatedAt.toLocal()),
                style: tt.labelSmall?.copyWith(color: fg.withOpacity(0.75)),
              ),
            ],
          ),
        ),
      ),
    );
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
      context.push('/home/categories/$categoryId/edit/${note.id}');
    }
  }

  Future<bool> _confirmNoteDelete(BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.noteDeletedSnack)),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme color;
  const _EmptyState({required this.color});

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_outlined, size: 64, color: color.outlineVariant),
          const SizedBox(height: 16),
          Text(l.notesListEmptyTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(l.notesListEmptyBody,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color.outline)),
        ],
      ),
    );
  }
}
