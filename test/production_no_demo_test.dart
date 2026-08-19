import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production source contains no seeded demo account flow', () {
    final lib = Directory('lib');
    expect(lib.existsSync(), isTrue);

    final forbidden = <String>[
      'DemoAccountChooserScreen',
      'Choose Demo Account',
      'Select a demo account to explore Chaty',
      'user_bandi_maya',
      'user_lisa_kim',
      'user_raj_patel',
      'user_sofia_garcia',
      'bandi.maya@example.com',
      'lisa.kim@example.com',
      'raj.patel@example.com',
      'sofia.garcia@example.com',
    ];

    final violations = <String>[];
    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final marker in forbidden) {
        if (source.contains(marker)) {
          violations.add('${entity.path}: $marker');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Production source must not contain seeded/demo account identities or the old demo chooser. Found: ${violations.join(', ')}',
    );
  });
}
