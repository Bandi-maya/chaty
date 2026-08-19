import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/conversation.dart';
import '../../data/repositories/mock_data_store.dart';

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
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late List<String> _selectedAssigneeIds;
  late TaskPriority _priority;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleCtrl = TextEditingController(text: task?.title ?? widget.initialTitle ?? '');
    _descCtrl = TextEditingController(text: task?.description ?? '');
    _selectedAssigneeIds = task?.assigneeIds.toList() ?? [widget.dataStore.currentUser.id];
    _priority = task?.priority ?? TaskPriority.medium;
    _dueDate = task?.dueAt ?? DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _saveTask() {
    if (_titleCtrl.text.trim().isEmpty) return;

    if (widget.existingTask != null) {
      // Update
      widget.dataStore.updateTaskStatus(widget.existingTask!.id, widget.existingTask!.status);
    } else {
      widget.dataStore.createTask(
        sourceConversationId: widget.sourceConversationId,
        sourceMessageId: widget.sourceMessageId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        assigneeIds: _selectedAssigneeIds,
        priority: _priority,
        dueAt: _dueDate,
        labels: ['In-Chat', 'Workflow'],
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${_titleCtrl.text.trim()}" saved and linked!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final currentUser = widget.dataStore.currentUser;
    final conv = widget.dataStore.conversations.firstWhere(
      (c) => c.id == widget.sourceConversationId,
      orElse: () => Conversation(
        id: widget.sourceConversationId,
        type: ConversationType.direct,
        title: 'Chat',
        participantIds: [currentUser.id],
        lastMessageText: '',
        lastMessageTime: DateTime.now(),
        lastMessageSenderId: currentUser.id,
      ),
    );

    // Filter candidate assignees: only users participating in this specific conversation
    final candidateAssignees = conv.participantIds
        .where((id) => id != currentUser.id)
        .map((id) => widget.dataStore.getUser(id))
        .whereType<UserProfile>()
        .toList();


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTask != null ? 'Edit Task' : 'Create Task (/task)',
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: theme.primaryTextColor, fontSize: 14.5),
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(theme.cornerRadius),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Description
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.primaryTextColor, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Description / Instructions',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(theme.cornerRadius),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assignees
              Text(
                'Assign To Participants',
                style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Self
                  FilterChip(
                    label: Text('You (${currentUser.displayName.split(' ')[0]})'),
                    selected: _selectedAssigneeIds.contains(currentUser.id),
                    selectedColor: theme.accentColor.withValues(alpha: 0.25),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAssigneeIds.add(currentUser.id);
                        } else {
                          _selectedAssigneeIds.remove(currentUser.id);
                        }
                      });
                    },
                  ),
                  ...candidateAssignees.map((c) {
                    final isSel = _selectedAssigneeIds.contains(c.id);
                    return FilterChip(
                      label: Text(c.displayName.split(' ')[0]),
                      selected: isSel,
                      selectedColor: theme.accentColor.withValues(alpha: 0.25),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedAssigneeIds.add(c.id);
                          } else {
                            _selectedAssigneeIds.remove(c.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),

              const SizedBox(height: 16),

              // Priority
              Text(
                'Priority',
                style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('Med')),
                  ButtonSegment(value: TaskPriority.high, label: Text('High')),
                  ButtonSegment(value: TaskPriority.urgent, label: Text('Urgent')),
                ],
                selected: {_priority},
                onSelectionChanged: (val) => setState(() => _priority = val.first),
              ),
              const SizedBox(height: 20),

              // Save Action
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(theme.cornerRadius),
                  ),
                ),
                onPressed: _saveTask,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Save and Share in Chat', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
