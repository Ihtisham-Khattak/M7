import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/exercise.dart';
import '../models/note.dart';
import '../models/progress_shot.dart';
import '../state/fit_state.dart';
import 'alarm_store.dart';
import 'media_store.dart';
import 'schema.dart';

const String kBackupJsonEntry = 'gymmane.json';
const String _imagesDir = 'media/images';
const String _videosDir = 'media/videos';
const String _notesDir = 'media/notes';
const String _timelineDir = 'timeline';
const String _momentsDir = 'moments';
const String _alarmDir = 'alarm';

bool looksLikeZip(Uint8List b) =>
    b.length > 4 && b[0] == 0x50 && b[1] == 0x4B && (b[2] == 0x03 || b[2] == 0x05 || b[2] == 0x07);

Future<Uint8List> buildBackupZip() async {
  final data = fit.toJson();
  final archive = Archive();
  final used = <String>{};
  final paths = <String, String>{};

  for (final entry in fit.exerciseMedia.entries) {
    final bytes = await MediaStore.readBytes(entry.value);
    if (bytes == null || bytes.isEmpty) continue;
    final ex = fit.exerciseById(entry.key);
    final dir = MediaStore.isVideo(entry.value) ? _videosDir : _imagesDir;
    final name = _uniqueName(used, slugify(ex == null ? entry.key : exerciseName(ex)),
        MediaStore.extOf(entry.value));
    archive.addFile(ArchiveFile.noCompress('$dir/$name', bytes.length, bytes));
    paths[entry.key] = '$dir/$name';
  }
  data['media'] = paths;

  final noteMedia = <String, String>{};
  for (final note in fit.notes) {
    for (final m in note.media) {
      if (noteMedia.containsKey(m)) continue;
      final bytes = await MediaStore.readBytes(m);
      if (bytes == null || bytes.isEmpty) continue;
      final name = _uniqueName(used, _noteSlug(note), MediaStore.extOf(m));
      archive.addFile(ArchiveFile.noCompress('$_notesDir/$name', bytes.length, bytes));
      noteMedia[m] = '$_notesDir/$name';
    }
  }
  data['noteMedia'] = noteMedia;

  final shotMedia = <String, String>{};
  for (final entry in fit.timelineAsc) {
    for (final pose in kPoses) {
      final name = entry.shot(pose);
      if (name == null || shotMedia.containsKey(name)) continue;
      final bytes = await MediaStore.readBytes(name);
      if (bytes == null || bytes.isEmpty) continue;
      final path = '$_timelineDir/${_day(entry.date)}/$pose.${MediaStore.extOf(name)}';
      used.add(path);
      archive.addFile(ArchiveFile.noCompress(path, bytes.length, bytes));
      shotMedia[name] = path;
    }
  }
  data['shotMedia'] = shotMedia;

  final momentMedia = <String, String>{};
  for (final moment in fit.moments) {
    if (momentMedia.containsKey(moment.file)) continue;
    final bytes = await MediaStore.readBytes(moment.file);
    if (bytes == null || bytes.isEmpty) continue;
    final path = '$_momentsDir/${_day(moment.date)}-${momentMedia.length + 1}'
        '.${MediaStore.extOf(moment.file)}';
    used.add(path);
    archive.addFile(ArchiveFile.noCompress(path, bytes.length, bytes));
    momentMedia[moment.file] = path;
  }
  data['momentMedia'] = momentMedia;

  final alarm = fit.alarmSound;
  final alarmPath = alarm == null ? null : AlarmStore.pathFor(alarm);
  if (alarm != null && alarmPath != null) {
    try {
      final bytes = await File(alarmPath).readAsBytes();
      archive.addFile(ArchiveFile.noCompress('$_alarmDir/$alarm', bytes.length, bytes));
    } catch (_) {}
  }

  archive.addFile(
      ArchiveFile.string(kBackupJsonEntry, const JsonEncoder.withIndent('  ').convert(data)));
  return ZipEncoder().encodeBytes(archive);
}

