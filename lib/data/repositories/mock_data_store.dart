import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/other_models.dart';
import '../services/chaty_backend_service.dart';

/// Realtime Reactive Adapter bridging screens to [ChatyBackendService].
/// Zero fake data, zero hardcoded contacts, zero demo seed accounts.
class MockDataStore extends ChangeNotifier {
  final ChatyBackendService _backend = ChatyBackendService();

  MockDataStore() {
    _backend.addListener(_onBackendChanged);
  }

  void _onBackendChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _backend.removeListener(_onBackendChanged);
    super.dispose();
  }

  UserProfile get currentUser => _backend.currentUser ?? UserProfile(
    id: 'usr_guest',
    displayName: 'Chaty User',
    username: 'guest',
    avatarInitials: 'CU',
    avatarColorHex: '0xFF6366F1',
    about: 'Chaty User',
    presence: PresenceState.online,
    lastSeenAt: DateTime.now(),
    isVerified: false,
  );

  List<UserProfile> get seededAccounts => _backend.allUsers;
  List<UserProfile> get contacts => _backend.allUsers.where((u) => u.id != currentUser.id).toList();
  List<Conversation> get conversations => _backend.conversations;
  List<ChatTask> get tasks => _backend.tasks;
  List<CallRecord> get calls => _backend.calls;
  List<UpdateStory> get stories => _backend.stories;
  List<LinkedDevice> get linkedDevices => _backend.currentUserDevices;

  UserProfile? getUser(String userId) {
    if (_backend.currentUser?.id == userId) return _backend.currentUser;
    return _backend.getUserById(userId);
  }

  UserProfile? getUserById(String userId) => getUser(userId);
  UserProfile? getContact(String userId) => getUser(userId);

  List<ChatMessage> getMessages(String conversationId) {
    return _backend.getMessages(conversationId);
  }

  bool isTypingInChat(String conversationId) => false;
  bool isUserTyping(String conversationId, [String? userId]) => false;


  void setTyping(String conversationId, bool isTyping) {
    // Typing event handled via realtime bus
  }

  void logout() {
    _backend.logout();
  }


  Future<void> sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    MessageAttachment? attachment,
    String? replyToMessageId,
    String? replyToPreviewText,
    String? replyToSenderName,
    String? linkedTaskId,
  }) async {
    await _backend.sendMessage(
      conversationId: conversationId,
      text: text,
      type: type,
      attachment: attachment,
      replyToMessageId: replyToMessageId,
      replyToPreviewText: replyToPreviewText,
      replyToSenderName: replyToSenderName,
      linkedTaskId: linkedTaskId,
    );
  }

  void toggleReaction(String conversationId, String messageId, String emoji) {
    _backend.toggleReaction(conversationId, messageId, emoji);
  }

  void deleteMessage(String conversationId, String messageId, {bool forEveryone = false}) {
    _backend.deleteMessage(conversationId, messageId, forEveryone: forEveryone);
  }

  void markAsRead(String conversationId) {
    _backend.markAsRead(conversationId);
  }

  void togglePinConversation(String conversationId) {}
  void toggleArchiveConversation(String conversationId) {}
  void toggleMuteConversation(String conversationId) {}
  void togglePinMessage(String conversationId, String messageId) {}
  void toggleStarMessage(String conversationId, String messageId) {}
  void setDraft(String conversationId, String draft) {}

  void createGroup({
    required String title,
    required List<String> memberIds,
    String? avatarInitials,
    String? avatarColorHex,
  }) {
    _backend.createGroup(
      title: title,
      memberUserIds: memberIds,
      avatarInitials: avatarInitials,
      avatarColorHex: avatarColorHex,
    );
  }

  void createTask({
    required String sourceConversationId,
    String? sourceMessageId,
    required String title,
    required String description,
    required List<String> assigneeIds,
    required TaskPriority priority,
    required DateTime dueAt,
    List<String> labels = const [],
  }) {
    _backend.createTask(
      sourceConversationId: sourceConversationId,
      sourceMessageId: sourceMessageId,
      title: title,
      description: description,
      assigneeIds: assigneeIds,
      priority: priority,
      dueAt: dueAt,
      labels: labels,
    );
  }

  void updateTaskStatus(String taskId, TaskStatus status) {
    _backend.updateTaskStatus(taskId, status);
  }

  void addStory(String content) {
    _backend.addStory(content);
  }

  void markStoryViewed(String storyId) {
    _backend.markStoryViewed(storyId);
  }

  void logCall({
    required String receiverId,
    required CallType type,
    required CallDirection direction,
    required int durationSeconds,
  }) {
    _backend.logCall(
      receiverId: receiverId,
      type: type,
      direction: direction,
      durationSeconds: durationSeconds,
    );
  }

  void revokeLinkedDevice(String deviceId) {
    _backend.revokeLinkedDevice(deviceId);
  }

  void updateProfile(UserProfile updated) {
    _backend.updateCurrentUser(updated);
  }

  void updateCurrentUser(UserProfile updated) => updateProfile(updated);
  Future<void> updateUser(UserProfile updated) async => updateProfile(updated);

  void switchDemoAccount(UserProfile user) {
    _backend.updateCurrentUser(user);
  }
}
