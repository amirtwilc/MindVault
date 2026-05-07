import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/ai_search_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/search_provider.dart';
import '../home/_ai_search_widgets.dart';
import '../home/search_screen.dart' show SearchResultCard;

class WidgetSearchScreen extends ConsumerStatefulWidget {
  const WidgetSearchScreen({super.key});

  @override
  ConsumerState<WidgetSearchScreen> createState() => _WidgetSearchScreenState();
}

class _WidgetSearchScreenState extends ConsumerState<WidgetSearchScreen>
    with SttMixin {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    initStt();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureKeyLoaded());
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    stopStt();
    super.dispose();
  }

  Future<void> _ensureKeyLoaded() async {
    if (!mounted) return;
    if (ref.read(aesKeyProvider) != null) return;
    final key = await ref.read(encryptionServiceProvider).loadKey();
    if (key != null && mounted) {
      ref.read(aesKeyProvider.notifier).state = key;
    }
  }

  void _onTextChanged() {
    final v = _controller.text;
    ref.read(searchQueryProvider.notifier).state = v;
    final ai = ref.read(aiSearchProvider);
    if (ai is AiSearchSuccess && ai.query != v) {
      ref.read(aiSearchProvider.notifier).reset();
    }
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

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final ai = ref.watch(aiSearchProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, size: 20, color: cs.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l.widgetSearchTitle,
                                style: tt.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => SystemNavigator.pop(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      // Query bar
                      AiQueryBar(
                        controller: _controller,
                        listening: listening,
                        sttAvailable: sttAvailable,
                        hasText: query.isNotEmpty,
                        onSubmit: (_) => _triggerAiSearch(),
                        onClear: _clearSearch,
                        onMic: () => toggleListen((words) {
                          _controller.text = words;
                          _controller.selection = TextSelection.collapsed(
                              offset: words.length);
                          _triggerAiSearch();
                        }),
                      ),
                      // Body — capped height so card doesn't overflow screen
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 80,
                          maxHeight: 420,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: _buildBody(query, results, ai, cs, tt),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    String query,
    List<SearchResult> results,
    AiSearchState ai,
    ColorScheme cs,
    TextTheme tt,
  ) {
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
      return AiAnswerView(
        key: const ValueKey('ai-success'),
        answer: ai.answer,
        citedTitles: ai.citedTitles,
        citedNoteIds: ai.citedNoteIds,
        fromCache: ai.fromCache,
        cs: cs,
        tt: tt,
      );
    }
    if (query.trim().isEmpty) {
      return _WidgetIdleHint(key: const ValueKey('idle'), cs: cs, tt: tt);
    }
    if (results.isEmpty) {
      return _WidgetNoResults(
        key: const ValueKey('no-results'),
        cs: cs,
        tt: tt,
        onAiSearch: _triggerAiSearch,
      );
    }
    return _WidgetResults(
      key: const ValueKey('results'),
      results: results,
      query: query.trim(),
      cs: cs,
      tt: tt,
      onAiSearch: _triggerAiSearch,
    );
  }
}

class _WidgetIdleHint extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _WidgetIdleHint({super.key, required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        AppStrings.of(context).searchIdleBody,
        style: tt.bodySmall?.copyWith(color: cs.outline),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _WidgetNoResults extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onAiSearch;
  const _WidgetNoResults({
    super.key,
    required this.cs,
    required this.tt,
    required this.onAiSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            l.searchNoResultsAiCta,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAiSearch,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('AI Search'),
          ),
        ],
      ),
    );
  }
}

class _WidgetResults extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onAiSearch;

  const _WidgetResults({
    super.key,
    required this.results,
    required this.query,
    required this.cs,
    required this.tt,
    required this.onAiSearch,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final items = results.take(5).toList(); // cap for widget space
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      itemCount: items.length + 1,
      itemBuilder: (context, i) {
        if (i == items.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: OutlinedButton.icon(
              onPressed: onAiSearch,
              icon: const Icon(Icons.auto_awesome_rounded, size: 14),
              label: Text(l.searchTryAiHint,
                  style: const TextStyle(fontSize: 12)),
            ),
          );
        }
        return SearchResultCard(result: items[i], query: query);
      },
    );
  }
}
