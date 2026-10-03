part of '../progress_screen.dart';

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.spots, this.color, this.rail, this.bg, {this.open = false});
  final List<double> spots;
  final Color color;
  final Color rail;
  final Color bg;
  final bool open;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Paint()
      ..color = rail
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (open) {
      for (var x = 0.0; x < size.width; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), line);
      }
      canvas.drawCircle(Offset(5, y), 5, Paint()..color = color);
      return;
    }
    canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    const inset = 5.0;
    final w = size.width - inset * 2;
    canvas.drawLine(
      Offset(inset, y),
      Offset(inset + w, y),
      Paint()
        ..shader = LinearGradient(colors: [color.withValues(alpha: 0.25), color])
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    for (final s in spots) {
      final c = Offset(inset + w * s, y);
      final edge = s <= 0.001 || s >= 0.999;
      canvas.drawCircle(c, edge ? 5 : 3.5, Paint()..color = bg);
      canvas.drawCircle(
          c,
          edge ? 5 : 3.5,
          Paint()
            ..color = edge ? color : color.withValues(alpha: 0.7)
            ..style = edge ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_TrackPainter o) =>
      o.spots != spots || o.color != color || o.rail != rail || o.open != open;
}
