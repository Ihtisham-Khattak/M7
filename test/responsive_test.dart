import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

/// GM-21: the core screens lay out without overflow on small and large phones, a tablet and in
/// landscape, with long translated names, large numbers, big text and the keyboard open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  const sizes = <String, Size>{
    'small 320x568': Size(320, 568),
    'phone 360x640': Size(360, 640),
    'large phone 411x891': Size(411, 891),
    'tablet 600x960': Size(600, 960),
    'tablet wide 900x1200': Size(900, 1200),
    'landscape 640x360': Size(640, 360),
    'landscape large 891x411': Size(891, 411),
  };

  final bench = kExercises.firstWhere((e) => e.primary == 'chest' && e.equipment == 'Barbell');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.startCountdown = false;
    fit.keepScreenOn = false;
    fit.onboarded = true;
    final now = DateTime.now();
    for (var i = 1; i <= 30; i++) {
      fit.sessions.add(LoggedSession(now.subtract(Duration(days: i)), 3000, [
        LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(10, 140), LoggedSet(10, 140), LoggedSet(10, 140)]),
      ]));
    }
  });
  tearDown(() {
    setAppLanguage('en');
    fit.persistNow();
  });

  void showWhere() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final at = RegExp(r'file:///[^\s]*lib/[^\s]*').firstMatch(details.toString())?.group(0);
      debugPrint('OVERFLOW ${details.exceptionAsString().split("\n").first} at ${at ?? "?"}');
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  void screen(WidgetTester tester, Size dp, {double scale = 1, double keyboard = 0}) {
    showWhere();
    tester.view.physicalSize = dp * 2;
    tester.view.devicePixelRatio = 2;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard * 2);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
  }

  Future<void> open(WidgetTester tester, String route) async {
    fit.route = route;
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 900));
  }

  void routine() {
    final id = fit.createRoutine('Push day');
    fit.toggleRoutineExercise(id, bench.id);
    fit.assignRoutineToDay(DateTime.now().weekday, id);
  }

  for (final size in sizes.entries) {
    group(size.key, () {
      for (final scale in [1.0, 1.3]) {
        testWidgets('home, exercises, train and onboarding at ${scale}x text', (tester) async {
          screen(tester, size.value, scale: scale);
          routine();
          for (final route in ['home', 'exercises', 'progress', 'settings', 'preferences']) {
            await open(tester, route);
            expect(tester.takeException(), isNull, reason: route);
          }
          fit.route = 'home';
          await tester.pumpWidget(const GymManeApp());
          await tester.pump(const Duration(milliseconds: 600));
          fit.startWorkout();
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull, reason: 'train');
          fit.toggleMuscle('chest');
          fit.trainContinue();
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull, reason: 'train review');
          fit.closeTrain();
          await tester.pump(const Duration(milliseconds: 400));
        });

        testWidgets('a live session at ${scale}x text', (tester) async {
          screen(tester, size.value, scale: scale);
          routine();
          await open(tester, 'home');
          fit.startRoutine(fit.todayRoutine!);
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull, reason: 'session');
          fit.setSessionWeight(0, 0, 1000.5);
          fit.setSessionReps(0, 0, 100);
          fit.toggleSet(0, 0);
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull, reason: 'session with a rest timer and large numbers');
          fit.saveAndExit();
          fit.skipRest();
        });
      }

      testWidgets('onboarding with the keyboard open', (tester) async {
        screen(tester, size.value, keyboard: size.value.height * 0.4);
        fit.onboarded = false;
        await open(tester, 'home');
        expect(tester.takeException(), isNull, reason: 'welcome');
        await tester.tap(find.byType(PrimaryButton).last, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull, reason: 'first question');
      });
    });
  }

  for (final lang in ['es', 'de', 'ru']) {
    testWidgets('home, exercises and a session in $lang on the smallest phone', (tester) async {
      setAppLanguage(lang);
      screen(tester, const Size(320, 568), scale: 1.15);
      routine();
      for (final route in ['home', 'exercises', 'progress']) {
        await open(tester, route);
        expect(tester.takeException(), isNull, reason: '$lang $route');
      }
      await open(tester, 'home');
      fit.startRoutine(fit.todayRoutine!);
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: '$lang session');
      fit.saveAndExit();
    });
  }

  testWidgets('on a tablet the app is a centred column no wider than 640dp', (tester) async {
    screen(tester, const Size(900, 1200));
    routine();
    await open(tester, 'home');
    final column = tester.getRect(find.byType(ReadableWidth).first);
    expect(column.width, 900);
    final inner = tester.getSize(find.descendant(of: find.byType(ReadableWidth), matching: find.byType(SizedBox)).first);
    expect(inner.width, lessThanOrEqualTo(640));
    final start = tester.getRect(find.byType(PrimaryButton).first);
    expect(start.center.dx, closeTo(450, 2), reason: 'content is centred');
    expect(start.width, lessThanOrEqualTo(640));
  });

  testWidgets('on a phone the width limit changes nothing', (tester) async {
    screen(tester, const Size(411, 891));
    await open(tester, 'home');
    expect(tester.getRect(find.byType(PrimaryButton).first).width, greaterThan(300));
  });
}
