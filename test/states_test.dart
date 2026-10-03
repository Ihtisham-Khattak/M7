import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/gymmane_app.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/states.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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
    fit.onboarded = true;
    fit.startCountdown = false;
  });
  tearDown(() => fit.persistNow());

  Widget host(Widget child, {double width = 320, double scale = 1}) => MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 700), textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: Center(child: SizedBox(width: width, child: child)))),
        ),
      );

  group('the components', () {
    testWidgets('EmptyState reads as one block and its action works', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(host(EmptyState(
        icon: PhosphorIconsRegular.notebook,
        title: 'Nothing here yet',
        body: 'Add your first one.',
        actionLabel: 'Add',
        onAction: () => taps++,
      )));
      expect(find.bySemanticsLabel(RegExp('Nothing here yet. Add your first one.')), findsOneWidget);
      await tester.tap(find.text('Add'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('long German and Russian copy wraps at 200% text without overflowing', (tester) async {
      for (final copy in [
        ('Noch keine Trainingseinheiten aufgezeichnet', 'Sobald du eine Einheit abgeschlossen hast, erscheinen hier deine Fortschritte und Rekorde.', 'Einheit starten'),
        ('Пока нет ни одной тренировки в журнале', 'Как только вы завершите тренировку, здесь появятся ваш прогресс и рекорды.', 'Начать тренировку'),
      ]) {
        await tester.pumpWidget(host(EmptyState(
          icon: PhosphorIconsRegular.chartLineUp,
          title: copy.$1,
          body: copy.$2,
          actionLabel: copy.$3,
          onAction: () {},
        ), scale: 2));
        expect(tester.takeException(), isNull, reason: copy.$1);
      }
    });

    testWidgets('LoadingSkeleton shows quiet placeholders and InlineError offers a retry', (tester) async {
      var retried = 0;
      await tester.pumpWidget(host(Column(children: [
        const LoadingSkeleton(rows: 3, semanticLabel: 'Loading'),
        InlineError(message: 'Could not read the file', actionLabel: 'Try again', onAction: () => retried++),
      ])));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('screens that can be empty explain it and offer the next step', () {
    Future<void> open(WidgetTester tester, String route) async {
      tester.view.physicalSize = const Size(720, 1400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      fit.route = route;
      await tester.pumpWidget(const GymManeApp());
      await tester.pump(const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull, reason: route);
    }

    for (final route in ['notes', 'moments', 'routines', 'places', 'timeline']) {
      testWidgets('$route with no data', (tester) async {
        await open(tester, route);
        expect(find.byType(EmptyState), findsOneWidget, reason: route);
      });
    }

    testWidgets('exercises with nothing found offers to clear the filters', (tester) async {
      fit.setExSearch('zzzzqqqq');
      await open(tester, 'exercises');
      expect(find.byType(EmptyState), findsOneWidget);
      await tester.tap(find.text(sentenceOr(t.clearFilters)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(fit.exSearch, isEmpty);
    });

    testWidgets('after Reset all data the same screens are explained again', (tester) async {
      fit.createRoutine('Temp');
      fit.resetAllData();
      fit.onboarded = true;
      await open(tester, 'routines');
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });
}

String sentenceOr(String s) => s.toUpperCase() == s ? s[0] + s.substring(1).toLowerCase() : s;
