import 'dart:async';

import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/conversation.dart';

/// Coordinates task mutations and verifies that the server-backed store has
/// actually reflected the requested change before UI success is reported.
class TaskWorkflowService {
  final MockDataStore dataStore;

  const TaskWorkflowService(this.dataStore);

  ChatTask? inferTaskFromMessage({
    required String conversationId,
    required String? messageId,
  }) {
    if (messageId == null || messageId.isEmpty) return null;
    final message = dataStore
        .getMessages(conversationId)
        .where((item) => item.id == messageId)
        .firstOrNull;
    final taskId = message?.linkedTaskId;
    if (taskId == null || taskId.isEmpty) return null;
    return dataStore.tasks.where((task) => task.id == taskId).firstOrNull;
  }

  Future<ChatTask> create({
    required String sourceConversationId,
    String? sourceMessageId,
    required String title,
    required String description,
    required List<String> assigneeIds,
    required TaskPriority priority,
    required DateTime dueAt,
    List<String> labels = const <String>[],
  }) async {
    final conversation = _validateMutation(
      sourceConversationId: sourceConversationId,
      sourceMessageId: sourceMessageId,
      title: title,
      assigneeIds: assigneeIds,
      dueAt: dueAt,
    );

    final task = await dataStore.createTaskAsync(
      sourceConversationId: sourceConversationId,
      sourceMessageId: sourceMessageId,
      title: title.trim(),
      description: description.trim(),
      assigneeIds: List<String>.unmodifiable(assigneeIds.toSet()),
      priority: priority,
      dueAt: dueAt,
      labels: labels,
    );

    if (task.id.isEmpty || task.sourceConversationId != conversation.id) {
      throw Exception('The server did not return a valid task. Please try again.');
    }
    if (sourceMessageId != null && task.sourceMessageId != sourceMessageId) {
      throw Exception('The task was created but the source message was not linked correctly.');
    }

    await _ensureTaskCard(task);
    return task;
  }

  Future<ChatTask> update({
    required ChatTask existingTask,
    required String title,
    required String description,
    required List<String> assigneeIds,
    required TaskPriority priority,
    required DateTime dueAt,
  }) async {
    _validateMutation(
      sourceConversationId: existingTask.sourceConversationId,
      sourceMessageId: existingTask.sourceMessageId,
      title: title,
      assigneeIds: assigneeIds,
      dueAt: dueAt,
    );

    final normalizedAssignees = List<String>.unmodifiable(assigneeIds.toSet());
    await dataStore.updateTaskAsync(
      taskId: existingTask.id,
      title: title.trim(),
      description: description.trim(),
      assigneeIds: normalizedAssignees,
      priority: priority,
      dueAt: dueAt,
      labels: existingTask.labels,
    );

    final confirmed = await _waitForTask(
      existingTask.id,
      (task) =>
          task.title == title.trim() &&
          task.description == description.trim() &&
          task.priority == priority &&
          task.dueAt.toUtc().difference(dueAt.toUtc()).abs() < const Duration(seconds: 2) &&
          _sameIds(task.assigneeIds, normalizedAssignees),
    );
    if (confirmed == null) {
      throw Exception('The server accepted the update, but Chaty could not confirm the refreshed task state.');
    }
    return confirmed;
  }

  Conversation _validateMutation({
    required String sourceConversationId,
    required String? sourceMessageId,
    required String title,
    required List<String> assigneeIds,
    required DateTime dueAt,
  }) {
    if (title.trim().isEmpty) throw Exception('Task title is required.');
    if (title.trim().length > 140) throw Exception('Task title cannot exceed 140 characters.');
    if (assigneeIds.isEmpty) throw Exception('Select at least one assignee.');
    if (dueAt.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      throw Exception('Due date cannot be in the past.');
    }

    final conversation = dataStore.conversations
        .where((item) => item.id == sourceConversationId)
        .firstOrNull;
    if (conversation == null) throw Exception('The source conversation is no longer available.');

    final allowed = <String>{...conversation.participantIds, dataStore.currentUser.id};
    final invalid = assigneeIds.where((id) => !allowed.contains(id)).toList(growable: false);
    if (invalid.isNotEmpty) {
      throw Exception('One or more selected assignees are not members of this conversation.');
    }

    if (sourceMessageId != null && sourceMessageId.isNotEmpty) {
      final source = dataStore
          .getMessages(sourceConversationId)
          .where((message) => message.id == sourceMessageId)
          .firstOrNull;
      // A task-card tap passes its own message id. That is valid even though the
      // task's original sourceMessageId can be null/different.
      if (source == null) throw Exception('The source message is no longer available in this conversation.');
    }
    return conversation;
  }

  Future<void> _ensureTaskCard(ChatTask task) async {
    final timeline = dataStore.getMessages(task.sourceConversationId);
    final existingCard = timeline.where((message) => message.linkedTaskId == task.id).firstOrNull;
    if (existingCard != null) return;

    await dataStore.sendMessage(
      conversationId: task.sourceConversationId,
      text: task.title,
      type: MessageType.taskCard,
      linkedTaskId: task.id,
    );

    final confirmed = dataStore
        .getMessages(task.sourceConversationId)
        .any((message) => message.linkedTaskId == task.id);
    if (!confirmed) {
      throw Exception('Task created, but its chat card could not be confirmed.');
    }
  }

  Future<ChatTask?> _waitForTask(
    String taskId,
    bool Function(ChatTask task) predicate,
  ) async {
    const timeout = Duration(seconds: 6);
    const interval = Duration(milliseconds: 150);
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final task = dataStore.tasks.where((item) => item.id == taskId).firstOrNull;
      if (task != null && predicate(task)) return task;
      await Future<void>.delayed(interval);
    }
    return null;
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b);
  }
}
