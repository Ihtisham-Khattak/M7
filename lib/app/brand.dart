import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The name people see. Internal identifiers (package id, `gymmane_v1`, `gymmane.json`,
/// class names) deliberately keep the old spelling so installs, data and backups carry over.
const String kAppName = 'Kaizan';

/// The Kaizan mark: a soft-cornered K whose upper arm rises (the 1 % better).
/// Geometry is in a 100x100 box; `tool/make_icons.py` draws the same shape for the launcher
/// icons, so change both together.
class KaizanMark extends StatelessWidget {
  const KaizanMark({super.key, this.size = 48, this.color, this.accent});

  final double size;

  /// Stem and leg; defaults to the text colour.
  final Color? color;

  /// The rising arm; defaults to the brand vermilion.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      label: kAppName,
      image: true,
      child: ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _MarkPainter(color ?? gc.text, accent ?? gc.ember),
        ),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.base, this.accent);

  final Color base;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    Paint stroke(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 15 * u
      ..isAntiAlias = true;
    Offset p(double x, double y) => Offset(x * u, y * u);

    final b = stroke(base);
    canvas.drawLine(p(22, 14), p(22, 86), b); // stem
    canvas.drawLine(p(47, 36), p(78, 86), b); // leg
    canvas.drawLine(p(22, 54), p(76, 14), stroke(accent)); // rising arm
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.base != base || old.accent != accent;
}

/// "KAIZAN" set in the app typeface, wide-tracked, with the mark when [withMark] is true.
class KaizanWordmark extends StatelessWidget {
  const KaizanWordmark({super.key, this.size = 20, this.color, this.withMark = false});

  final double size;
  final Color? color;
  final bool withMark;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final c = color ?? gc.text;
    final word = Text(
      kAppName.toUpperCase(),
      style: AppTheme.f(size, weight: FontWeight.w800, color: c, letterSpacing: size * 0.26, height: 1),
    );
    if (!withMark) return Semantics(label: kAppName, child: ExcludeSemantics(child: word));
    return Semantics(
      label: kAppName,
      child: ExcludeSemantics(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          KaizanMark(size: size * 1.5, color: c),
          SizedBox(width: size * 0.5),
          word,
        ]),
      ),
    );
  }
}
