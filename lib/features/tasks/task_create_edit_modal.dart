import 'package:flutter/material.dart';

import '../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user_profile.dart';
import 'task_workflow_service.dart';

class TaskCreateEditModal extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final String sourceConversationId;
  final String? initialTitle;
  final String? sourceMessageId;
  final ChatTask? existingTask;

  const TaskCreateEditModal({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.sourceConversationId,
    this.initialTitle,
    this.sourceMessageId,
    this.existingTask,
  });

  @override
  State<TaskCreateEditModal> createState() => _TaskCreateEditModalState();
}

class _TaskCreateEditModalState extends State<TaskCreateEditModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TaskWorkflowService _workflow;
  late final ChatTask? _editingTask;
  late List<String> _selectedAssigneeIds;
  late TaskPriority _priority;
  late DateTime _dueDate;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _workflow = TaskWorkflowService(widget.dataStore);
    _editingTask = widget.existingTask ??
        _workflow.inferTaskFromMessage(
          conversationId: widget.sourceConversationId,
          messageId: widget.sourceMessageId,
        );
    final task = _editingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? widget.initialTitle ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    _selectedAssigneeIds = task?.assigneeIds.toList() ?? <String>[widget.dataStore.currentUser.id];
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueAt ?? DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_isSaving) return;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _errorMessage = 'Task title is required.');
      return;
    }
    if (_selectedAssigneeIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one assignee.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final ChatTask savedTask;
      if (_editingTask != null) {
        savedTask = await _workflow.update(
          existingTask: _editingTask!,
          title: title,
          description: _descCtrl.text.trim(),
          assigneeIds: _selectedAssigneeIds,
          priority: _priority,
          dueAt: _dueDate,
        );
      } else {
        savedTask = await _workflow.create(
          sourceConversationId: widget.sourceConversationId,
          sourceMessageId: widget.sourceMessageId,
          title: title,
          description: _descCtrl.text.trim(),
          assigneeIds: _selectedAssigneeIds,
          priority: _priority,
          dueAt: _dueDate,
          labels: const <String>['In-Chat', 'Workflow'],
        );
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(savedTask);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _editingTask == null
                ? 'Task "$title" created and linked to this chat.'
                : 'Task "$title" updated.',
          ),
          backgroundColor: widget.theme.successColor,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickDueDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final initial = _dueDate.isBefore(today) ? today : _dueDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 3650)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _dueDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _dueDate.hour,
        _dueDate.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final currentUser = widget.dataStore.currentUser;
    final conv = widget.dataStore.conversations.firstWhere(
      (conversation) => conversation.id == widget.sourceConversationId,
      orElse: () => Conversation(
        id: widget.sourceConversationId,
        type: ConversationType.direct,
        title: 'Chat',
        participantIds: <String>[currentUser.id],
        lastMessageText: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: currentUser.id,
      ),
    );

    final candidateAssignees = conv.participantIds
        .where((id) => id != currentUser.id)
        .map(widget.dataStore.getUser)
        .whereType<UserProfile>()
        .toList();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.secondaryTextColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _editingTask != null ? 'Edit task' : 'Create task',
                      style: TextStyle(color: theme.primaryTextColor, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              if (_editingTask == null) ...[
                Text(
                  'Create an action item for this conversation. You can also type /task followed by a title.',
                  style: TextStyle(color: theme.secondaryTextColor, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _titleCtrl,
                enabled: !_isSaving,
                maxLength: 140,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: theme.primaryTextColor, fontSize: 14.5),
                decoration: InputDecoration(
                  labelText: 'Task title',
                  counterText: '',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.cornerRadius)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 2000,
                style: TextStyle(color: theme.primaryTextColor, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Description / instructions',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(theme.cornerRadius)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Assign to', style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(
                conv.type == ConversationType.group
                    ? 'Choose yourself or any participant in this group.'
                    : 'Choose yourself or the other participant.',
                style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('You (${currentUser.displayName.split(' ').first})'),
                    selected: _selectedAssigneeIds.contains(currentUser.id),
                    selectedColor: theme.accentColor.withValues(alpha: 0.25),
                    onSelected: _isSaving ? null : (selected) => _setAssignee(currentUser.id, selected),
                  ),
                  ...candidateAssignees.map((candidate) {
                    final selected = _selectedAssigneeIds.contains(candidate.id);
                    return FilterChip(
                      label: Text(candidate.displayName.split(' ').first),
                      selected: selected,
                      selectedColor: theme.accentColor.withValues(alpha: 0.25),
                      onSelected: _isSaving ? null : (value) => _setAssignee(candidate.id, value),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
              Text('Priority', style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const <ButtonSegment<TaskPriority>>[
                  ButtonSegment<TaskPriority>(value: TaskPriority.low, label: Text('Low')),
                  ButtonSegment<TaskPriority>(value: TaskPriority.medium, label: Text('Med')),
                  ButtonSegment<TaskPriority>(value: TaskPriority.high, label: Text('High')),
                  ButtonSegment<TaskPriority>(value: TaskPriority.urgent, label: Text('Urgent')),
                ],
                selected: <TaskPriority>{_priority},
                onSelectionChanged: _isSaving ? null : (value) => setState(() => _priority = value.first),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickDueDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  'Due ${_dueDate.day.toString().padLeft(2, '0')}/'
                  '${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.dangerColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: theme.dangerColor, fontSize: 13)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.onAccentColor,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(theme.cornerRadius)),
                ),
                onPressed: _isSaving ? null : _saveTask,
                icon: _isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: theme.onAccentColor),
                      )
                    : Icon(_editingTask == null ? Icons.add_task_rounded : Icons.save_rounded, size: 19),
                label: Text(
                  _isSaving
                      ? (_editingTask == null ? 'Creating…' : 'Saving…')
                      : (_editingTask == null ? 'Create and link to chat' : 'Save changes'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setAssignee(String userId, bool selected) {
    setState(() {
      if (selected) {
        if (!_selectedAssigneeIds.contains(userId)) _selectedAssigneeIds.add(userId);
      } else {
        _selectedAssigneeIds.remove(userId);
      }
    });
  }
}
