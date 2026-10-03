import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/workout.dart';
import '../services/home_focus.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'components.dart';
import 'svg_icon.dart';
import 'ui_kit.dart';

enum WorkoutStatus { none, planned, inProgress, done, rest }

/// Everything the app says about "a workout" (name, muscles, exercise count, time, status), so
/// Home, the start sheet and the routine list describe it the same way (GM-15).
class WorkoutSummary {
  const WorkoutSummary({
    required this.title,
    this.muscles = '',
    this.exerciseCount = 0,
    this.minutes = 0,
    this.status = WorkoutStatus.none,
  });

  final String title;
  final String muscles;
  final int exerciseCount;
  final int minutes;
  final WorkoutStatus status;

  factory WorkoutSummary.of(Routine r, {WorkoutStatus status = WorkoutStatus.none}) {
    final ids = [for (final id in r.exerciseIds) fit.exerciseById(id)?.primary ?? ''];
    return WorkoutSummary(
      title: fit.routineTitle(r),
      muscles: leadingMuscles(ids).map(t.muscle).join(' + '),
      exerciseCount: r.exerciseIds.length,
      minutes: estimateWorkoutMinutes([
        for (final id in r.exerciseIds) (sets: fit.routineSets(r, id), restSeconds: fit.restFor(id)),
      ]),
      status: status,
    );
  }

  String? get statusLabel => switch (status) {
        WorkoutStatus.none => null,
        WorkoutStatus.planned => sentenceCase(t.plannedRoutine),
        WorkoutStatus.inProgress => sentenceCase(t.inProgress),
        WorkoutStatus.done => sentenceCase(t.done),
        WorkoutStatus.rest => t.restDayShort,
      };

  /// "Chest + Biceps · 5 exercises · ~45 min"
  String get meta => [
        t.exerciseCount(exerciseCount),
        if (minutes > 0) '~${t.minutesOption(minutes)}',
      ].join(' · ');

  /// One sentence for a screen reader.
  String get spoken => [title, ?statusLabel, if (muscles.isNotEmpty) muscles, meta].join('. ');
}

/// A compact one-line workout, for lists and sheets.
class WorkoutTile extends StatelessWidget {
  const WorkoutTile({super.key, required this.summary, required this.onTap, this.highlighted = false, this.heading});

  final WorkoutSummary summary;
  final VoidCallback onTap;

  /// The planned-for-today workout: soft brand tint and a filled play button.
  final bool highlighted;
  final String? heading;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final s = summary;
    return Semantics(
      button: true,
      label: s.spoken,
      excludeSemantics: true,
      onTap: onTap,
      child: GymCard(
        radius: GymRadius.lg,
        color: highlighted ? gc.emberSoft : null,
        borderColor: highlighted ? gc.ember.withValues(alpha: 0.4) : null,
        padding: const EdgeInsets.symmetric(horizontal: GymSpace.lg, vertical: GymSpace.md),
        onTap: onTap,
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (heading != null) ...[
                  Text(heading!.toUpperCase(),
                      style: GymText.caption(color: gc.textTertiary, weight: FontWeight.w700).copyWith(letterSpacing: 1.2)),
                  const SizedBox(height: GymSpace.xs),
                ],
                Text(s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GymText.bodyLarge(color: gc.text, weight: FontWeight.w700)),
                const SizedBox(height: GymSpace.xs / 2),
                Text([if (s.muscles.isNotEmpty) s.muscles, s.meta].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GymText.caption(color: gc.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: GymSpace.md),
          Container(
            width: GymSpace.minTarget - 4,
            height: GymSpace.minTarget - 4,
            decoration: BoxDecoration(
              color: highlighted ? gc.ember : gc.bgRaised2,
              borderRadius: BorderRadius.circular(GymRadius.md),
            ),
            child: Icon(PhosphorIconsFill.play, size: 18, color: highlighted ? gc.onEmber : gc.textSecondary),
          ),
        ]),
      ),
    );
  }
}

/// "What do I do today?" in one card: label, title, what it trains, how long it takes, its
/// status and one Start button (GM-16). The only coloured element is the button.
class WorkoutCard extends StatelessWidget {
  const WorkoutCard({
    super.key,
    required this.label,
    required this.title,
    required this.onStart,
    required this.startLabel,
    this.muscles,
    this.meta,
    this.status,
    this.done = false,
  });

  final String label;
  final String title;
  final String? muscles;
  final String? meta;
  final String? status;
  final bool done;
  final String startLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      container: true,
      label: [title, ?status, ?muscles, ?meta].join('. '),
      child: GymCard(
      radius: GymRadius.xl,
      padding: const EdgeInsets.all(GymSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label.toUpperCase(),
                    style: GymText.caption(color: gc.textTertiary, weight: FontWeight.w700).copyWith(letterSpacing: 1.4)),
              ),
              if (status != null)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (done) ...[
                    SvgPathIcon(Ic.checkBold, size: 12, color: gc.success),
                    const SizedBox(width: GymSpace.xs),
                  ],
                  Text(sentenceCase(status!),
                      style: GymText.caption(color: done ? gc.success : gc.textSecondary, weight: FontWeight.w700)),
                ]),
            ],
          ),
          const SizedBox(height: GymSpace.sm),
          Semantics(
            header: true,
            child: Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GymText.display(color: gc.text).copyWith(fontSize: 28, height: 1.12)),
          ),
          if (muscles != null && muscles!.isNotEmpty) ...[
            const SizedBox(height: GymSpace.sm),
            Text(muscles!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GymText.bodyLarge(color: gc.textSecondary)),
          ],
          if (meta != null && meta!.isNotEmpty) ...[
            const SizedBox(height: GymSpace.xs),
            Text(meta!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GymText.body(color: gc.textSecondary)),
          ],
          const SizedBox(height: GymSpace.xl),
          PrimaryButton(label: startLabel, icon: Ic.play, onTap: onStart),
        ],
      ),
      ),
    );
  }
}
