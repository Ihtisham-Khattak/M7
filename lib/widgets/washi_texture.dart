import 'dart:math' as math;

import 'package:flutter/material.dart';

class WashiPainter extends CustomPainter {
  const WashiPainter({required this.ink, required this.paper, this.seed = 7});

  final Color ink;
  final Color paper;
  final int seed;

  static const double maxMarkAlpha = 0.07;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rnd = math.Random(seed);
    final area = size.width * size.height;

    final blotch = Paint();
    for (var i = 0; i < 7; i++) {
      final c = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = (0.22 + rnd.nextDouble() * 0.3) * size.shortestSide;
      final tint = rnd.nextBool() ? ink : paper;
      blotch.shader = RadialGradient(colors: [tint.withValues(alpha: 0.03), tint.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, blotch);
    }

    final fibre = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fibres = (area / 380).round();
    for (var i = 0; i < fibres; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final angle = (rnd.nextDouble() - 0.5) * math.pi * 1.6 + (rnd.nextBool() ? 0 : math.pi / 2.2);
      final len = 5 + rnd.nextDouble() * 24;
      final bend = (rnd.nextDouble() - 0.5) * 6;
      final end = p + Offset(math.cos(angle), math.sin(angle)) * len;
      final mid = Offset.lerp(p, end, 0.5)! + Offset(-math.sin(angle), math.cos(angle)) * bend;
      fibre
        ..strokeWidth = 0.45 + rnd.nextDouble() * 0.7
        ..color = ink.withValues(alpha: 0.025 + rnd.nextDouble() * (maxMarkAlpha - 0.025));
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy),
        fibre,
      );
    }

    final fleck = Paint();
    final flecks = (area / 2600).round();
    for (var i = 0; i < flecks; i++) {
      final p = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      fleck.color = ink.withValues(alpha: 0.03 + rnd.nextDouble() * 0.04);
      canvas.drawCircle(p, 0.4 + rnd.nextDouble() * 0.7, fleck);
    }
  }

  @override
  bool shouldRepaint(WashiPainter old) => old.ink != ink || old.paper != paper || old.seed != seed;
}
