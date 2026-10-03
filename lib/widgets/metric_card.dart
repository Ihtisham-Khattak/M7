import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'entrance.dart';
import 'ui_kit.dart';

/// One number with its label and unit (weight, reps, sets, duration, volume, PR) - GM-15.
/// Digits are tabular so columns of metrics line up.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.emphasis = false,
    this.animate = true,
  });

  final String label;
  final String value;
  final String unit;

  /// The single headline metric on a screen: brand colour.
  final bool emphasis;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    // height 1.0 would clip the descent of rolling digits; keep the numeric role's tabular figures
    final style = GymText.numeric(GymText.headlineSize + 3, color: emphasis ? gc.ember : gc.text, weight: FontWeight.w800)
        .copyWith(height: 1.2);
    return Semantics(
      container: true,
      label: '$label: $value${unit.isEmpty ? '' : ' $unit'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: GymSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FitText(label.toUpperCase(),
                  style: GymText.caption(color: gc.textTertiary, weight: FontWeight.w600).copyWith(letterSpacing: 0.9)),
              const SizedBox(height: GymSpace.sm - 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: animate ? RollIn(value, style: style) : Text(value, style: style),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: GymSpace.xs - 1),
                    Text(unit, style: GymText.caption(color: gc.textSecondary, weight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
