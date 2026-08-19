import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('settings exposes persistent app icon customization', () {
    final settings = File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final screen = File('lib/features/settings/appearance/app_icon_settings_screen.dart').readAsStringSync();
    final service = File('lib/data/services/chaty_app_icon_service.dart').readAsStringSync();

    expect(settings, contains("'App icon'"));
    expect(settings, contains('AppIconSettingsScreen'));
    expect(screen, contains('Upload your own icon'));
    expect(screen, contains('_AppIconCropScreen'));
    expect(screen, contains('InteractiveViewer'));
    expect(screen, contains('chaty_custom_icon.png'));
    expect(service, contains('SharedPreferences'));
    expect(service, contains("MethodChannel('chaty/app_icon')"));
    expect(service, contains('setLauncherIcon'));
    expect(service, contains('customSelection'));
  });

  test('Android launcher exposes one alias per packaged icon preset', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final activity = File('android/app/src/main/kotlin/com/example/chat/MainActivity.kt').readAsStringSync();

    for (final alias in <String>[
      'DefaultLauncher',
      'BubbleLauncher',
      'MessagesLauncher',
      'SecureLauncher',
      'MinimalLauncher',
      'CallLauncher',
    ]) {
      expect(manifest, contains(alias));
      expect(activity, contains(alias));
    }
    expect(manifest, contains('activity-alias'));
    expect(activity, contains('PackageManager.COMPONENT_ENABLED_STATE_ENABLED'));
    expect(activity, contains('PackageManager.COMPONENT_ENABLED_STATE_DISABLED'));
  });

  test('custom runtime icon limitation is explicit instead of faked', () {
    final screen = File('lib/features/settings/appearance/app_icon_settings_screen.dart').readAsStringSync();
    expect(screen, contains('Android only allows the installed launcher icon'));
    expect(screen, isNot(contains('custom launcher resource updated')));
  });
}
