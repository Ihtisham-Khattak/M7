import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/services/background_guard.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/media_store.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_colors.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/app_background.dart';
import 'package:gymmane/widgets/background_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uint8List _solid(int gray, {int pixels = 64}) {
  final out = Uint8List(pixels * 4);
  for (var i = 0; i < pixels; i++) {
    out[i * 4] = gray;
    out[i * 4 + 1] = gray;
    out[i * 4 + 2] = gray;
    out[i * 4 + 3] = 255;
  }
  return out;
}

Future<File> _png(Directory dir, String name, Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 32, 32), Paint()..color = color);
  final image = await recorder.endRecording().toImage(32, 32);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${dir.path}/$name.png')..writeAsBytesSync(data!.buffer.asUint8List());
  return file;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('readability guard', () {
    test('contrast math matches the WCAG reference', () {
      expect(contrastOfLuminances(1, 0), closeTo(21, 0.001));
      expect(compositeContrast(imageLuminance: 1, text: Colors.black, scrim: Colors.white, alpha: 0), closeTo(21, 0.01));
    });

    test('image analysis reports the dark and bright ends of a picture', () {
      final white = analyzeTones(_solid(255));
      expect(white.bright, closeTo(1, 0.01));
      expect(white.dark, closeTo(1, 0.01));
      final mixed = Uint8List.fromList([..._solid(0, pixels: 50), ..._solid(255, pixels: 50)]);
      final tones = analyzeTones(mixed);
      expect(tones.dark, lessThan(0.01));
      expect(tones.bright, greaterThan(0.99));
      expect(analyzeTones(Uint8List(0)), kUnknownTones);
    });

    for (final entry in {'dark': GymColors.dark, 'light': GymColors.light}.entries) {
      test('${entry.key} theme: text stays readable over any picture brightness', () {
        final gc = entry.value;
        final texts = {'text': gc.text, 'secondary': gc.textSecondary, 'tertiary': gc.textTertiary};
        for (var step = 0; step <= 20; step++) {
          final y = step / 20;
          final alpha = readableScrim(tones: (dark: y, bright: y), texts: texts.values, scrim: gc.bg);
          expect(alpha, inInclusiveRange(0, kMaxScrim));
          for (final t in texts.entries) {
            final ratio = compositeContrast(imageLuminance: y, text: t.value, scrim: gc.bg, alpha: alpha);
            expect(ratio, greaterThanOrEqualTo(alpha >= kMaxScrim ? 3.0 : 4.5),
                reason: '${t.key} over luminance $y (alpha ${alpha.toStringAsFixed(2)})');
          }
        }
      });
    }

    test('a brighter picture needs a stronger scrim in the dark theme, a darker one in the light theme', () {
      double alpha(GymColors gc, double y) => readableScrim(
          tones: (dark: y, bright: y), texts: [gc.text, gc.textSecondary, gc.textTertiary], scrim: gc.bg);
      var prev = -1.0;
      for (var s = 0; s <= 10; s++) {
        final a = alpha(GymColors.dark, s / 10);
        expect(a, greaterThanOrEqualTo(prev - 1e-9));
        prev = a;
      }
      prev = 2.0;
      for (var s = 0; s <= 10; s++) {
        final a = alpha(GymColors.light, s / 10);
        expect(a, lessThanOrEqualTo(prev + 1e-9));
        prev = a;
      }
    });

    test('lowering opacity pulls a bright picture toward the page so it needs less scrim', () {
      final gc = GymColors.dark;
      const white = (dark: 1.0, bright: 1.0);
      double need(ImageTones t) =>
          readableScrim(tones: t, texts: [gc.text, gc.textSecondary, gc.textTertiary], scrim: gc.bg);
      expect(blendTones(white, gc.bg, 1), white);
      final faded = blendTones(white, gc.bg, 0.5);
      expect(faded.bright, lessThan(1));
      expect(need(faded), lessThan(need(white)));
      final ghost = blendTones(white, gc.bg, 0.35);
      expect(ghost.bright, lessThan(faded.bright));
    });

    test('a picture that is already readable needs no extra scrim', () {
      final gc = GymColors.dark;
      expect(readableScrim(tones: (dark: 0.0, bright: 0.0), texts: [gc.text, gc.textSecondary], scrim: gc.bg), 0);
    });
  });

  group('the photo background', () {
    late Directory tmp;

    setUp(() async => tmp = await Directory.systemTemp.createTemp('gymmane_bg'));
    tearDown(() async => tmp.delete(recursive: true));

    double topAlpha(WidgetTester tester) {
      final boxes = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((b) {
        final d = b.decoration;
        return d is BoxDecoration && d.gradient is LinearGradient;
      });
      return ((boxes.first.decoration as BoxDecoration).gradient as LinearGradient).colors.first.a;
    }

    Future<double> scrimOver(WidgetTester tester, Color picture, ThemeData theme, {double dim = 0.3}) async {
      late File file;
      await tester.runAsync(() async => file = await _png(tmp, 'p${picture.toARGB32()}', picture));
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(body: AppBackground(pattern: 'photo', photo: file.path, dim: dim)),
      ));
      var last = -1.0;
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        final now = topAlpha(tester);
        if ((now - last).abs() < 1e-9 && i > 3) break;
        last = now;
      }
      return topAlpha(tester);
    }

    testWidgets('a white picture in the dark theme is dimmed far beyond the chosen level', (tester) async {
      final a = await scrimOver(tester, Colors.white, AppTheme.dark);
      expect(a, greaterThan(0.7));
    });

    testWidgets('a dark picture in the dark theme keeps exactly the chosen dim', (tester) async {
      final a = await scrimOver(tester, const Color(0xFF050505), AppTheme.dark, dim: 0.4);
      expect(a, closeTo(0.4, 0.01));
    });

    testWidgets('a black picture in the light theme is lifted so dark text stays readable', (tester) async {
      final a = await scrimOver(tester, Colors.black, AppTheme.light);
      expect(a, greaterThan(0.7));
    });

    testWidgets('a missing photo draws nothing and never throws', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: AppBackground(pattern: 'photo', photo: '/no/such/file.png')),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('the background setting', () {
    late Directory tmp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      tmp = await Directory.systemTemp.createTemp('gymmane_bgs');
      MediaStore.directory = tmp.path;
      fit.resetAllData();
    });

    tearDown(() async {
      MediaStore.directory = null;
      await tmp.delete(recursive: true);
    });

    test('all five modes are valid and unknown values fall back to dots', () async {
      expect(SettingsState.bgPatterns, containsAll(['none', 'dots', 'grid', 'ancient', 'photo']));
      for (final mode in ['none', 'dots', 'grid', 'ancient']) {
        fit.setBgPattern(mode);
        expect(fit.bgPattern, mode);
      }
      await Store.instance.save({'onboarded': true, 'bg': 'sparkles'});
      fit.loadFromStore();
      expect(fit.bgPattern, 'dots');
    });

    test('a photo mode without a photo is not accepted', () {
      fit.setBgPattern('photo');
      expect(fit.bgPattern, isNot('photo'));
    });

    test('the mode and dim survive a restart and a backup round trip', () {
      fit.setBgPattern('grid');
      fit.setBgDim(0.7);
      fit.persistNow();
      fit.loadFromStore();
      expect((fit.bgPattern, fit.bgDim), ('grid', 0.7));

      final backup = Map<String, dynamic>.from(fit.toJson());
      fit.setBgPattern('none');
      fit.setBgDim(0.4);
      expect(fit.applyBackup(backup), true);
      expect((fit.bgPattern, fit.bgDim), ('grid', 0.7));
    });

    test('settings saved before the ancient mode existed still load unchanged', () async {
      await Store.instance.save({'onboarded': true, 'bg': 'photo', 'bgDim': 0.55});
      fit.loadFromStore();
      expect(fit.bgPattern, 'dots', reason: 'photo mode without a stored photo falls back safely');
      await Store.instance.save({'onboarded': true, 'bg': 'dots', 'bgDim': 0.55});
      fit.loadFromStore();
      expect(fit.bgPattern, 'dots');
    });

    test('resetting everything never leaves the app in photo mode without a photo', () async {
      final src = File('${tmp.path}/pic.png')..writeAsBytesSync([1, 2, 3]);
      await fit.setBgPhoto(src.path);
      expect(fit.bgPattern, 'photo');
      fit.resetAllData();
      expect(fit.bgPattern, isNot('photo'));
      expect(fit.bgPhoto, isNull);
    });

    test('framing, opacity and blur are clamped to safe ranges', () {
      fit.setBgZoom(9);
      fit.setBgOffset(5, -5);
      fit.setBgOpacity(0);
      fit.setBgBlur(99);
      expect((fit.bgZoom, fit.bgDx, fit.bgDy, fit.bgOpacity, fit.bgBlur), (3.0, 1.0, -1.0, 0.35, 12.0));
      fit.setBgZoom(0);
      fit.setBgOpacity(7);
      fit.setBgBlur(-3);
      expect((fit.bgZoom, fit.bgOpacity, fit.bgBlur), (1.0, 1.0, 0.0));
    });

    test('framing survives a restart and a backup, and a hand-edited store cannot break it', () async {
      fit.setBgZoom(2);
      fit.setBgOffset(0.4, -0.2);
      fit.setBgOpacity(0.6);
      fit.setBgBlur(5);
      fit.persistNow();
      fit.loadFromStore();
      expect((fit.bgZoom, fit.bgDx, fit.bgDy, fit.bgOpacity, fit.bgBlur), (2.0, 0.4, -0.2, 0.6, 5.0));

      final backup = Map<String, dynamic>.from(fit.toJson());
      fit.resetBgFraming();
      expect(fit.applyBackup(backup), true);
      expect((fit.bgZoom, fit.bgBlur), (2.0, 5.0));

      await Store.instance.save({'onboarded': true, 'bgZoom': 'x', 'bgDx': 80, 'bgOp': -4, 'bgBlur': null});
      fit.loadFromStore();
      expect(fit.bgZoom, 1.0);
      expect(fit.bgDx, 1.0);
      expect(fit.bgOpacity, 0.35);
      expect(fit.bgBlur, 0.0);
    });

    test('choosing a new picture, removing it or resetting starts from a neutral framing', () async {
      final src = File('${tmp.path}/pic.png')..writeAsBytesSync([1, 2, 3]);
      await fit.setBgPhoto(src.path);
      fit.setBgZoom(2.5);
      fit.setBgBlur(8);
      await fit.setBgPhoto(src.path);
      expect((fit.bgZoom, fit.bgBlur, fit.bgOpacity), (1.0, 0.0, 1.0));
      fit.setBgZoom(2);
      fit.clearBgPhoto();
      expect(fit.bgZoom, 1.0);
      fit.setBgBlur(4);
      fit.resetAllData();
      expect(fit.bgBlur, 0.0);
    });

    testWidgets('the preview blurs only when asked and reports drags as a new position', (tester) async {
      late File file;
      await tester.runAsync(() async => file = await _png(tmp, 'prev', const Color(0xFF334455)));
      var moved = Offset.zero;
      Widget host(double blur) => MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: BackgroundPreview(
                pattern: 'photo',
                photo: file.path,
                dim: 0.4,
                zoom: 2,
                dx: 0,
                dy: 0,
                opacity: 1,
                blur: blur,
                onMove: (x, y) => moved = Offset(x, y),
              ),
            ),
          );

      await tester.pumpWidget(host(0));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump();
      }
      expect(tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled, false);

      await tester.pumpWidget(host(6));
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump();
      }
      expect(tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled, true);

      await tester.drag(find.byType(BackgroundPreview), const Offset(-42, 0));
      expect(moved.dx, greaterThan(0), reason: 'dragging the picture left reveals more of its right side');
      expect(moved.dy, closeTo(0, 1e-6));
      expect(tester.takeException(), isNull);
    });
  });
}
