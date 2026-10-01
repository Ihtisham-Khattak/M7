import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/theme/tokens.dart';

import 'support/fonts.dart';

double _width(String text, TextStyle style) {
  final p = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  return p.width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  test('the bundled typeface and its licence ship with the app', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Manrope'));
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
      expect(File('assets/fonts/Manrope-$w.ttf').existsSync(), true, reason: w);
      expect(pubspec, contains('assets/fonts/Manrope-$w.ttf'));
    }
    expect(File('assets/fonts/Manrope-OFL.txt').existsSync(), true);
    expect(File('CREDITS.md').readAsStringSync(), contains('Manrope'));
    expect(pubspec, isNot(contains('Nunito')));
    expect(Directory('assets/fonts').listSync().whereType<File>().where((f) => f.path.contains('Nunito')), isEmpty);
  });

  test('every text style uses the one family', () {
    expect(AppTheme.f(14).fontFamily, 'Manrope');
    expect(AppTheme.s(14).fontFamily, 'Manrope');
    expect(AppTheme.d(14).fontFamily, 'Manrope');
    for (final style in [
      GymText.caption(),
      GymText.label(),
      GymText.body(),
      GymText.bodyLarge(),
      GymText.button(),
      GymText.title(),
      GymText.headline(),
      GymText.display(),
      GymText.numeric(20),
    ]) {
      expect(style.fontFamily, 'Manrope');
    }
  });

  test('digits line up: every figure is the same width in the numeric role', () {
    final style = GymText.numeric(28);
    expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    final widths = {for (final d in '0123456789'.split('')) d: _width(d * 4, style)};
    final first = widths.values.first;
    for (final e in widths.entries) {
      expect(e.value, closeTo(first, 0.5), reason: 'digit ${e.key} differs in width');
    }
  });

  test('a column of sets and weights keeps its decimal points aligned', () {
    final style = GymText.numeric(18);
    expect(_width('111.1', style), closeTo(_width('888.8', style), 0.5));
    expect(_width('1:11', style), closeTo(_width('8:88', style), 0.5));
  });

  test('the weights are real: heavier roles are measurably wider than regular', () {
    final regular = _width('Strength', AppTheme.f(20, weight: FontWeight.w400));
    final medium = _width('Strength', AppTheme.f(20, weight: FontWeight.w500));
    final bold = _width('Strength', AppTheme.f(20, weight: FontWeight.w700));
    final extra = _width('Strength', AppTheme.f(20, weight: FontWeight.w800));
    expect(medium, greaterThan(regular));
    expect(bold, greaterThan(medium));
    expect(extra, greaterThan(bold));
  });

  test('Latin, Cyrillic and Greek text is drawn with the bundled font, not a fallback', () {
    final latin = _width('Training', AppTheme.f(16));
    final cyrillic = _width('Тренировка', AppTheme.f(16));
    final greek = _width('Προπόνηση', AppTheme.f(16));
    final missing = _width('Training', const TextStyle(fontFamily: 'NoSuchFont', fontSize: 16));
    expect(latin, isNot(closeTo(missing, 0.1)));
    expect(cyrillic, greaterThan(40));
    expect(greek, greaterThan(40));
  });
}
