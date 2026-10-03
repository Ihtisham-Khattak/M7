part of '../session_screen.dart';

class _ExerciseStage extends StatefulWidget {
  const _ExerciseStage({required this.index, required this.child, this.haptic = false, this.autoMoves});

  final int index;
  final Widget child;
  final bool haptic;
  final int? autoMoves;

  @override
  State<_ExerciseStage> createState() => _ExerciseStageState();
}

class _ExerciseStageState extends State<_ExerciseStage> {
  double _dir = 1;

  @override
  void didUpdateWidget(_ExerciseStage old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _dir = widget.index > old.index ? 1 : -1;
    if (!widget.haptic) return;
    HapticFeedback.selectionClick();
    if (widget.autoMoves != old.autoMoves) _announce();
  }

  void _announce() {
    final ex = fit.currentExercise;
    if (ex == null) return;
    final gc = context.gc;
    final where = fit.inSuperset ? '${t.superset} · ${fit.sessionProgressLabel}' : fit.sessionProgressLabel;
    HapticFeedback.mediumImpact();
    showNotchToast(context, t.catalogName(ex.id, ex.name),
        subtitle: where,
        icon: fit.inSuperset ? PhosphorIconsBold.link : PhosphorIconsBold.arrowRight,
        accent: fit.inSuperset ? gc.brass : gc.ember,
        duration: const Duration(milliseconds: 1900));
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.index;
    final dir = _dir;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 520),
      switchInCurve: const Interval(0.3, 1, curve: Curves.easeOutCubic),
      switchOutCurve: const Interval(0.55, 1, curve: Curves.easeInCubic),
      transitionBuilder: (child, animation) {
        final incoming = (child.key as ValueKey?)?.value == current;
        final from = Offset(incoming ? 0.5 * dir : -0.5 * dir, 0);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: from, end: Offset.zero).animate(animation),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: child,
            ),
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [
          ...previousChildren,
          ?currentChild,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(current), child: widget.child),
    );
  }
}

class _LockGuard extends StatefulWidget {
  const _LockGuard({required this.locked, required this.child});

  final bool locked;
  final Widget child;

  @override
  State<_LockGuard> createState() => _LockGuardState();
}

class _LockGuardState extends State<_LockGuard> {
  DateTime? _last;
  int _taps = 0;

  void _tap() {
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) > const Duration(milliseconds: 1500)) _taps = 0;
    _last = now;
    if (++_taps >= 2) {
      _taps = 0;
      _showLockHint(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.locked ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
      onTap: widget.locked ? _tap : null,
      child: IgnorePointer(
        ignoring: widget.locked,
        child: AnimatedOpacity(
          opacity: widget.locked ? 0.35 : 1,
          duration: const Duration(milliseconds: 220),
          child: widget.child,
        ),
      ),
    );
  }
}

class _HoldToUnlock extends StatefulWidget {
  const _HoldToUnlock({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  State<_HoldToUnlock> createState() => _HoldToUnlockState();
}

class _HoldToUnlockState extends State<_HoldToUnlock> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    reverseDuration: const Duration(milliseconds: 220),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onUnlock();
      }
    });
  DateTime? _last;
  int _taps = 0;

  void _down() {
    HapticFeedback.selectionClick();
    _hold.forward();
  }

  void _up() {
    if (_hold.isCompleted) return;
    _hold.reverse();
    final now = DateTime.now();
    if (_last == null || now.difference(_last!) > const Duration(milliseconds: 1500)) _taps = 0;
    _last = now;
    if (++_taps >= 2) {
      _taps = 0;
      _showLockHint(context);
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      button: true,
      label: t.unlockWorkout,
      hint: t.holdToUnlock,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final v = _hold.value;
            return Transform.scale(
              scale: 1 - 0.04 * v,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                decoration: BoxDecoration(
                  color: gc.emberSoft,
                  borderRadius: BorderRadius.circular(GymRadius.pill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: v,
                          strokeWidth: 2.4,
                          strokeCap: StrokeCap.round,
                          color: gc.ember,
                          backgroundColor: gc.ember.withValues(alpha: 0.15),
                        ),
                      ),
                      Icon(PhosphorIconsFill.fingerprint, size: 14, color: gc.ember),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      t.holdToUnlock,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.f(12, weight: FontWeight.w800, color: gc.ember),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Celebrate extends StatefulWidget {
  const _Celebrate({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_Celebrate> createState() => _CelebrateState();
}

class _CelebrateState extends State<_Celebrate> {
  static Object? _shownFor;

  @override
  void initState() {
    super.initState();
    final s = fit.session;
    if (!widget.active || s == null || identical(_shownFor, s)) return;
    _shownFor = s;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gc = context.gc;
      celebrate(context, colors: [gc.accent, gc.brass, gc.sage, gc.text]);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
