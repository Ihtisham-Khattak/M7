part of '../session_screen.dart';

extension _SessionSetRows on SessionScreen {
  Widget _setsHeader(GymColors gc, String mode, bool repsOnly) {
    final s = AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4);

    Widget label(String t) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(t, maxLines: 1, softWrap: false, style: s),
        );
    final effort = _showsEffort(mode);
    final gap = effort ? SessionScreen._tightGap : SessionScreen._gap;
    return Row(children: [
      SizedBox(width: SessionScreen._numCol, child: label(t.setCol)),
      for (final h in _headers(mode, repsOnly)) ...[
        SizedBox(width: gap),
        Expanded(child: label(h)),
      ],
      if (effort) ...[
        SizedBox(width: gap),
        SizedBox(width: SessionScreen._effortCol, child: label(fit.usesRir ? 'RIR' : 'RPE')),
      ],
      SizedBox(width: gap),
      const SizedBox(width: SessionScreen._checkCol),
    ]);
  }

  List<Widget> _cells(GymColors gc, int exIdx, int j, SessionSet st, String mode, bool repsOnly) {
    final cardio = mode == 'cardio';
    Widget reps() => _miniStepper(
          gc,
          '${st.reps}',
          () => fit.bumpSessionReps(exIdx, j, -1),
          () => fit.bumpSessionReps(exIdx, j, 1),
          22,
          onEdit: (context) => _ruler(
            context,
            title: t.repsTitle,
            value: st.reps.toDouble(),
            max: 100,
            step: 1,
            majorEvery: 5,
            onSave: (v) => fit.setSessionReps(exIdx, j, v.round()),
          ),
        );
    Widget weight() => _miniStepper(
          gc,
          fit.weightValue(st.weight),
          () => fit.bumpSessionWeight(exIdx, j, -1),
          () => fit.bumpSessionWeight(exIdx, j, 1),
          26,
          onEdit: (context) => _ruler(
            context,
            title: t.weightTitle(fit.units.toUpperCase()),
            value: fit.toDisplayWeight(st.weight),
            max: fit.isLb ? 660 : 300,
            step: fit.isLb ? 1 : 0.5,
            majorEvery: 10,
            unit: fit.units,
            onSave: (v) => fit.setSessionWeightShown(exIdx, j, v),
          ),
        );
    Widget time() => _miniStepper(
          gc,
          durationLabel(st.sec ?? 0),
          () => fit.bumpSessionSeconds(exIdx, j, cardio ? -60 : -15),
          () => fit.bumpSessionSeconds(exIdx, j, cardio ? 60 : 15),
          34,
          onEdit: (context) => cardio
              ? _ruler(
                  context,
                  title: t.timeMinutesTitle,
                  value: ((st.sec ?? 0) / 60).roundToDouble(),
                  max: 300,
                  step: 1,
                  majorEvery: 5,
                  unit: 'min',
                  onSave: (v) => fit.setSessionSeconds(exIdx, j, (v * 60).round()),
                )
              : _ruler(
                  context,
                  title: t.timeSecondsTitle,
                  value: (st.sec ?? 0).toDouble(),
                  max: 900,
                  step: 5,
                  majorEvery: 6,
                  format: (v) => clockLabel(v.round()),
                  onSave: (v) => fit.setSessionSeconds(exIdx, j, v.round()),
                ),
        );
    Widget distance() => _miniStepper(
          gc,
          fit.distanceValue(st.km ?? 0),
          () => fit.bumpSessionDistance(exIdx, j, -1),
          () => fit.bumpSessionDistance(exIdx, j, 1),
          30,
          onEdit: (context) => _ruler(
            context,
            title: t.distanceTitle(fit.distanceUnit),
            value: fit.toDisplayKm(st.km ?? 0),
            max: 100,
            step: 0.1,
            majorEvery: 10,
            unit: fit.distanceUnit,
            onSave: (v) => fit.setSessionDistanceShown(exIdx, j, v),
          ),
        );
    return switch (mode) {
      'cardio' => [distance(), time()],
      'time' => [time(), if (!repsOnly) weight()],
      _ => [reps(), if (!repsOnly) weight()],
    };
  }

  List<String> _headers(String mode, bool repsOnly) => switch (mode) {
        'cardio' => [t.distanceCol(fit.distanceUnit.toUpperCase()), t.timeCol],
        'time' => [t.timeCol, if (!repsOnly) t.weightCol(fit.units.toUpperCase())],
        _ => [t.repsCol, if (!repsOnly) t.weightCol(fit.units.toUpperCase())],
      };

  Widget _setRow(GymColors gc, int exIdx, int j, SessionSet st, bool repsOnly, bool locked) {
    final mode = fit.modeOf(fit.session?.exercises[exIdx].id ?? '');
    return Builder(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: locked
            ? null
            : () {
                HapticFeedback.mediumImpact();
                _kindSheet(ctx, exIdx, j, st.kind);
              },
        child: _setRowBody(gc, exIdx, j, st, repsOnly, locked, mode),
      ),
    );
  }

  Widget _setRowBody(GymColors gc, int exIdx, int j, SessionSet st, bool repsOnly, bool locked, String mode) {
    final effort = _showsEffort(mode);
    final gap = effort ? SessionScreen._tightGap : SessionScreen._gap;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: SessionScreen._rowPad),
      decoration: BoxDecoration(
        color: st.done ? gc.sageSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(GymRadius.md),
      ),
      child: Row(children: [
        SizedBox(
          width: SessionScreen._numCol,
          child: Builder(
            builder: (ctx) => Semantics(
              button: true,
              label: t.setType,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: locked ? null : () => _kindSheet(ctx, exIdx, j, st.kind),
                child: MinTarget(minWidth: SessionScreen._numCol, child: _setBadge(gc, exIdx, j, st)),
              ),
            ),
          ),
        ),
        for (final cell in _cells(gc, exIdx, j, st, mode, repsOnly)) ...[
          SizedBox(width: gap),
          Expanded(child: cell),
        ],
        if (effort) ...[
          SizedBox(width: gap),
          SizedBox(width: SessionScreen._effortCol, child: _effortCell(gc, exIdx, j, st, mode, locked)),
        ],
        SizedBox(width: gap),
        Semantics(
          button: true,
          checked: st.done,
          label: t.markSet(j + 1),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fit.toggleSet(exIdx, j),
            child: SizedBox(
              width: SessionScreen._checkCol,
              height: GymSpace.minTarget,
              child: Center(
                child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: st.done ? gc.sage : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: st.done ? gc.sage : gc.textTertiary, width: 2),
                ),
                  child: st.done
                      ? Center(child: SvgPathIcon(Ic.checkBold, size: 14, color: Colors.white))
                      : null,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  bool _asksEffort(SessionExercise ex, int j, String mode) {
    if (!fit.logRpe || mode == 'cardio') return false;
    final st = ex.sets[j];
    return st.done && st.counts && st.rpe == null && ex.sets.lastIndexWhere((x) => x.done) == j;
  }

  bool _showsEffort(String mode) => fit.logRpe && mode != 'cardio';

  Widget _effortCell(GymColors gc, int exIdx, int j, SessionSet st, String mode, bool locked) {
    final ex = fit.session?.exercises[exIdx];
    final waiting = ex != null && _asksEffort(ex, j, mode);
    final rpe = st.rpe;
    return Builder(
      builder: (ctx) => Semantics(
        button: true,
        label: fit.usesRir ? 'RIR' : 'RPE',
        value: rpe == null ? null : fmt(fit.usesRir ? 10 - rpe : rpe),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: locked ? null : () => _editEffort(ctx, exIdx, j, rpe),
          child: SizedBox(
            height: 44,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rpe == null ? Colors.transparent : gc.bgRaised2,
                  borderRadius: BorderRadius.circular(GymRadius.xs),
                  border: Border.all(
                    color: waiting ? gc.ember : (rpe == null ? gc.border : Colors.transparent),
                    width: waiting ? 1.6 : 1,
                  ),
                ),
                child: Text(
                  rpe == null ? '–' : fmt(fit.usesRir ? 10 - rpe : rpe),
                  style: AppTheme.f(14,
                      weight: FontWeight.w700, color: rpe == null ? gc.textTertiary : gc.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editEffort(BuildContext context, int exIdx, int j, double? rpe) async {
    final rir = fit.usesRir;
    final v = await askRuler(context,
        title: rir ? 'RIR' : 'RPE',
        value: rir ? 10 - (rpe ?? 8) : rpe ?? 8,
        min: rir ? 0 : 1,
        max: rir ? 9 : 10,
        step: 0.5,
        majorEvery: 2,
        format: (v) => fmt(v),
        hint: rir ? t.rirHint : t.rpeHint,
        clearLabel: rpe == null ? null : t.none);
    if (v == null) return;
    fit.setSessionRpe(exIdx, j, v.isNaN ? null : (rir ? 10 - v : v));
  }

  Widget _dashedAction(GymColors gc, String label, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MinTarget(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GymRadius.md),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: AppTheme.f(13,
                      weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4)),
            ),
          ),
        ),
      );
}
