import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runtime theme keeps selected base theme separate from semantic override', () {
    final source = File('lib/ui/core/theme/theme_controller.dart').readAsStringSync();
    expect(source, contains('ThemeConfig? _runtimeThemeOverride'));
    expect(source, contains('ThemeConfig get baseTheme => _globalTheme'));
    expect(source, contains('ThemeConfig get globalTheme => _runtimeThemeOverride ?? _globalTheme'));
    expect(source, contains('setRuntimeThemeOverride'));
    expect(source, contains('applyPlatformBrightness'));
  });

  test('app resolves GB semantic theme from the base theme', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('GbThemeOverrides.resolve(_themeController.baseTheme'));
    expect(source, contains('_themeController.setRuntimeThemeOverride(currentTheme)'));
  });

  test('home FAB controls have real runtime consumers', () {
    final source = File('lib/features/chats/chats_home_screen.dart').readAsStringSync();
    for (final key in <String>[
      'hide_fab',
      'ModFabNormalColor',
      'ModFabPressedColor',
      'ModFabTextColor',
    ]) {
      expect(source, contains("'$key'"), reason: '$key must affect the actual home FAB');
    }
    expect(source, contains('floatingActionButton: hideFab'));
    expect(source, contains('splashColor: fabPressed'));
  });

  test('semantic theme bindings cover home, conversation and status colors', () {
    final source = File('lib/ui/core/gb/gb_theme_overrides.dart').readAsStringSync();
    for (final key in <String>[
      'HomeBarColor',
      'HomeBarText',
      'ModContactNameColor',
      'ModContactStatusColor',
      'ModConTimeColor',
      'ModChatRightBubble',
      'ModChatLeftBubble',
      'ModOnlineColor',
    ]) {
      expect(source, contains("'$key'"));
    }
    expect(source, contains('_ensureContrast'));
    expect(source, contains('4.5'));
  });
}
