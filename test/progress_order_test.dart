import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/catalog/exercise_catalog.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/services/train_reminder.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/widgets/charts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bench = kExercises.firstWhere((e) => e.name == 'Barbell Bench Press');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    ProgressReminder.instance.enabled = false;
    TrainReminder.instance.enabled = false;
    fit.resetAllData();
    fit.completeOnboarding();
    for (final id in ['strength', 'body', 'muscles', 'all_time']) {
      Store.instance.setNote('disclosure_progress_$id', '');
    }
  });

  void logSessions() {
    for (var i = 1; i <= 6; i++) {
      fit.sessions.add(LoggedSession(
        DateTime.now().subtract(Duration(days: i * 3)),
        3600,
        [
          LoggedExercise(bench.id, bench.name, bench.primary, [LoggedSet(8, 70)]),
        ],
      ));
    }
  }

  Future<double> yOf(WidgetTester tester, String text) async {
    final finder = find.text(text);
    expect(finder, findsWidgets, reason: 'no se encontró "$text"');
    return tester.getTopLeft(finder.first).dy;
  }

  testWidgets('the numbers come first, then the grid, then the body', (tester) async {
    logSessions();
    fit.route = 'progress';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    final volume = await yOf(tester, t.tileVolume30.toUpperCase());
    final heat = tester.getTopLeft(find.byType(Heatmap)).dy;
    final groups = await yOf(tester, t.progressStrength);

    expect(volume, lessThan(heat));
    expect(heat, lessThan(groups), reason: 'GM-18: the details sit in collapsed groups below the grid');
  });

  testWidgets('a card with nothing in it is not drawn at all', (tester) async {
    logSessions();
    fit.route = 'progress';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    expect(find.text(t.measures), findsNothing, reason: 'sin medidas, no hay tarjeta de medidas');
    expect(find.text(t.setupMeasures), findsOneWidget,
        reason: 'lo que falta se cuenta una sola vez, en la tarjeta de arranque');
  });

  testWidgets('the card shows up as soon as there is something to show', (tester) async {
    logSessions();
    fit.addMeasure('chest', 100);
    fit.persistNow();
    fit.route = 'progress';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(t.progressBody));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.progressBody));
    await tester.pumpAndSettle();

    expect(find.text(t.measures), findsWidgets);
    expect(find.byIcon(PhosphorIconsFill.checkCircle), findsWidgets,
        reason: 'lo ya hecho se queda listado, pero con su tic');
  });

  testWidgets('a fresh install leads with what to fill in, not with empty cards', (tester) async {
    fit.route = 'progress';
    await tester.pumpWidget(const GymManeApp());
    await tester.pumpAndSettle();

    final setup = await yOf(tester, t.setupTitle);
    final volume = await yOf(tester, t.tileVolume30.toUpperCase());

    expect(setup, lessThan(volume));
    expect(find.byType(Heatmap), findsNothing,
        reason: 'una rejilla vacía no dice nada a quien acaba de instalar');
  });
}
