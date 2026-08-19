import 'package:flutter_test/flutter_test.dart';

import 'package:chat/domain/models/conversation.dart';
import 'package:chat/domain/models/user_profile.dart';
import 'package:chat/domain/models/visual_preferences.dart';
import 'package:chat/ui/core/commands/chat_command_parser.dart';
import 'package:chat/ui/core/realtime/realtime_event_bus.dart';
import 'package:chat/ui/core/theme/theme_presets.dart';
import 'package:chat/ui/core/validators/chaty_validators.dart';

void main() {
  group('ChatyValidators Unit Tests', () {
    test('Username validation allows valid usernames', () {
      expect(ChatyValidators.validateUsername('bandi_maya'), isNull);
      expect(ChatyValidators.validateUsername('@alex_rivera99'), isNull);
      expect(ChatyValidators.validateUsername('john_doe'), isNull);
    });

    test('Username validation rejects invalid patterns and reserved keywords', () {
      expect(ChatyValidators.validateUsername('abc'), isNotNull);
      expect(ChatyValidators.validateUsername('admin'), isNotNull);
      expect(ChatyValidators.validateUsername('root'), isNotNull);
      expect(ChatyValidators.validateUsername('support'), isNotNull);
      expect(ChatyValidators.validateUsername('chaty'), isNotNull);
      expect(ChatyValidators.validateUsername('user!name'), isNotNull);
    });

    test('Email validator enforces valid email patterns', () {
      expect(ChatyValidators.validateEmail('maya@chaty.app'), isNull);
      expect(ChatyValidators.validateEmail('invalid-email'), isNotNull);
      expect(ChatyValidators.validateEmail(''), isNotNull);
    });

    test('Password validator enforces minimum strength', () {
      expect(ChatyValidators.validatePassword('secret123'), isNull);
      expect(ChatyValidators.validatePassword('123'), isNotNull);
      expect(ChatyValidators.validatePassword(''), isNotNull);
    });
  });

  group('Chat Command Parser Tests', () {
    test('Parses /task commands accurately with arguments', () {
      final command = ChatCommandParser.parse('/task Review pull request #42');
      expect(command.isCommand, isTrue);
      expect(command.type, ChatCommandType.task);
      expect(command.argument, 'Review pull request #42');
    });

    test('Parses /task without arguments cleanly', () {
      final command = ChatCommandParser.parse('/task');
      expect(command.isCommand, isTrue);
      expect(command.type, ChatCommandType.task);
      expect(command.argument, isEmpty);
    });

    test('Treats standard text as non-command', () {
      final regular = ChatCommandParser.parse('Hello /task inside sentence');
      expect(regular.isCommand, isFalse);
      expect(regular.type, ChatCommandType.unknown);
    });
  });

  group('Production Appearance Contract Tests', () {
    test('Theme catalogue exposes exactly 20 unique production presets', () {
      expect(ThemePresets.all, hasLength(20));
      expect(
        ThemePresets.all.map((theme) => theme.id).toSet(),
        hasLength(20),
      );
    });

    test('Every visual customization category exposes 20 unique choices', () {
      final categories = <List<String>>[
        VisualPreferences.topBarStyles,
        VisualPreferences.bottomBarStyles,
        VisualPreferences.bubbleStyles,
        VisualPreferences.appIconStyles,
        VisualPreferences.notificationIconStyles,
        VisualPreferences.typographyStyles,
        VisualPreferences.animationStyles,
      ];

      for (final category in categories) {
        expect(category, hasLength(20));
        expect(category.toSet(), hasLength(20));
      }
    });

    test('Visual preferences round-trip persisted selections', () {
      final original = const VisualPreferences().copyWith(
        topBarStyle: VisualPreferences.topBarStyles.last,
        bottomBarStyle: VisualPreferences.bottomBarStyles[7],
        bubbleStyle: VisualPreferences.bubbleStyles[12],
        appIconStyle: VisualPreferences.appIconStyles[4],
        notificationIconStyle: VisualPreferences.notificationIconStyles[8],
        typographyStyle: VisualPreferences.typographyStyles[6],
        entryAnimation: VisualPreferences.animationStyles[14],
        exitAnimation: VisualPreferences.animationStyles[2],
      );

      final restored = VisualPreferences.fromMap(original.toMap());
      expect(restored.topBarStyle, original.topBarStyle);
      expect(restored.bottomBarStyle, original.bottomBarStyle);
      expect(restored.bubbleStyle, original.bubbleStyle);
      expect(restored.typographyStyle, original.typographyStyle);
      expect(restored.entryAnimation, original.entryAnimation);
      expect(restored.exitAnimation, original.exitAnimation);
    });
  });

  group('Production Security Contract Tests', () {
    test('Conversations never claim E2EE by default', () {
      final conversation = Conversation(
        id: 'conversation-id',
        type: ConversationType.direct,
        title: 'Secure chat',
        participantIds: const <String>['a', 'b'],
        lastMessageText: '',
        lastMessageTime: DateTime.utc(2026),
        lastMessageSenderId: 'a',
      );

      expect(
        conversation.encryptionStatus,
        EncryptionStatus.verificationNeeded,
      );
    });

    test('Profiles do not fabricate cryptographic safety numbers', () {
      final profile = UserProfile(
        id: 'user-id',
        displayName: 'User',
        username: 'user_name',
        avatarInitials: 'US',
        avatarColorHex: '0xFF6366F1',
        about: '',
        lastSeenAt: DateTime.utc(2026),
      );

      expect(profile.safetyNumber, isEmpty);
    });

    test('Realtime event bus publishes typed events', () async {
      final bus = RealtimeEventBus();
      final events = <RealtimeEvent>[];
      final subscription = bus.events.listen(events.add);

      bus.publish(
        RealtimeEvent(
          type: RealtimeEventType.messageCreated,
          conversationId: 'conversation-id',
          userId: 'user-id',
          payload: const <String, dynamic>{'text': 'Hello world!'},
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(events, hasLength(1));
      expect(events.single.type, RealtimeEventType.messageCreated);
      expect(events.single.conversationId, 'conversation-id');
      await subscription.cancel();
    });
  });
}
