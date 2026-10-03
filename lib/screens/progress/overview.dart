part of '../progress_screen.dart';

extension _ProgressOverview on ProgressScreen {
  /// The three numbers that matter first (GM-18): consistency, streak and the 30-day volume.
  Widget _headline(BuildContext context, GymColors gc, int? change) {
    return GymCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.all(GymSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MetricCard(
                  label: t.consistency,
                  value: '${fit.daysDoneThisWeek}/${fit.weeklyTarget}',
                  emphasis: true,
                ),
              ),
              Expanded(child: MetricCard(label: t.statStreak, value: '${fit.currentStreak}', unit: t.statDays)),
              Expanded(
                child: MetricCard(
                  label: t.tileVolume30,
                  value: fit.volumeValue(fit.volume30dKg),
                  unit: fit.volumeUnit,
                ),
              ),
            ],
          ),
          if (change != null) ...[
            const SizedBox(height: GymSpace.md),
            Align(alignment: AlignmentDirectional.centerEnd, child: _delta(gc, change)),
          ],
        ],
      ),
    );
  }

  Widget _hint(GymColors gc, IconData icon, String text) =>
      EmptyState(icon: icon, title: text, compact: true);

  List<Widget> _groups(BuildContext context, GymColors gc, List<double> bw, List<PersonalRecord> prs) {
    final hasSessions = fit.sessions.isNotEmpty;
    final hasBody = fit.bodyweight.isNotEmpty || fit.measures.isNotEmpty || fit.shotCount > 0;
    Widget stack(List<Widget> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: GymSpace.md),
              items[i],
            ],
          ],
        );
    return [
      Disclosure(
        id: 'progress_strength',
        title: t.progressStrength,
        summary: prs.isEmpty ? null : '${prs.length}',
        child: fit.trackedExercises.isEmpty && prs.isEmpty
            ? _hint(gc, PhosphorIconsRegular.barbell, t.progressRecordsEmpty)
            : stack([
                if (fit.trackedExercises.isNotEmpty) _StrengthCard(),
                if (prs.isNotEmpty) _PrCard(prs),
              ]),
      ),
      Disclosure(
        id: 'progress_body',
        title: t.progressBody,
        summary: fit.latestBodyweight == null ? null : '${fit.weightValue(fit.latestBodyweight!.kg)} ${fit.units}',
        child: !hasBody
            ? stack([_hint(gc, PhosphorIconsRegular.scales, t.progressBodyEmpty), _bodyweightTile(context, gc, bw)])
            : stack([
                _bodyweightTile(context, gc, bw),
                if (fit.shotCount > 0) _timelineCard(gc),
                if (fit.measures.isNotEmpty) _measuresCard(gc),
              ]),
      ),
      Disclosure(
        id: 'progress_muscles',
        title: t.progressMuscles,
        child: stack([
          const _MuscleMapCard(),
          if (hasSessions) const MuscleRadarCard(),
        ]),
      ),
      if (hasSessions)
        Disclosure(
          id: 'progress_all_time',
          title: t.progressAllTime,
          child: stack([_thisWeek(gc), _totals(gc)]),
        ),
    ];
  }

  Widget _bodyweightTile(BuildContext context, GymColors gc, List<double> bw) {
    final weight = fit.latestBodyweight;
    return weight == null
        ? _tile(gc, label: t.weightLabel, value: '—', note: t.tileAddWeight, onTap: () => _logBodyweight(context))
        : _tile(
            gc,
            label: t.weightLabel,
            value: fit.weightValue(weight.kg),
            unit: fit.units,
            note: t.shortDate(weight.date),
            chart: bw.length < 2
                ? const SizedBox(height: 40)
                : Sparkline(
                    values: [for (final v in bw) fit.toDisplayWeight(v)],
                    height: 40,
                    color: gc.textSecondary,
                    scale: fmt,
                  ),
            onTap: () => _logBodyweight(context),
          );
  }
}
