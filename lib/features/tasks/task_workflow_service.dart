import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/conversation.dart';

/// Coordinates task mutations and verifies that the server-backed store has
/// actually reflected the requested change before UI success is reported.
class TaskWorkflowService {
  final MockDataStore dataStore;
  final SupabaseClient _client;
  final Uuid _uuid;

  TaskWorkflowService(
    this.dataStore, {
    SupabaseClient? client,
    Uuid uuid = const Uuid(),
  })  : _client = client ?? Supabase.instance.client,
        _uuid = uuid;

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
    final normalizedAssignees = List<String>.unmodifiable(assigneeIds.toSet());
    final clientTaskId = _uuid.v4();

    final raw = await _client.rpc('create_chat_task', params: <String, dynamic>{
      'p_conversation_id': sourceConversationId,
      'p_client_task_id': clientTaskId,
      'p_title': title.trim(),
      'p_assignee_ids': normalizedAssignees,
      'p_priority': _priorityToDatabase(priority),
      'p_due_at': dueAt.toUtc().toIso8601String(),
      'p_description': description.trim(),
      'p_labels': labels,
      'p_source_message_id': sourceMessageId,
    });
    final taskId = _extractTaskId(raw);
    if (taskId.isEmpty) {
      throw Exception('The server did not return a task identifier. Please try again.');
    }

    final task = await _waitForTask(taskId, (candidate) => candidate.sourceConversationId == conversation.id);
    if (task == null) {
      throw Exception('Task creation could not be confirmed from the realtime task feed.');
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
    await _client.rpc('update_chat_task', params: <String, dynamic>{
      'p_task_id': existingTask.id,
      'p_title': title.trim(),
      'p_description': description.trim(),
      'p_assignee_ids': normalizedAssignees,
      'p_priority': _priorityToDatabase(priority),
      'p_due_at': dueAt.toUtc().toIso8601String(),
      'p_labels': existingTask.labels,
    });

    final confirmed = await _waitForTask(
      existingTask.id,
      (task) =>
          task.title == title.trim() &&
          task.description == description.trim() &&
          task.priority == priority &&
          task.dueAt.toUtc().difference(dueAt.toUtc()).inMilliseconds.abs() < 2000 &&
          _sameIds(task.assigneeIds, normalizedAssignees),
    );
    if (confirmed == null) {
      throw Exception('The server accepted the update, but Chaty could not confirm the refreshed task state.');
    }
    return confirmed;
  }

  Future<ChatTask> updateStatus(ChatTask existingTask, TaskStatus status) async {
    if (existingTask.status == status) return existingTask;
    await _client.rpc('update_task_status', params: <String, dynamic>{
      'p_task_id': existingTask.id,
      'p_status': _statusToDatabase(status),
    });
    final confirmed = await _waitForTask(existingTask.id, (task) => task.status == status);
    if (confirmed == null) {
      throw Exception('The task status change could not be confirmed.');
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
      if (source == null) throw Exception('The source message is no longer available in this conversation.');
    }
    return conversation;
  }

  Future<void> _ensureTaskCard(ChatTask task) async {
    final existingCard = dataStore
        .getMessages(task.sourceConversationId)
        .where((message) => message.linkedTaskId == task.id)
        .firstOrNull;
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

  String _extractTaskId(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Map) {
      for (final key in <String>['id', 'task_id', 'taskId']) {
        final value = raw[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return '';
    }
    if (raw is List && raw.isNotEmpty) return _extractTaskId(raw.first);
    return raw.toString().trim();
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b);
  }

  String _priorityToDatabase(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'normal';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  String _statusToDatabase(TaskStatus status) {
    switch (status) {
      case TaskStatus.inbox:
        return 'inbox';
      case TaskStatus.assigned:
        return 'assigned';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.blocked:
        return 'blocked';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.archived:
        return 'archived';
    }
  }
}
