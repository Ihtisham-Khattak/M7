import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/exercise.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/exercise_card.dart';
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
  tearDown(() => setAppLanguage('en'));

  const custom = Exercise(
    id: 'custom-1',
    name: 'My odd cable thing',
    primary: 'chest',
    secondary: [],
    equipment: 'Cable',
    difficulty: 'Beginner',
    art: '',
    steps: [],
  );

  Widget host(Widget child, {double width = 360, double scale = 1}) => MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800), textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: SizedBox(width: width, child: child))),
        ),
      );

  group('ExerciseCard', () {
    testWidgets('shows the localised name and "muscle · equipment", also for a custom exercise without art',
        (tester) async {
      await tester.pumpWidget(host(const ExerciseCard(exercise: custom)));
      expect(find.text('My odd cable thing'), findsOneWidget);
      expect(find.text('${t.muscle('chest')} · ${t.equipment('Cable')}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses the translated catalogue name, never the raw English one', (tester) async {
      setAppLanguage('es');
      final ex = kExercises.firstWhere((e) => exerciseName(e) != e.name);
      await tester.pumpWidget(host(ExerciseCard(exercise: ex)));
      expect(find.text(exerciseName(ex)), findsOneWidget);
      expect(find.text(ex.name), findsNothing);
      expect(find.text(t.muscle(ex.primary), findRichText: true), findsNothing, reason: 'the muscle sits inside the subtitle line');
      expect(find.textContaining(t.muscle(ex.primary)), findsOneWidget);
    });

    testWidgets('selected, dimmed, bare and trailing/leading variants build and react to taps', (tester) async {
      var taps = 0, thumb = 0;
      await tester.pumpWidget(host(Column(children: [
        ExerciseCard(exercise: custom, selected: true, onTap: () => taps++, onThumbTap: () => thumb++, trailing: const Icon(Icons.add)),
        const ExerciseCard(exercise: custom, dimmed: true, leading: SizedBox(width: 20, child: Icon(Icons.drag_handle))),
        const ExerciseCard(exercise: custom, bare: true, divider: true, subtitle: 'Last: 60×8'),
      ])));
      expect(find.text('Last: 60×8'), findsOneWidget);
      await tester.tap(find.byType(ExerciseCard).first);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reads as one sentence for a screen reader', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(ExerciseCard(exercise: custom, onTap: () {}, selected: true)));
      expect(find.bySemanticsLabel(RegExp('My odd cable thing, ${RegExp.escape(t.muscle('chest'))}')), findsOneWidget);
      handle.dispose();
    });

    for (final lang in ['es', 'de', 'ru']) {
      testWidgets('long $lang names fit at 1.15x and 2.0x text on a 320dp phone', (tester) async {
        setAppLanguage(lang);
        final longest = (kExercises.toList()..sort((a, b) => exerciseName(b).length.compareTo(exerciseName(a).length))).first;
        for (final scale in [1.15, 2.0]) {
          await tester.pumpWidget(host(
            Column(children: [
              ExerciseCard(exercise: longest, trailing: const Icon(Icons.check), showDifficulty: true),
              ExerciseCard(exercise: longest, bare: true, thumbSize: 52, trailing: const SizedBox(width: 48, height: 48)),
            ]),
            width: 320,
            scale: scale,
          ));
          expect(tester.takeException(), isNull, reason: '$lang at $scale');
        }
      });
    }

    testWidgets('a list of all exercises stays lazy: only the visible rows are built', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ListView.builder(
            itemCount: kExercises.length,
            itemBuilder: (_, i) => ExerciseCard(exercise: kExercises[i], bare: true, divider: true),
          ),
        ),
      ));
      expect(kExercises.length, greaterThan(500));
      expect(find.byType(ExerciseCard).evaluate().length, lessThan(25));
      await tester.fling(find.byType(ListView), const Offset(0, -3000), 4000);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });

  group('ExerciseTile and MuscleChip', () {
    testWidgets('the carousel tile opens the exercise and names it', (tester) async {
      final handle = tester.ensureSemantics();
      var opened = 0;
      await tester.pumpWidget(host(SizedBox(height: 158, child: Align(alignment: Alignment.centerLeft, child: ExerciseTile(exercise: custom, onTap: () => opened++)))));
      await tester.tap(find.byType(ExerciseTile));
      expect(opened, 1);
      expect(find.bySemanticsLabel(RegExp('My odd cable thing')), findsWidgets);
      handle.dispose();
    });

    testWidgets('a muscle chip is a plain label, or a 48dp selectable button', (tester) async {
      final handle = tester.ensureSemantics();
      var picked = 0;
      await tester.pumpWidget(host(Column(children: [
        const MuscleChip('chest'),
        MuscleChip('biceps', selected: true, onTap: () => picked++),
      ])));
      expect(find.text(t.muscle('chest')), findsOneWidget);
      final tappable = find.ancestor(of: find.text(t.muscle('biceps')), matching: find.byType(MuscleChip));
      expect(tester.getSize(tappable).height, greaterThanOrEqualTo(48));
      await tester.tap(find.text(t.muscle('biceps')));
      expect(picked, 1);
      expect(tester.getSemantics(find.text(t.muscle('biceps'))), isSemantics(isButton: true, isSelected: true, hasSelectedState: true, hasTapAction: true));
      handle.dispose();
    });
  });

  test('every place that lists exercises uses the shared card', () {
    final expected = {
      'lib/screens/exercises_screen.dart': 'ExerciseCard(',
      'lib/screens/train_screen.dart': 'ExerciseCard(',
      'lib/screens/routine_edit_screen.dart': 'ExerciseCard(',
      'lib/screens/session/sheets.dart': 'ExerciseCard(',
      'lib/screens/home_screen.dart': 'ExerciseTile(',
    };
    expected.forEach((path, needle) => expect(File(path).readAsStringSync(), contains(needle), reason: path));
    for (final path in expected.keys) {
      final own = RegExp(r'ExerciseMedia\(ex:').allMatches(File(path).readAsStringSync()).length;
      // the session overview sheet keeps its picture because it shows live progress, not a pick
      expect(own, path.endsWith('session/sheets.dart') ? 1 : 0, reason: '$path should not draw its own exercise picture');
    }
  });
}
