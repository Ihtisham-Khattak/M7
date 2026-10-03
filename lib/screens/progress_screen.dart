import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/progress_shot.dart';
import '../models/workout.dart';
import '../services/media_store.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/body_map.dart';
import '../widgets/charts.dart';
import '../widgets/dialogs.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_media.dart';
import '../widgets/glass.dart';
import '../widgets/muscle_radar.dart';
import '../widgets/rolling_text.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/disclosure.dart';
import '../widgets/metric_card.dart';
import '../widgets/components.dart';
import '../widgets/states.dart';
import '../widgets/ui_kit.dart';
import 'share_sheet.dart';
import 'start_sheet.dart';

part 'progress/body_cards.dart';
part 'progress/overview.dart';
part 'progress/muscle_map.dart';
part 'progress/strength_card.dart';
part 'progress/day_sheet.dart';
part 'progress/log_sheets.dart';
part 'progress/track_painter.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final change = fit.volumeChangePct;
    final prs = fit.personalRecords;
    final bw = fit.bodyweightSeries;

    return RiseScope(
      id: 'progress',
      child: SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: riseAll([
            Row(
              children: [
                Expanded(
                  child: Text(t.progressTitle,
                      style: AppTheme.f(26, weight: FontWeight.w800, color: gc.text)),
                ),
                RoundAction(
                  label: t.share,
                  onTap: () => showShareSheet(context),
                  child: Icon(PhosphorIconsRegular.shareNetwork, size: 17, color: gc.text),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (fit.sessions.isEmpty) ...[
              _setupCard(context, gc),
              const SizedBox(height: 12),
            ],
            _headline(context, gc, change),
            if (fit.sessions.isNotEmpty) ...[
              const SizedBox(height: 12),
              _consistency(context, gc),
            ],
            for (final group in _groups(context, gc, bw, prs)) ...[
              const SizedBox(height: 8),
              group,
            ],
            if (fit.sessions.isNotEmpty && _missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              _setupCard(context, gc),
            ],
          ]),
        ),
      ),
      ),
    );
  }

  Widget _tile(
    GymColors gc, {
    required String label,
    required String value,
    String unit = '',
    String? note,
    Widget? chart,
    Widget? badge,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(GymRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: FitText(label.toUpperCase(),
                  style: AppTheme.f(11,
                      weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
            ),
            ?badge,
          ]),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                RollIn(value, style: AppTheme.f(28, weight: FontWeight.w800, color: gc.text)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(unit, style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
                ],
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary)),
          ],
          if (chart != null) ...[
            const SizedBox(height: 12),
            chart,
          ],
        ],
      ),
      ),
    );
  }

  Widget _delta(GymColors gc, int pct) {
    final up = pct >= 0;
    final color = up ? gc.sage : gc.accent;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(up ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown, size: 11, color: color),
      const SizedBox(width: 3),
      Text('${pct.abs()}%', style: AppTheme.f(11, weight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _consistency(BuildContext context, GymColors gc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(GymRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(t.consistency.toUpperCase(),
                  style: AppTheme.f(11,
                      weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showHeatToneSheet(context),
                child: Semantics(
                  button: true,
                  label: t.heatToneTitle,
                  child: Row(children: [
                    for (final c in heatRamp(gc, fit.heatTone).skip(1))
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(left: 3),
                        decoration:
                            BoxDecoration(color: c, borderRadius: BorderRadius.circular(GymRadius.hair)),
                      ),
                    const SizedBox(width: 7),
                    Icon(PhosphorIconsRegular.caretDown, size: 11, color: gc.textTertiary),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Heatmap(levels: fit.heatmapLevels, onTapDay: (i) => _showDay(context, i)),
          const SizedBox(height: 14),
          Row(children: [
            Icon(PhosphorIconsFill.fire, size: 14, color: gc.accent),
            const SizedBox(width: 7),
            Text(t.streakDays(fit.currentStreak),
                style: AppTheme.f(12, weight: FontWeight.w600, color: gc.text)),
            const Spacer(),
            Text(t.weekOfGoal(fit.daysDoneThisWeek, fit.weeklyTarget),
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textTertiary)),
          ]),
        ],
      ),
    );
  }

  Widget _totals(GymColors gc) {
    final hours = fit.totalTime.inHours;
    final cells = <(String, String, String)>[
      (t.allTimeSessions, '${fit.totalSessions}', ''),
      (t.allTimeSets, '${fit.totalSets}', ''),
      (
        t.allTimeTime,
        hours >= 1 ? '$hours' : '${fit.totalTime.inMinutes}',
        hours >= 1 ? t.unitHours : 'min'
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            Expanded(child: _tile(gc, label: cells[i].$1, value: cells[i].$2, unit: cells[i].$3)),
            if (i < cells.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _thisWeek(GymColors gc) {
    final start = fit.weekStartDate;
    final sets = List<int>.filled(7, 0);
    for (final session in fit.sessions) {
      final day = DateTime(session.date.year, session.date.month, session.date.day);
      final i = day.difference(start).inDays;
      if (i >= 0 && i < 7) sets[i] += session.setCount;
    }
    final top = sets.fold(0, (m, v) => v > m ? v : m);
    final todayIndex = fit.todayIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(GymRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(t.thisWeekTitle.toUpperCase(),
                style: AppTheme.f(11,
                    weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
            const Spacer(),
            Text(t.setsThisWeek(sets.fold(0, (a, b) => a + b)),
                style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary)),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(sets[i] > 0 ? '${sets[i]}' : '',
                            style: AppTheme.f(11,
                                weight: FontWeight.w700,
                                color: i == todayIndex ? gc.text : gc.textSecondary)),
                        const SizedBox(height: 6),
                        Container(
                          height: top == 0 ? 6 : (8 + 52 * sets[i] / top),
                          decoration: BoxDecoration(
                            color: sets[i] == 0
                                ? gc.bgRaised2
                                : (i == todayIndex ? gc.text : gc.text.withValues(alpha: 0.32)),
                            borderRadius: BorderRadius.circular(GymRadius.xs),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < 6) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 7; i++) ...[
                Expanded(
                  child: Text(
                    t.weekdayInitial(fit.weekdayAt(i)),
                    textAlign: TextAlign.center,
                    style: AppTheme.f(11,
                        weight: i == todayIndex ? FontWeight.w700 : FontWeight.w500,
                        color: i == todayIndex ? gc.text : gc.textTertiary),
                  ),
                ),
                if (i < 6) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<({String label, bool done, String route})> _steps() => [
        (label: t.setupWorkout, done: fit.sessions.isNotEmpty, route: 'train'),
        (label: t.setupWeight, done: fit.bodyweight.isNotEmpty, route: 'weight'),
        (label: t.setupMeasures, done: fit.measures.isNotEmpty, route: 'measures'),
        (label: t.setupPhoto, done: fit.shotCount > 0, route: 'timeline'),
      ];

  List<String> get _missing =>
      [for (final s in _steps()) if (!s.done) s.label];

  void _goStep(BuildContext context, String route) {
    switch (route) {
      case 'train':
        fit.startWorkout();
      case 'weight':
        _logBodyweight(context);
      case 'measures':
        fit.goMeasures();
      case 'timeline':
        fit.goTimeline();
    }
  }

  Widget _setupCard(BuildContext context, GymColors gc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(GymRadius.lg),
        border: Border.all(color: gc.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.setupTitle, style: AppTheme.f(15, color: gc.text)),
          const SizedBox(height: 4),
          Text(t.setupHint,
              style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textTertiary, height: 1.4)),
          const SizedBox(height: 14),
          for (final step in _steps())
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: step.done ? null : () => _goStep(context, step.route),
              child: MinTarget(
                alignment: AlignmentDirectional.centerStart,
                child: Row(children: [
                  Icon(
                    step.done ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circleDashed,
                    size: 17,
                    color: step.done ? gc.sage : gc.textTertiary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(step.label,
                        style: AppTheme.f(13,
                            weight: FontWeight.w500,
                            color: step.done ? gc.textTertiary : gc.text)),
                  ),
                  if (!step.done)
                    Icon(PhosphorIconsBold.caretRight, size: 13, color: gc.textTertiary),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  void _showDay(BuildContext context, int index) => showDaySheet(context, fit.heatmapDate(index));

  void _logBodyweight(BuildContext context) {
    final start = fit.latestBodyweight?.kg ?? fit.profile.weightKg;
    showAppSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LogBodyweightSheet(start: start),
    );
  }
}
