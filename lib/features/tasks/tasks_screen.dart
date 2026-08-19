import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../domain/models/chat_task.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/status_badge.dart';
import '../../ui/core/widgets/app_avatar.dart';
import 'task_create_edit_modal.dart';

import '../../injection/locator.dart';
import '../../../ui/core/theme/theme_controller.dart';

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

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedPriorityFilter = 'All'; // 'All', 'Urgent', 'High', 'Med', 'Low'

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

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final dataStore = widget.dataStore;
    final allTasks = dataStore.tasks;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Tasks & Action Items',
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 22 * theme.fontScale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_task_rounded),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => TaskCreateEditModal(
                          theme: theme,
                          dataStore: dataStore,
                          sourceConversationId: dataStore.conversations.first.id,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar (List vs Kanban Board)
            TabBar(
              controller: _tabCtrl,
              labelColor: theme.accentColor,
              unselectedLabelColor: theme.secondaryTextColor,
              indicatorColor: theme.accentColor,
              tabs: const [
                Tab(icon: Icon(Icons.list_alt_rounded, size: 18), text: 'Task List (S-012)'),
                Tab(icon: Icon(Icons.view_kanban_outlined, size: 18), text: 'Kanban Board (S-013)'),
              ],
            ),

            // Filter Chips (Left-aligned)
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 4.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: ['All', 'Urgent', 'High', 'Med', 'Low'].map((p) {
                    final isSel = _selectedPriorityFilter == p;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: isSel,
                        selectedColor: theme.accentColor.withValues(alpha: 0.25),
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: isSel ? theme.accentColor : theme.secondaryTextColor,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedPriorityFilter = p);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Tab View
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildListView(allTasks, theme, dataStore),
                  _buildKanbanView(allTasks, theme, dataStore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<ChatTask> tasks, ThemeConfig theme, MockDataStore dataStore) {
    final filtered = tasks.where((t) {
      if (_selectedPriorityFilter == 'Urgent') return t.priority == TaskPriority.urgent;
      if (_selectedPriorityFilter == 'High') return t.priority == TaskPriority.high;
      if (_selectedPriorityFilter == 'Med') return t.priority == TaskPriority.medium;
      if (_selectedPriorityFilter == 'Low') return t.priority == TaskPriority.low;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.task_alt_rounded,
                  size: 54,
                  color: theme.accentColor,
                ),
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
                'Assign and track action items from your conversations or create one using the + button.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {

        final task = filtered[index];
        final isOverdue = task.isOverdue;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(theme.cornerRadius),
            border: Border.all(
              color: isOverdue ? theme.dangerColor.withValues(alpha: 0.5) : theme.surfaceColor,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge(status: task.status),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: task.priority),
                  const Spacer(),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dangerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: theme.dangerColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                task.title,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 15 * theme.fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13 * theme.fontScale,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  ...task.assigneeIds.map((id) {
                    final contact = dataStore.contacts.firstWhere(
                      (c) => c.id == id,
                      orElse: () => dataStore.contacts.first,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: AppAvatar(
                        initials: contact.avatarInitials,
                        colorHex: contact.avatarColorHex,
                        size: 26,
                      ),
                    );
                  }),
                  const Spacer(),
                  Text(
                    'Due ${task.dueAt.day}/${task.dueAt.month}',
                    style: TextStyle(
                      color: isOverdue ? theme.dangerColor : theme.secondaryTextColor,
                      fontSize: 11.5,
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanView(List<ChatTask> tasks, ThemeConfig theme, MockDataStore dataStore) {
    final columns = [
      {'status': TaskStatus.inbox, 'title': 'Inbox'},
      {'status': TaskStatus.assigned, 'title': 'Assigned'},
      {'status': TaskStatus.inProgress, 'title': 'In Progress'},
      {'status': TaskStatus.completed, 'title': 'Completed'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns.map((col) {
          final status = col['status'] as TaskStatus;
          final title = col['title'] as String;
          final colTasks = tasks.where((t) => t.status == status).toList();

          return Container(
            width: 260,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(theme.cornerRadius),
              border: Border.all(color: theme.surfaceColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        colTasks.length.toString(),
                        style: TextStyle(color: theme.secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...colTasks.map((t) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: TextStyle(
                            color: theme.primaryTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * theme.fontScale,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            PriorityBadge(priority: t.priority),
                            const Spacer(),
                            // Quick status progress
                            InkWell(
                              onTap: () {
                                final nextStatus = status == TaskStatus.inbox
                                    ? TaskStatus.assigned
                                    : status == TaskStatus.assigned
                                        ? TaskStatus.inProgress
                                        : TaskStatus.completed;
                                dataStore.updateTaskStatus(t.id, nextStatus);
                              },
                              child: Icon(Icons.arrow_forward_rounded, size: 14, color: theme.accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
