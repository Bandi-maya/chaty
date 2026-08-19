import 'package:flutter/material.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_task.dart';
import '../../injection/locator.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../ui/core/widgets/status_badge.dart';
import 'task_create_edit_modal.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;

  const TasksScreen({
    super.key,
    required this.theme,
    required this.dataStore,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _selectedPriorityFilter = 'All';

  static const List<_KanbanColumn> _columns = <_KanbanColumn>[
    _KanbanColumn(TaskStatus.inbox, 'Inbox'),
    _KanbanColumn(TaskStatus.assigned, 'Assigned'),
    _KanbanColumn(TaskStatus.inProgress, 'In progress'),
    _KanbanColumn(TaskStatus.blocked, 'Blocked'),
    _KanbanColumn(TaskStatus.completed, 'Completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ChatTask> _filtered(List<ChatTask> tasks) {
    return tasks.where((task) {
      return switch (_selectedPriorityFilter) {
        'Urgent' => task.priority == TaskPriority.urgent,
        'High' => task.priority == TaskPriority.high,
        'Med' => task.priority == TaskPriority.medium,
        'Low' => task.priority == TaskPriority.low,
        _ => true,
      };
    }).toList();
  }

  void _openTask(ChatTask task, ThemeConfig theme) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          theme: theme,
          dataStore: widget.dataStore,
        ),
      ),
    );
  }

  Future<void> _createTask(ThemeConfig theme) async {
    final conversations = widget.dataStore.conversations;
    if (conversations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a conversation before creating a chat-linked task.'),
        ),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TaskCreateEditModal(
        theme: theme,
        dataStore: widget.dataStore,
        sourceConversationId: conversations.first.id,
      ),
    );
  }

  TaskStatus? _adjacentStatus(TaskStatus status, int direction) {
    final index = _columns.indexWhere((column) => column.status == status);
    if (index < 0) return null;
    final next = index + direction;
    if (next < 0 || next >= _columns.length) return null;
    return _columns[next].status;
  }

  void _moveTask(ChatTask task, TaskStatus status) {
    if (task.status == status) return;
    widget.dataStore.updateTaskStatus(task.id, status);
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final dataStore = widget.dataStore;
    final tasks = _filtered(dataStore.tasks);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Tasks & Action Items',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 22 * theme.fontScale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Create task',
                    icon: const Icon(Icons.add_task_rounded),
                    color: theme.primaryTextColor,
                    onPressed: () => _createTask(theme),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              labelColor: theme.accentColor,
              unselectedLabelColor: theme.secondaryTextColor,
              indicatorColor: theme.accentColor,
              tabs: const <Tab>[
                Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Task List'),
                Tab(icon: Icon(Icons.view_kanban_outlined, size: 18), text: 'Kanban'),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: <Widget>[
                    for (final priority
                        in const <String>['All', 'Urgent', 'High', 'Med', 'Low'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(priority),
                          selected: _selectedPriorityFilter == priority,
                          selectedColor: theme.accentColor.withValues(alpha: 0.18),
                          backgroundColor: theme.cardColor,
                          labelStyle: TextStyle(
                            color: _selectedPriorityFilter == priority
                                ? theme.accentColor
                                : theme.secondaryTextColor,
                            fontWeight: _selectedPriorityFilter == priority
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedPriorityFilter = priority);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: <Widget>[
                  _buildListView(tasks, theme, dataStore),
                  _buildKanbanView(tasks, theme, dataStore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
    List<ChatTask> tasks,
    ThemeConfig theme,
    MockDataStore dataStore,
  ) {
    if (tasks.isEmpty) {
      return _EmptyTasks(theme: theme);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(
          task: task,
          theme: theme,
          dataStore: dataStore,
          onTap: () => _openTask(task, theme),
          onMoveLeft: () {
            final status = _adjacentStatus(task.status, -1);
            if (status != null) _moveTask(task, status);
          },
          onMoveRight: () {
            final status = _adjacentStatus(task.status, 1);
            if (status != null) _moveTask(task, status);
          },
          canMoveLeft: _adjacentStatus(task.status, -1) != null,
          canMoveRight: _adjacentStatus(task.status, 1) != null,
        );
      },
    );
  }

  Widget _buildKanbanView(
    List<ChatTask> tasks,
    ThemeConfig theme,
    MockDataStore dataStore,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _columns.map((column) {
          final columnTasks = tasks
              .where((task) => task.status == column.status)
              .toList();
          return DragTarget<ChatTask>(
            onWillAcceptWithDetails: (details) => details.data.status != column.status,
            onAcceptWithDetails: (details) => _moveTask(details.data, column.status),
            builder: (context, candidates, rejects) {
              final highlighted = candidates.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 272,
                constraints: const BoxConstraints(minHeight: 150),
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlighted
                      ? theme.accentColor.withValues(alpha: 0.10)
                      : theme.cardColor.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(theme.cornerRadius),
                  border: Border.all(
                    color: highlighted
                        ? theme.accentColor
                        : theme.secondaryTextColor.withValues(alpha: 0.12),
                    width: highlighted ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            column.title,
                            style: TextStyle(
                              color: theme.primaryTextColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            columnTasks.length.toString(),
                            style: TextStyle(
                              color: theme.secondaryTextColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (columnTasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.secondaryTextColor.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Text(
                          highlighted ? 'Drop task here' : 'No tasks',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.secondaryTextColor,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ...columnTasks.map((task) {
                      final card = _KanbanTaskCard(
                        task: task,
                        theme: theme,
                        onTap: () => _openTask(task, theme),
                        onMoveLeft: () {
                          final status = _adjacentStatus(task.status, -1);
                          if (status != null) _moveTask(task, status);
                        },
                        onMoveRight: () {
                          final status = _adjacentStatus(task.status, 1);
                          if (status != null) _moveTask(task, status);
                        },
                        canMoveLeft: _adjacentStatus(task.status, -1) != null,
                        canMoveRight: _adjacentStatus(task.status, 1) != null,
                      );
                      return LongPressDraggable<ChatTask>(
                        data: task,
                        feedback: Material(
                          color: Colors.transparent,
                          child: SizedBox(
                            width: 248,
                            child: Opacity(opacity: 0.94, child: card),
                          ),
                        ),
                        childWhenDragging: Opacity(opacity: 0.28, child: card),
                        child: card,
                      );
                    }),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final ChatTask task;
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final VoidCallback onTap;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final bool canMoveLeft;
  final bool canMoveRight;

  const _TaskCard({
    required this.task,
    required this.theme,
    required this.dataStore,
    required this.onTap,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.canMoveLeft,
    required this.canMoveRight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(theme.cornerRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.cornerRadius),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.cornerRadius),
            border: Border.all(
              color: task.isOverdue
                  ? theme.dangerColor.withValues(alpha: 0.45)
                  : theme.secondaryTextColor.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  StatusBadge(status: task.status),
                  const SizedBox(width: 7),
                  PriorityBadge(priority: task.priority),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.secondaryTextColor,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.title,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 15 * theme.fontScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (task.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 12.5 * theme.fontScale,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  ...task.assigneeIds.take(4).map((id) {
                    final user = dataStore.getUser(id);
                    return Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: AppAvatar(
                        initials: user?.avatarInitials ?? 'CU',
                        colorHex: user?.avatarColorHex ?? '0xFF6366F1',
                        size: 25,
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    'Due ${task.dueAt.toLocal().day}/${task.dueAt.toLocal().month}',
                    style: TextStyle(
                      color: task.isOverdue
                          ? theme.dangerColor
                          : theme.secondaryTextColor,
                      fontSize: 11,
                      fontWeight: task.isOverdue ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ChevronButton(
                    icon: Icons.chevron_left_rounded,
                    enabled: canMoveLeft,
                    theme: theme,
                    onPressed: onMoveLeft,
                  ),
                  _ChevronButton(
                    icon: Icons.chevron_right_rounded,
                    enabled: canMoveRight,
                    theme: theme,
                    onPressed: onMoveRight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  final ChatTask task;
  final ThemeConfig theme;
  final VoidCallback onTap;
  final VoidCallback onMoveLeft;
  final VoidCallback onMoveRight;
  final bool canMoveLeft;
  final bool canMoveRight;

  const _KanbanTaskCard({
    required this.task,
    required this.theme,
    required this.onTap,
    required this.onMoveLeft,
    required this.onMoveRight,
    required this.canMoveLeft,
    required this.canMoveRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: theme.secondaryTextColor.withValues(alpha: 0.10),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontWeight: FontWeight.w650,
                  fontSize: 12.8 * theme.fontScale,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  PriorityBadge(priority: task.priority),
                  const Spacer(),
                  _ChevronButton(
                    icon: Icons.chevron_left_rounded,
                    enabled: canMoveLeft,
                    theme: theme,
                    onPressed: onMoveLeft,
                  ),
                  _ChevronButton(
                    icon: Icons.chevron_right_rounded,
                    enabled: canMoveRight,
                    theme: theme,
                    onPressed: onMoveRight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final ThemeConfig theme;
  final VoidCallback onPressed;

  const _ChevronButton({
    required this.icon,
    required this.enabled,
    required this.theme,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: theme.accentColor,
      disabledColor: theme.secondaryTextColor.withValues(alpha: 0.28),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final ThemeConfig theme;

  const _EmptyTasks({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.task_alt_rounded, size: 54, color: theme.accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              'No action items yet',
              style: TextStyle(
                color: theme.primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a task from a conversation or use the create button above.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.secondaryTextColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn {
  final TaskStatus status;
  final String title;

  const _KanbanColumn(this.status, this.title);
}
