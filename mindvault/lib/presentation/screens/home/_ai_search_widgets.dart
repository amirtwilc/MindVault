import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../domain/entities/note.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/notes_provider.dart';

// ── Query bar (with optional mic) ─────────────────────────────────────────────

class AiQueryBar extends StatelessWidget {
  final TextEditingController controller;
  final bool listening;
  final bool sttAvailable;
  final bool hasText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onMic;

  const AiQueryBar({
    super.key,
    required this.controller,
    required this.listening,
    required this.sttAvailable,
    required this.hasText,
    required this.onSubmit,
    required this.onClear,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.psychology_rounded, size: 20, color: cs.primary),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: AppStrings.of(context).aiSearchHint,
                  border: InputBorder.none,
                  hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: tt.bodyMedium,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmit,
              ),
            ),
            if (hasText)
              _IconBtn(icon: Icons.close_rounded, color: cs.onSurfaceVariant, onTap: onClear)
            else if (sttAvailable)
              _IconBtn(
                icon: listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: listening ? cs.error : cs.onSurfaceVariant,
                onTap: onMic,
              ),
            if (hasText)
              _IconBtn(
                icon: Icons.arrow_upward_rounded,
                color: cs.primary,
                onTap: () => onSubmit(controller.text),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

// ── Idle hint with suggestions ────────────────────────────────────────────────

class AiIdleHint extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final ValueChanged<String> onSuggestion;

  const AiIdleHint({
    super.key,
    required this.cs,
    required this.tt,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final suggestions = [
      l.aiSearchSuggestion1,
      l.aiSearchSuggestion2,
      l.aiSearchSuggestion3,
      l.aiSearchSuggestion4,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 56, color: cs.primary.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            l.searchIdleTitle,
            style: tt.titleMedium?.copyWith(color: cs.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.searchIdleBody,
            style: tt.bodySmall?.copyWith(color: cs.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...suggestions.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AiSuggestionChip(label: s, cs: cs, tt: tt, onTap: () => onSuggestion(s)),
            ),
          ),
        ],
      ),
    );
  }
}

class AiSuggestionChip extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onTap;

  const AiSuggestionChip({
    super.key,
    required this.label,
    required this.cs,
    required this.tt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.north_east_rounded, size: 16, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurface))),
          ],
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class AiLoadingView extends StatelessWidget {
  final ColorScheme cs;
  const AiLoadingView({super.key, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: cs.primary),
          const SizedBox(height: 20),
          Text(
            AppStrings.of(context).aiSearchLoading,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── Answer view ───────────────────────────────────────────────────────────────

class AiAnswerView extends ConsumerWidget {
  final String answer;
  final List<String> citedTitles;
  final List<String> citedNoteIds;
  final bool fromCache;
  final ColorScheme cs;
  final TextTheme tt;

  const AiAnswerView({
    super.key,
    required this.answer,
    required this.citedTitles,
    required this.citedNoteIds,
    required this.fromCache,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppStrings.of(context);
    final allNotes = ref.watch(allNotesProvider).valueOrNull ?? [];
    final idToNote = <String, Note>{};
    final titleToNote = <String, Note>{};
    for (final n in allNotes) {
      idToNote[n.id] = n;
      titleToNote[n.title.toLowerCase()] = n;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fromCache)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(l.aiSearchFromCache, style: tt.labelSmall?.copyWith(color: cs.outline)),
                ],
              ),
            ),
          SelectableText(
            answer,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.6),
          ),
          if (citedTitles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.article_outlined, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l.aiSearchSources,
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
                for (int i = 0; i < citedTitles.length; i++)
                  AiSourceChip(
                    title: citedTitles[i],
                    note: citedNoteIds.length > i
                        ? idToNote[citedNoteIds[i]]
                        : titleToNote[citedTitles[i].toLowerCase()],
                    cs: cs,
                    tt: tt,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AiSourceChip extends StatelessWidget {
  final String title;
  final Note? note;
  final ColorScheme cs;
  final TextTheme tt;

  const AiSourceChip({
    super.key,
    required this.title,
    required this.note,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_rounded, size: 13, color: cs.onPrimaryContainer),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (note != null) {
      return GestureDetector(
        onTap: () => context.push('/home/categories/${note!.categoryId}/edit/${note!.id}'),
        child: chip,
      );
    }
    return chip;
  }
}

// ── Rate limited ──────────────────────────────────────────────────────────────

class AiRateLimitedView extends StatelessWidget {
  final DateTime? resetAt;
  final ColorScheme cs;
  final TextTheme tt;

  const AiRateLimitedView({
    super.key,
    required this.resetAt,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final String detail;
    if (resetAt != null) {
      final diff = resetAt!.difference(DateTime.now());
      if (diff.inSeconds < 90) {
        detail = l.aiSearchRateSeconds(diff.inSeconds);
      } else if (diff.inMinutes < 60) {
        detail = l.aiSearchRateMinutes(diff.inMinutes);
      } else {
        detail = l.aiSearchRateResetsAt(_fmt(resetAt!));
      }
    } else {
      detail = l.aiSearchRateDefault;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(l.aiSearchRateTitle, style: tt.titleMedium?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 8),
            Text(detail,
                style: tt.bodySmall?.copyWith(color: cs.outline), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Error ─────────────────────────────────────────────────────────────────────

class AiErrorView extends StatelessWidget {
  final String message;
  final ColorScheme cs;
  final TextTheme tt;
  final VoidCallback onRetry;

  const AiErrorView({
    super.key,
    required this.message,
    required this.cs,
    required this.tt,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: cs.error.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppStrings.of(context).actionTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STT mixin helper ──────────────────────────────────────────────────────────

mixin SttMixin<T extends StatefulWidget> on State<T> {
  final SpeechToText stt = SpeechToText();
  bool sttAvailable = false;
  bool listening = false;

  Future<void> initStt() async {
    final available = await stt.initialize(onError: (_) {
      if (mounted) setState(() => listening = false);
    });
    if (mounted) setState(() => sttAvailable = available);
  }

  Future<void> toggleListen(void Function(String) onResult) async {
    if (listening) {
      await stt.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    if (mounted) setState(() => listening = true);
    await stt.listen(
      onResult: (result) {
        if (!mounted) return;
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          setState(() => listening = false);
          onResult(result.recognizedWords);
        }
      },
      cancelOnError: true,
      pauseFor: const Duration(seconds: 3),
    );
  }

  void stopStt() => stt.stop();
}
