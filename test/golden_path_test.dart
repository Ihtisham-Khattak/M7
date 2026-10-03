import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'support/fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bench = kExercises.firstWhere((e) => e.equipment == 'Barbell' && e.primary == 'chest');

  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.setUnits('kg');
    fit.startCountdown = false;
    fit.keepScreenOn = false;
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> settle(WidgetTester tester, [int ms = 600]) async {
    await tester.pump(Duration(milliseconds: ms));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  }

  testWidgets('first launch: skipping onboarding lands on Home', (tester) async {
    await phone(tester);
    fit.onboarded = false;
    await tester.pumpWidget(const GymManeApp());
    await settle(tester);

    expect(find.byType(PrimaryButton), findsOneWidget);
    await tester.tap(find.text(t.skip2));
    await settle(tester);

    expect(fit.onboarded, true);
    expect(fit.route, 'home');
    expect(find.text(t.today.toUpperCase()), findsWidgets);
    fit.persistNow();
  });

  testWidgets('a planned routine: start from the nav button, tick every set, finish, find it in progress',
      (tester) async {
    await phone(tester);
    final semantics = tester.ensureSemantics();
    fit.onboarded = true;
    final routine = fit.createRoutine('Push day');
    fit.toggleRoutineExercise(routine, bench.id);
    fit.assignRoutineToDay(DateTime.now().weekday, routine);
    fit.route = 'home';
    await tester.pumpWidget(const GymManeApp());
    await settle(tester);

    await tester.tap(find.byIcon(PhosphorIconsFill.play).first);
    await settle(tester);
    expect(fit.route, 'session');
    expect(fit.isSessionActive, true);
    expect(fit.session!.exercises.single.id, bench.id);

    final sets = fit.session!.exercises.single.sets.length;
    expect(sets, greaterThan(0));
    for (var i = 1; i <= sets; i++) {
      await tester.tap(find.bySemanticsLabel(t.markSet(i)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(fit.session!.exercises.single.sets.every((s) => s.done), true);

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(fit.isSessionComplete, true, reason: 'finishing the last set closes the workout');
    expect(fit.sessions.length, 1);
    expect(fit.sessions.single.exercises.single.sets.length, sets);

    await tester.tap(find.widgetWithText(PrimaryButton, t.done.toUpperCase()).evaluate().isEmpty
        ? find.byType(PrimaryButton).last
        : find.widgetWithText(PrimaryButton, t.done.toUpperCase()));
    await settle(tester);
    expect(fit.session, isNull);
    expect(fit.route, 'home');

    fit.goProgress();
    await settle(tester);
    await tester.ensureVisible(find.text(t.progressStrength));
    await tester.pump();
    await tester.tap(find.text(t.progressStrength));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(exerciseName(bench)), findsWidgets, reason: 'the logged lift shows up under records');
    fit.persistNow();
    semantics.dispose();
  });

  testWidgets('body-map training: pick a muscle, review the picks, start the session', (tester) async {
    await phone(tester);
    fit.onboarded = true;
    fit.route = 'home';
    await tester.pumpWidget(const GymManeApp());
    await settle(tester);

    fit.startWorkout();
    await settle(tester);
    expect(fit.route, 'train');
    expect(fit.trainStep, 'select');

    fit.toggleMuscle('chest');
    await settle(tester);
    await tester.tap(find.byType(PrimaryButton).last);
    await settle(tester);
    expect(fit.trainStep, 'review');
    expect(fit.sessionPicks, isNotEmpty);

    await tester.tap(find.byType(PrimaryButton).last);
    await settle(tester);
    expect(fit.route, 'session');
    expect(fit.isSessionActive, true);
    expect(fit.session!.exercises.map((e) => e.primary), contains('chest'));
    fit.saveAndExit();
    await settle(tester);
  });
}
