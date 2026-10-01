import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/app_shell.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/theme/app_theme.dart';

import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  tearDown(() => setAppLanguage('en'));

  double naturalWidth(String label, double scale) {
    final p = TextPainter(
      text: TextSpan(text: navLabel(label), style: AppTheme.s(kNavLabelSize * scale, weight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return p.width;
  }

  // Manrope covers Latin and Cyrillic; the other scripts render with the platform font, which a
  // test cannot measure, so they are held to a plain length limit instead.
  const platformFont = {'ar', 'fa', 'ja', 'ko', 'zh', 'zh_Hant'};

  test('every tab label in every language fits its slot at 1.15x text without shrinking below 70%', () {
    final worst = <String>[];
    for (final code in appLanguages) {
      setAppLanguage(code);
      for (final label in [t.home, t.progress, t.exercises, t.profile]) {
        if (platformFont.contains(code)) {
          if (label.characters.length > 10) worst.add('$code "$label": ${label.characters.length} characters');
          continue;
        }
        final shrink = kNavLabelWidth / naturalWidth(label, 1.15);
        if (shrink < 0.7) worst.add('$code "$label": ${(shrink * 100).round()}%');
      }
    }
    expect(worst, isEmpty, reason: 'shorten these tab labels (or widen the slot)');
  });

  test('all four tab labels use one case style in every language', () {
    for (final code in appLanguages) {
      setAppLanguage(code);
      final shown = [t.home, t.progress, t.exercises, t.profile].map(navLabel).toList();
      final shouty = shown.where((s) => s == s.toUpperCase() && s != s.toLowerCase()).toList();
      expect(shouty, isEmpty, reason: '$code: $shown');
    }
  });
}
