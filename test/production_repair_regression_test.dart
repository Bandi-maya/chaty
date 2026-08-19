import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outgoing messages are optimistic and chat listens for changes', () {
    final store = File('lib/data/repositories/mock_data_store.dart').readAsStringSync();
    final chat = File('lib/features/chats/chat_detail_screen.dart').readAsStringSync();

    expect(store, contains('_optimisticMessages'));
    expect(store, contains('DeliveryState.sending'));
    expect(store, contains("id: optimisticId"));
    expect(chat, contains('widget.dataStore.addListener(_onDataStoreChanged)'));
    expect(chat, contains('widget.dataStore.removeListener(_onDataStoreChanged)'));
    expect(chat, contains("message.id.startsWith('local_')"));
  });

  test('login accepts username or email through secure resolver', () {
    final login = File('lib/features/auth/login_screen.dart').readAsStringSync();
    final migration = File('supabase/migrations/20260820023700_secure_username_login_resolution.sql').readAsStringSync();

    expect(login, contains('Username or email'));
    expect(login, contains("'resolve_login_email'"));
    expect(migration, contains('security definer'));
    expect(migration, contains('encrypted_password = extensions.crypt'));
  });

  test('status screen renders enriched profile identity', () {
    final service = File('lib/data/services/status_service.dart').readAsStringSync();
    final updates = File('lib/features/updates/updates_screen.dart').readAsStringSync();

    expect(service, contains('final String displayName;'));
    expect(service, contains(".select('id,display_name,avatar_initials,avatar_color_hex')"));
    expect(service, contains(".inFilter('id', missing)"));
    expect(updates, contains('_ownerName(status)'));
    expect(updates, contains('_ownerInitials(status)'));
  });

  test('settings expose account actions and canonical component selector', () {
    final settings = File('lib/features/settings/settings_screen.dart').readAsStringSync();
    final conversation = File('lib/features/settings/conversation/conversation_settings_page.dart').readAsStringSync();

    expect(settings, contains("_sectionLabel(context, 'ACCOUNT')"));
    expect(settings, contains("'Edit profile'"));
    expect(settings, contains("'Log out'"));
    expect(settings, contains("'Component templates'"));
    expect(conversation, contains('UniversalAppearanceScreen'));
    expect(conversation, isNot(contains('static const List<String> _bubbleShapes')));
    expect(conversation, isNot(contains('static const List<String> _tickStyles')));
  });

  test('default UI readability is larger than legacy baseline', () {
    final theme = File('lib/ui/core/theme/theme_controller.dart').readAsStringSync();
    expect(theme, contains('_defaultFontScale = 1.06'));
    expect(theme, contains('_defaultDensity = 1.04'));
  });
}
