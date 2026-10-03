part of '../session_screen.dart';

extension _SessionLiveBar on SessionScreen {
  Widget _liveBar(GymColors gc, bool locked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (locked)
          Flexible(child: _lockedChip(gc))
        else
          Flexible(
            child: Row(children: [
              _stepOutButton(gc),
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: fit.sessionPaused ? gc.textTertiary : gc.ember, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fit.sessionPaused ? t.paused : t.inProgress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(12,
                      weight: FontWeight.w600,
                      color: fit.sessionPaused ? gc.textTertiary : gc.ember,
                      letterSpacing: 0.4),
                ),
              ),
            ]),
          ),
        Row(children: [
          // The clock sits between two 48dp buttons on a 360dp phone: cap its growth, not the rest.
          Builder(
            builder: (context) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.4,
              child: RollingText(fit.elapsedLabel,
                  style: AppTheme.f(18,
                      weight: FontWeight.w700, color: fit.sessionPaused ? gc.textSecondary : gc.text)),
            ),
          ),
          const SizedBox(width: 2),
          if (!locked)
            Semantics(
              button: true,
              label: t.lockWorkout,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setLock(true),
                child: SizedBox(
                  width: 44,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: gc.bgRaised2,
                        shape: BoxShape.circle,
                        border: Border.all(color: gc.border),
                      ),
                      child: Icon(PhosphorIconsRegular.fingerprint, size: 17, color: gc.text),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 2),
          _guard(
            locked,
            Semantics(
            button: true,
            label: fit.sessionPaused ? t.resumeWorkout : t.pauseWorkout,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: fit.toggleSessionPause,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: fit.sessionPaused ? gc.ember : gc.bgRaised2,
                      shape: BoxShape.circle,
                      border: Border.all(color: fit.sessionPaused ? gc.ember : gc.border),
                    ),
                    child: Icon(
                      fit.sessionPaused ? PhosphorIconsFill.play : PhosphorIconsFill.pause,
                      size: 16,
                      color: fit.sessionPaused ? gc.onEmber : gc.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ]),
      ],
    );
  }

  Widget _lockedChip(GymColors gc) => _HoldToUnlock(onUnlock: () => _setLock(false));

  Widget _stepOutButton(GymColors gc) => RoundAction(
        label: t.stepOutOfWorkout,
        onTap: fit.stepOutOfSession,
        child: Icon(PhosphorIconsBold.caretDown, size: 15, color: gc.text),
      );

  Widget _manualBar(GymColors gc, WorkoutSession s) {
    return Row(children: [
      _stepOutButton(gc),
      const SizedBox(width: 12),
      Icon(PhosphorIconsRegular.calendarPlus, size: 15, color: gc.brass),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '${t.logging} · ${t.longDate(s.loggedAt ?? DateTime.now())}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.f(12.5, weight: FontWeight.w700, color: gc.brass, letterSpacing: 0.6),
        ),
      ),
    ]);
  }
}
