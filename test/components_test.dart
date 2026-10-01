import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/components.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'support/fonts.dart';

Widget _host(Widget child, {ThemeData? theme, double textScale = 1, bool reduceMotion = false}) => MaterialApp(
      theme: theme ?? AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 800),
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: child))),
      ),
    );

Widget _catalogue({VoidCallback? tap}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('This week'),
        const SectionHeader.label('General'),
        SectionHeader('Recommended', onMore: tap),
        for (final kind in GymButtonKind.values) ...[
          GymButton(label: 'Save ${kind.name}', kind: kind, onTap: tap),
          GymButton(label: 'Compact ${kind.name}', kind: kind, size: GymButtonSize.compact, onTap: tap, expand: false),
        ],
        GymButton(label: 'Disabled', onTap: null),
        GymButton(label: 'Loading', onTap: tap, loading: true),
        for (final kind in GymCardKind.values) GymCard(kind: kind, onTap: tap, semanticLabel: kind.name, child: Text(kind.name)),
        GymCard(child: Column(children: [
          ListRow(icon: PhosphorIconsRegular.translate, title: 'Language', trailing: const Text('English'), chevron: true, divider: true, onTap: tap),
          ListRow(icon: PhosphorIconsRegular.trash, title: 'Reset all data', destructive: true, onTap: tap),
          ListRow(title: 'A very long title that should wrap instead of overflowing the row on small phones', subtitle: 'And a subtitle that is long enough to need two lines on a narrow screen as well', trailing: const Text('Value')),
        ])),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);

  for (final theme in {'dark': AppTheme.dark, 'light': AppTheme.light}.entries) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('the catalogue lays out in ${theme.key} at text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(_catalogue(tap: () {}), theme: theme.value, textScale: scale));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('every button and tappable row is at least 48dp tall and announced as a button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_catalogue(tap: () {})));
    await tester.pump(const Duration(milliseconds: 300));
    for (final f in [find.byType(GymButton), find.byType(ListRow)]) {
      for (final e in f.evaluate()) {
        expect(tester.getSize(find.byWidget(e.widget)).height, greaterThanOrEqualTo(48), reason: '${e.widget}');
      }
    }
    expect(tester.getSemantics(find.text('Save primary')), isSemantics(isButton: true, hasTapAction: true, isEnabled: true, hasEnabledState: true));
    handle.dispose();
  });

  testWidgets('a disabled or loading button does not react and says it is disabled', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(_host(Column(children: [
      const GymButton(label: 'Off', onTap: null),
      GymButton(label: 'Busy', onTap: () => taps++, loading: true),
      GymButton(label: 'On', onTap: () => taps++),
    ])));
    await tester.tap(find.text('Off'));
    await tester.tap(find.text('Busy'));
    expect(taps, 0);
    await tester.tap(find.text('On'));
    expect(taps, 1);
    expect(tester.getSemantics(find.text('Off')), isSemantics(isButton: true, isEnabled: false, hasEnabledState: true));
    expect(tester.getSemantics(find.text('Busy')), isSemantics(isButton: true, isEnabled: false, hasEnabledState: true));
    handle.dispose();
  });

  testWidgets('pressing scales a card down quickly and releasing eases back; reduced motion skips it', (tester) async {
    double scaleOf() => tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;
    await tester.pumpWidget(_host(GymCard(onTap: () {}, child: const Text('Card'))));
    final g = await tester.startGesture(tester.getCenter(find.text('Card')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(scaleOf(), lessThan(1));
    expect(scaleOf(), greaterThanOrEqualTo(0.95), reason: 'calm, not dramatic');
    await g.up();
    await tester.pump(const Duration(milliseconds: 200));
    expect(scaleOf(), 1);

    await tester.pumpWidget(_host(GymCard(onTap: () {}, child: const Text('Card')), reduceMotion: true));
    final animated = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first);
    expect(animated.duration, Duration.zero);
  });

  testWidgets('list rows and cards report their taps', (tester) async {
    var row = 0, card = 0, more = 0;
    await tester.pumpWidget(_host(Column(children: [
      ListRow(title: 'Row', onTap: () => row++),
      GymCard(onTap: () => card++, child: const Text('Card')),
      SectionHeader('Head', onMore: () => more++),
    ])));
    await tester.tap(find.text('Row'));
    await tester.tap(find.text('Card'));
    await tester.tap(find.text('Head'));
    expect((row, card, more), (1, 1, 1));
  });
}
