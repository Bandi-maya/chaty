import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/commands/chat_command_parser.dart';

void main() {
  test('/task parser preserves the task title argument', () {
    final parsed = ChatCommandParser.parse(' /task Prepare release checklist ');
    expect(parsed.type, ChatCommandType.task);
    expect(parsed.argument, 'Prepare release checklist');
  });

  test('task workflow performs real server mutations and confirmation', () {
    final source = File('lib/features/tasks/task_workflow_service.dart').readAsStringSync();
    expect(source, contains("rpc('create_chat_task'"));
    expect(source, contains("rpc('update_chat_task'"));
    expect(source, contains("rpc('update_task_status'"));
    expect(source, contains('_waitForTask('));
    expect(source, contains('_ensureTaskCard('));
    expect(source, contains('linkedTaskId: task.id'));
    expect(source, contains("'p_source_message_id': sourceMessageId"));
  });

  test('task workflow rejects invalid assignee/source combinations', () {
    final source = File('lib/features/tasks/task_workflow_service.dart').readAsStringSync();
    expect(source, contains('not members of this conversation'));
    expect(source, contains('source message is no longer available'));
    expect(source, contains('Due date cannot be in the past'));
  });

  test('task modal does not report success before verified workflow completes', () {
    final source = File('lib/features/tasks/task_create_edit_modal.dart').readAsStringSync();
    final workflowCall = source.indexOf('await _workflow.');
    final successMessage = source.indexOf('created and linked to this chat');
    expect(workflowCall, greaterThanOrEqualTo(0));
    expect(successMessage, greaterThan(workflowCall));
    expect(source, contains('_isSaving = true'));
    expect(source, contains('_isSaving = false'));
  });

  test('tapping an existing task card resolves to edit instead of duplicate create', () {
    final workflow = File('lib/features/tasks/task_workflow_service.dart').readAsStringSync();
    final modal = File('lib/features/tasks/task_create_edit_modal.dart').readAsStringSync();
    expect(workflow, contains('inferTaskFromMessage'));
    expect(workflow, contains('message?.linkedTaskId'));
    expect(modal, contains('widget.existingTask ??'));
    expect(modal, contains('_workflow.inferTaskFromMessage'));
  });

  test('task card title is rendered from authoritative task state', () {
    final source = File('lib/features/messages/message_bubble.dart').readAsStringSync();
    expect(source, contains('message.type == MessageType.taskCard'));
    expect(source, contains('store.tasks'));
    expect(source, contains('message.copyWith(text: task.title)'));
  });

  test('task details exposes confirmed edit flow', () {
    final source = File('lib/features/tasks/task_detail_screen.dart').readAsStringSync();
    expect(source, contains('TaskCreateEditModal('));
    expect(source, contains('existingTask: _task'));
    expect(source, contains('showModalBottomSheet<ChatTask>'));
    expect(source, contains('_task = updated'));
  });
}
