import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final shell = File('lib/app/app_shell.dart').readAsStringSync();
  final body = shell.substring(shell.indexOf('Widget _screen() {'));
  final routes = RegExp(r"case '([a-z-]+)'").allMatches(body.substring(0, body.indexOf('\n  }\n'))).map((m) => m.group(1)!).toSet();

  test('the shell maps the routes we expect', () {
    expect(routes, containsAll(['home', 'progress', 'exercises', 'settings', 'preferences', 'train', 'session']));
    expect(routes.length, greaterThan(15));
  });

  test('no orphaned screens: every route has at least one way in', () {
    final sources = [
      for (final dir in ['lib/state', 'lib/screens', 'lib/widgets', 'lib/app', 'lib/services'])
        for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
          if (f.path.endsWith('.dart')) f.readAsStringSync(),
    ].join('\n');
    final orphans = [
      for (final r in routes)
        if (!RegExp("(pushRoute|_setRoute|resetRoute|route\\s*=)\\(?\\s*'$r'").hasMatch(sources)) r,
    ];
    expect(orphans, isEmpty);
  });

  test('the architecture doc lists every route', () {
    final doc = File('docs/ARCHITECTURE.md').readAsStringSync();
    final missing = [for (final r in routes) if (!doc.contains('`$r`')) r];
    expect(missing, isEmpty);
  });
}
