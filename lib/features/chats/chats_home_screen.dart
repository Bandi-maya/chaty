import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../data/services/chaty_notification_service.dart';
import '../../ui/core/design_system/chaty_settings_primitives.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';
import '../search/global_search_screen.dart';


class ChatsHomeScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final ChatyPreferencesController preferencesController;
  final ThemeController themeController;
  final ChatyNotificationService notificationService;

  const ChatsHomeScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.preferencesController,
    required this.themeController,
    required this.notificationService,
  });

  @override
  State<ChatsHomeScreen> createState() => _ChatsHomeScreenState();
}

class _ChatsHomeScreenState extends State<ChatsHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter = 'All'; // 'All', 'Unread', 'Groups', 'Direct'
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showShortcutsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Quick Shortcuts', style: TextStyle(color: widget.theme.primaryTextColor, fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.qr_code_2_rounded, color: Colors.blueAccent),
                  title: const Text('My Safety Number QR Code'),
                  subtitle: const Text('View and share your identity key'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safety Number: 58291 04928 11948 29384')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add_rounded, color: Colors.greenAccent),
                  title: const Text('Create New Group'),
                  subtitle: const Text('Start an encrypted group conversation'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewChatScreen(theme: widget.theme, dataStore: widget.dataStore, preferencesController: widget.preferencesController)));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: Colors.purpleAccent),
                  title: const Text('Instant Ghost Lock'),
                  subtitle: const Text('Hide previews and activate ghost security'),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.preferencesController.updateHome(widget.preferencesController.home.copyWith(ghostMode: true));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ghost Mode activated.')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    } else if (now.difference(dt).inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeController.globalTheme;
    final dataStore = widget.dataStore;
    final homePrefs = widget.preferencesController.home;

    final allConversations = dataStore.conversations.where((c) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchQuery = query.isEmpty ||
          c.title.toLowerCase().contains(query) ||
          c.lastMessageText.toLowerCase().contains(query);

      if (!matchQuery) return false;

      if (_selectedFilter == 'Unread') return c.unreadCount > 0;
      if (_selectedFilter == 'Groups' || homePrefs.separateChatsAndGroups) return c.type == ConversationType.group;
      if (_selectedFilter == 'Direct') return c.type == ConversationType.direct;
      return true; // All
    }).toList();

    final pinned = allConversations.where((c) => c.isPinned && !c.isArchived).toList();
    final recent = allConversations.where((c) => !c.isPinned && !c.isArchived).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Chaty',
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 24 * theme.fontScale,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (homePrefs.showCameraIcon)
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Camera',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quick camera launch simulation')),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'QR & Shortcuts',
                    onPressed: _showShortcutsMenu,
                  ),
                  IconButton(
                    icon: Icon(_isSearchOpen ? Icons.close_rounded : Icons.search_rounded),
                    tooltip: 'Search Chats',
                    onPressed: () {
                      setState(() {
                        _isSearchOpen = !_isSearchOpen;
                        if (!_isSearchOpen) {
                          _searchCtrl.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      theme.brightness == Brightness.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: theme.primaryTextColor,
                    ),
                    tooltip: 'Toggle Dark / Light Mode',
                    onPressed: () {
                      widget.themeController.toggleBrightness();
                    },
                  ),
                ],
              ),
            ),

            // Search Bar Input Box (Shown when search icon is clicked)
            if (_isSearchOpen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: theme.primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search chats, contacts, or messages...',
                    hintStyle: TextStyle(color: theme.secondaryTextColor),
                    filled: true,
                    fillColor: theme.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    prefixIcon: Icon(Icons.search, color: theme.secondaryTextColor, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchCtrl.clear()),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // Instagram-like Stories Strip
            if (homePrefs.enableStoriesStrip) ...[
              SizedBox(
                height: 86,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: dataStore.contacts.length,
                  itemBuilder: (context, idx) {
                    final contact = dataStore.contacts[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.pinkAccent, Colors.purpleAccent, Colors.amberAccent],
                              ),
                            ),
                            child: ChatyAvatar(
                              initials: contact.avatarInitials,
                              color: Color(int.parse(contact.avatarColorHex)),
                              size: 48,
                              shape: homePrefs.avatarShape,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.displayName.split(' ').first,
                            style: TextStyle(
                              fontSize: 11 * theme.fontScale,
                              color: theme.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Search Bar
            if (homePrefs.showSearchBar)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() {}),
                  style: TextStyle(color: theme.primaryTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search chats and messages...',
                    hintStyle: TextStyle(color: theme.secondaryTextColor.withValues(alpha: 0.8), fontSize: 13.5),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.secondaryTextColor, size: 20),
                    filled: true,
                    fillColor: theme.cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(theme.cornerRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // Filter Chips Row (Left-aligned)
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 2.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: ['All', 'Unread', 'Groups', 'Direct'].map((filter) {
                    final isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSel,
                        selectedColor: theme.accentColor.withValues(alpha: 0.25),
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: isSel ? theme.accentColor : theme.secondaryTextColor,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Chat List
            Expanded(
              child: allConversations.isEmpty
                  ? Center(
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
                                Icons.chat_bubble_outline_rounded,
                                size: 54,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Search for any user by @username or create a new group to start communicating.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.secondaryTextColor,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => GlobalSearchScreen(
                                      theme: theme,
                                      dataStore: dataStore,
                                      preferencesController: widget.preferencesController,
                                      themeController: widget.themeController,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.search_rounded, size: 18),
                              label: const Text('Discover by @username'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.accentColor,
                                foregroundColor: theme.onAccentColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),

                      children: [
                        if (pinned.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(Icons.push_pin_rounded, size: 14, color: theme.accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  'PINNED CHATS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: theme.accentColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...pinned.map((c) => _buildConversationTile(context, c, theme, dataStore)),
                          const SizedBox(height: 8),
                        ],
                        if (recent.isNotEmpty) ...[
                          if (pinned.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                              child: Text(
                                'ALL MESSAGES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.secondaryTextColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ...recent.map((c) => _buildConversationTile(context, c, theme, dataStore)),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.accentColor,
        foregroundColor: theme.onAccentColor,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NewChatScreen(theme: theme, dataStore: dataStore),
            ),
          );
        },
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    ThemeConfig theme,
    MockDataStore dataStore,
  ) {
    final homePrefs = widget.preferencesController.home;
    final otherParticipant = conversation.participantIds.firstWhere(
      (id) => id != dataStore.currentUser.id,
      orElse: () => '',
    );
    final otherUser = otherParticipant.isNotEmpty ? dataStore.getUser(otherParticipant) : null;
    final isOnline = otherUser?.presence == PresenceState.online;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: conversation.isPinned ? theme.cardColor.withValues(alpha: 0.9) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: conversation.isPinned ? Border.all(color: theme.accentColor.withValues(alpha: 0.25), width: 1) : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                conversationId: conversation.id,
                theme: theme,
                dataStore: dataStore,
                preferencesController: widget.preferencesController,
                themeController: widget.themeController,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        leading: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ChatyAvatar(
                initials: conversation.avatarInitials ?? conversation.title.characters.take(2).toString().toUpperCase(),
                color: conversation.avatarColorHex != null ? Color(int.parse(conversation.avatarColorHex!)) : theme.accentColor,
                size: 50,
                shape: homePrefs.avatarShape,
              ),
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.backgroundColor, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.title,
              style: TextStyle(
                color: theme.primaryTextColor,
                fontSize: 15 * theme.fontScale,
                fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              color: conversation.unreadCount > 0 ? theme.accentColor : theme.secondaryTextColor,
              fontSize: 12,
              fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessageText,
                style: TextStyle(
                  color: conversation.unreadCount > 0 ? theme.primaryTextColor : theme.secondaryTextColor,
                  fontSize: 13 * theme.fontScale,
                  fontWeight: conversation.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



