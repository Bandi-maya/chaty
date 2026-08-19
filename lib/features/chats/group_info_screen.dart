import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/mock_data_store.dart';
import '../../data/services/group_management_service.dart';
import '../../ui/core/theme/theme_config.dart';
import '../../ui/core/widgets/app_avatar.dart';

class GroupInfoScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final String conversationId;

  const GroupInfoScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.conversationId,
  });

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupManagementService _groups = GroupManagementService();
  bool _busy = false;
  late String _title;
  late List<String> _participantIds;

  @override
  void initState() {
    super.initState();
    final conversation = widget.dataStore.conversations.firstWhere((c) => c.id == widget.conversationId);
    _title = conversation.title;
    _participantIds = List<String>.from(conversation.participantIds);
  }

  bool get _isAdmin {
    final conversation = widget.dataStore.conversations.where((c) => c.id == widget.conversationId).firstOrNull;
    return conversation?.adminIds.contains(widget.dataStore.currentUser.id) ?? false;
  }

  Future<void> _editTitle() async {
    if (!_isAdmin || _busy) return;
    final controller = TextEditingController(text: _title);
    final next = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit group name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.done,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    final clean = next?.trim() ?? '';
    if (clean.isEmpty || clean == _title || !mounted) return;
    setState(() => _busy = true);
    try {
      await _groups.updateTitle(conversationId: widget.conversationId, title: clean);
      if (!mounted) return;
      setState(() => _title = clean);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addMember() async {
    if (!_isAdmin || _busy) return;
    final available = widget.dataStore.contacts.where((user) => !_participantIds.contains(user.id)).toList(growable: false);
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No additional Chaty contacts are available to add.')));
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          itemCount: available.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = available[index];
            return ListTile(
              leading: AppAvatar(initials: user.avatarInitials, colorHex: user.avatarColorHex, size: 40),
              title: Text(user.displayName),
              subtitle: Text('@${user.username}'),
              onTap: () => Navigator.of(sheetContext).pop(user.id),
            );
          },
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _groups.addMember(conversationId: widget.conversationId, userId: selected);
      if (!mounted) return;
      setState(() {
        if (!_participantIds.contains(selected)) _participantIds.add(selected);
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveGroup() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave group?'),
        content: const Text('You will stop receiving messages from this group. If you are the owner, ownership is transferred to another member when possible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _groups.leaveGroup(widget.conversationId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final conv = widget.dataStore.conversations.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => widget.dataStore.conversations.first,
    );
    final participants = _participantIds.map(widget.dataStore.getUserById).whereType<dynamic>().toList(growable: false);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Group info'),
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: 'Edit group name',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _busy ? null : _editTitle,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(theme.cornerRadius)),
                  child: Column(
                    children: [
                      AppAvatar(initials: conv.avatarInitials ?? 'GP', colorHex: conv.avatarColorHex, size: 72),
                      const SizedBox(height: 14),
                      Text(_title, textAlign: TextAlign.center, style: TextStyle(color: theme.primaryTextColor, fontSize: 18 * theme.fontScale, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('${participants.length} participants', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12.5 * theme.fontScale)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(theme.cornerRadius)),
                  child: ListTile(
                    leading: Icon(Icons.shield_outlined, color: theme.accentColor),
                    title: Text('Message security', style: TextStyle(color: theme.primaryTextColor, fontSize: 14)),
                    subtitle: Text('End-to-end encryption has not been independently verified for this build.', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(theme.cornerRadius)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Participants (${participants.length})', style: TextStyle(color: theme.primaryTextColor, fontSize: 14 * theme.fontScale, fontWeight: FontWeight.bold))),
                          if (_isAdmin)
                            TextButton.icon(onPressed: _busy ? null : _addMember, icon: const Icon(Icons.person_add_outlined, size: 17), label: const Text('Add member')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: participants.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = participants[index];
                          final isAdmin = conv.adminIds.contains(p.id);
                          final isMe = p.id == widget.dataStore.currentUser.id;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: AppAvatar(initials: p.avatarInitials, colorHex: p.avatarColorHex, size: 38),
                            title: Row(
                              children: [
                                Flexible(child: Text(isMe ? '${p.displayName} (You)' : p.displayName, overflow: TextOverflow.ellipsis, style: TextStyle(color: theme.primaryTextColor, fontSize: 13.5 * theme.fontScale, fontWeight: FontWeight.w600))),
                                if (isAdmin) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: theme.accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                    child: Text('Admin', style: TextStyle(color: theme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text('@${p.username}', style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(theme.cornerRadius)),
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app_rounded, color: theme.dangerColor),
                    title: Text('Leave group', style: TextStyle(color: theme.dangerColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    onTap: _busy ? null : _leaveGroup,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: theme.backgroundColor.withValues(alpha: .45),
                child: Center(child: CircularProgressIndicator(color: theme.accentColor)),
              ),
            ),
        ],
      ),
    );
  }
}
