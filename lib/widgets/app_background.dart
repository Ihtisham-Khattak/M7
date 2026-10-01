import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/background_guard.dart';
import '../theme/app_colors.dart';
import 'washi_texture.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.pattern,
    this.photo,
    this.dim = 0.55,
    this.zoom = 1,
    this.dx = 0,
    this.dy = 0,
    this.opacity = 1,
    this.blur = 0,
  });

  final String pattern;
  final String? photo;
  final double dim;
  final double zoom;
  final double dx;
  final double dy;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    if (pattern == 'photo') {
      final path = photo;
      if (path == null) return const SizedBox.shrink();
      return _PhotoBackground(path: path, dim: dim, zoom: zoom, dx: dx, dy: dy, opacity: opacity, blur: blur);
    }
    if (pattern == 'ancient') {
      return IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: WashiPainter(ink: gc.textTertiary, paper: gc.bgRaised),
          ),
        ),
      );
    }
    if (pattern != 'dots' && pattern != 'grid') return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BgPainter(pattern: pattern, color: gc.border),
        ),
      ),
    );
  }
}

final Map<String, ImageTones> _toneCache = {};

Future<ImageTones> _measure(String path) async {
  final cached = _toneCache[path];
  if (cached != null) return cached;
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 48);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.image.dispose();
    codec.dispose();
    final tones = data == null ? kUnknownTones : analyzeTones(data.buffer.asUint8List());
    return _toneCache[path] = tones;
  } catch (e) {
    debugPrint('AppBackground: could not measure the picture ($e)');
    return kUnknownTones;
  }
}

class _PhotoBackground extends StatefulWidget {
  const _PhotoBackground({
    required this.path,
    required this.dim,
    required this.zoom,
    required this.dx,
    required this.dy,
    required this.opacity,
    required this.blur,
  });

  final String path;
  final double dim;
  final double zoom;
  final double dx;
  final double dy;
  final double opacity;
  final double blur;

  @override
  State<_PhotoBackground> createState() => _PhotoBackgroundState();
}

class _PhotoBackgroundState extends State<_PhotoBackground> {
  ImageTones? _tones;

  @override
  void initState() {
    super.initState();
    _tones = _toneCache[widget.path];
    _load();
  }

  @override
  void didUpdateWidget(_PhotoBackground old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) {
      _tones = _toneCache[widget.path];
      _load();
    }
  }

  Future<void> _load() async {
    final path = widget.path;
    final tones = await _measure(path);
    if (mounted && path == widget.path) setState(() => _tones = tones);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final guard = readableScrim(
      tones: blendTones(_tones ?? kUnknownTones, gc.bg, widget.opacity),
      texts: [gc.text, gc.textSecondary, gc.textTertiary],
      scrim: gc.bg,
    );
    final top = math.max(widget.dim, guard).clamp(0.0, kMaxScrim);
    final bottom = math.min(top + 0.12, 1.0);
    final media = MediaQuery.of(context);
    final cacheWidth = (media.size.width * media.devicePixelRatio).round();
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: widget.opacity,
              child: ClipRect(
                child: ImageFiltered(
                  enabled: widget.blur > 0.05,
                  imageFilter: ui.ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur, tileMode: TileMode.clamp),
                  child: Transform.scale(
                    scale: widget.zoom,
                    alignment: Alignment(widget.dx, widget.dy),
                    child: Image.file(
                      File(widget.path),
                      fit: BoxFit.cover,
                      alignment: Alignment(widget.dx, widget.dy),
                      cacheWidth: (cacheWidth * math.min(widget.zoom, 2.0)).round(),
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gc.bg.withValues(alpha: top), gc.bg.withValues(alpha: bottom)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter({required this.pattern, required this.color});

  final String pattern;
  final Color color;
  static const _gap = 26.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (pattern == 'dots') {
      final p = Paint()..color = color.withValues(alpha: 0.5);
      for (double y = _gap; y < size.height; y += _gap) {
        for (double x = _gap; x < size.width; x += _gap) {
          canvas.drawCircle(Offset(x, y), 1.1, p);
        }
      }
    } else {
      final p = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 1;
      for (double x = _gap; x < size.width; x += _gap) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      }
      for (double y = _gap; y < size.height; y += _gap) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.pattern != pattern || old.color != color;
}
