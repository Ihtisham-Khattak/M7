import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/disclosure.dart';
import 'package:gymmane/widgets/metric_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

/// GM-18: Progress opens on three headline numbers; everything else is one tap away.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final bench = kExercises.firstWhere((e) => e.primary == 'chest' && e.equipment == 'Barbell');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.onboarded = true;
    fit.startCountdown = false;
    // the Store keeps its preferences instance between tests: forget which groups were opened
    for (final id in ['strength', 'body', 'muscles', 'all_time']) {
      Store.instance.setNote('disclosure_progress_$id', '');
    }
  });
  tearDown(() => fit.persistNow());

  void seed() {
    final now = DateTime.now();
    for (var i = 1; i <= 9; i++) {
      fit.sessions.add(LoggedSession(now.subtract(Duration(days: i * 2)), 3000, [
        LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 60.0 + i), LoggedSet(6, 65.0 + i)]),
      ]));
    }
    fit.addBodyweight(78.5);
  }

  Future<void> open(WidgetTester tester, {Size dp = const Size(360, 640)}) async {
    tester.view.physicalSize = dp * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    fit.route = 'progress';
    await tester.pumpWidget(const GymManeApp());
    await tester.pump(const Duration(milliseconds: 900));
    expect(tester.takeException(), isNull);
  }

  Finder group(String title) => find.widgetWithText(Disclosure, title);

  testWidgets('the first view has exactly three headline numbers, fully visible on a 360x640 phone', (tester) async {
    seed();
    await open(tester);
    expect(find.byType(MetricCard), findsNWidgets(3));
    for (final card in find.byType(MetricCard).evaluate()) {
      final r = tester.getRect(find.byWidget(card.widget));
      expect(r.top, greaterThan(0));
      expect(r.bottom, lessThan(640 - 80), reason: 'above the navigation bar');
    }
  });

  testWidgets('the groups start closed and open with one tap, revealing everything that used to be on the page',
      (tester) async {
    seed();
    await open(tester, dp: const Size(360, 1400));
    for (final title in [t.progressStrength, t.progressBody, t.progressMuscles, t.progressAllTime]) {
      expect(group(title), findsOneWidget, reason: title);
    }
    expect(find.text(t.personalRecords.toUpperCase()), findsNothing, reason: 'records are inside a closed group');

    await tester.tap(find.text(t.progressStrength));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.personalRecords.toUpperCase()), findsOneWidget);

    await tester.tap(find.text(t.progressBody));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.weightLabel.toUpperCase()), findsOneWidget);

    await tester.tap(find.text(t.progressMuscles));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.muscleMap.toUpperCase()), findsWidgets);

    await tester.tap(find.text(t.progressAllTime));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.allTimeSessions.toUpperCase()), findsOneWidget);
  });

  testWidgets('a group announces whether it is open and remembers the choice', (tester) async {
    final handle = tester.ensureSemantics();
    seed();
    await open(tester, dp: const Size(360, 1000));
    expect(tester.getSemantics(find.text(t.progressStrength)), isSemantics(isButton: true, hasExpandedState: true, isExpanded: false));
    await tester.tap(find.text(t.progressStrength));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSemantics(find.text(t.progressStrength)), isSemantics(isButton: true, hasExpandedState: true, isExpanded: true));
    expect(Store.instance.note('disclosure_progress_strength'), '1');

    await open(tester, dp: const Size(360, 1000));
    await tester.pumpWidget(const SizedBox());
    await open(tester, dp: const Size(360, 1000));
    expect(find.text(t.personalRecords.toUpperCase()), findsOneWidget, reason: 'still open after reopening');
    handle.dispose();
  });

  testWidgets('with no data the same groups are there, each explaining what will appear', (tester) async {
    await open(tester, dp: const Size(360, 1200));
    for (final title in [t.progressStrength, t.progressBody, t.progressMuscles]) {
      expect(group(title), findsOneWidget, reason: title);
    }
    await tester.tap(find.text(t.progressStrength));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.progressRecordsEmpty), findsOneWidget);
    await tester.tap(find.text(t.progressBody));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.progressBodyEmpty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
