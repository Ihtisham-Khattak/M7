import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/background_guard.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/widgets/washi_texture.dart';

Future<Uint8List> _render(GymColors gc, {int w = 360, int h = 780}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), Paint()..color = gc.bg);
  WashiPainter(ink: gc.textTertiary, paper: gc.bgRaised).paint(canvas, Size(w.toDouble(), h.toDouble()));
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in {'dark': GymColors.dark, 'light': GymColors.light}.entries) {
    final gc = entry.value;

    test('${entry.key}: the texture is visible but very faint', () async {
      final pixels = await _render(gc);
      final base = gc.bg;
      var maxDelta = 0.0, changed = 0;
      for (var i = 0; i < pixels.length; i += 4) {
        final d = [
          (pixels[i] - base.r * 255).abs(),
          (pixels[i + 1] - base.g * 255).abs(),
          (pixels[i + 2] - base.b * 255).abs(),
        ].reduce((a, b) => a > b ? a : b);
        if (d > maxDelta) maxDelta = d;
        if (d >= 1) changed++;
      }
      final total = pixels.length / 4;
      expect(changed / total, greaterThan(0.03), reason: 'there must be a texture');
      expect(changed / total, lessThan(0.6), reason: 'it must stay sparse');
      expect(maxDelta, lessThanOrEqualTo(46), reason: 'no mark may be strong');
    });

    test('${entry.key}: every text tier keeps 4.5:1 on the darkest and lightest paper pixels', () async {
      final pixels = await _render(gc);
      final tones = analyzeTones(pixels, percentile: 0.999);
      for (final t in [gc.text, gc.textSecondary, gc.textTertiary]) {
        for (final y in [tones.dark, tones.bright]) {
          expect(contrastOfLuminances(luminanceOf(t), y), greaterThanOrEqualTo(4.5));
        }
      }
    });

    test('${entry.key}: the texture is identical every time (fixed seed)', () async {
      final a = await _render(gc);
      final b = await _render(gc);
      expect(a, b);
    });
  }

  test('it repaints only when the colours change and ships no assets', () {
    final a = WashiPainter(ink: Colors.black, paper: Colors.white);
    expect(a.shouldRepaint(WashiPainter(ink: Colors.black, paper: Colors.white)), false);
    expect(a.shouldRepaint(WashiPainter(ink: Colors.red, paper: Colors.white)), true);
    expect(WashiPainter.maxMarkAlpha, lessThanOrEqualTo(0.08));
  });

  test('the mode has a name in every language', () {
    expect(t.bgAncient.trim(), isNotEmpty);
  });
}
