import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_colors.dart';

double _channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) => 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final themes = {'dark': GymColors.dark, 'light': GymColors.light};

  for (final entry in themes.entries) {
    final name = entry.key;
    final gc = entry.value;
    final surfaces = {'bg': gc.bg, 'bgRaised': gc.bgRaised, 'bgRaised2': gc.bgRaised2};

    group('$name theme contrast', () {
      test('every text tier reads at 4.5:1 on every surface', () {
        final text = {'text': gc.text, 'textSecondary': gc.textSecondary, 'textTertiary': gc.textTertiary};
        final low = <String>[];
        for (final t in text.entries) {
          for (final s in surfaces.entries) {
            final ratio = contrast(t.value, s.value);
            if (ratio < 4.5) low.add('${t.key} on ${s.key}: ${ratio.toStringAsFixed(2)}');
          }
        }
        expect(low, isEmpty);
      });

      test('the text tiers stay in order of emphasis', () {
        final bg = gc.bg;
        expect(contrast(gc.text, bg), greaterThan(contrast(gc.textSecondary, bg)));
        expect(contrast(gc.textSecondary, bg), greaterThan(contrast(gc.textTertiary, bg)));
      });

      test('accent and status colors used as text reach 4.5:1 on the main surfaces', () {
        final colors = {
          'accent': gc.accent,
          'brass': gc.brass,
          'sage': gc.sage,
          'info': gc.info,
          'warn': gc.warn,
          'danger': gc.danger,
          'success': gc.success,
          'progress': gc.progress,
          'streak': gc.streak,
        };
        final low = <String>[];
        for (final c in colors.entries) {
          for (final s in [surfaces['bg']!, surfaces['bgRaised']!]) {
            final ratio = contrast(c.value, s);
            if (ratio < 4.5) low.add('${c.key}: ${ratio.toStringAsFixed(2)}');
          }
        }
        expect(low, isEmpty);
      });

      test('colors on raised fills reach 3:1 (large text and icons)', () {
        final colors = [gc.accent, gc.sage, gc.info, gc.warn, gc.danger, gc.success, gc.progress, gc.streak];
        for (final c in colors) {
          expect(contrast(c, gc.bgRaised2), greaterThanOrEqualTo(3));
        }
      });

      test('text on the accent button is readable', () {
        expect(contrast(gc.onEmber, gc.ember), greaterThanOrEqualTo(4.5));
      });
    });
  }

  test('the contrast helper matches the WCAG reference values', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrast(const Color(0xFF777777), Colors.white), closeTo(4.48, 0.02));
  });
}
