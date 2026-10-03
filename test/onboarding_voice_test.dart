import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/choice.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

/// GM-100: the welcome page speaks the Kaizan philosophy and the step label and bar always agree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.startCountdown = false;
  });
  tearDown(() {
    setAppLanguage('en');
    fit.persistNow();
  });

  void phone(WidgetTester tester, {Size size = const Size(960, 1600), double scale = 1}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
  }

  StepProgress bar(WidgetTester tester) => tester.widget<StepProgress>(find.byType(StepProgress));

  String? labelOnScreen() {
    for (final n in [for (var i = 1; i <= 6; i++) for (var j = 1; j <= 6; j++) (i, j)]) {
      if (find.text(t.onbStep(n.$1, n.$2).toUpperCase()).evaluate().isNotEmpty) return '${n.$1}/${n.$2}';
    }
    return null;
  }

  testWidgets('the bar has one segment per question, none filled on the welcome page, and always matches the label',
      (tester) async {
    phone(tester);
    fit.onboarded = false;
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    expect(bar(tester).index, -1, reason: 'welcome is not a numbered step');
    expect(labelOnScreen(), isNull);
    final total = bar(tester).count;
    expect(total, greaterThanOrEqualTo(3));

    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(labelOnScreen(), '1/$total');
    expect(bar(tester).index, 0);

    await tester.tap(find.text(t.goalLeanTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    expect(labelOnScreen(), '2/${bar(tester).count}');
    expect(bar(tester).index, 1);
  });

  testWidgets('re-personalizing from Home has no welcome page, and its bar and label still agree', (tester) async {
    phone(tester);
    fit.onboarded = true;
    fit.route = 'personalize';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    expect(labelOnScreen(), '1/${bar(tester).count}');
    expect(bar(tester).index, 0);
  });

  testWidgets('the welcome page states the philosophy and still fits a 320dp phone at 200% text', (tester) async {
    phone(tester, size: const Size(960, 1600), scale: 2);
    fit.onboarded = false;
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    expect(find.text(t.welcomeBlurb), findsOneWidget);
    expect(find.text(t.tagline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the philosophy line is translated in every language and names the app', () {
    final english = (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map)['welcomeBlurb'] as String;
    for (final code in appLanguages) {
      setAppLanguage(code);
      expect(t.welcomeBlurb.trim(), isNotEmpty, reason: code);
      if (code != 'en') expect(t.welcomeBlurb, isNot(english), reason: code);
    }
    expect(english, contains('Kaizan'));
    expect(english.toLowerCase(), isNot(contains('no internet')), reason: 'privacy lives in the three promises below');
  });
}
