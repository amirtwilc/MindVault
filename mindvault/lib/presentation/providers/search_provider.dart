import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/note.dart';
import 'categories_provider.dart';
import 'notes_provider.dart';

class SearchResult {
  final Note note;
  final Category? category;
  final List<String> matchingLines;
  final int score;

  const SearchResult({
    required this.note,
    required this.category,
    required this.matchingLines,
    this.score = 0,
  });
}

/// Scored, multi-tier search over decrypted notes. All in-memory — FTS5 indexes
/// ciphertext and is not useful here.
///
/// Tier 1 (exact phrase): full query string appears verbatim → title +100, body +50.
/// Tier 2 (AND): every token present → title +40, body +20 (skipped if tier-1 already matched).
/// Tier 3 (substring): per-token additive → title +8, body +4 (covers OR and spec's "Prefix").
/// Boosters: isPinned +15; recency ≤7d +10, ≤30d +5.
/// Sort: score desc, tie-break by most-recently-touched desc.
List<SearchResult> filterNotesForSearch(
  String query,
  List<Note> notes,
  Map<String, Category> categoryMap, {
  DateTime? now,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final ref = now ?? DateTime.now();
  final results = <SearchResult>[];

  for (final note in notes) {
    if (note.isPrivate) continue;

    final titleLow = note.title.toLowerCase();
    final bodyLow = note.body.toLowerCase();
    int score = 0;

    // Tier 1 — exact phrase
    final exactTitle = titleLow.contains(q);
    final exactBody = bodyLow.contains(q);
    if (exactTitle) score += 100;
    if (exactBody) score += 50;

    // Per-field AND coverage: all tokens must appear in the same field
    final titleAllTokens = tokens.every((t) => titleLow.contains(t));
    final bodyAllTokens = tokens.every((t) => bodyLow.contains(t));

    // Exclude notes where no single field covers every token (no OR hits)
    if (!exactTitle && !exactBody && !titleAllTokens && !bodyAllTokens) continue;

    // Tier 2 — all tokens AND (only when tier 1 didn't already match that field)
    if (!exactTitle && titleAllTokens) score += 40;
    if (!exactBody && bodyAllTokens) score += 20;

    // Tier 3 — per-token additive only within fields where all tokens matched
    for (final t in tokens) {
      if (titleAllTokens && titleLow.contains(t)) score += 8;
      if (bodyAllTokens && bodyLow.contains(t)) score += 4;
    }

    // Pinned boost
    if (note.isPinned) score += 15;

    // Recency boost — mirrors widget_data_service.dart "most recently touched" logic
    final touched = (note.lastOpenedAt != null && note.lastOpenedAt!.isAfter(note.createdAt))
        ? note.lastOpenedAt!
        : note.createdAt;
    final ageDays = ref.difference(touched).inDays;
    if (ageDays <= 7) {
      score += 10;
    } else if (ageDays <= 30) {
      score += 5;
    }

    // Matching lines — only lines containing the full phrase or all tokens
    final matchingLines = note.body.split('\n').where((line) {
      if (line.trim().isEmpty) return false;
      final ll = line.toLowerCase();
      return ll.contains(q) || tokens.every(ll.contains);
    }).toList();

    results.add(SearchResult(
      note: note,
      category: categoryMap[note.categoryId],
      matchingLines: matchingLines,
      score: score,
    ));
  }

  results.sort((a, b) {
    final cmp = b.score.compareTo(a.score);
    if (cmp != 0) return cmp;
    // Tie-break: most recently touched first
    final aT = (a.note.lastOpenedAt != null && a.note.lastOpenedAt!.isAfter(a.note.createdAt))
        ? a.note.lastOpenedAt!
        : a.note.createdAt;
    final bT = (b.note.lastOpenedAt != null && b.note.lastOpenedAt!.isAfter(b.note.createdAt))
        ? b.note.lastOpenedAt!
        : b.note.createdAt;
    return bT.compareTo(aT);
  });

  return results;
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final notes = ref.watch(allNotesProvider).valueOrNull ?? [];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final categoryMap = <String, Category>{
    for (final c in categories) c.id: c,
  };
  return filterNotesForSearch(query, notes, categoryMap);
});
