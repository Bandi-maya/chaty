import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import 'chat_detail_screen.dart';

class NewChatScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final ChatyPreferencesController? preferencesController;

  const NewChatScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    this.preferencesController,
  });

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedGroupMembers = {};
  bool _isCreatingGroup = false;
  final TextEditingController _groupNameCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  void _finishGroupCreation() {
    if (_groupNameCtrl.text.trim().isEmpty || _selectedGroupMembers.isEmpty) return;

    widget.dataStore.createGroup(
      title: _groupNameCtrl.text.trim(),
      memberIds: _selectedGroupMembers.toList(),
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Group "${_groupNameCtrl.text.trim()}" created successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final contacts = widget.dataStore.contacts.where((c) {
      final query = _searchCtrl.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(query) || c.username.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: Text(_isCreatingGroup ? 'New Group (${_selectedGroupMembers.length})' : 'New Chat'),
        actions: [
          if (_isCreatingGroup)
            TextButton(
              onPressed: _selectedGroupMembers.isNotEmpty ? _finishGroupCreation : null,
              child: Text(
                'Create',
                style: TextStyle(
                  color: _selectedGroupMembers.isNotEmpty ? theme.accentColor : theme.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Group Name Input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                if (_isCreatingGroup) ...[
                  TextField(
                    controller: _groupNameCtrl,
                    style: TextStyle(color: theme.primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Enter group subject...',
                      hintStyle: TextStyle(color: theme.secondaryTextColor),
                      filled: true,
                      fillColor: theme.cardColor,
                      prefixIcon: const Icon(Icons.group_work_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(theme.cornerRadius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(color: theme.primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search contacts...',
                    hintStyle: TextStyle(color: theme.secondaryTextColor),
                    filled: true,
                    fillColor: theme.cardColor,
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.cornerRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // New Group CTA button if not currently creating group
          if (!_isCreatingGroup)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add_rounded, color: theme.accentColor, size: 22),
              ),
              title: Text(
                'Create New Group',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5 * theme.fontScale,
                ),
              ),
              subtitle: Text(
                'Add multiple contacts with custom roles',
                style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
              ),
              onTap: () => setState(() => _isCreatingGroup = true),
            ),

          const Divider(height: 1),

          // Contacts List
          Expanded(
            child: ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = contacts[index];
                final isSelected = _selectedGroupMembers.contains(c.id);

                return ListTile(
                  leading: AppAvatar(
                    initials: c.avatarInitials,
                    colorHex: c.avatarColorHex,
                    size: 42,
                    showOnlineBadge: true,
                    presence: c.presence,
                  ),
                  title: Text(
                    c.displayName,
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 14 * theme.fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    c.about,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
                  ),
                  trailing: _isCreatingGroup
                      ? Checkbox(
                          value: isSelected,
                          activeColor: theme.accentColor,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedGroupMembers.add(c.id);
                              } else {
                                _selectedGroupMembers.remove(c.id);
                              }
                            });
                          },
                        )
                      : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  onTap: () {
                    if (_isCreatingGroup) {
                      setState(() {
                        if (isSelected) {
                          _selectedGroupMembers.remove(c.id);
                        } else {
                          _selectedGroupMembers.add(c.id);
                        }
                      });
                    } else {
                      // Open direct chat
                      Navigator.pop(context);
                      // Check if existing conv
                      final existing = widget.dataStore.conversations.firstWhere(
                        (conv) => conv.participantIds.contains(c.id) && conv.participantIds.length == 2,
                        orElse: () => widget.dataStore.conversations.first,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            theme: theme,
                            dataStore: widget.dataStore,
                            conversationId: existing.id,
                            preferencesController: widget.preferencesController ?? ChatyPreferencesController(),
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
