import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the session and progress screens stay split into files under 1,000 lines', () {
    final long = <String>[];
    for (final path in [
      ...Directory('lib/screens').listSync().whereType<File>().map((f) => f.path),
      ...Directory('lib/screens/session').listSync().whereType<File>().map((f) => f.path),
      ...Directory('lib/screens/progress').listSync().whereType<File>().map((f) => f.path),
    ]) {
      final name = path.split('/').last;
      final area = path.contains('/session/') || path.contains('/progress/') || name.startsWith('session_') || name.startsWith('progress_');
      if (!area || !path.endsWith('.dart')) continue;
      final lines = File(path).readAsLinesSync().length;
      if (lines > 1000) long.add('$path: $lines lines');
    }
    expect(long, isEmpty, reason: 'add new code to a part file under lib/screens/session or progress');
  });
}
