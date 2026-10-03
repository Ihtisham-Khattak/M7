import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/ui_kit.dart';
import '../widgets/workout_card.dart';

void showStartSheet(BuildContext context, {DateTime? day}) {
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => StartSheet(day: day),
  );
}

class StartSheet extends StatelessWidget {
  const StartSheet({super.key, this.day});

  final DateTime? day;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final planned = fit.routinesOn(day ?? DateTime.now()).where((r) => r.exerciseIds.isNotEmpty).toList();
    final others = [
      for (final group in fit.routineGroups) ...fit.routinesInGroup(group),
      ...fit.routinesInGroup(''),
    ].where((r) => !planned.contains(r) && r.exerciseIds.isNotEmpty).toList();
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      padding: sheetPad(context),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text(day == null ? t.startTitle : t.logTitle,
              style: AppTheme.f(21, weight: FontWeight.w700, color: gc.text)),
          const SizedBox(height: 4),
          Text(t.longDate(day ?? DateTime.now()),
              style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary)),
          if (day != null) ...[
            const SizedBox(height: 12),
            Text(t.logHint, style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textTertiary)),
          ],
          const SizedBox(height: 18),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final r in planned) ...[
                    _plannedCard(context, gc, r),
                    const SizedBox(height: 10),
                  ],
                  if (others.isNotEmpty) ...[
                    _label(gc, t.yourRoutines),
                    for (final r in others) ...[
                      _routineRow(context, gc, r),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 6),
                  ],
                  _label(gc, t.orStartFrom),
                  _option(context, gc, PhosphorIconsRegular.listPlus, t.pickExercisesOption,
                      () => fit.startPicking(on: day)),
                  const SizedBox(height: 8),
                  _option(context, gc, PhosphorIconsRegular.person, t.chooseFocusOption,
                      () => fit.startWorkout(null, day)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(GymColors gc, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text.toUpperCase(),
            style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.2)),
      );

  Widget _plannedCard(BuildContext context, GymColors gc, Routine r) => WorkoutTile(
        summary: WorkoutSummary.of(r, status: WorkoutStatus.planned),
        heading: day == null ? t.todaysRoutine : t.plannedRoutine,
        highlighted: true,
        onTap: () => _go(context, () => fit.startRoutine(r, on: day)),
      );

  Widget _routineRow(BuildContext context, GymColors gc, Routine r) => WorkoutTile(
        summary: WorkoutSummary.of(r),
        onTap: () => _go(context, () => fit.startRoutine(r, on: day)),
      );

  Widget _option(
      BuildContext context, GymColors gc, IconData icon, String label, VoidCallback action) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _go(context, action),
      child: SoftCard(
        radius: GymRadius.lg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 19, color: gc.textSecondary),
          const SizedBox(width: 13),
          Expanded(child: Text(label, style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text))),
        ]),
      ),
    );
  }

  void _go(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }
}
