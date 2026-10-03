import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/entrance.dart';
import 'package:gymmane/widgets/metric_card.dart';
import 'package:gymmane/widgets/progress_ring.dart';
import 'package:gymmane/widgets/routine_folder.dart';
import 'package:gymmane/widgets/workout_card.dart';
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
  });
  tearDown(() => fit.persistNow());

  Routine routine(int exercises, {String name = 'Push day'}) {
    final id = fit.createRoutine(name);
    for (final e in kExercises.take(exercises)) {
      fit.toggleRoutineExercise(id, e.id);
    }
    fit.persistNow();
    return fit.routines.firstWhere((r) => r.id == id);
  }

  Widget host(Widget child, {double width = 360, double scale = 1}) => MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: SizedBox(width: width, child: child))),
        ),
      );

  group('WorkoutSummary', () {
    test('describes an empty routine without inventing a duration', () {
      final s = WorkoutSummary.of(routine(0));
      expect((s.exerciseCount, s.minutes, s.muscles), (0, 0, ''));
      expect(s.meta, t.exerciseCount(0));
    });

    test('names the muscles, the count and an estimated time', () {
      final s = WorkoutSummary.of(routine(6));
      expect(s.exerciseCount, 6);
      expect(s.minutes, greaterThan(0));
      expect(s.minutes % 5, 0);
      expect(s.meta, contains(t.exerciseCount(6)));
      expect(s.meta, contains('~'));
      expect(s.muscles, isNotEmpty);
    });

    test('twenty exercises give a longer workout than six', () {
      int mins(int n) => WorkoutSummary.of(routine(n)).minutes;
      expect(mins(20), greaterThan(mins(6)));
    });

    test('every state has its own wording, and rest has no workout attached', () {
      final r = routine(2);
      final labels = {
        for (final st in WorkoutStatus.values) st: WorkoutSummary.of(r, status: st).statusLabel,
      };
      expect(labels[WorkoutStatus.none], isNull);
      expect(labels.values.whereType<String>().toSet().length, 4);
    });

    test('the spoken line carries title, status, muscles and meta', () {
      final r = routine(3);
      final s = WorkoutSummary.of(r, status: WorkoutStatus.done);
      expect(s.spoken, allOf(contains('Push day'), contains(s.statusLabel!), contains(s.meta)));
    });
  });

  group('WorkoutTile', () {
    testWidgets('survives a very long name and large text, and speaks one summary', (tester) async {
      final handle = tester.ensureSemantics();
      final long = 'Upper body hypertrophy block with a very long name that keeps going ' * 2;
      final r = routine(4, name: long);
      var taps = 0;
      await tester.pumpWidget(host(
        WorkoutTile(summary: WorkoutSummary.of(r), heading: 'Today', highlighted: true, onTap: () => taps++),
        width: 320,
        scale: 2,
      ));
      expect(tester.takeException(), isNull);
      final summary = WorkoutSummary.of(r);
      expect(find.bySemanticsLabel(summary.spoken), findsOneWidget);
      await tester.tap(find.byType(WorkoutTile));
      expect(taps, 1);
      handle.dispose();
    });
  });

  group('the routine folder', () {
    testWidgets('is announced with the same summary, for 0 and 20 exercises', (tester) async {
      final handle = tester.ensureSemantics();
      for (final n in [0, 20]) {
        final r = routine(n, name: 'R$n');
        await tester.pumpWidget(host(Center(child: SizedBox(width: 170, child: RoutineFolder(routine: r, onMenu: () {})))));
        expect(find.bySemanticsLabel(RegExp(RegExp.escape(WorkoutSummary.of(r).spoken))), findsWidgets, reason: '$n exercises');
        expect(tester.takeException(), isNull);
      }
      handle.dispose();
    });
  });

  group('ProgressRing and MetricCard', () {
    testWidgets('the ring clamps nonsense and announces its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(Column(children: const [
        ProgressRing(value: 7, semanticLabel: 'over'),
        ProgressRing(value: -1, semanticLabel: 'under'),
        ProgressRing(value: double.nan, semanticLabel: 'nan'),
      ])));
      await tester.pump(const Duration(milliseconds: 600));
      for (final l in ['over', 'under', 'nan']) {
        expect(find.bySemanticsLabel(l), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('metric digits are not clipped: the rolling number keeps a full line height', (tester) async {
      await tester.pumpWidget(host(const MetricCard(label: 'Sets', value: '36')));
      final roll = tester.widget<RollIn>(find.byType(RollIn));
      expect(roll.style.height, greaterThanOrEqualTo(1.15), reason: 'height 1.0 cuts the bottom off the digits');
    });

    testWidgets('a metric reads as "label: value unit" and scales down instead of overflowing', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(
        const Row(children: [
          Expanded(child: MetricCard(label: 'Volume', value: '12,345.6', unit: 'kg', animate: false)),
          Expanded(child: MetricCard(label: 'PRs', value: '3', emphasis: true, animate: false)),
        ]),
        width: 220,
        scale: 2,
      ));
      expect(find.bySemanticsLabel('Volume: 12,345.6 kg'), findsOneWidget);
      expect(find.bySemanticsLabel('PRs: 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });
}
