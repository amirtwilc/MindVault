import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/ai_search_provider.dart';
import '../../providers/notes_provider.dart';
import '../../../domain/entities/note.dart';

class AiSearchHistoryScreen extends ConsumerWidget {
  const AiSearchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(aiSearchHistoryProvider);
    final allNotes = ref.watch(allNotesProvider).valueOrNull ?? [];
    final notesById = <String, Note>{for (final n in allNotes) n.id: n};
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.aiHistoryTitle),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    l.aiHistoryEmpty,
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: entries.length,
            itemBuilder: (context, i) => _HistoryCard(
              entry: entries[i],
              notesById: notesById,
              cs: cs,
              tt: tt,
              isFirst: i == 0,
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AiHistoryEntry entry;
  final Map<String, Note> notesById;
  final ColorScheme cs;
  final TextTheme tt;
  final bool isFirst;

  const _HistoryCard({
    required this.entry,
    required this.notesById,
    required this.cs,
    required this.tt,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: isFirst,
        title: Text(
          entry.query,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _relativeTime(context, entry.createdAt),
            style: tt.labelSmall?.copyWith(color: cs.outline),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                SelectableText(
                  entry.answer,
                  style:
                      tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.6),
                ),
                if (entry.citedTitles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.article_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        AppStrings.of(context).aiSearchSources,
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < entry.citedTitles.length; i++)
                        _CitedChip(
                          title: entry.citedTitles[i],
                          note: entry.citedNoteIds.length > i
                              ? notesById[entry.citedNoteIds[i]]
                              : null,
                          cs: cs,
                          tt: tt,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(BuildContext context, DateTime dt) {
    final l = AppStrings.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l.aiHistoryRelativeNow;
    if (diff.inHours < 1) return l.aiHistoryRelativeMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l.aiHistoryRelativeHours(diff.inHours);
    return l.aiHistoryRelativeDays(diff.inDays);
  }
}

class _CitedChip extends StatelessWidget {
  final String title;
  final Note? note;
  final ColorScheme cs;
  final TextTheme tt;

  const _CitedChip({
    required this.title,
    required this.note,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final exists = note != null;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: exists ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.note_rounded,
            size: 13,
            color: exists ? cs.onPrimaryContainer : cs.outline,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              style: tt.labelMedium?.copyWith(
                color: exists ? cs.onPrimaryContainer : cs.outline,
                decoration: exists ? null : TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (exists) {
      return GestureDetector(
        onTap: () =>
            context.push('/home/clusters/${note!.categoryId}/edit/${note!.id}'),
        child: chip,
      );
    }
    return chip;
  }
}
