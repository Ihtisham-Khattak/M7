import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'components.dart';
import 'exercise_media.dart';
import 'ui_kit.dart';

/// The one way an exercise is shown in a list or a picker (GM-14): thumbnail, localised name,
/// "muscle · equipment" (or your own line), optional extra content and a trailing control.
/// Completion and selection are quiet: a border or a check, never a badge.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    this.subtitle,
    this.showDifficulty = false,
    this.trailing,
    this.leading,
    this.body,
    this.selected = false,
    this.dimmed = false,
    this.bare = false,
    this.divider = false,
    this.onTap,
    this.onLongPress,
    this.onThumbTap,
    this.thumbSize = 44,
    this.semanticHint,
  });

  final Exercise exercise;

  /// Replaces the default "Muscle · Equipment" line (e.g. "Last: 60×8").
  final String? subtitle;
  final bool showDifficulty;
  final Widget? trailing;

  /// Before the thumbnail, e.g. a drag handle.
  final Widget? leading;

  /// Extra content under the subtitle (steppers, a plan line).
  final Widget? body;

  /// Ember outline: picked, in the routine.
  final bool selected;
  final bool dimmed;

  /// No card around it: a plain row for use inside a grouped list.
  final bool bare;
  final bool divider;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Tapping the picture opens a preview.
  final VoidCallback? onThumbTap;
  final double thumbSize;
  final String? semanticHint;

  static String lineFor(Exercise ex, {bool difficulty = false}) => [
        muscleLabel(ex.primary),
        t.equipment(ex.equipment),
        if (difficulty) t.difficulty(ex.difficulty),
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final name = exerciseName(exercise);
    final line = subtitle ?? lineFor(exercise, difficulty: showDifficulty);

    final thumb = SizedBox(
      width: thumbSize,
      child: ExerciseMedia(ex: exercise, height: thumbSize, radius: GymRadius.sm, bordered: false),
    );
    final content = Row(children: [
      if (leading != null) leading!,
      onThumbTap == null
          ? thumb
          : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onThumbTap, child: thumb),
      const SizedBox(width: GymSpace.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GymText.bodyLarge(color: gc.text, weight: FontWeight.w600)),
            const SizedBox(height: GymSpace.xs / 2),
            Text(line, maxLines: 1, overflow: TextOverflow.ellipsis, style: GymText.caption(color: gc.textSecondary)),
            ?body,
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: GymSpace.sm), trailing!],
    ]);

    final Widget visual;
    if (bare) {
      visual = Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GymSpace.md, vertical: GymSpace.sm),
          child: ConstrainedBox(constraints: const BoxConstraints(minHeight: GymSpace.minTarget), child: content),
        ),
        if (divider)
          Container(
            margin: EdgeInsets.only(left: GymSpace.md + thumbSize + GymSpace.md),
            height: GymBorder.hairline,
            color: gc.border.withValues(alpha: 0.6),
          ),
      ]);
    } else {
      visual = AnimatedContainer(
        duration: GymMotion.of(context, GymMotion.fast),
        padding: const EdgeInsets.all(GymSpace.sm),
        decoration: BoxDecoration(
          color: gc.bgRaised,
          border: Border.all(color: selected ? gc.ember : gc.border),
          borderRadius: BorderRadius.circular(GymRadius.md),
        ),
        child: ConstrainedBox(constraints: const BoxConstraints(minHeight: GymSpace.minTarget), child: content),
      );
    }

    final tapped = onTap == null && onLongPress == null
        ? visual
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            onLongPress: onLongPress,
            child: visual,
          );
    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected,
      label: '$name, $line',
      hint: semanticHint,
      child: Opacity(opacity: dimmed ? 0.45 : 1, child: tapped),
    );
  }
}

/// A muscle group as a small label; selectable when [onTap] is given. Neutral by default, the
/// brand tint only when selected - no per-group colours.
class MuscleChip extends StatelessWidget {
  const MuscleChip(this.muscleId, {super.key, this.selected = false, this.onTap});

  final String muscleId;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: GymSpace.md, vertical: GymSpace.xs + 2),
      decoration: BoxDecoration(
        color: selected ? gc.emberSoft : gc.bgRaised2,
        borderRadius: BorderRadius.circular(GymRadius.sm),
      ),
      child: Text(muscleLabel(muscleId),
          style: GymText.caption(color: selected ? gc.ember : gc.textSecondary, weight: FontWeight.w600)),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      label: muscleLabel(muscleId),
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(onTap: onTap, child: MinTarget(child: chip)),
    );
  }
}

/// Vertical variant for carousels: picture on top, localised name under it.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({super.key, required this.exercise, required this.onTap, this.width = 132});

  final Exercise exercise;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final name = exerciseName(exercise);
    return SizedBox(
      width: width,
      child: GymCard(
        borderless: true,
        padding: const EdgeInsets.all(GymSpace.sm),
        onTap: onTap,
        semanticLabel: '$name, ${ExerciseCard.lineFor(exercise)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExerciseMedia(ex: exercise, height: 88, radius: GymRadius.md),
            const SizedBox(height: GymSpace.sm),
            Expanded(
              child: Text(name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GymText.caption(color: gc.text, weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
