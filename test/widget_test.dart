import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/theme/theme_presets.dart';
import 'package:chat/domain/models/chaty_preferences.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';


import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Theme Engine Tests', () {

    test('Midnight preset loads with dark brightness and valid colors', () {
      final theme = ThemePresets.midnight;
      expect(theme.id, 'midnight');
      expect(theme.hasContrastIssue, isFalse);
    });

    test('High Contrast preset satisfies accessibility ratios', () {
      final theme = ThemePresets.highContrast;
      expect(theme.highContrast, isTrue);
      expect(theme.hasContrastIssue, isFalse);
    });

    test('All presets are registered and accessible', () {
      final presets = ThemePresets.all;
      expect(presets.length, greaterThanOrEqualTo(13));
      for (final p in presets) {
        expect(p.name.isNotEmpty, isTrue);
        expect(p.id.isNotEmpty, isTrue);
      }
    });
  });

  group('Chaty Preferences Domain & State Tests', () {
    test('Default preferences initialize with valid defaults', () {
      final prefs = ChatyPreferencesController();
      expect(prefs.privacy.freezeLastSeen, isFalse);
      expect(prefs.security.isAppLockEnabled, isFalse);
      expect(prefs.home.homeStyle, 'Chaty Default');
      expect(prefs.conversation.bubbleShape, 'Rounded');
      expect(prefs.automation.enableAutoReply, isFalse);
      expect(prefs.effects.pageTransitionStyle, 'Fade Through');
    });

    test('Updating preferences persists in controller state', () {
      final prefs = ChatyPreferencesController();
      prefs.updatePrivacy(prefs.privacy.copyWith(freezeLastSeen: true, antiViewOnce: true));
      expect(prefs.privacy.freezeLastSeen, isTrue);
      expect(prefs.privacy.antiViewOnce, isTrue);

      prefs.updateConversation(prefs.conversation.copyWith(bubbleShape: 'Card', sidebarPosition: 'Left'));
      expect(prefs.conversation.bubbleShape, 'Card');
      expect(prefs.conversation.sidebarPosition, 'Left');
    });

    test('Preferences serialization toMap and fromMap roundtrip', () {
      final original = const PrivacyPreferences(
        freezeLastSeen: true,
        antiDeleteMessages: true,
        antiViewOnce: true,
        showBlueTicksAfterReply: true,
        typingIndicators: false,
      );
      final map = original.toMap();
      final restored = PrivacyPreferences.fromMap(map);
      expect(restored.freezeLastSeen, isTrue);
      expect(restored.antiDeleteMessages, isTrue);
      expect(restored.antiViewOnce, isTrue);
      expect(restored.showBlueTicksAfterReply, isTrue);
      expect(restored.typingIndicators, isFalse);
    });
  });
}
