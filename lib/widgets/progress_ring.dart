import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';

/// A ring showing [value] (0..1). Uses the brand colour, so use it once per screen for the one
/// progress that matters (GM-15); everything else stays neutral.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 44, this.semanticLabel, this.child});

  final double value;
  final double size;
  final String? semanticLabel;

  /// Optional centre content (a number, an icon).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final v = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: v),
            duration: GymMotion.of(context, const Duration(milliseconds: 500)),
            curve: GymMotion.curve,
            builder: (context, shown, _) => CustomPaint(
              painter: _RingPainter(shown, gc.bgRaised2, gc.ember),
              child: child == null ? null : Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.track, this.color);

  final double value;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset(stroke / 2, stroke / 2) & Size(size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track
      ..isAntiAlias = true;
    canvas.drawArc(rect, 0, 6.2831853, false, base);
    if (value <= 0) return;
    canvas.drawArc(
      rect,
      -1.5707963,
      6.2831853 * value,
      false,
      base
        ..color = color
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value || old.track != track || old.color != color;
}
