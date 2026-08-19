import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all semantic customization groups are normal settings destinations', () {
    final source = File('lib/features/settings/settings_screen.dart').readAsStringSync();
    for (final section in <String>[
      'Privacy & security',
      'Chats & messaging',
      'Appearance & home',
      'Status & stories',
      'Calls',
      'Media & storage',
      'Notifications & presence',
      'Navigation & gestures',
      'Automation & behavior',
    ]) {
      expect(source, contains("_featureSection('$section')"), reason: '$section must be reachable from Settings');
    }
    expect(source, isNot(contains("title: 'Advanced settings'")));
    expect(source, contains("'All customization settings'"));
    expect(source, contains("_sectionLabel(context, 'ACCOUNT')"));
  });

  test('settings and category pages constrain wide layouts and preserve touch sizing', () {
    final root = File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final categories = File('lib/features/settings/gb_features/gb_settings_hub_screen.dart').readAsStringSync();
    expect(root, contains('BoxConstraints(maxWidth: 860)'));
    expect(categories, contains('BoxConstraints(maxWidth: 760)'));
    expect(categories, contains('minTileHeight: 62'));
  });

  test('fake backup success was replaced by a real customization JSON export', () {
    final source = File('lib/features/settings/settings_screen.dart').readAsStringSync();
    expect(source, contains('Clipboard.setData'));
    expect(source, contains("'chaty-settings-v1'"));
    expect(source, isNot(contains('Exported backup package successfully')));
  });
}
