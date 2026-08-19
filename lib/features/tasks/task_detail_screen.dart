import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/user_profile.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../ui/core/widgets/status_badge.dart';
import 'task_create_edit_modal.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final ThemeConfig theme;
  final MockDataStore dataStore;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.theme,
    required this.dataStore,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _loadingActivity = true;
  String? _activityError;
  List<_ActivityRow> _activity = const <_ActivityRow>[];

  ChatTask? get _task => widget.dataStore.tasks
      .where((task) => task.id == widget.taskId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final raw = await Supabase.instance.client
          .from('task_activity')
          .select('id,user_id,action,created_at')
          .eq('task_id', widget.taskId)
          .order('created_at', ascending: false);
      final rows = (raw as List)
          .map(
            (row) => _ActivityRow.fromMap(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _activity = rows;
        _activityError = null;
        _loadingActivity = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _activityError = error.toString().replaceFirst('PostgrestException', '');
        _loadingActivity = false;
      });
    }
  }

  UserProfile? _user(String id) => widget.dataStore.getUser(id);

  String _personName(String id) {
    if (id == widget.dataStore.currentUser.id) return 'You';
    return _user(id)?.displayName ?? 'Chaty user';
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(TaskStatus status) {
    return switch (status) {
      TaskStatus.inbox => 'Inbox',
      TaskStatus.assigned => 'Assigned',
      TaskStatus.inProgress => 'In progress',
      TaskStatus.blocked => 'Blocked',
      TaskStatus.completed => 'Completed',
      TaskStatus.archived => 'Archived',
    };
  }

  Future<void> _edit(ChatTask task) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskCreateEditModal(
        theme: widget.theme,
        dataStore: widget.dataStore,
        sourceConversationId: task.sourceConversationId,
        existingTask: task,
      ),
    );
    await _loadActivity();
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final theme = widget.theme;
    if (task == null) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: const Text('Task'),
        ),
        body: Center(
          child: Text(
            'This task is no longer available.',
            style: TextStyle(color: theme.secondaryTextColor),
          ),
        ),
      );
    }

    final creator = _user(task.creatorId);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Task details'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(task),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivity,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
                border: Border.all(
                  color: theme.secondaryTextColor.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      StatusBadge(status: task.status),
                      PriorityBadge(priority: task.priority),
                      _MetaPill(
                        icon: Icons.account_tree_outlined,
                        label: _statusLabel(task.status),
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    task.title,
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 21 * theme.fontScale,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (task.description.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 13.5 * theme.fontScale,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Created by',
                    value: creator?.displayName ?? _personName(task.creatorId),
                    theme: theme,
                  ),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Created',
                    value: _formatDate(task.createdAt),
                    theme: theme,
                  ),
                  _DetailRow(
                    icon: Icons.update_rounded,
                    label: 'Last changed',
                    value: _formatDate(task.updatedAt),
                    theme: theme,
                  ),
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Due',
                    value: _formatDate(task.dueAt),
                    theme: theme,
                    danger: task.isOverdue,
                  ),
                  _DetailRow(
                    icon: Icons.forum_outlined,
                    label: 'Source conversation',
                    value: task.sourceConversationId,
                    theme: theme,
                  ),
                  if (task.sourceMessageId != null)
                    _DetailRow(
                      icon: Icons.link_rounded,
                      label: 'Source message',
                      value: task.sourceMessageId!,
                      theme: theme,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ASSIGNEES',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (task.assigneeIds.isEmpty)
              Text(
                'No assignee',
                style: TextStyle(color: theme.secondaryTextColor),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.assigneeIds.map((id) {
                  final user = _user(id);
                  return Container(
                    padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppAvatar(
                          initials: user?.avatarInitials ?? 'CU',
                          colorHex: user?.avatarColorHex ?? '0xFF6366F1',
                          size: 26,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _personName(id),
                          style: TextStyle(
                            color: theme.primaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (task.labels.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Text(
                'LABELS',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: task.labels
                    .map(
                      (label) => Chip(
                        label: Text(label),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'ACTIVITY TREE',
                    style: TextStyle(
                      color: theme.secondaryTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh activity',
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                  onPressed: _loadActivity,
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_loadingActivity)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_activityError != null)
              _ActivityMessage(
                icon: Icons.error_outline_rounded,
                text: 'Activity could not be loaded. Pull to retry.',
                theme: theme,
              )
            else if (_activity.isEmpty)
              _ActivityMessage(
                icon: Icons.account_tree_outlined,
                text: 'No recorded changes yet.',
                theme: theme,
              )
            else
              ...List<Widget>.generate(_activity.length, (index) {
                final activity = _activity[index];
                final user = _user(activity.userId);
                return _ActivityTreeNode(
                  activity: activity,
                  actorName: user?.displayName ?? _personName(activity.userId),
                  actorInitials: user?.avatarInitials ?? 'CU',
                  actorColor: user?.avatarColorHex ?? '0xFF6366F1',
                  isLast: index == _activity.length - 1,
                  theme: theme,
                  formattedDate: _formatDate(activity.createdAt),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow {
  final String id;
  final String userId;
  final String action;
  final DateTime createdAt;

  const _ActivityRow({
    required this.id,
    required this.userId,
    required this.action,
    required this.createdAt,
  });

  factory _ActivityRow.fromMap(Map<String, dynamic> map) => _ActivityRow(
        id: map['id']?.toString() ?? '',
        userId: map['user_id']?.toString() ?? '',
        action: map['action']?.toString() ?? 'Task changed',
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class _ActivityTreeNode extends StatelessWidget {
  final _ActivityRow activity;
  final String actorName;
  final String actorInitials;
  final String actorColor;
  final bool isLast;
  final ThemeConfig theme;
  final String formattedDate;

  const _ActivityTreeNode({
    required this.activity,
    required this.actorName,
    required this.actorInitials,
    required this.actorColor,
    required this.isLast,
    required this.theme,
    required this.formattedDate,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                if (!isLast)
                  Positioned(
                    top: 18,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: theme.secondaryTextColor.withValues(alpha: 0.2),
                    ),
                  ),
                Positioned(
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.backgroundColor, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 20,
                  child: Container(
                    width: 14,
                    height: 1.5,
                    color: theme.secondaryTextColor.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.secondaryTextColor.withValues(alpha: 0.10),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppAvatar(
                    initials: actorInitials,
                    colorHex: actorColor,
                    size: 28,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          activity.action,
                          style: TextStyle(
                            color: theme.primaryTextColor,
                            fontWeight: FontWeight.w650,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$actorName • $formattedDate',
                          style: TextStyle(
                            color: theme.secondaryTextColor,
                            fontSize: 10.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeConfig theme;
  final bool danger;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: danger ? theme.dangerColor : theme.secondaryTextColor),
          const SizedBox(width: 9),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: danger ? theme.dangerColor : theme.primaryTextColor,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeConfig theme;

  const _MetaPill({required this.icon, required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: theme.secondaryTextColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: theme.secondaryTextColor, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeConfig theme;

  const _ActivityMessage({required this.icon, required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: theme.secondaryTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: theme.secondaryTextColor)),
          ),
        ],
      ),
    );
  }
}
