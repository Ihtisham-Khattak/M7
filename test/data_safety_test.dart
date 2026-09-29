import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/models/workout.dart';
import 'package:gymmane/services/backup_zip.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/media_store.dart';
import 'package:gymmane/services/progress_reminder.dart';
import 'package:gymmane/services/schema.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Store.instance.init();
    tmp = await Directory.systemTemp.createTemp('gymmane_safety');
    MediaStore.directory = tmp.path;
    ProgressReminder.instance.enabled = false;
    fit.resetAllData();
    fit.setUnits('kg');
  });

  tearDown(() async {
    MediaStore.directory = null;
    if (tmp.existsSync()) await tmp.delete(recursive: true);
  });

  Map<String, dynamic> populated() {
    fit.updateProfile(name: 'Sam');
    fit.addBodyweight(80);
    final r = fit.createRoutine('Push');
    fit.assignRoutineToDay(1, r);
    fit.sessions.add(
      LoggedSession(DateTime(2026, 3, 2, 10), 1800, [
        LoggedExercise('EIeI8Vf', 'Barbell Bench Press', 'chest', [LoggedSet(8, 80), LoggedSet(5, 90)]),
      ]),
    );
    return jsonDecode(jsonEncode(fit.toJson())) as Map<String, dynamic>;
  }

  Future<void> store(Map<String, dynamic> doc) => Store.instance.save(doc);

  group('schema version', () {
    test('every saved document carries the current version', () {
      expect(fit.toJson()[kSchemaKey], kSchemaVersion);
      expect(kSchemaVersion, 1);
    });

    test('documents written before versioning count as version 1 and load unchanged', () async {
      final doc = populated()..remove(kSchemaKey);
      expect(schemaOf(doc), 1);
      expect(migrateDocument(doc), doc);

      fit.resetAllData();
      await store(doc);
      fit.loadFromStore();
      expect(fit.profile.name, 'Sam');
      expect(fit.sessions.single.exercises.single.sets.length, 2);
      expect(fit.weeklyPlan.length, 1);
    });

    test('migrations run in order and stamp each version', () {
      final steps = <DocMigration>[
        (d) => {...d, 'a': 1},
        (d) => {...d, 'b': (d['a'] as int) + 1},
      ];
      final out = migrateDocument({'profile': {}}, migrations: steps);
      expect(out['a'], 1);
      expect(out['b'], 2);
      expect(out[kSchemaKey], 3);

      final partway = migrateDocument({kSchemaKey: 2, 'a': 1}, migrations: steps);
      expect(partway['b'], 2);
      expect(partway[kSchemaKey], 3);

      final current = migrateDocument({kSchemaKey: 3, 'x': 1}, migrations: steps);
      expect(current, {kSchemaKey: 3, 'x': 1});
    });

    test('a document from a newer app is rejected instead of guessed at', () {
      expect(() => migrateDocument({kSchemaKey: 99}), throwsA(isA<SchemaTooNew>()));
      expect(fit.applyBackup({kSchemaKey: 99, 'sessions': []}), false);
      expect(checkDocument({kSchemaKey: 99}), DocumentProblem.newer);
    });

    test('newer stored data is never overwritten by an older app', () async {
      final raw = jsonEncode({
        kSchemaKey: 99,
        'sessions': [],
        'profile': {'name': 'Future'},
      });
      await Store.instance.save(jsonDecode(raw) as Map<String, dynamic>);
      final before = Store.instance.corruptCopy();

      fit.loadFromStore();
      expect(fit.storeLocked, true);
      fit.addBodyweight(70);
      fit.persistNow();

      final after = Store.instance.load();
      expect(after[kSchemaKey], 99);
      expect((after['profile'] as Map)['name'], 'Future');
      expect(before, isNull);

      fit.resetAllData();
      expect(fit.storeLocked, false);
      expect(Store.instance.load()[kSchemaKey], kSchemaVersion);
    });
  });

  group('loading tolerates damaged records', () {
    test('a malformed session, weekly plan key and note are skipped, everything else loads', () async {
      final doc = populated();
      (doc['sessions'] as List)
        ..add({'d': 'not a date', 'dur': 1, 'ex': []})
        ..add({
          'd': '2026-01-01T10:00:00.000',
          'ex': [
            {
              'id': 'x',
              'n': 'X',
              'p': 'chest',
              's': [
                {'w': 5},
              ],
            },
          ],
        })
        ..add('garbage');
      (doc['weeklyPlan'] as Map)['monday'] = 'r1';
      (doc['bodyweight'] as List).add({'d': '2026-01-01T10:00:00.000'});
      doc['notes'] = [
        {'id': 'n1', 't': 'kept', 'x': ''},
        7,
      ];

      fit.resetAllData();
      await store(doc);
      fit.loadFromStore();

      expect(fit.sessions.length, 1);
      expect(fit.sessions.single.exercises.single.name, 'Barbell Bench Press');
      expect(fit.weeklyPlan.keys, [1]);
      expect(fit.bodyweight.length, 1);
      expect(fit.notes.single.text, 'kept');
      expect(fit.profile.name, 'Sam');
      expect(fit.loadSkipped, greaterThanOrEqualTo(5));
    });

    test('a copy of the raw data is kept when anything had to be skipped', () async {
      final doc = populated();
      (doc['sessions'] as List).add({'oops': true});
      fit.resetAllData();
      await store(doc);
      fit.loadFromStore();

      final copy = Store.instance.corruptCopy();
      expect(copy, isNotNull);
      expect((jsonDecode(copy!) as Map)['sessions'], hasLength(2));
    });

    test('clean data skips nothing and keeps no copy', () async {
      final doc = populated();
      fit.resetAllData();
      await Store.instance.save(doc);
      fit.loadFromStore();
      expect(fit.loadSkipped, 0);
    });

    test('scalar fields with the wrong type do not stop the rest from loading', () async {
      final doc = populated()
        ..['rest'] = 'ninety'
        ..['bgDim'] = 'dark'
        ..['live'] = {'ex': 'nope'};
      fit.resetAllData();
      await store(doc);
      fit.loadFromStore();

      expect(fit.sessions.length, 1);
      expect(fit.session, isNull);
      expect(fit.loadSkipped, greaterThan(0));
    });

    test('randomly damaged documents always load', () async {
      final base = populated();
      final rnd = Random(7);

      Object? mangle(Object? v, int depth) {
        final roll = rnd.nextInt(12);
        if (roll == 0) return null;
        if (roll == 1) return 'x${rnd.nextInt(9)}';
        if (roll == 2) return rnd.nextInt(100);
        if (roll == 3) return <String, dynamic>{};
        if (roll == 4) return <Object?>[];
        if (v is Map && depth < 4) {
          return {
            for (final e in v.entries)
              if (rnd.nextInt(6) != 0) e.key: mangle(e.value, depth + 1),
          };
        }
        if (v is List && depth < 4) {
          return [
            for (final e in v)
              if (rnd.nextInt(6) != 0) mangle(e, depth + 1),
          ];
        }
        return v;
      }

      for (var i = 0; i < 150; i++) {
        final copy = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
        final doc = <String, dynamic>{
          for (final e in copy.entries)
            if (rnd.nextInt(10) != 0) e.key: mangle(e.value, 1),
        };
        await store(doc);
        try {
          fit.loadFromStore();
        } catch (e, st) {
          fail('iteration $i threw $e\n$st\n${jsonEncode(doc)}');
        }
      }
    });
  });

  group('restoring and importing', () {
    test('documents that are not a GymMane backup are refused and change nothing', () {
      populated();
      final before = jsonEncode(fit.toJson());

      expect(fit.applyBackup({}), false);
      expect(fit.importJson('{}'), false);
      expect(fit.importJson('{"hello":"world"}'), false);
      expect(fit.importJson('[1,2,3]'), false);
      expect(fit.importJson('not json'), false);
      expect(fit.applyBackup({'sessions': 'nope'}), false);
      expect(fit.applyBackup({'profile': 5}), false);

      expect(jsonEncode(fit.toJson()), before);
    });

    test('an error half way through puts the previous data back and keeps saving', () async {
      populated();
      final before = jsonEncode(fit.toJson());

      final ok = fit.applyBackup({
        'sessions': <Object?>[],
        'profile': {'name': 'Intruder'},
        'units': 5,
      });

      expect(ok, false);
      expect(jsonEncode(fit.toJson()), before);

      fit.addBodyweight(71);
      fit.persistNow();
      final saved = Store.instance.load();
      expect((saved['bodyweight'] as List).length, 2, reason: 'saving must not stay disabled');
    });

    test('a valid backup replaces the data, restores heatTone and reports success', () {
      populated();
      fit.setHeatTone('mono');
      final backup = jsonDecode(jsonEncode(fit.toJson())) as Map<String, dynamic>;

      fit.resetAllData();
      fit.setHeatTone('ember');
      expect(fit.applyBackup(backup), true);

      expect(fit.profile.name, 'Sam');
      expect(fit.sessions.length, 1);
      expect(fit.heatTone, 'mono');
    });

    test('damaged items inside an otherwise valid backup are skipped, not fatal', () {
      final doc = populated();
      (doc['sessions'] as List).add({'d': 'bad'});
      fit.resetAllData();

      expect(fit.applyBackup(doc), true);
      expect(fit.sessions.length, 1);
    });

    Future<Uint8List> zipOf(Map<String, dynamic> doc, {Map<String, Uint8List> files = const {}}) async {
      final archive = Archive()..addFile(ArchiveFile.string(kBackupJsonEntry, jsonEncode(doc)));
      files.forEach((name, bytes) => archive.addFile(ArchiveFile.noCompress(name, bytes.length, bytes)));
      return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
    }

    test('a bad zip leaves the existing media files alone', () async {
      final keep = File('${tmp.path}/keep-me.png')..writeAsBytesSync([1, 2, 3]);
      populated();

      expect(await restoreBackupZip(await zipOf({})), false);
      expect(await restoreBackupZip(await zipOf({'hello': 1})), false);
      expect(await restoreBackupZip(await zipOf({kSchemaKey: 99, 'sessions': []})), false);
      expect(await restoreBackupZip(Uint8List.fromList([1, 2, 3])), false);

      expect(keep.existsSync(), true);
      expect(fit.profile.name, 'Sam');
    });

    test('a failed apply removes the media it wrote but keeps the old ones', () async {
      final keep = File('${tmp.path}/keep-me.png')..writeAsBytesSync([1, 2, 3]);
      populated();
      final before = tmp.listSync().length;

      final zip = await zipOf(
        {
          'units': 5,
          'media': {'EIeI8Vf': 'media/images/x.png'},
        },
        files: {
          'media/images/x.png': Uint8List.fromList([9, 9, 9]),
        },
      );

      expect(await restoreBackupZip(zip), false);
      expect(tmp.listSync().length, before);
      expect(keep.existsSync(), true);
    });

    test('a good restore drops media that the backup does not reference', () async {
      final stale = File('${tmp.path}/stale.png')..writeAsBytesSync([1]);
      final doc = populated();
      doc['media'] = {'EIeI8Vf': 'media/images/bench.png'};

      final zip = await zipOf(
        doc,
        files: {
          'media/images/bench.png': Uint8List.fromList([7, 7]),
        },
      );
      expect(await restoreBackupZip(zip), true);

      expect(stale.existsSync(), false);
      final base = fit.exerciseMedia['EIeI8Vf'];
      expect(base, isNotNull);
      expect(File('${tmp.path}/$base').readAsBytesSync(), [7, 7]);
    });
  });
}
