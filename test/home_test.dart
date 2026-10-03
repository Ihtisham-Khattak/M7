import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/screens/home_screen.dart';
import 'package:gymmane/services/home_focus.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:gymmane/widgets/workout_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final bench = kExercises.firstWhere((e) => e.primary == 'chest' && e.equipment == 'Barbell');
  final curl = kExercises.firstWhere((e) => e.primary == 'biceps');
  final fly = kExercises.firstWhere((e) => e.primary == 'chest' && e.id != bench.id);

  group('focus rules', () {
    test('the estimate adds work and rest per set and rounds to 5 minutes', () {
      expect(estimateWorkoutMinutes([(sets: 3, restSeconds: 90), (sets: 3, restSeconds: 90)]), 15);
      expect(estimateWorkoutMinutes([for (var i = 0; i < 5; i++) (sets: 4, restSeconds: 90)]), 45);
      expect(estimateWorkoutMinutes([(sets: 1, restSeconds: 0)]), 5, reason: 'never below five');
      expect(estimateWorkoutMinutes([]), 0);
      expect(estimateWorkoutMinutes([(sets: 0, restSeconds: 90)]), 0);
      expect(estimateWorkoutMinutes([(sets: 3, restSeconds: -5)]), 5, reason: 'bad rest counts as none');
    });

    test('a longer rest makes a longer workout', () {
      int mins(int rest) => estimateWorkoutMinutes([for (var i = 0; i < 5; i++) (sets: 4, restSeconds: rest)]);
      expect(mins(120), greaterThan(mins(60)));
    });

    test('the title muscles are the most trained two, in order of first appearance on ties', () {
      expect(leadingMuscles(['chest', 'chest', 'biceps', 'back']), ['chest', 'biceps']);
      expect(leadingMuscles(['back', 'chest', 'chest']), ['chest', 'back']);
      expect(leadingMuscles(['biceps', 'chest']), ['biceps', 'chest']);
      expect(leadingMuscles(['', 'quads']), ['quads']);
      expect(leadingMuscles([]), isEmpty);
      expect(leadingMuscles(['a', 'b', 'c'], max: 3), ['a', 'b', 'c']);
    });
  });

  group('the Home screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      setAppLanguage('en');
      fit.resetAllData();
      fit.onboarded = true;
      fit.startCountdown = false;
      fit.keepScreenOn = false;
      fit.route = 'home';
    });

    void phone(WidgetTester tester, Size dp) {
      tester.view.physicalSize = dp * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(const GymManeApp());
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    }

    String routineToday() {
      final id = fit.createRoutine('Push day');
      for (final e in [bench, fly, curl]) {
        fit.toggleRoutineExercise(id, e.id);
      }
      fit.assignRoutineToDay(DateTime.now().weekday, id);
      return id;
    }

    testWidgets('Start is visible without scrolling on a 360x640 phone', (tester) async {
      routineToday();
      phone(tester, const Size(360, 640));
      await open(tester);

      final start = find.descendant(of: find.byType(WorkoutCard), matching: find.byType(PrimaryButton));
      expect(start, findsOneWidget);
      final box = tester.getRect(start);
      final nav = tester.getTopLeft(find.byType(GymManeApp)).dy;
      expect(box.bottom, lessThan(640 - 90), reason: 'above the navigation bar, $nav');
      expect(box.top, greaterThan(0));
      fit.persistNow();
    });

    testWidgets('Start is visible with no routine too, and with the long titles of a translated UI', (tester) async {
      phone(tester, const Size(360, 640));
      await open(tester);
      expect(find.widgetWithText(PrimaryButton, t.startWorkout.toUpperCase()).evaluate().length +
          find.byType(PrimaryButton).evaluate().length, greaterThan(0));
      expect(tester.getRect(find.byType(PrimaryButton).first).bottom, lessThan(640 - 90));
    });

    testWidgets('the focus card names the muscles, the exercise count and an estimated time', (tester) async {
      routineToday();
      phone(tester, const Size(390, 800));
      await open(tester);

      expect(find.text('Push day'), findsOneWidget);
      expect(find.text('${t.muscle('chest')} + ${t.muscle('biceps')}'), findsOneWidget);
      expect(find.textContaining(t.exerciseCount(3)), findsOneWidget);
      expect(find.textContaining('~'), findsWidgets);
      expect(find.text(sentenceCase(t.plannedRoutine)), findsOneWidget);
      fit.persistNow();
    });

    testWidgets('after training today the card says so', (tester) async {
      routineToday();
      fit.sessions.add(LoggedSession(DateTime.now(), 600, [
        LoggedExercise(bench.id, 'Bench', 'chest', [LoggedSet(5, 60)]),
      ]));
      phone(tester, const Size(390, 800));
      await open(tester);
      expect(find.text(sentenceCase(t.done)), findsOneWidget);
      fit.persistNow();
    });

    testWidgets('by default Home has at most four sections and no heat-map', (tester) async {
      routineToday();
      phone(tester, const Size(390, 1200));
      await open(tester);

      expect(find.byType(WorkoutCard), findsOneWidget);
      expect(find.text(t.thisWeek.toUpperCase()), findsOneWidget);
      expect(find.text(t.routines.substring(0, 1) + t.routines.substring(1).toLowerCase()), findsOneWidget);
      expect(find.text(t.recommended), findsNothing, reason: 'recommended is opt-in');
      expect(find.text(t.activityLabel), findsNothing, reason: 'the heat-map lives on Progress');
      fit.persistNow();
    });

    testWidgets('turning recommended on brings its section back', (tester) async {
      fit.toggleRecommended();
      phone(tester, const Size(390, 1200));
      await open(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(fit.showRecommended, isTrue);
      fit.persistNow();
    });

    testWidgets('what left Home is one tap away: Routines, Tools, Journal and Progress', (tester) async {
      phone(tester, const Size(390, 1200));
      await open(tester);

      await tester.tap(find.text('Routines'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fit.route, 'routines');
      fit.goHome();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Tools'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fit.route, 'tools');
      fit.goHome();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Journal'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fit.route, 'notes');
      fit.goHome();
      await tester.pump(const Duration(milliseconds: 400));

      fit.goProgress();
      await tester.pump(const Duration(milliseconds: 400));
      expect(fit.route, 'progress');
      fit.persistNow();
    });

    testWidgets('check-ins and Start still work from the new layout', (tester) async {
      final id = routineToday();
      phone(tester, const Size(390, 900));
      await open(tester);

      await tester.tap(find.byType(PrimaryButton).first);
      await tester.pump(const Duration(milliseconds: 600));
      expect(fit.route, 'session');
      expect(fit.isSessionActive, true);
      expect(fit.session!.exercises.length, 3);
      expect(id, isNotEmpty);
      fit.saveAndExit();
      fit.persistNow();
    });

    testWidgets('every tappable on Home is at least 48dp', (tester) async {
      routineToday();
      phone(tester, const Size(390, 900));
      await open(tester);
      for (final label in ['Routines', 'Tools', 'Journal']) {
        final card = find.ancestor(of: find.text(label), matching: find.byType(Pressable)).first;
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48), reason: label);
      }
      expect(tester.getSize(find.byType(PrimaryButton).first).height, greaterThanOrEqualTo(48));
      fit.persistNow();
    });
  });
}
