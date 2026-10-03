import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_card.dart';
import '../widgets/glass.dart';
import '../widgets/svg_icon.dart';
import '../widgets/components.dart';
import '../widgets/metric_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/workout_card.dart';
import '../widgets/ui_kit.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final recommended = fit.recommendedExercises(8);

    return RiseScope(
      id: 'home',
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const PageStorageKey('home'),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(GymSpace.pageGutter, GymSpace.md, GymSpace.pageGutter, 116),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: riseAll([
              _topBar(gc),
              const SizedBox(height: GymSpace.lg),
              if (fit.showFocus || fit.todayRoutine?.exerciseIds.isNotEmpty == true) ...[
                _hero(context, gc),
                const SizedBox(height: GymSpace.md),
              ],
              if (fit.canOfferPersonalize) ...[
                _personalizeNudge(gc),
                const SizedBox(height: GymSpace.md),
              ],
              if (fit.photoDue) ...[
                _photoNudge(gc),
                const SizedBox(height: GymSpace.md),
              ],
              _progressCard(context, gc),
              if (fit.showRecommended && recommended.isNotEmpty) ...[
                const SizedBox(height: GymSpace.xxl),
                SectionHeader(t.recommended, onMore: fit.goExercises),
                const SizedBox(height: GymSpace.md),
                SizedBox(
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recommended.length,
                    separatorBuilder: (_, _) => const SizedBox(width: GymSpace.md),
                    itemBuilder: (_, i) => _recCard(gc, recommended[i]),
                  ),
                ),
              ],
              const SizedBox(height: GymSpace.xxl),
              _shortcuts(gc),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _topBar(GymColors gc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.today.toUpperCase(),
                  style: AppTheme.f(11,
                      weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.4)),
              const SizedBox(height: 3),
              Text(t.longDate(DateTime.now()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(20, color: gc.text)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: '${fit.currentStreak}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: fit.goProgress,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GymSpace.minTarget),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: GymSpace.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(GymRadius.md)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPathIcon(Ic.flame, size: 15, color: gc.accent),
                    const SizedBox(width: GymSpace.sm - 2),
                    Text('${fit.currentStreak}', style: GymText.numeric(GymText.bodySize, color: gc.text, weight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _tc(String s) => titleCase(s);

  Widget _hero(BuildContext context, GymColors gc) {
    final routine = fit.todayRoutine;
    final focus = fit.suggestedFocus;
    final isRoutine = routine != null && routine.exerciseIds.isNotEmpty;
    final today = fit.routinesOn(DateTime.now());
    final trained = fit.trainedToday;

    final summary = isRoutine
        ? WorkoutSummary.of(routine,
            status: trained ? WorkoutStatus.done : WorkoutStatus.planned)
        : null;
    final meta = [
      if (summary != null) summary.meta else if (fit.hasData) '${focus.subtitle} · ${t.exerciseCount(fit.getFilteredExercises(focus.muscles).length)}' else t.firstSessionHint,
      if (summary != null && today.length > 1) t.routineOfDay(today.indexOf(routine!) + 1, today.length),
    ].join(' · ');

    return WorkoutCard(
      label: isRoutine ? t.todaysRoutine : t.todaysFocus,
      title: summary?.title ?? focus.title,
      muscles: summary?.muscles,
      meta: meta,
      status: summary?.statusLabel ?? (trained ? t.done : null),
      done: trained,
      startLabel: t.startWorkout,
      onStart: isRoutine ? () => fit.startRoutine(routine) : fit.startFocusWorkout,
    );
  }

  Widget _weekDay(BuildContext context, GymColors gc, int i) {
    final done = fit.isDayDone(i);
    final isToday = i == fit.todayIndex;
    final isFuture = i > fit.todayIndex;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFuture
          ? null
          : fit.isSessionDay(i)
              ? () => showDaySheet(context, fit.dateForWeekday(i))
              : () => fit.toggleCheckin(i),
      child: Opacity(
        opacity: isFuture ? 0.5 : 1,
        child: Column(
          children: [
            Text(t.weekdayInitial(fit.weekdayAt(i)),
                style: AppTheme.f(11,
                    weight: FontWeight.w700,
                    color: isToday ? gc.text : gc.textTertiary,
                    letterSpacing: 0.5)),
            const SizedBox(height: 9),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: done ? gc.ember : gc.bgRaised2,
                shape: BoxShape.circle,
                border: isToday && !done ? Border.all(color: gc.ember, width: 2) : null,
              ),
              child:
                  done ? Center(child: SvgPathIcon(Ic.checkBold, size: 13, color: gc.onEmber)) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context, GymColors gc) {
    return GymCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.all(GymSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader.label(t.thisWeek),
          const SizedBox(height: GymSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (int i = 0; i < 7; i++) Expanded(child: _weekDay(context, gc, i))],
          ),
          const SizedBox(height: GymSpace.lg),
          Container(height: GymBorder.hairline, color: gc.border),
          const SizedBox(height: GymSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: MetricCard(label: t.statWorkouts, value: '${fit.sessionsThisWeek}')),
                    Expanded(
                      child: MetricCard(label: t.volume, value: fit.volumeValue(fit.volumeThisWeekKg), unit: fit.volumeUnit),
                    ),
                    Expanded(child: MetricCard(label: t.prs, value: '${fit.prsThisWeek}')),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: t.weeklyGoal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showWeeklyGoalSheet(context),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: GymSpace.minTarget, minHeight: GymSpace.minTarget),
                    child: Column(
                      children: [
                        ProgressRing(value: fit.goalPct / 100, size: 44, semanticLabel: t.goalRingLabel(fit.goalPct.clamp(0, 100))),
                        const SizedBox(height: GymSpace.sm - 1),
                        Text('${fit.daysDoneThisWeek}/${fit.weeklyTarget}',
                            style: GymText.caption(color: gc.textSecondary, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcuts(GymColors gc) {
    Widget tile(IconData icon, String title, String detail, VoidCallback onTap) => Expanded(
          child: GymCard(
            radius: GymRadius.md,
            padding: const EdgeInsets.all(GymSpace.md),
            onTap: onTap,
            semanticLabel: '$title, $detail',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: gc.textSecondary),
                const SizedBox(height: GymSpace.sm),
                Text(_tc(title), maxLines: 1, overflow: TextOverflow.ellipsis, style: GymText.label(color: gc.text)),
                const SizedBox(height: GymSpace.xs),
                Text(detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GymText.caption(color: gc.textTertiary)),
              ],
            ),
          ),
        );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile(PhosphorIconsRegular.listChecks, t.routines, t.routineCount(fit.routines.length), fit.goRoutines),
          const SizedBox(width: GymSpace.sm),
          tile(PhosphorIconsRegular.calculator, t.tools, t.calculatorsInside, fit.goTools),
          const SizedBox(width: GymSpace.sm),
          tile(PhosphorIconsRegular.notePencil, t.journal, t.noteCount(fit.notes.length), fit.goNotes),
        ],
      ),
    );
  }

  Widget _personalizeNudge(GymColors gc) {
    return GymCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.sparkle, size: 19, color: gc.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Semantics(
              button: true,
              label: '${t.personalizeTitle}. ${t.personalizeBody}',
              excludeSemantics: true,
              onTap: fit.goPersonalize,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: fit.goPersonalize,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.personalizeTitle, style: AppTheme.f(14, color: gc.text)),
                    const SizedBox(height: 2),
                    Text(t.personalizeBody,
                        style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35)),
                    const SizedBox(height: 6),
                    Text(t.personalizeCta, style: AppTheme.f(13, weight: FontWeight.w700, color: gc.accent)),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: t.notNow,
            excludeSemantics: true,
            onTap: fit.dismissPersonalize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: fit.dismissPersonalize,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(child: Icon(PhosphorIconsBold.x, size: 15, color: gc.textTertiary)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoNudge(GymColors gc) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goMoments,
      child: GymCard(
        radius: GymRadius.lg,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Row(
          children: [
            Icon(PhosphorIconsRegular.camera, size: 19, color: gc.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.photoDueNow, style: AppTheme.f(14, color: gc.text)),
                  const SizedBox(height: 2),
                  Text(t.photoInterval(fit.photoIntervalDays),
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                ],
              ),
            ),
            Icon(PhosphorIconsBold.caretRight, size: 14, color: gc.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _recCard(GymColors gc, Exercise ex) => ExerciseTile(exercise: ex, onTap: () => fit.openExercise(ex.id));
}

void showWeeklyGoalSheet(BuildContext context) {
  final gc = context.gc;
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setSheet) => Container(
        padding: sheetPad(sheet),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            Text(t.weeklyGoal,
                textAlign: TextAlign.center,
                style: AppTheme.f(20, color: gc.text)),
            const SizedBox(height: 6),
            Text(t.sessionsLogged(fit.sessionsThisWeek),
                textAlign: TextAlign.center,
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
            const SizedBox(height: 20),
            Center(
              child: StepperControl(
                value: t.perWeek(fit.profile.weeklyGoal),
                minWidth: 148,
                onDec: () => setSheet(() => fit.updateProfile(weeklyGoalDelta: -1)),
                onInc: () => setSheet(() => fit.updateProfile(weeklyGoalDelta: 1)),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.onbGoalWhy,
                textAlign: TextAlign.center,
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
            const SizedBox(height: 22),
            PrimaryButton(label: t.done, onTap: () => Navigator.of(sheet).pop()),
          ],
        ),
      ),
    ),
  );
}
