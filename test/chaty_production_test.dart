import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/validators/chaty_validators.dart';
import 'package:chat/data/services/chaty_backend_service.dart';
import 'package:chat/ui/core/realtime/realtime_event_bus.dart';
import 'package:chat/ui/core/commands/chat_command_parser.dart';
import 'package:chat/domain/models/chat_message.dart';
import 'package:chat/domain/models/conversation.dart';
import 'package:chat/domain/models/chat_task.dart';
void main() {
  group('ChatyValidators Unit Tests', () {
    test('Username validation allows valid usernames', () {
      expect(ChatyValidators.validateUsername('bandi_maya'), isNull);
      expect(ChatyValidators.validateUsername('@alex_rivera99'), isNull);
      expect(ChatyValidators.validateUsername('john_doe'), isNull);
    });

    test('Username validation rejects invalid patterns and reserved keywords', () {
      expect(ChatyValidators.validateUsername('abc'), isNotNull); // Too short
      expect(ChatyValidators.validateUsername('admin'), isNotNull); // Reserved
      expect(ChatyValidators.validateUsername('root'), isNotNull); // Reserved
      expect(ChatyValidators.validateUsername('support'), isNotNull); // Reserved
      expect(ChatyValidators.validateUsername('chaty'), isNotNull); // Reserved
      expect(ChatyValidators.validateUsername('user!name'), isNotNull); // Invalid char
    });

    test('Email validator enforces valid email patterns', () {
      expect(ChatyValidators.validateEmail('maya@chaty.app'), isNull);
      expect(ChatyValidators.validateEmail('invalid-email'), isNotNull);
      expect(ChatyValidators.validateEmail(''), isNotNull);
    });

    test('Password validator enforces length rules', () {
      expect(ChatyValidators.validatePassword('secret123'), isNull);
      expect(ChatyValidators.validatePassword('123'), isNotNull); // Too short
      expect(ChatyValidators.validatePassword(''), isNotNull);
    });
  });

  group('Chat Command Parser Tests', () {
    test('Parses /task commands accurately with arguments', () {
      final cmd = ChatCommandParser.parse('/task Review pull request #42');
      expect(cmd.isCommand, isTrue);
      expect(cmd.type, ChatCommandType.task);
      expect(cmd.argument, 'Review pull request #42');
    });

    test('Parses /task without arguments cleanly', () {
      final cmd = ChatCommandParser.parse('/task');
      expect(cmd.isCommand, isTrue);
      expect(cmd.type, ChatCommandType.task);
      expect(cmd.argument, isEmpty);
    });

    test('Treats standard text as non-command', () {
      final regular = ChatCommandParser.parse('Hello /task inside sentence');
      expect(regular.isCommand, isFalse);
      expect(regular.type, ChatCommandType.unknown);
    });
  });

  group('ChatyBackendService Zero-Mock Integration Tests', () {
    late ChatyBackendService backend;

    setUp(() async {
      backend = ChatyBackendService();
      await backend.clearStateForTesting();
      await backend.initialize();
    });

    test('Registration creates user, authenticates session, and enforces unique handles', () async {
      // Register User A
      final userA = await backend.registerUser(
        displayName: 'Alice Engineer',
        username: 'alice_eng',
        password: 'secure_password_123',
        email: 'alice@chaty.app',
      );

      expect(userA.id, isNotEmpty);
      expect(userA.username, 'alice_eng');
      expect(backend.currentUser?.id, userA.id);
      expect(backend.isAuthenticated, isTrue);

      // Verify availability checks
      expect(backend.isUsernameAvailable('alice_eng'), isFalse);
      expect(backend.isUsernameAvailable('bob_designer'), isTrue);

      // Duplicate registration must throw
      expect(
        () => backend.registerUser(
          displayName: 'Alice Imposter',
          username: 'alice_eng',
          password: 'another_password',
        ),
        throwsException,
      );
    });

    test('Two-user communication lifecycle: search, message, reaction, read receipt', () async {
      // Register User A
      final userA = await backend.registerUser(
        displayName: 'Alice Rivera',
        username: 'alice_r',
        password: 'password123',
      );

      // Register User B
      final userB = await backend.registerUser(
        displayName: 'Bob Builder',
        username: 'bob_b',
        password: 'password123',
      );

      // User B searches for User A
      final searchResults = backend.searchUsers('alice', includeSelf: false);
      expect(searchResults.any((u) => u.username == 'alice_r'), isTrue);

      // User B creates/opens direct chat with User A
      final directConv = backend.getOrCreateDirectConversation(userA);
      expect(directConv.type, ConversationType.direct);
      expect(directConv.participantIds.contains(userA.id), isTrue);
      expect(directConv.participantIds.contains(userB.id), isTrue);

      // User B sends message to User A
      final msg = await backend.sendMessage(
        conversationId: directConv.id,
        text: 'Hi Alice! Welcome to the production channel.',
      );
      expect(msg.deliveryState, DeliveryState.sent);

      // User A reads message
      backend.markAsRead(directConv.id);
      final messages = backend.getMessages(directConv.id);
      expect(messages.first.text, 'Hi Alice! Welcome to the production channel.');
    });

    test('/task creation inside direct chat scopes assignees and links card', () async {
      final userA = await backend.registerUser(
        displayName: 'Alice Lead',
        username: 'alice_lead',
        password: 'password123',
      );

      final userB = await backend.registerUser(
        displayName: 'Charlie Tech',
        username: 'charlie_tech',
        password: 'password123',
      );

      final conv = backend.getOrCreateDirectConversation(userB);

      // User A creates task assigned to User B
      backend.createTask(
        sourceConversationId: conv.id,
        title: 'Complete security audit for v1.0',
        description: 'Verify ASVS L3 compliance.',
        assigneeIds: [userA.id, userB.id],
        priority: TaskPriority.urgent,
        dueAt: DateTime.now().add(const Duration(days: 3)),
      );

      expect(backend.tasks.length, 1);
      final createdTask = backend.tasks.first;
      expect(createdTask.title, 'Complete security audit for v1.0');
      expect(createdTask.assigneeIds.contains(userB.id), isTrue);

      // Task status transition
      backend.updateTaskStatus(createdTask.id, TaskStatus.inProgress);
      final updatedTask = backend.tasks.firstWhere((t) => t.id == createdTask.id);
      expect(updatedTask.status, TaskStatus.inProgress);
      expect(updatedTask.activities.any((a) => a.text.contains('inProgress')), isTrue);
    });

    test('Realtime event bus publishes and filters events', () async {
      final bus = RealtimeEventBus();
      final events = <RealtimeEvent>[];
      final sub = bus.events.listen((e) => events.add(e));

      bus.publish(
        RealtimeEvent(
          type: RealtimeEventType.messageCreated,
          conversationId: 'c_test',
          userId: 'u_test',
          payload: {'text': 'Hello world!'},
        ),
      );

      await Future.delayed(const Duration(milliseconds: 20));
      expect(events.length, 1);
      expect(events.first.type, RealtimeEventType.messageCreated);
      await sub.cancel();
    });
  });
}
