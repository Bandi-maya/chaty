import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_task.dart';
import '../../domain/models/user_profile.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../ui/core/widgets/status_badge.dart';
import 'task_create_edit_modal.dart';

class TaskDetailScreen extends StatefulWidget {
  final ChatTask task;
  final ThemeConfig theme;
  final MockDataStore dataStore;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.theme,
    required this.dataStore,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late ChatTask _task;
  late Future<List<Map<String, dynamic>>> _activityFuture;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _activityFuture = _loadActivity();
  }

  Future<List<Map<String, dynamic>>> _loadActivity() async {
    final rows = await Supabase.instance.client
        .from('task_activity')
        .select('id,user_id,action,created_at')
        .eq('task_id', _task.id)
        .order('created_at', ascending: false);
    return (rows as List)
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Future<void> _editTask() async {
    final updated = await showModalBottomSheet<ChatTask>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskCreateEditModal(
        theme: widget.theme,
        dataStore: widget.dataStore,
        sourceConversationId: _task.sourceConversationId,
        sourceMessageId: _task.sourceMessageId,
        existingTask: _task,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _task = updated;
      _activityFuture = _loadActivity();
    });
  }

  UserProfile? _user(String id) {
    if (id == widget.dataStore.currentUser.id) return widget.dataStore.currentUser;
    return widget.dataStore.getUser(id);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final task = _task;
    final creator = _user(task.creatorId);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.primaryTextColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(task),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        title: const Text('Task details'),
        actions: [
          IconButton(
            tooltip: 'Edit task',
            onPressed: _editTask,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
                border: Border.all(color: theme.surfaceColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusBadge(status: task.status),
                      PriorityBadge(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    task.title,
                    style: TextStyle(color: theme.primaryTextColor, fontSize: 21, height: 1.2, fontWeight: FontWeight.w800),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(task.description, style: TextStyle(color: theme.secondaryTextColor, fontSize: 14, height: 1.45)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _TreeCard(
              theme: theme,
              title: 'Task information',
              children: [
                _TreeLine(theme: theme, keyText: 'Created by', valueText: creator?.displayName ?? task.creatorId),
                _TreeLine(theme: theme, keyText: 'Created', valueText: _formatDate(task.createdAt)),
                _TreeLine(theme: theme, keyText: 'Updated', valueText: _formatDate(task.updatedAt)),
                _TreeLine(theme: theme, keyText: 'Due', valueText: _formatDate(task.dueAt)),
                _TreeLine(theme: theme, keyText: 'Status', valueText: task.status.name),
                _TreeLine(theme: theme, keyText: 'Priority', valueText: task.priority.name),
                if (task.sourceMessageId != null)
                  _TreeLine(theme: theme, keyText: 'Linked message', valueText: task.sourceMessageId!),
                const SizedBox(height: 8),
                Text('Assignees', style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                ...task.assigneeIds.map((id) {
                  final user = _user(id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        AppAvatar(
                          initials: user?.avatarInitials ?? 'CU',
                          colorHex: user?.avatarColorHex ?? '0xFF6366F1',
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user?.displayName ?? id,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: theme.primaryTextColor, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (task.labels.isNotEmpty)
                  _TreeLine(theme: theme, keyText: 'Labels', valueText: task.labels.join(', ')),
              ],
            ),
            const SizedBox(height: 16),
            _TreeCard(
              theme: theme,
              title: 'Activity',
              children: [
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _activityFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(color: theme.accentColor)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Unable to load task activity: ${snapshot.error}',
                          style: TextStyle(color: theme.dangerColor, fontSize: 12),
                        ),
                      );
                    }
                    final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                    if (rows.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('No changes recorded yet.', style: TextStyle(color: theme.secondaryTextColor)),
                      );
                    }
                    return Column(
                      children: rows.map((row) {
                        final userId = row['user_id']?.toString() ?? '';
                        final user = _user(userId);
                        final time = DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
                        return _ActivityRow(
                          theme: theme,
                          userName: user?.displayName ?? userId,
                          action: row['action']?.toString() ?? 'updated task',
                          time: time == null ? '' : _formatDate(time),
                        );
                      }).toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  final ThemeConfig theme;
  final String title;
  final List<Widget> children;

  const _TreeCard({required this.theme, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.cornerRadius),
        border: Border.all(color: theme.surfaceColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(theme.cornerRadius)),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt_rounded, size: 17, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: theme.primaryTextColor, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }
}

class _TreeLine extends StatelessWidget {
  final ThemeConfig theme;
  final String keyText;
  final String valueText;

  const _TreeLine({required this.theme, required this.keyText, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(keyText, style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(valueText, style: TextStyle(color: theme.primaryTextColor, fontSize: 12))),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ThemeConfig theme;
  final String userName;
  final String action;
  final String time;

  const _ActivityRow({required this.theme, required this.userName, required this.action, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(Icons.circle, size: 9, color: theme.accentColor),
              Container(width: 1, height: 34, color: theme.surfaceColor),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w700, fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(action, style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5)),
                if (time.isNotEmpty)
                  Text(time, style: TextStyle(color: theme.secondaryTextColor.withValues(alpha: 0.7), fontSize: 10.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
