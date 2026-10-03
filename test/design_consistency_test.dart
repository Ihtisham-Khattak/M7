import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GM-99: the screens and shared widgets stay on the design language. These are ratchets: the
/// numbers can go down, never up. `python3 tool/design_audit.py` prints the full inventory.
void main() {
  final skip = {'body_svg.dart', 'svg_icon.dart', 'washi_texture.dart', 'medal.dart', 'share_cards.dart', 'home_widget_views.dart'};

  Iterable<File> sources() => [
        ...Directory('lib/screens').listSync(recursive: true),
        ...Directory('lib/widgets').listSync(recursive: true),
      ].whereType<File>().where((f) => f.path.endsWith('.dart') && !skip.contains(f.uri.pathSegments.last));

  Iterable<(File, int, String)> codeLines() sync* {
    for (final f in sources()) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('//')) continue;
        yield (f, i + 1, lines[i]);
      }
    }
  }

  test('corner radii come from GymRadius, except hairline painter details under 4px', () {
    final bad = <String>[];
    final re = RegExp(r'(?:BorderRadius|Radius)\.circular\(\s*([0-9]+(?:\.[0-9]+)?)\s*\)');
    for (final (f, n, line) in codeLines()) {
      for (final m in re.allMatches(line)) {
        if (double.parse(m.group(1)!) >= 4) bad.add('${f.path}:$n: ${line.trim()}');
      }
    }
    expect(bad, isEmpty, reason: 'use GymRadius.xs/sm/md/lg/xl/xxl/pill');
  });

  test('font sizes stay on the type scale', () {
    const scale = {'11', '12', '13', '14', '15', '17', '20', '22', '26', '28', '30', '32', '34', '36', '40', '52', '54', '170'};
    final off = <String>[];
    final re = RegExp(r'AppTheme\.[fsd]\(\s*([0-9]+(?:\.[0-9]+)?)');
    for (final (f, n, line) in codeLines()) {
      for (final m in re.allMatches(line)) {
        if (!scale.contains(m.group(1))) off.add('${f.path}:$n: size ${m.group(1)}');
      }
    }
    expect(off, isEmpty, reason: 'snap to the scale or use a GymText role');
  });

  test('literal colours only live where they are content (photos, art, palettes), and their number never grows', () {
    const allowed = {
      'lib/screens/moments_screen.dart': 2,
      'lib/screens/profile_screen.dart': 6,
      'lib/screens/session/set_rows.dart': 1,
      'lib/screens/session/sheets.dart': 1,
      'lib/screens/sticker_screen.dart': 6,
      'lib/screens/timeline_screen.dart': 2,
      'lib/widgets/award_celebration.dart': 7,
      'lib/widgets/body_map.dart': 32,
      'lib/widgets/glass.dart': 5,
      'lib/widgets/liquid_notch.dart': 7,
      'lib/widgets/muscle_radar.dart': 2,
      'lib/widgets/note_kit.dart': 7,
      'lib/widgets/routine_folder.dart': 9,
      'lib/widgets/ruler_picker.dart': 4,
    };
    final re = RegExp(r'Color\(\s*0x[0-9A-Fa-f]{8}\s*\)|Colors\.(?!transparent|length)[a-zA-Z]+');
    final counts = <String, int>{};
    for (final (f, _, line) in codeLines()) {
      final n = re.allMatches(line).length;
      if (n > 0) counts[f.path] = (counts[f.path] ?? 0) + n;
    }
    final grew = [
      for (final e in counts.entries)
        if (e.value > (allowed[e.key] ?? 0)) '${e.key}: ${e.value} (allowed ${allowed[e.key] ?? 0}) - use GymColors tokens',
    ];
    expect(grew, isEmpty);
  });

  test('icons use three weights with fixed jobs: Regular by default, Fill for the active state, Bold for small affordances', () {
    final odd = <String>[];
    final re = RegExp(r'PhosphorIcons(Thin|Light|Duotone)\.');
    for (final (f, n, line) in codeLines()) {
      if (re.hasMatch(line)) odd.add('${f.path}:$n');
    }
    expect(odd, isEmpty);
  });

  test('screens do not hand-roll sheet corners or pill chips any more', () {
    final bad = <String>[];
    for (final (f, n, line) in codeLines()) {
      if (line.contains('Radius.circular(28)') || line.contains('circular(100)')) bad.add('${f.path}:$n');
    }
    expect(bad, isEmpty);
  });
}
