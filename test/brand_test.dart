import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/app/brand.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/services/schema.dart';
import 'package:gymmane/theme/app_theme.dart';

import 'support/fonts.dart';

/// The app is called Kaizan (GM-90); the identifiers that keep installs, data and backups
/// working are not renamed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  tearDown(() => setAppLanguage('en'));

  test('the display name is Kaizan everywhere a person can read it', () {
    expect(kAppName, 'Kaizan');
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="Kaizan"'));
    expect(File('fastlane/metadata/android/en-US/title.txt').readAsStringSync().trim(), 'Kaizan');
    expect(File('fastlane/metadata/android/es-ES/title.txt').readAsStringSync().trim(), 'Kaizan');
    expect(File('pubspec.yaml').readAsStringSync(), contains('description: "Kaizan'));
  });

  test('no translation still calls the app GymMane', () {
    final left = <String>[];
    for (final f in Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
      final arb = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      arb.forEach((key, value) {
        if (value is String && RegExp('gymmane', caseSensitive: false).hasMatch(value)) {
          left.add('${f.uri.pathSegments.last}: $key');
        }
      });
    }
    expect(left, isEmpty);
  });

  test('user-visible string literals in the app code use the brand constant', () {
    final left = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (f.path.contains('lib/l10n/')) continue;
      for (final (i, line) in f.readAsLinesSync().indexed) {
        final text = line.replaceAll(RegExp(r'https?://\S+|InlitX/GymMane|gymmane[_.\-]\w*|com\.gymmane\.\w+'), '');
        if (RegExp(r"""['"][^'"]*GymMane[^'"]*['"]""").hasMatch(text)) left.add('${f.path}:${i + 1}: ${line.trim()}');
      }
    }
    expect(left, isEmpty, reason: 'use kAppName (lib/app/brand.dart)');
  });

  test('install identity, data key and backup name are unchanged so updates and old backups still work', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.gymmane.app"'));
    expect(File('lib/services/local_store.dart').readAsStringSync(), contains('gymmane_v1'));
    expect(File('lib/services/backup_zip.dart').readAsStringSync(), allOf(contains('kBackupJsonEntry'), contains('gymmane.json')));
    expect(DocumentProblem.values.map((e) => e.name), contains('notGymMane'));
  });

  test('the tagline exists in every language and none of them is just the English line', () {
    final english = (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map)['tagline'] as String;
    expect(english, 'Soft but not weak.');
    for (final code in appLanguages) {
      setAppLanguage(code);
      expect(t.tagline.trim(), isNotEmpty, reason: code);
      if (code != 'en') expect(t.tagline, isNot(english), reason: code);
    }
  });

  test('the launcher artwork exists in every form Android and the stores need', () {
    for (final path in [
      'assets/icon/ic_1024.png',
      'assets/icon/ic_fg_1024.png',
      'assets/icon/ic_mono_1024.png',
      'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
      'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_monochrome.png',
      'android/app/src/main/res/drawable-xxxhdpi/ic_stat_gymmane.png',
      'fastlane/metadata/android/en-US/images/icon.png',
    ]) {
      expect(File(path).existsSync(), true, reason: path);
    }
    final adaptive = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();
    expect(adaptive, allOf(contains('<foreground>'), contains('<monochrome>')));
  });

  testWidgets('the mark and the wordmark render and are announced as the app name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(body: Center(child: KaizanWordmark(size: 30, withMark: true))),
    ));
    expect(find.bySemanticsLabel('Kaizan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
