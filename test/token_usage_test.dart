import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const tokenized = [
    'lib/widgets/ui_kit.dart',
    'lib/widgets/dialogs.dart',
    'lib/widgets/glass.dart',
    'lib/widgets/choice.dart',
    'lib/widgets/components.dart',
  ];

  test('shared widgets take radii, text sizes and paddings from the design tokens', () {
    final literal = <Pattern>[
      RegExp(r'BorderRadius\.circular\(\s*\d'),
      RegExp(r'AppTheme\.[fsd]\(\s*\d'),
      RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]*(?<![\w.])\d+(?:\.\d+)?(?![\w.])(?!\s*\*)'),
    ];
    final offenders = <String>[];
    for (final path in tokenized) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final p in literal) {
          if (line.contains(p) && !RegExp(r'EdgeInsets\.(?:all|symmetric|only|fromLTRB)\([^)]*\b0\b[^.\d]').hasMatch(line)) {
            offenders.add('$path:${i + 1}: ${line.trim()}');
            break;
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'use GymSpace / GymRadius / GymText from lib/theme/tokens.dart');
  });

  test('the token scales stay on the agreed steps', () {
    final src = File('lib/theme/tokens.dart').readAsStringSync();
    for (final name in ['xs = 4', 'sm = 8', 'md = 12', 'lg = 16', 'xl = 20', 'xxl = 24', 'xxxl = 32', 'minTarget = 48']) {
      expect(src, contains(name));
    }
  });
}
