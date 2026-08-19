import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../domain/models/chaty_preferences.dart';
import '../../../data/repositories/mock_data_store.dart';

class MessageManagementPage extends StatefulWidget {
  final ChatyPreferencesController preferencesController;
  final MockDataStore dataStore;

  const MessageManagementPage({
    super.key,
    required this.preferencesController,
    required this.dataStore,
  });

  @override
  State<MessageManagementPage> createState() => _MessageManagementPageState();
}

class _MessageManagementPageState extends State<MessageManagementPage> {
  void _addAutoReplyRule() {
    final keywordCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Auto-Reply Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keywordCtrl,
              decoration: const InputDecoration(labelText: 'Keyword Trigger', hintText: 'e.g. busy, help'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Auto-Reply Response', hintText: 'Message to send automatically'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (keywordCtrl.text.isNotEmpty && messageCtrl.text.isNotEmpty) {
                final auto = widget.preferencesController.automation;
                final newRules = List<AutoReplyRule>.from(auto.autoReplyRules)
                  ..add(AutoReplyRule(
                    id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                    keyword: keywordCtrl.text.trim(),
                    responseMessage: messageCtrl.text.trim(),
                  ));
                widget.preferencesController.updateAutomation(
                  auto.copyWith(autoReplyRules: newRules),
                  logTitle: 'Add Auto Reply Rule',
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Rule'),
          ),
        ],
      ),
    );
  }

  void _scheduleMessage() {
    String? selectedConvId = widget.dataStore.conversations.isNotEmpty ? widget.dataStore.conversations.first.id : null;
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Schedule Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedConvId,
                decoration: const InputDecoration(labelText: 'Recipient Conversation'),
                items: widget.dataStore.conversations.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(c.title, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) => setDlgState(() => selectedConvId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Message Text', hintText: 'Enter scheduled message'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedConvId != null && textCtrl.text.isNotEmpty) {
                  final conv = widget.dataStore.conversations.firstWhere((c) => c.id == selectedConvId);
                  final auto = widget.preferencesController.automation;
                  final nextSched = List<ScheduledMessageEntry>.from(auto.scheduledMessages)
                    ..add(ScheduledMessageEntry(
                      id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
                      recipientId: conv.id,
                      recipientName: conv.title,
                      text: textCtrl.text.trim(),
                      scheduledAt: DateTime.now().add(const Duration(seconds: 10)), // 10 seconds for demo test
                    ));
                  widget.preferencesController.updateAutomation(
                    auto.copyWith(scheduledMessages: nextSched),
                    logTitle: 'Schedule Message',
                  );
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scheduled message for execution in 10s!')),
                  );
                }
              },
              child: const Text('Schedule (In 10s)'),
            ),
          ],
        ),
      ),
    );
  }

  void _addQuickReply() {
    final shortcutCtrl = TextEditingController(text: '#');
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Quick Reply Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shortcutCtrl,
              decoration: const InputDecoration(labelText: 'Shortcut', hintText: 'e.g. #thanks'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Thank You'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Template Content'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (shortcutCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                final auto = widget.preferencesController.automation;
                final nextList = List<QuickReplyTemplate>.from(auto.quickReplies)
                  ..add(QuickReplyTemplate(
                    shortcut: shortcutCtrl.text.trim(),
                    title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : shortcutCtrl.text.trim(),
                    content: contentCtrl.text.trim(),
                  ));
                widget.preferencesController.updateAutomation(
                  auto.copyWith(quickReplies: nextList),
                  logTitle: 'Add Quick Reply',
                );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auto = widget.preferencesController.automation;

    return ChatySettingsPage(
      title: 'Message Management',
      subtitle: 'Auto-Reply Rules, Scheduler & Quick Replies',
      children: [
        // Auto Reply Rules
        ChatySettingsSection(
          title: 'Auto-Reply Automation',
          description: 'Automatically respond to incoming messages containing specific keywords.',
          children: [
            ChatySwitchTile(
              icon: Icons.reply_all_rounded,
              iconColor: Colors.tealAccent,
              title: 'Enable Auto-Reply Engine',
              subtitle: 'Activate automatic message responses',
              value: auto.enableAutoReply,
              onChanged: (val) {
                widget.preferencesController.updateAutomation(
                  auto.copyWith(enableAutoReply: val),
                  logTitle: 'Enable Auto Reply',
                );
              },
            ),
            ...auto.autoReplyRules.map((rule) {
              return ChatySettingsTile(
                icon: Icons.subtitles_rounded,
                title: 'Trigger: "${rule.keyword}"',
                subtitle: 'Reply: ${rule.responseMessage}',
                badgeText: rule.enabled ? 'ACTIVE' : 'OFF',
                badgeColor: rule.enabled ? Colors.greenAccent : Colors.grey,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () {
                    final nextRules = auto.autoReplyRules.where((r) => r.id != rule.id).toList();
                    widget.preferencesController.updateAutomation(
                      auto.copyWith(autoReplyRules: nextRules),
                      logTitle: 'Delete Rule',
                    );
                  },
                ),
              );
            }),
            ChatySettingsTile(
              icon: Icons.add_circle_outline_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Add New Auto-Reply Rule',
              onTap: _addAutoReplyRule,
            ),
          ],
        ),

        // Message Scheduler
        ChatySettingsSection(
          title: 'Message Scheduler',
          description: 'Schedule messages for automatic execution during runtime.',
          children: [
            ...auto.scheduledMessages.map((entry) {
              return ChatySettingsTile(
                icon: Icons.schedule_rounded,
                iconColor: Colors.amberAccent,
                title: 'To: ${entry.recipientName}',
                subtitle: '"${entry.text}"',
                badgeText: entry.isExecuted ? 'EXECUTED' : 'PENDING',
                badgeColor: entry.isExecuted ? Colors.blueAccent : Colors.amberAccent,
              );
            }),
            ChatySettingsTile(
              icon: Icons.alarm_add_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Schedule New Message',
              subtitle: 'Pick recipient & message text',
              onTap: _scheduleMessage,
            ),
          ],
        ),

        // Quick Reply Templates
        ChatySettingsSection(
          title: 'Quick Reply Templates',
          description: 'Type trigger "#" in composer to access defined quick reply templates.',
          children: [
            ...auto.quickReplies.map((q) {
              return ChatySettingsTile(
                icon: Icons.bolt_rounded,
                iconColor: Colors.purpleAccent,
                title: '${q.shortcut} (${q.title})',
                subtitle: q.content,
              );
            }),
            ChatySettingsTile(
              icon: Icons.add_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              title: 'Add Quick Reply Template',
              onTap: _addQuickReply,
            ),
          ],
        ),
      ],
    );
  }
}
