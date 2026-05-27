import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/reminder_provider.dart';
import '../providers/walkthrough_provider.dart';

enum WalkthroughTarget { archive, clusters, recall, sparks }

class AppWalkthroughOverlay extends ConsumerStatefulWidget {
  final Map<WalkthroughTarget, GlobalKey> targetKeys;
  final ValueChanged<int> onNavigateToSection;

  const AppWalkthroughOverlay({
    super.key,
    required this.targetKeys,
    required this.onNavigateToSection,
  });

  @override
  ConsumerState<AppWalkthroughOverlay> createState() =>
      _AppWalkthroughOverlayState();
}

class _AppWalkthroughOverlayState extends ConsumerState<AppWalkthroughOverlay> {
  int _step = 0;
  bool _wasVisible = false;

  static const _targetPages = <int, int>{
    2: 0,
    3: 2,
    4: 3,
    5: 1,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walkthroughProvider);
    if (state.isVisible && !_wasVisible) {
      _step = 0;
    }
    _wasVisible = state.isVisible;
    if (!state.isVisible) return const SizedBox.shrink();

    final l = AppStrings.of(context);
    final steps = _steps(l);
    final current = steps[_step];

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final targetRect = _targetRect(current.target);
            return Stack(
              children: [
                Positioned.fill(
                  child: _WalkthroughScrim(targetRect: targetRect),
                ),
                if (targetRect != null) _TargetHighlight(rect: targetRect),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: _panelBottom(constraints.maxHeight, targetRect),
                  child: SafeArea(
                    top: false,
                    child: _WalkthroughPanel(
                      stepNumber: _step + 1,
                      stepCount: steps.length,
                      title: current.title,
                      body: current.body,
                      showBack: _step > 0,
                      primaryLabel: _primaryLabel(l, current),
                      secondaryLabel: _secondaryLabel(l, current),
                      onBack: _previous,
                      onPrimary: () => _primaryAction(current),
                      onSecondary: current.action ==
                              _WalkthroughAction.backgroundSettings
                          ? _next
                          : null,
                      onSkip: () =>
                          ref.read(walkthroughProvider.notifier).skip(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<_WalkthroughStep> _steps(AppStrings l) => [
        _WalkthroughStep(
          title: l.walkthroughWelcomeTitle,
          body: l.walkthroughWelcomeBody,
          action: _WalkthroughAction.notifications,
        ),
        _WalkthroughStep(
          title: l.walkthroughBackgroundTitle,
          body: l.walkthroughBackgroundBody,
          action: _WalkthroughAction.backgroundSettings,
        ),
        _WalkthroughStep(
          title: l.walkthroughArchiveTitle,
          body: l.walkthroughArchiveBody,
          target: WalkthroughTarget.archive,
        ),
        _WalkthroughStep(
          title: l.walkthroughClustersTitle,
          body: l.walkthroughClustersBody,
          target: WalkthroughTarget.clusters,
        ),
        _WalkthroughStep(
          title: l.walkthroughRecallTitle,
          body: l.walkthroughRecallBody,
          target: WalkthroughTarget.recall,
        ),
        _WalkthroughStep(
          title: l.walkthroughSparksTitle,
          body: l.walkthroughSparksBody,
          target: WalkthroughTarget.sparks,
        ),
        _WalkthroughStep(
          title: l.walkthroughWidgetsTitle,
          body: l.walkthroughWidgetsBody,
          action: _WalkthroughAction.finish,
        ),
      ];

  String _primaryLabel(AppStrings l, _WalkthroughStep step) {
    switch (step.action) {
      case _WalkthroughAction.notifications:
        return l.walkthroughAllowNotifications;
      case _WalkthroughAction.backgroundSettings:
        return l.walkthroughOpenBackgroundSettings;
      case _WalkthroughAction.finish:
        return l.walkthroughDone;
      case _WalkthroughAction.next:
        return l.walkthroughNext;
    }
  }

  String? _secondaryLabel(AppStrings l, _WalkthroughStep step) {
    return step.action == _WalkthroughAction.backgroundSettings
        ? l.walkthroughDoLater
        : null;
  }

  Future<void> _primaryAction(_WalkthroughStep step) async {
    switch (step.action) {
      case _WalkthroughAction.notifications:
        await ref
            .read(reminderSchedulerProvider)
            .requestPermissions(requestExactAlarm: false);
        if (!mounted) return;
        _next();
        return;
      case _WalkthroughAction.backgroundSettings:
        final scheduler = ref.read(reminderSchedulerProvider);
        await scheduler.markBackgroundPermissionPromptDone();
        await scheduler.openBackgroundPermissionSettings();
        if (!mounted) return;
        _next();
        return;
      case _WalkthroughAction.finish:
        widget.onNavigateToSection(0);
        await ref.read(walkthroughProvider.notifier).complete();
        return;
      case _WalkthroughAction.next:
        _next();
        return;
    }
  }

  void _next() {
    final maxStep = _steps(AppStrings.of(context)).length - 1;
    if (_step >= maxStep) {
      ref.read(walkthroughProvider.notifier).complete();
      return;
    }
    setState(() => _step++);
    _syncTargetPage();
  }

  void _previous() {
    if (_step == 0) return;
    setState(() => _step--);
    _syncTargetPage();
  }

  void _syncTargetPage() {
    final page = _targetPages[_step];
    if (page == null) return;
    widget.onNavigateToSection(page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Rect? _targetRect(WalkthroughTarget? target) {
    final key = target == null ? null : widget.targetKeys[target];
    final context = key?.currentContext;
    if (context == null) return null;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    final offset = render.localToGlobal(Offset.zero);
    return offset & render.size;
  }

  double _panelBottom(double height, Rect? targetRect) {
    if (targetRect == null) return 32;
    return height - targetRect.top + 16;
  }
}

class _WalkthroughStep {
  final String title;
  final String body;
  final WalkthroughTarget? target;
  final _WalkthroughAction action;

  const _WalkthroughStep({
    required this.title,
    required this.body,
    this.target,
    this.action = _WalkthroughAction.next,
  });
}

enum _WalkthroughAction { next, notifications, backgroundSettings, finish }

class _WalkthroughPanel extends StatelessWidget {
  final int stepNumber;
  final int stepCount;
  final String title;
  final String body;
  final String primaryLabel;
  final String? secondaryLabel;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;
  final VoidCallback onSkip;

  const _WalkthroughPanel({
    required this.stepNumber,
    required this.stepCount,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.showBack,
    required this.onBack,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$stepNumber / $stepCount',
                  style: tt.labelMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  child: Text(l.walkthroughSkip),
                ),
              ],
            ),
            Text(
              title,
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(body, style: tt.bodyMedium),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showBack)
                      TextButton(
                        onPressed: onBack,
                        child: Text(l.walkthroughBack),
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FilledButton(
                                  onPressed: onPrimary,
                                  child: _ButtonLabel(primaryLabel),
                                ),
                                if (secondaryLabel != null &&
                                    onSecondary != null) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: onSecondary,
                                    child: _ButtonLabel(secondaryLabel!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  final String text;

  const _ButtonLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}

class _TargetHighlight extends StatelessWidget {
  final Rect rect;

  const _TargetHighlight({required this.rect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned.fromRect(
      rect: rect.inflate(8),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.primary, width: 3),
            color: cs.primaryContainer.withOpacity(0.12),
          ),
        ),
      ),
    );
  }
}

class _WalkthroughScrim extends StatelessWidget {
  final Rect? targetRect;

  const _WalkthroughScrim({required this.targetRect});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WalkthroughScrimPainter(targetRect),
      child: const SizedBox.expand(),
    );
  }
}

class _WalkthroughScrimPainter extends CustomPainter {
  final Rect? targetRect;

  const _WalkthroughScrimPainter(this.targetRect);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final path = Path()..addRect(full);
    final target = targetRect;
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(18)),
      );
      path.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.58));
  }

  @override
  bool shouldRepaint(_WalkthroughScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
