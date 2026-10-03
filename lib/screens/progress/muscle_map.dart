part of '../progress_screen.dart';

class _MuscleMapCard extends StatefulWidget {
  const _MuscleMapCard();

  @override
  State<_MuscleMapCard> createState() => _MuscleMapCardState();
}

class _MuscleMapCardState extends State<_MuscleMapCard> {
  int _days = 7;
  String? _focus;

  void _setDays(int d) => setState(() {
        _days = d;
        _focus = null;
      });

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    if (_days == 0) return _recoveryCard(gc);
    final sets = fit.muscleSetsOver(_days);
    final heat = fit.muscleHeatOver(_days);
    final focus = _focus;
    final behind = fit.neglectedMuscles(_days);

    return SoftCard(
      radius: GymRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.muscleMap,
                  style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
              _modes(),
            ],
          ),
          const SizedBox(height: 16),
          BodyHeatMap(
            intensity: heat,
            focus: focus,
            onTap: (id) => setState(() => _focus = focus == id ? null : id),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text(t.heatLow, style: AppTheme.s(11, color: gc.textTertiary)),
            const SizedBox(width: 8),
            for (int i = 0; i <= heatLevels; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: heatLevelColor(gc, i),
                    borderRadius: BorderRadius.circular(GymRadius.hair),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(t.heatHigh, style: AppTheme.s(11, color: gc.textTertiary)),
          ]),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.centerLeft,
            child: focus != null
                ? _readout(gc, focus, sets[focus] ?? 0, heat[focus] ?? 0)
                : Text(
                    sets.isEmpty
                        ? t.muscleMapEmpty
                        : behind.isEmpty
                            ? t.muscleMapHint
                            : t.muscleMapBehind(behind.map(t.muscle).join(' · ')),
                    style: AppTheme.s(13, color: gc.textSecondary),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _modes() => SegToggle(
        [
          SegOption(t.days7, _days == 7, () => _setDays(7)),
          SegOption(t.days30, _days == 30, () => _setDays(30)),
          SegOption(t.recoveryTab, _days == 0, () => _setDays(0)),
        ],
        hPad: 10,
        vPad: 5,
        fontSize: 11,
      );

  Widget _recoveryCard(GymColors gc) {
    final recovery = fit.muscleRecovery();
    final overall = fit.overallRecovery();
    final tired = fit.stillRecovering();
    final focus = _focus;
    return SoftCard(
      radius: GymRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.muscleMap,
                  style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
              _modes(),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: overall / 100,
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: gc.bgRaised2,
                    color: recoveryColor(gc, overall / 100),
                  ),
                ),
                Text('$overall', style: AppTheme.f(14, weight: FontWeight.w800, color: gc.text)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.recoveryOverall(overall),
                      style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
                  const SizedBox(height: 2),
                  Text(tired.isEmpty ? t.recoveryAllFresh : t.recoveryStill(tired.take(3).map(t.muscle).join(' · ')),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.s(12, color: gc.textSecondary)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          BodyRecoveryMap(
            recovery: recovery,
            focus: focus,
            onTap: (id) => setState(() => _focus = focus == id ? null : id),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Text(t.recoveryTired, style: AppTheme.s(11, color: gc.textTertiary)),
            const SizedBox(width: 8),
            for (var i = 0; i <= 4; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: recoveryColor(gc, i / 4),
                    borderRadius: BorderRadius.circular(GymRadius.hair),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(t.recoveryFresh, style: AppTheme.s(11, color: gc.textTertiary)),
          ]),
          const SizedBox(height: 14),
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            alignment: Alignment.centerLeft,
            child: focus == null
                ? Text(t.recoveryHint, style: AppTheme.s(13, color: gc.textSecondary))
                : _recoveryReadout(gc, focus, recovery[focus] ?? 1),
          ),
        ],
      ),
    );
  }

  Widget _recoveryReadout(GymColors gc, String id, double value) {
    final hours = fit.hoursUntilRecovered(id);
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: recoveryColor(gc, value), shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(t.muscle(id), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
            hours == null
                ? t.recoveryPct((value * 100).round())
                : '${t.recoveryPct((value * 100).round())} · ${t.readyInHours(hours)}',
            style: AppTheme.s(13, color: gc.textSecondary)),
      ),
    ]);
  }

  Widget _readout(GymColors gc, String id, double sets, double heat) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: heatColor(gc, heat), shape: BoxShape.circle),
      ),
      const SizedBox(width: 8),
      Text(t.muscle(id), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
      const SizedBox(width: 8),
      Expanded(
        child: Text('${t.setCount(sets.round())} · ${t.ofTarget((heat * 100).round())}',
            style: AppTheme.s(13, color: gc.textSecondary)),
      ),
    ]);
  }
}
