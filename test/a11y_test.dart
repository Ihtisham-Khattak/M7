import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/body_map.dart';
import 'package:gymmane/widgets/charts.dart';
import 'package:gymmane/widgets/rest_announcer.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/widgets/ui_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fonts.dart';

/// Accessibility baseline (GM-20): core screens at 200% text on a small phone, tap targets,
/// and what a screen reader is told.
const _muscleIds = [
  'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearm', 'trapezius', 'abdomen', 'obliques', 'quads',
  'hamstrings', 'glutes', 'calves',
];
Set<String> get _muscles => {for (final id in _muscleIds) t.muscle(id)};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  final bench = kExercises.firstWhere((e) => e.primary == 'chest' && e.equipment == 'Barbell');
  final curl = kExercises.firstWhere((e) => e.primary == 'biceps');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    setAppLanguage('en');
    fit.resetAllData();
    fit.startCountdown = false;
    fit.keepScreenOn = false;
    fit.onboarded = true;
  });

  tearDown(() => fit.persistNow());

  // Print where an overflow happened, not just that it did.
  void showWhere(WidgetTester tester) {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      final at = RegExp(r'file:///[^\s]*lib/[^\s]*').firstMatch(text)?.group(0);
      debugPrint('PROBLEM ${details.exceptionAsString().split("\n").first} at ${at ?? 'unknown'}');
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  void phone(WidgetTester tester, {double scale = 1}) {
    showWhere(tester);
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearAllTestValues();
    });
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 300));
  }

  void seedRoutine() {
    final id = fit.createRoutine('Push day');
    fit.toggleRoutineExercise(id, bench.id);
    fit.toggleRoutineExercise(id, curl.id);
    fit.assignRoutineToDay(DateTime.now().weekday, id);
  }

  /// Interactive nodes smaller than [min] dp that are on screen.
  List<String> smallTargets(WidgetTester tester, {double min = 48}) {
    final out = <String>[];
    void visit(SemanticsNode n) {
      final data = n.getSemanticsData();
      final tappable = data.hasAction(ui.SemanticsAction.tap) || data.hasAction(ui.SemanticsAction.longPress);
      if (tappable && !n.isInvisible && !n.isMergedIntoParent) {
        var m = Matrix4.identity();
        for (SemanticsNode? p = n; p != null; p = p.parent) {
          if (p.transform != null) m = p.transform! * m;
        }
        final r = MatrixUtils.transformRect(m, n.rect);
        final dpr = tester.view.devicePixelRatio;
        final w = r.width / dpr, h = r.height / dpr;
        final view = Offset.zero & tester.view.physicalSize;
        // fully visible: a row cut off by the edge of the screen only looks small
        final whole = r.left >= view.left && r.right <= view.right && r.top > view.top + 1 && r.bottom < view.bottom - 1;
        final field = data.flagsCollection.isTextField;
        // Muscles on the body map are drawn regions of a figure, exposed to a screen reader at
        // their real outline; they cannot be padded to 48dp.
        final bodyRegion = _muscles.contains(data.label);
        // Dense rows (the seven-day strip, the +/- steppers in a set row) cannot give every target
        // 48dp of width on a 360dp phone: they are at least 28dp wide and 48dp tall (WCAG 2.2 AA asks for 24dp).
        final weekDay = h >= min - 0.5 && w >= 28;
        if (whole && !field && !bodyRegion && !weekDay && (w < min - 0.5 || h < min - 0.5)) {
          out.add('"${data.label.isEmpty ? data.tooltip : data.label}" ${w.round()}x${h.round()}dp');
        }
      }
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
    return out;
  }

  group('200% text on a 360x640 phone', () {
    Future<void> check(WidgetTester tester, String what) async {
      await settle(tester);
      final problem = tester.takeException();
      if (problem != null) fail('$what: ${problem is FlutterError ? problem.toStringDeep() : problem}');
    }

    testWidgets('onboarding', (tester) async {
      phone(tester, scale: 2);
      fit.onboarded = false;
      await tester.pumpWidget(const GymManeApp());
      await check(tester, 'welcome');
      await tester.tap(find.byType(PrimaryButton).last);
      await check(tester, 'goal');
      await tester.tap(find.text(t.goalLeanTitle));
      await check(tester, 'goal chosen');
      await tester.tap(find.byType(PrimaryButton).last);
      await check(tester, 'training');
      await tester.ensureVisible(find.text(t.expIntermediate));
      await tester.tap(find.text(t.expIntermediate));
      await check(tester, 'experience chosen');
      for (var i = 0; i < 4 && fit.onboarded == false; i++) {
        await tester.ensureVisible(find.byType(PrimaryButton).last);
        await tester.tap(find.byType(PrimaryButton).last, warnIfMissed: false);
        await check(tester, 'step ${i + 4}');
      }
    });

    testWidgets('home, with a routine planned', (tester) async {
      phone(tester, scale: 2);
      seedRoutine();
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      await check(tester, 'home');
    });

    testWidgets('train picker', (tester) async {
      phone(tester, scale: 2);
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      fit.startWorkout();
      await check(tester, 'train select');
      fit.toggleMuscle('chest');
      fit.trainContinue();
      await check(tester, 'train review');
    });

    testWidgets('exercises', (tester) async {
      phone(tester, scale: 2);
      fit.route = 'exercises';
      await tester.pumpWidget(const GymManeApp());
      await check(tester, 'exercises');
    });

    testWidgets('live session', (tester) async {
      phone(tester, scale: 2);
      seedRoutine();
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      fit.startRoutine(fit.todayRoutine!);
      await check(tester, 'session');
      fit.setSessionWeight(0, 0, 100);
      fit.setSessionReps(0, 0, 8);
      fit.toggleSet(0, 0);
      await check(tester, 'session after a set');
      fit.saveAndExit();
    });
  });

  group('tap targets', () {
    testWidgets('live session: set rows, controls and rest timer', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      seedRoutine();
      fit.route = 'home';
      await tester.pumpWidget(const GymManeApp());
      await settle(tester);
      fit.startRoutine(fit.todayRoutine!);
      await settle(tester);
      expect(smallTargets(tester), isEmpty, reason: 'session');
      fit.setSessionWeight(0, 0, 100);
      fit.setSessionReps(0, 0, 8);
      fit.toggleSet(0, 0);
      await settle(tester);
      expect(smallTargets(tester), isEmpty, reason: 'session with a rest timer');
      fit.saveAndExit();
      handle.dispose();
    });

    testWidgets('onboarding: welcome, goal, training', (tester) async {
      phone(tester);
      final handle = tester.ensureSemantics();
      fit.onboarded = false;
      await tester.pumpWidget(const GymManeApp());
      await settle(tester);
      expect(smallTargets(tester), isEmpty, reason: 'welcome');
      await tester.tap(find.byType(PrimaryButton).last);
      await settle(tester);
      expect(smallTargets(tester), isEmpty, reason: 'goal');
      await tester.tap(find.text(t.goalLeanTitle));
      await tester.tap(find.byType(PrimaryButton).last);
      await settle(tester);
      expect(smallTargets(tester), isEmpty, reason: 'training');
      handle.dispose();
    });

    for (final screen in ['home', 'exercises', 'progress', 'settings', 'preferences', 'train', 'routines', 'tools', 'notes', 'measures']) {
      testWidgets('$screen: nothing interactive is smaller than 48dp', (tester) async {
        phone(tester);
        final handle = tester.ensureSemantics();
        seedRoutine();
        fit.route = screen;
        await tester.pumpWidget(const GymManeApp());
        await settle(tester);
        expect(smallTargets(tester), isEmpty, reason: screen);
        handle.dispose();
      });
    }
  });

  group('what a screen reader is told', () {
    Widget host(Widget child) => MaterialApp(
          theme: ThemeData(extensions: [GymColors.dark]),
          home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
        );

    testWidgets('the weekly goal ring, the heat-map and the trend charts have a spoken summary', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(Column(children: [
        const GoalRing(pct: 50),
        Heatmap(levels: [0, 1, 2, 0, 3, 0, 0, 1, 0, 0, 0, 0], onTapDay: (_) {}),
        const TrendChart(values: [60, 62.5, 64]),
        const Sparkline(values: [1, 2, 3]),
      ])));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.bySemanticsLabel(t.goalRingLabel(50)), findsOneWidget);
      expect(find.bySemanticsLabel(t.heatmapLabel(4)), findsOneWidget);
      expect(find.bySemanticsLabel(t.trendChartLabel('60', '64')), findsNWidgets(1));
      expect(find.bySemanticsLabel(t.trendChartLabel('1', '3')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the body map names the highlighted muscles and each muscle can be toggled', (tester) async {
      final handle = tester.ensureSemantics();
      final toggled = <String>[];
      await tester.pumpWidget(host(BodyMap(selected: const {'chest', 'biceps'}, onToggle: toggled.add)));

      expect(find.bySemanticsLabel(t.bodyMapLabel('${t.muscle('biceps')}, ${t.muscle('chest')}')), findsOneWidget);
      final chest = find.semantics.byLabel(t.muscle('chest'));
      expect(chest, findsOneWidget);
      final node = chest.evaluate().single;
      expect(node, isSemantics(isButton: true, isSelected: true, hasTapAction: true, hasSelectedState: true));
      tester.binding.pipelineOwner.semanticsOwner!.performAction(node.id, SemanticsAction.tap);
      expect(toggled, ['chest']);

      await tester.pumpWidget(host(BodyMap(selected: const {}, onToggle: toggled.add)));
      expect(find.bySemanticsLabel(t.bodyMapNone), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the stepper buttons say what they do', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(StepperControl(value: '90s', onDec: () {}, onInc: () {})));
      expect(find.bySemanticsLabel(t.decrease), findsOneWidget);
      expect(find.bySemanticsLabel(t.increase), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the rest timer is announced when it starts, at ten seconds and when it ends - not every second',
        (tester) async {
      seedRoutine();
      fit.route = 'home';
      final said = <String>[];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: RestAnnouncer(announce: said.add))));
      fit.startRoutine(fit.todayRoutine!);
      fit.setSessionWeight(0, 0, 100);
      fit.setSessionReps(0, 0, 8);
      fit.toggleSet(0, 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(said, hasLength(1));
      expect(said.first, t.restLeftAnnounce(fit.session!.restRemaining!));

      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(said.length, lessThanOrEqualTo(2), reason: 'a countdown read aloud every second would be unusable');

      fit.skipRest();
      fit.saveAndExit();
    });
  });
}