Future<bool> restoreBackupZip(Uint8List zipBytes) async {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(zipBytes);
  } catch (_) {
    return false;
  }

  final jsonFile = _findJson(archive);
  if (jsonFile == null) return false;
  final Map<String, dynamic> data;
  try {
    final decoded = jsonDecode(utf8.decode(jsonFile.readBytes() ?? const []));
    if (decoded is! Map<String, dynamic>) return false;
    data = decoded;
  } catch (_) {
    return false;
  }

  if (checkDocument(data) != null) return false;

  final written = <String>{};

  Future<Map<String, String>> restoreGroup(String key, String Function(String oldKey) owner) async {
    final wanted = <String, String>{};
    ((data[key] as Map?) ?? {}).forEach((k, v) {
      if (k is String && v is String && v.isNotEmpty) wanted[k] = v;
    });
    final restored = <String, String>{};
    for (final e in wanted.entries) {
      final bytes = archive.findFile(e.value)?.readBytes();
      if (bytes == null) continue;
      final base = await MediaStore.saveBytes(owner(e.key), MediaStore.extOf(e.value), bytes);
      if (base != null) {
        restored[e.key] = base;
        written.add(base);
      }
    }
    return restored;
  }

  final restored = await restoreGroup('media', (k) => k);
  final restoredNotes = await restoreGroup('noteMedia', (_) => 'note');
  final restoredShots = await restoreGroup('shotMedia', (_) => 'shot');
  final restoredMoments = await restoreGroup('momentMedia', (_) => 'moment');

  final alarmName = data['alarmSound'] as String?;
  final alarmBytes = (alarmName == null || alarmName.isEmpty)
      ? null
      : archive.findFile('$_alarmDir/$alarmName')?.readBytes();

  final applied = fit.applyBackup(
    data,
    restoredMedia: restored,
    restoredNoteMedia: restoredNotes,
    restoredShots: restoredShots,
    restoredMoments: restoredMoments,
  );
  if (!applied) {
    for (final name in written) {
      await MediaStore.delete(name);
    }
    return false;
  }

  await MediaStore.retainOnly(fit.referencedMedia());

  final alarmBase = alarmBytes == null ? null : await AlarmStore.saveBytes(alarmName!, alarmBytes);
  if (alarmBase != null) {
    fit.setAlarmSound(alarmBase, (data['alarmSoundName'] as String?) ?? alarmBase);
  } else {
    await fit.clearAlarmSound();
  }
  return true;
}

ArchiveFile? _findJson(Archive a) {
  ArchiveFile? fallback;
  for (final f in a.files) {
    if (!f.isFile || !f.name.toLowerCase().endsWith('.json')) continue;
    if (f.name == kBackupJsonEntry) return f;
    fallback ??= f;
  }
  return fallback;
}

String _day(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

String _noteSlug(GymNote n) {
  final day = _day(n.date);
  final title = slugify(n.title);
  final short = title.length <= 28 ? title : title.substring(0, 28);
  return short.isEmpty ? day : '$day-$short';
}

String _two(int n) => n.toString().padLeft(2, '0');

String _uniqueName(Set<String> used, String slug, String ext) {
  final base = slug.isEmpty ? 'exercise' : slug;
  var name = '$base.$ext';
  var n = 2;
  while (!used.add(name)) {
    name = '$base-$n.$ext';
    n++;
  }
  return name;
}

const Map<String, String> _fold = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c', 'ß': 'ss',
};

String slugify(String name) {
  final buffer = StringBuffer();
  for (final ch in name.toLowerCase().split('')) {
    final folded = _fold[ch] ?? ch;
    if (RegExp(r'^[a-z0-9]+$').hasMatch(folded)) {
      buffer.write(folded);
    } else {
      buffer.write('-');
    }
  }
  return buffer
      .toString()
      .replaceAll(RegExp('-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
