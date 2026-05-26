import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/ai_search_provider.dart';
import '../../providers/search_provider.dart';
import '_ai_search_widgets.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> with SttMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
    _controller.addListener(_onTextChanged);
    initStt();
  }

  void _onTextChanged() {
    final v = _controller.text;
    ref.read(searchQueryProvider.notifier).state = v;
    // Reset AI state when user edits query so stale AI result doesn't linger
    final ai = ref.read(aiSearchProvider);
    if (ai is AiSearchSuccess && ai.query != v) {
      ref.read(aiSearchProvider.notifier).reset();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    stopStt();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    ref.read(aiSearchProvider.notifier).reset();
  }

  void _triggerAiSearch() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    ref.read(aiSearchProvider.notifier).search(q);
  }

  void _showAiInfoDialog() {
    final l = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.aiInfoTitle),
        content: Text(l.aiInfoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.aiInfoDismiss),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final ai = ref.watch(aiSearchProvider);
    final historyCount =
        ref.watch(aiSearchHistoryProvider).valueOrNull?.length ?? 0;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: _SearchBar(
                  controller: _controller,
                  showClear: query.isNotEmpty,
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  onClear: _clearSearch,
                ),
              ),
              if (historyCount > 0)
                IconButton(
                  icon: const Icon(Icons.history_rounded),
                  tooltip: l.searchHistoryButtonTooltip,
                  onPressed: () => context.push('/home/recall/history'),
                ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _buildBody(context, query, results, ai, cs, tt, l),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String query,
    List<SearchResult> results,
    AiSearchState ai,
    ColorScheme cs,
    TextTheme tt,
    AppStrings l,
  ) {
    // AI states take priority
    if (ai is AiSearchLoading) {
      return AiLoadingView(key: const ValueKey('ai-loading'), cs: cs);
    }
    if (ai is AiSearchRateLimited) {
      return AiRateLimitedView(
        key: const ValueKey('ai-ratelimited'),
        resetAt: ai.resetAt,
        cs: cs,
        tt: tt,
      );
    }
    if (ai is AiSearchFailed) {
      return AiErrorView(
        key: const ValueKey('ai-error'),
        message: ai.message,
        cs: cs,
        tt: tt,
        onRetry: _triggerAiSearch,
      );
    }
    if (ai is AiSearchSuccess) {
      return _AiSuccessView(
        key: const ValueKey('ai-success'),
        answer: ai.answer,
        citedTitles: ai.citedTitles,
        citedNoteIds: ai.citedNoteIds,
        fromCache: ai.fromCache,
        cs: cs,
        tt: tt,
        onBack: () => ref.read(aiSearchProvider.notifier).reset(),
      );
    }

    // Regular search states
    if (query.trim().isEmpty) {
      return AiIdleHint(
        key: const ValueKey('idle'),
        cs: cs,
        tt: tt,
        onSuggestion: (s) {
          _controller.text = s;
          _controller.selection = TextSelection.collapsed(offset: s.length);
          ref.read(searchQueryProvider.notifier).state = s;
          // Per spec: chip tap runs regular search only, not AI
        },
      );
    }
    if (results.isEmpty) {
      return _NoResultsWithAiCta(
        key: const ValueKey('no-results'),
        cs: cs,
        tt: tt,
        onAiSearch: _triggerAiSearch,
        onInfo: _showAiInfoDialog,
      );
    }
    return _ResultsWithAiCta(
      key: const ValueKey('results'),
      results: results,
      query: query.trim(),
      cs: cs,
      tt: tt,
      onAiSearch: _triggerAiSearch,
      onInfo: _showAiInfoDialog,
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppStrings.of(context).searchHint,
                border: InputBorder.none,
                hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: tt.bodyMedium,
              textAlignVertical: TextAlignVertical.center,
              onChanged: onChanged,
            ),
          ),
          if (showClear)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
              ),
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ── AI success wrapper (adds "back to results" button) ────────────────────────

class _AiSuccessView extends StatelessWidget {
  final String answer;
  final List<String> citedTitles;
  final List<String> citedNoteIds;
  final bool fromCache;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onBack;

  const _AiSuccessView({
    super.key,
    required this.answer,
    required this.citedTitles,
    required this.citedNoteIds,
    required this.fromCache,
    required this.cs,
    required this.tt,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AiAnswerView(
            answer: answer,
            citedTitles: citedTitles,
            citedNoteIds: citedNoteIds,
            fromCache: fromCache,
            cs: cs,
            tt: tt,
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(AppStrings.of(context).searchBackToResults),
            ),
          ),
        ),
      ],
    );
  }
}

// ── No results + AI CTA ───────────────────────────────────────────────────────

class _NoResultsWithAiCta extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onAiSearch;
  final VoidCallback onInfo;

  const _NoResultsWithAiCta({
    super.key,
    required this.cs,
    required this.tt,
    required this.onAiSearch,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: cs.outlineVariant),
            const SizedBox(height: 20),
            Text(
              l.searchNoResultsAiCta,
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAiSearch,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('AI Search'),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onInfo,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(l.aiInfoTitle,
                      style: tt.labelSmall?.copyWith(color: cs.outline)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Results list + bottom AI CTA ──────────────────────────────────────────────

class _ResultsWithAiCta extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onAiSearch;
  final VoidCallback onInfo;

  const _ResultsWithAiCta({
    super.key,
    required this.results,
    required this.query,
    required this.cs,
    required this.tt,
    required this.onAiSearch,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: results.length + 1,
      itemBuilder: (context, i) {
        if (i == results.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Column(
              children: [
                OutlinedButton.icon(
                  onPressed: onAiSearch,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(l.searchTryAiHint),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onInfo,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14, color: cs.outline),
                      const SizedBox(width: 4),
                      Text(l.aiInfoTitle,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.outline)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return SearchResultCard(result: results[i], query: query);
      },
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────────

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final String query;
  const SearchResultCard(
      {super.key, required this.result, required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final note = result.note;
    final category = result.category;

    final catBg = categoryColor(category?.color);
    final catFg = categoryTextColor(catBg);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push('/home/clusters/${note.categoryId}/edit/${note.id}'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: catBg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title.isEmpty ? l.noteUntitled : note.title,
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (category != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: catBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category.name,
                                style: tt.labelSmall?.copyWith(color: catFg),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (result.matchingLines.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...result.matchingLines.take(3).map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: RichText(
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  text: _highlightSpan(
                                    line.trim(),
                                    query,
                                    tt.bodySmall
                                        ?.copyWith(color: cs.onSurfaceVariant),
                                    cs.primaryContainer,
                                    cs.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                        if (result.matchingLines.length > 3)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              l.searchMoreLines(
                                  result.matchingLines.length - 3),
                              style: tt.labelSmall
                                  ?.copyWith(color: cs.outlineVariant),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: cs.outlineVariant,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _highlightSpan(
    String text,
    String query,
    TextStyle? base,
    Color highlightBg,
    Color highlightFg,
  ) {
    if (query.isEmpty) return TextSpan(text: text, style: base);

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: base?.copyWith(
          backgroundColor: highlightBg,
          color: highlightFg,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = index + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: base));
    }

    return TextSpan(children: spans);
  }
}
