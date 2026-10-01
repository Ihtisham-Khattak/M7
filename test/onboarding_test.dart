import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/catalog/exercise_meta.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/models/training_profile.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/onboarding_flow.dart';
import 'package:gymmane/services/schema.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/choice.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.setUnits('kg');
  });

  tearDown(() => fit.persistNow());

  group('which questions are asked', () {
    List<OnboardingStep> steps(TrainingGoal? g, Experience? e, {bool welcome = true}) =>
        visibleSteps(OnboardingAnswers(goal: g, experience: e), welcome: welcome);

    test('a beginner who wants strength is not asked which muscles to favour', () {
      expect(steps(TrainingGoal.muscleStrength, Experience.beginner), isNot(contains(OnboardingStep.focus)));
      expect(steps(TrainingGoal.muscleStrength, null), isNot(contains(OnboardingStep.focus)));
    });

    test('lean aesthetic and experienced lifters are asked', () {
      expect(steps(TrainingGoal.leanAesthetic, Experience.beginner), contains(OnboardingStep.focus));
      expect(steps(TrainingGoal.muscleStrength, Experience.advanced), contains(OnboardingStep.focus));
      expect(steps(TrainingGoal.muscleStrength, Experience.intermediate), contains(OnboardingStep.focus));
    });

    test('nobody sees more than six steps, and the order never changes', () {
      for (final goal in [null, ...TrainingGoal.values]) {
        for (final level in [null, ...Experience.values]) {
          final list = steps(goal, level);
          expect(list.length, lessThanOrEqualTo(6), reason: '$goal $level');
          expect(list.first, OnboardingStep.welcome);
          expect(list.last, OnboardingStep.about);
          final indexes = list.map((s) => s.index).toList();
          expect(indexes, orderedEquals([...indexes]..sort()));
        }
      }
    });

    test('re-personalizing skips the welcome page', () {
      expect(steps(TrainingGoal.leanAesthetic, Experience.beginner, welcome: false).first, OnboardingStep.goal);
    });

    test('home and outdoors offer no machines, barbells or cables that do not fit', () {
      expect(gearChoices('home'), isNot(contains('Machine')));
      expect(gearChoices('home'), isNot(contains('Cable')));
      expect(gearChoices('outdoors'), everyElement(anyOf('Band', 'Weighted', 'Rings')));
      expect(gearChoices('gym'), contains('Machine'));
      expect(gearChoices('gym'), isNot(contains('Bodyweight')));
    });
  });

  group('training profile', () {
    test('answers are kept, rounded to the offered choices and survive a restart', () {
      fit.setTrainingGoal(TrainingGoal.leanAesthetic);
      fit.setTrainingExperience(Experience.intermediate);
      fit.setSessionMinutes(60);
      fit.setTrainingSetting('home');
      fit.toggleFocusGroup(MuscleGroup.chest.name);
      fit.toggleFocusGroup(MuscleGroup.back.name);
      fit.persistNow();

      fit.training = TrainingProfile();
      fit.loadFromStore();

      expect(fit.training.goal, TrainingGoal.leanAesthetic);
      expect(fit.training.experience, Experience.intermediate);
      expect(fit.training.sessionMinutes, 60);
      expect(fit.training.setting, 'home');
      expect(fit.training.focus, ['chest', 'back']);
    });

    test('the number of days is the weekly goal, not a second copy', () {
      fit.setTrainingDays(5);
      expect(fit.profile.weeklyGoal, 5);
      fit.updateProfile(weeklyGoalDelta: -2);
      expect(fit.trainingDays, 3);
    });

    test('at most three focus groups can be picked and one can be dropped again', () {
      for (final g in [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.legs, MuscleGroup.core]) {
        fit.toggleFocusGroup(g.name);
      }
      expect(fit.training.focus.length, kMaxFocusGroups);
      expect(fit.training.focus, isNot(contains('core')));
      fit.toggleFocusGroup('chest');
      fit.toggleFocusGroup('core');
      expect(fit.training.focus, ['back', 'legs', 'core']);
    });

    test('damaged or unknown stored values fall back to safe defaults', () {
      final p = TrainingProfile.fromJson({
        'g': 'bodybuilder',
        'x': 7,
        'm': 52,
        's': 4,
        'f': ['chest', 3, 'back', 'legs', 'core'],
      });
      expect(p.goal, isNull);
      expect(p.experience, isNull);
      expect(p.sessionMinutes, 45);
      expect(p.setting, '');
      expect(p.focus, ['chest', 'back', 'legs']);
      expect(p.isSet, false);
      expect(TrainingProfile.fromJson({'m': 200}).sessionMinutes, 75);
    });

    test('it is part of the backup and is cleared by reset', () {
      fit.setTrainingGoal(TrainingGoal.muscleStrength);
      fit.setTrainingExperience(Experience.advanced);
      final backup = jsonDecode(jsonEncode(fit.toJson())) as Map<String, dynamic>;
      expect(backup['training'], isA<Map>());

      fit.resetAllData();
      expect(fit.training.isSet, false);
      expect(fit.toJson().containsKey('training'), false);

      expect(fit.applyBackup(backup), true);
      expect(fit.training.goal, TrainingGoal.muscleStrength);
      expect(fit.training.experience, Experience.advanced);
    });

    test('a training key of the wrong type is refused, not half applied', () {
      fit.updateProfile(name: 'Kept');
      expect(fit.applyBackup({'training': 'oops', 'profile': {}}), false);
      expect(fit.profile.name, 'Kept');
    });
  });

  group('people who already use the app', () {
    test('old data loads untouched and gets an offer instead of a questionnaire', () async {
      final doc = {
        'onboarded': true,
        'profile': {'name': 'Sam', 'goal': 3},
        'routines': [
          {'id': 'r1', 'n': 'Push', 'ex': [kExercises.first.id]},
        ],
        'weeklyPlan': {'1': 'r1'},
      };
      await Store.instance.save(doc);
      fit.loadFromStore();

      expect(fit.onboarded, true);
      expect(fit.routines.single.name, 'Push');
      expect(fit.weeklyPlan, {1: 'r1'});
      expect(fit.profile.weeklyGoal, 3);
      expect(fit.training.isSet, false);
      expect(fit.canOfferPersonalize, true);
      expect(kSchemaVersion, 1);
    });

    test('dismissing the offer is remembered and answering it removes it', () async {
      fit.onboarded = true;
      expect(fit.canOfferPersonalize, true);

      fit.dismissPersonalize();
      fit.persistNow();
      fit.personalizeDismissed = false;
      fit.loadFromStore();
      expect(fit.personalizeDismissed, true);
      expect(fit.canOfferPersonalize, false);

      fit.personalizeDismissed = false;
      fit.setTrainingGoal(TrainingGoal.leanAesthetic);
      expect(fit.canOfferPersonalize, false);
    });
  });

  group('taxonomy', () {
    test('every muscle belongs to exactly one display group', () {
      final seen = <String>[];
      for (final muscles in kGroupMuscles.values) {
        seen.addAll(muscles);
      }
      expect(seen.toSet().length, seen.length, reason: 'a muscle is listed twice');
      expect(seen.toSet(), kMuscles.map((m) => m.id).toSet());
      for (final g in MuscleGroup.values) {
        expect(kGroupMuscles[g], isNotEmpty);
      }
    });

    test('exercises resolve to a group through their primary muscle', () {
      expect(groupOfMuscle('quads'), MuscleGroup.legs);
      expect(groupOfMuscle('trapezius'), MuscleGroup.back);
      expect(groupOfMuscle('obliques'), MuscleGroup.core);
      expect(groupOfMuscle('nope'), isNull);
      for (final e in kExercises) {
        expect(groupOfMuscle(e.primary), isNotNull, reason: e.name);
      }
    });

    test('every group has a translated name', () {
      for (final g in MuscleGroup.values) {
        expect(t.groupLabel(g).trim(), isNotEmpty);
      }
    });

    test('the exercise metadata table only names exercises that exist', () {
      final ids = kExercises.map((e) => e.id).toSet();
      expect(kExerciseMeta.keys.where((id) => !ids.contains(id)), isEmpty);
      expect(metaOf('a-custom-exercise'), isNull);
    });

    test('group names can be read back from what is stored', () {
      expect(muscleGroupNamed('glutes'), MuscleGroup.glutes);
      expect(muscleGroupNamed('x'), isNull);
    });
  });

  group('the screens', () {
    Future<void> phone(WidgetTester tester, {Size size = const Size(1080, 1920)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      final f = find.text(text);
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Future<void> tapNext(WidgetTester tester) async {
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('a new user answers the questions on a small phone and lands on Home', (tester) async {
      await phone(tester);
      fit.onboarded = false;
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      await tester.pumpAndSettle();
      expect(find.byType(StepProgress), findsOneWidget);

      await tapNext(tester);
      expect(find.text(t.onbGoalQTitle), findsOneWidget);

      await tapNext(tester);
      expect(find.text(t.onbGoalQTitle), findsOneWidget, reason: 'cannot move on without a goal');
      expect(fit.training.goal, isNull);

      await tapText(tester, t.goalStrengthTitle);
      expect(fit.training.goal, TrainingGoal.muscleStrength);
      await tapNext(tester);

      expect(find.text(t.onbTrainTitle), findsOneWidget);
      await tapNext(tester);
      expect(find.text(t.onbTrainTitle), findsOneWidget, reason: 'experience is required');

      for (final chip in tester.widgetList<SelectChip>(find.byType(SelectChip))) {
        final size = tester.getSize(find.byWidget(chip));
        expect(size.width, lessThan(160), reason: 'chips must hug their label, not fill the row');
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await tapText(tester, t.expBeginner);
      await tapText(tester, '3');
      await tapText(tester, t.minutesOption(60));
      expect(fit.training.experience, Experience.beginner);
      expect(fit.trainingDays, 3);
      expect(fit.training.sessionMinutes, 60);
      await tapNext(tester);

      expect(find.text(t.onbPlaceTitle), findsOneWidget);
      await tapText(tester, t.placeHome);
      expect(find.text(t.equipment('Machine')), findsNothing, reason: 'no gym machines for a home setup');
      expect(find.text(t.equipment('Dumbbell')), findsOneWidget);
      await tapNext(tester);

      expect(find.text(t.onbFocusTitle), findsNothing, reason: 'a beginner going for strength skips it');
      expect(find.text(t.onbAboutTitle), findsOneWidget);
      await tapNext(tester);

      expect(fit.onboarded, true);
      expect(fit.training.setting, 'home');
      expect(fit.places.single.name, t.placeHome);
      expect(fit.activePlace?.name, t.placeHome);
    });

    testWidgets('choosing lean aesthetic adds the muscle focus step', (tester) async {
      await phone(tester);
      fit.onboarded = false;
      await tester.pumpWidget(const GymManeApp());
      await tester.pumpAndSettle();
      await tapNext(tester);
      await tapText(tester, t.goalLeanTitle);
      await tapNext(tester);
      await tapText(tester, t.expAdvanced);
      await tapNext(tester);
      await tapNext(tester);

      expect(find.text(t.onbFocusTitle), findsOneWidget);
      await tapText(tester, t.groupLabel(MuscleGroup.chest));
      await tapText(tester, t.groupLabel(MuscleGroup.back));
      await tapText(tester, t.groupLabel(MuscleGroup.legs));
      await tapText(tester, t.groupLabel(MuscleGroup.core));
      expect(fit.training.focus, ['chest', 'back', 'legs']);
    });

    testWidgets('going back keeps the answers and skip finishes without any', (tester) async {
      await phone(tester);
      fit.onboarded = false;
      await tester.pumpWidget(const GymManeApp());
      await tester.pumpAndSettle();
      await tapNext(tester);
      await tapText(tester, t.goalLeanTitle);
      await tapNext(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text(t.onbGoalQTitle), findsOneWidget);
      expect(fit.training.goal, TrainingGoal.leanAesthetic);

      await tapText(tester, t.skip2);
      expect(fit.onboarded, true);
      expect(fit.canOfferPersonalize, false, reason: 'the goal was answered before skipping');
    });

    testWidgets('an existing user sees the offer on Home and can open or dismiss it', (tester) async {
      await phone(tester);
      fit.onboarded = true;
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      await tester.pumpAndSettle();

      expect(find.text(t.personalizeTitle), findsOneWidget);
      await tapText(tester, t.personalizeTitle);
      expect(fit.route, 'personalize');
      expect(find.text(t.onbGoalQTitle), findsOneWidget);
      expect(find.text(t.onbGoalQTitle), findsOneWidget);

      fit.handleBack();
      await tester.pumpAndSettle();
      expect(fit.route, 'home');

      await tester.tap(find.bySemanticsLabel(t.notNow));
      await tester.pumpAndSettle();
      expect(find.text(t.personalizeTitle), findsNothing);
      expect(fit.personalizeDismissed, true);
    });

    testWidgets('the whole flow fits a 320dp phone with large text', (tester) async {
      await phone(tester, size: const Size(960, 1600));
      tester.platformDispatcher.textScaleFactorTestValue = 1.15;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      fit.onboarded = false;
      await tester.pumpWidget(const GymManeApp());
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tapNext(tester);
        if (i == 0) {
          await tapText(tester, t.goalLeanTitle);
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
      await tapText(tester, t.expIntermediate);
      expect(tester.takeException(), isNull);
      fit.persistNow();
    });
  });
}
