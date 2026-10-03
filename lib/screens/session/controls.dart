part of '../session_screen.dart';

extension _SessionControls on SessionScreen {
  Widget _holdCard(GymColors gc) {
    final count = fit.sessionSetCount;
    final lead = fit.holdLead;
    return TimerPanel(
      label: lead > 0 ? t.getReady : t.holdLabel,
      remaining: lead > 0 ? lead : fit.holdRemaining ?? 0,
      total: lead > 0 ? WorkoutState.holdLeadIn : fit.holdTotal,
      elapsed: fit.elapsedLabel,
      elapsedLabel: t.elapsedCaps,
      sets: '${count.done}/${count.total}',
      setsLabel: t.setsCaps,
      hint: t.tapToStop,
      color: gc.accent,
      onTap: fit.stopHold,
    );
  }

  Widget _restCard(GymColors gc, WorkoutSession s) {
    final count = fit.sessionSetCount;
    return TimerPanel(
      label: t.liveResting,
      remaining: s.restRemaining ?? 0,
      total: fit.restTotal,
      elapsed: fit.elapsedLabel,
      elapsedLabel: t.elapsedCaps,
      sets: '${count.done}/${count.total}',
      setsLabel: t.setsCaps,
      hint: t.tapToSkip,
      onTap: fit.skipRest,
      onMinus: () => fit.nudgeRest(-15),
      onPlus: () => fit.nudgeRest(15),
    );
  }

  Widget _mainAction(GymColors gc, SessionExercise? ex, int exIdx, int total, bool locked) {
    final pending = ex == null ? -1 : ex.sets.indexWhere((st) => !st.done);
    if (pending >= 0 && ex != null && fit.isTimed(ex.id)) {
      if (fit.holding && fit.holdEx == exIdx) {
        return PrimaryButton(
          label: '${t.stopLabel} · ${durationLabel(fit.holdRemaining ?? 0)}',
          onTap: fit.stopHold,
          height: 56,
        );
      }
      return PrimaryButton(
        label: t.startHold(durationLabel(ex.sets[pending].sec ?? 30)),
        icon: Ic.play,
        onTap: () => fit.startHold(exIdx, pending),
        height: 56,
      );
    }
    if (pending >= 0) {
      return PrimaryButton(label: t.setDone, onTap: () => fit.toggleSet(exIdx, pending), height: 56);
    }
    if (fit.pendingAfter(exIdx) != null) {
      return PrimaryButton(label: t.nextExercise, onTap: fit.goNextPending, height: 56);
    }
    if (exIdx < total - 1) {
      return _guard(
          locked, PrimaryButton(label: t.nextExercise, onTap: fit.nextExercise, height: 56));
    }
    return _guard(
        locked, PrimaryButton(label: t.finishSession, onTap: fit.finishSession, height: 56));
  }

  Widget _textAction(GymColors gc, String label, VoidCallback onTap) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(label,
                style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textTertiary)),
          ),
        ),
      );

  Widget _circleBtn(GymColors gc, List<IconPath> icon, VoidCallback onTap, {bool enabled = true}) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: enabled ? gc.bgRaised : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPathIcon(icon, size: 18, color: enabled ? gc.text : gc.textTertiary),
          ),
        ),
      ),
    );
  }
}
