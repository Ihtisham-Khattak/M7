import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/theme/tokens.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'support/fonts.dart';

List<File> _sources() => [
      for (final dir in ['lib/screens', 'lib/widgets', 'lib/app'])
        ...Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  test('the radius scale is small-to-medium and increases step by step', () {
    final steps = [
      GymRadius.xs,
      GymRadius.sm,
      GymRadius.md,
      GymRadius.lg,
      GymRadius.xl,
      GymRadius.xxl,
    ];
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], greaterThan(steps[i - 1]));
    }
    expect(GymRadius.xxl, lessThanOrEqualTo(24), reason: 'no giant rounded cards');
    expect(GymRadius.lg, lessThanOrEqualTo(16), reason: 'standard card radius');
  });

  test('screens and widgets use no radius above medium except documented pills', () {
    final offenders = <String>[];
    final literal = RegExp(r'BorderRadius\.circular\((\d+(?:\.\d+)?)\)');
    for (final f in _sources()) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in literal.allMatches(lines[i])) {
          final r = double.parse(m.group(1)!);
          if (r > 12 && r != GymRadius.pill) offenders.add('${f.path}:${i + 1} radius $r');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'use GymRadius tokens; pills (100) are for tags, switches and bars only');
  });

  testWidgets('buttons are structured rectangles, not pills', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Column(children: [
          PrimaryButton(label: 'Start', onTap: () {}),
          GhostButton(label: 'Share', icon: PhosphorIconsRegular.shareNetwork, onTap: () {}),
        ]),
      ),
    ));
    final radii = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.borderRadius)
        .whereType<BorderRadius>()
        .map((r) => r.topLeft.x)
        .toList();
    expect(radii, isNotEmpty);
    expect(radii, everyElement(lessThanOrEqualTo(GymRadius.lg)));
  });

  test('shadows follow the theme: lighter in the light theme, never pure black', () {
    final dark = GymElevation.overlay(GymColors.dark).single;
    final light = GymElevation.overlay(GymColors.light).single;
    expect(light.color.a, lessThan(dark.color.a));
    expect(GymElevation.raised(GymColors.light).single.color.a, lessThan(GymElevation.raised(GymColors.dark).single.color.a));
    expect(GymElevation.none, isEmpty);
  });

  test('blur is limited to the places that have a recorded reason', () {
    const allowed = {
      'lib/app/app_shell.dart',
      'lib/widgets/app_background.dart',
      'lib/widgets/glass.dart',
      'lib/widgets/liquid_notch.dart',
      'lib/widgets/start_countdown.dart',
      'lib/screens/moments_screen.dart',
    };
    final using = <String>{
      for (final f in _sources())
        if (f.readAsStringSync().contains(RegExp(r'BackdropFilter\(|ImageFilter\.blur'))) f.path,
    };
    expect(using.difference(allowed), isEmpty,
        reason: 'new blur needs a reason in DEVELOPMENT_GUIDELINES (shape language) and an entry here');
  });
}
