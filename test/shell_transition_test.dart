import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/app_shell.dart' show navLabel;
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/screens/home_screen.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/motion.dart';
import 'package:gymmane/widgets/award_celebration.dart';
import 'package:gymmane/widgets/screen_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    ProgressReminder.instance.enabled = false;
    setAppLanguage('es');
    fit.onboarded = true;
    fit.session = null;
    fit.sessions.clear();
    fit.awards.clear();
    fit.awardsSeen.clear();
    fit.pendingAwards.clear();
    fit.resetRoute('home');
  });

  Future<void> startTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  }

  bool isShellSwitcher(Widget w) => w is ScreenSwitcher;

  ScreenSwitcher shellSwitcher(WidgetTester tester) =>
      tester.widget<ScreenSwitcher>(find.byWidgetPredicate(isShellSwitcher));

  double homeOpacity(WidgetTester tester) {
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: find.byType(HomeScreen), matching: find.byType(FadeTransition)).first,
    );
    return fade.opacity.value;
  }

  testWidgets('the screen being left is gone before the new one shows up', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();

    fit.goProgress();
    await startTransition(tester);
    await tester.pump(const Duration(milliseconds: 56));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(homeOpacity(tester), 0, reason: 'la pantalla anterior se quedaba de fondo');

    await tester.pump(GymMotion.maxTab);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('switching tabs is a plain crossfade that finishes within 200 ms', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();
    fit.goProgress();
    await startTransition(tester);
    expect(shellSwitcher(tester).duration, GymMotion.tab);
    expect(GymMotion.tab, lessThanOrEqualTo(GymMotion.maxTab));
    expect(find.descendant(of: find.byWidgetPredicate(isShellSwitcher), matching: find.byType(ImageFiltered)), findsNothing,
        reason: 'no blur while switching tabs');
    await tester.pump(GymMotion.maxTab);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('a screen opened by a slower push still leaves at tab speed', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();
    fit.goPlaces();
    await startTransition(tester);
    await tester.pump(GymMotion.maxPush);

    fit.goHome();
    await startTransition(tester);
    await tester.pump(GymMotion.maxTab);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hammering the tabs mid-transition ends on exactly one screen', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      i.isEven ? fit.goProgress() : fit.goHome();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pump(GymMotion.maxPush);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ScreenSwitcher), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening a deeper screen takes no longer than 300 ms', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();

    fit.goPlaces();
    await startTransition(tester);
    expect(shellSwitcher(tester).duration, lessThanOrEqualTo(GymMotion.maxPush));
    await tester.pump(GymMotion.maxPush);
    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final route in ['progress', 'places']) {
    testWidgets('with animations removed, $route replaces home with a short fade and no movement', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(const GymManeApp());
      await tester.pump();

      route == 'progress' ? fit.goProgress() : fit.goPlaces();
      await startTransition(tester);
      expect(shellSwitcher(tester).duration, GymMotion.reducedFade);
      final shell = find.byWidgetPredicate(isShellSwitcher);
      expect(find.descendant(of: shell, matching: find.byType(ImageFiltered)), findsNothing);
      expect(find.ancestor(of: find.byType(HomeScreen), matching: find.byType(FadeTransition)), findsWidgets);
      await tester.pump(GymMotion.reducedFade + const Duration(milliseconds: 20));
      expect(find.byType(HomeScreen), findsNothing);
    });
  }

  testWidgets('a medal waits before taking over the screen', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();

    fit.refreshAwards();
    await tester.pump();
    expect(find.byType(AwardCelebration), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AwardCelebration), findsNothing,
        reason: 'no da tiempo a ver la app antes de la medalla');

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(AwardCelebration), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(AwardCelebration), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    fit.persistNow();
  });

  testWidgets('medals queue up one after another with a pause in between', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();

    fit.sessions.add(LoggedSession(DateTime.now(), 1200, [
      LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [LoggedSet(10, 60)]),
    ]));
    fit.refreshAwards();
    expect(fit.pendingAwards.length, greaterThan(1));

    await tester.pump(const Duration(milliseconds: 4500));
    expect(find.byType(AwardCelebration), findsOneWidget);

    await tester.tap(find.text(t.awardNice));
    await tester.pump();
    expect(find.byType(AwardCelebration), findsNothing);

    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(AwardCelebration), findsNothing,
        reason: 'la segunda medalla salía pegada a la primera');

    await tester.pump(const Duration(milliseconds: 2500));
    expect(find.byType(AwardCelebration), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    fit.persistNow();
  });

  testWidgets('holding a tab lets the pill slide to another one', (tester) async {
    await tester.pumpWidget(const GymManeApp());
    await tester.pump();

    final home = tester.getCenter(find.text(navLabel(t.home)));
    final profile = tester.getCenter(find.text(navLabel(t.profile)));
    final gesture = await tester.startGesture(home);
    await tester.pump(const Duration(milliseconds: 700));
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(home, profile, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(fit.route, 'home');
    await gesture.up();
    await tester.pump();
    expect(fit.route, 'settings');
    await tester.pump(const Duration(seconds: 1));
  });
}
