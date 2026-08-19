import 'package:flutter/material.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_notification_service.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/visual_preferences.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/design_system/chaty_settings_primitives.dart';
import '../search/global_search_screen.dart';
import 'chat_detail_screen.dart';
import 'new_chat_screen.dart';

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
  String _selectedFilter = 'All';
  bool _isSearchOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) _searchCtrl.clear();
    });
  }

  void _showShortcutsMenu() {
    final theme = widget.themeController.globalTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Quick Shortcuts',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.qr_code_2_rounded, color: theme.accentColor),
                title: Text(
                  'My Safety Number QR Code',
                  style: TextStyle(color: theme.primaryTextColor),
                ),
                subtitle: Text(
                  'View and share your identity key',
                  style: TextStyle(color: theme.secondaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Safety numbers are available after cryptographic verification.',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.group_add_rounded, color: theme.successColor),
                title: Text(
                  'Create New Group',
                  style: TextStyle(color: theme.primaryTextColor),
                ),
                subtitle: Text(
                  'Start a group conversation',
                  style: TextStyle(color: theme.secondaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NewChatScreen(
                        theme: theme,
                        dataStore: widget.dataStore,
                        preferencesController: widget.preferencesController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.shield_moon_rounded, color: theme.accentColor),
                title: Text(
                  'Instant Ghost Lock',
                  style: TextStyle(color: theme.primaryTextColor),
                ),
                subtitle: Text(
                  'Hide previews and activate ghost privacy options',
                  style: TextStyle(color: theme.secondaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.preferencesController.updateHome(
                    widget.preferencesController.home.copyWith(ghostMode: true),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final difference = DateTime(now.year, now.month, now.day).difference(
      DateTime(local.year, local.month, local.day),
    );
    if (difference.inDays == 0) {
      final hour = local.hour.toString().padLeft(2, '0');
      final min = local.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }
    if (difference.inDays == 1) return 'Yesterday';
    return '${local.day}/${local.month}';
  }

  String _formatLastSeen(UserProfile? user) {
    if (user == null) return '';
    if (user.presence == PresenceState.online) return 'Online';
    final local = user.lastSeenAt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final days = today.difference(day).inDays;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (days == 0) return 'Last seen $time';
    if (days == 1) return 'Last seen yesterday $time';
    return 'Last seen ${local.day}/${local.month} $time';
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.themeController.globalTheme;
    final dataStore = widget.dataStore;
    final homePrefs = widget.preferencesController.home;
    final visual = widget.preferencesController.visual;
    final topProfile = _TopBarProfile.fromStyle(visual.topBarStyle);

    final allConversations = dataStore.conversations.where((conversation) {
      final query = _searchCtrl.text.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          conversation.title.toLowerCase().contains(query) ||
          conversation.lastMessageText.toLowerCase().contains(query);
      if (!matchesQuery) return false;
      if (_selectedFilter == 'Unread') return conversation.unreadCount > 0;
      if (_selectedFilter == 'Groups') {
        return conversation.type == ConversationType.group;
      }
      if (_selectedFilter == 'Direct') {
        return conversation.type == ConversationType.direct;
      }
      if (homePrefs.separateChatsAndGroups) {
        return conversation.type == ConversationType.group;
      }
      return true;
    }).toList();

    final pinned = allConversations
        .where((conversation) => conversation.isPinned && !conversation.isArchived)
        .toList();
    final recent = allConversations
        .where((conversation) => !conversation.isPinned && !conversation.isArchived)
        .toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                topProfile.horizontalPadding,
                topProfile.verticalPadding,
                topProfile.horizontalPadding,
                4,
              ),
              child: Container(
                constraints: BoxConstraints(minHeight: topProfile.height),
                padding: EdgeInsets.symmetric(
                  horizontal: topProfile.innerPadding,
                  vertical: topProfile.compact ? 2 : 5,
                ),
                decoration: BoxDecoration(
                  color: topProfile.filled ? theme.surfaceColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(topProfile.radius),
                  border: topProfile.outlined
                      ? Border.all(
                          color: theme.secondaryTextColor.withValues(alpha: 0.16),
                        )
                      : null,
                  boxShadow: topProfile.elevated
                      ? <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: theme.brightness == Brightness.dark ? 0.22 : 0.07,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : const <BoxShadow>[],
                ),
                child: Row(
                  children: <Widget>[
                    if (topProfile.centered) const Spacer(),
                    Text(
                      'Chaty',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: topProfile.largeTitle
                            ? 28 * theme.fontScale
                            : 23 * theme.fontScale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    if (homePrefs.showCameraIcon)
                      _TopAction(
                        icon: Icons.camera_alt_outlined,
                        tooltip: 'Camera',
                        theme: theme,
                        pill: topProfile.pillActions,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Camera capture is available from status and attachments.'),
                            ),
                          );
                        },
                      ),
                    _TopAction(
                      icon: Icons.qr_code_scanner_rounded,
                      tooltip: 'QR & Shortcuts',
                      theme: theme,
                      pill: topProfile.pillActions,
                      onPressed: _showShortcutsMenu,
                    ),
                    _TopAction(
                      icon: _isSearchOpen ? Icons.close_rounded : Icons.search_rounded,
                      tooltip: _isSearchOpen ? 'Close search' : 'Search chats',
                      theme: theme,
                      pill: topProfile.pillActions,
                      onPressed: _toggleSearch,
                    ),
                    _TopAction(
                      icon: theme.brightness == Brightness.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      tooltip: 'Toggle light / dark mode',
                      theme: theme,
                      pill: topProfile.pillActions,
                      onPressed: widget.themeController.toggleBrightness,
                    ),
                    if (topProfile.centered) const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: _isSearchOpen
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: theme.primaryTextColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search chats, contacts, or messages…',
                          hintStyle: TextStyle(color: theme.secondaryTextColor),
                          filled: true,
                          fillColor: theme.surfaceColor,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.secondaryTextColor,
                            size: 20,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (homePrefs.enableStoriesStrip) ...<Widget>[
              SizedBox(
                height: 86,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: dataStore.contacts.length,
                  itemBuilder: (context, index) {
                    final contact = dataStore.contacts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.accentColor.withValues(alpha: 0.7),
                                width: 2,
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
                          SizedBox(
                            width: 58,
                            child: Text(
                              contact.displayName.split(' ').first,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11 * theme.fontScale,
                                color: theme.secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Row(
                  children: <Widget>[
                    for (final filter in const <String>['All', 'Unread', 'Groups', 'Direct'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _selectedFilter == filter,
                          selectedColor: theme.accentColor.withValues(alpha: 0.18),
                          backgroundColor: theme.cardColor,
                          labelStyle: TextStyle(
                            color: _selectedFilter == filter
                                ? theme.accentColor
                                : theme.secondaryTextColor,
                            fontWeight: _selectedFilter == filter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedFilter = filter);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: allConversations.isEmpty
                  ? _EmptyChats(
                      theme: theme,
                      onDiscover: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GlobalSearchScreen(
                              theme: theme,
                              dataStore: dataStore,
                              preferencesController: widget.preferencesController,
                              themeController: widget.themeController,
                            ),
                          ),
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      children: <Widget>[
                        if (pinned.isNotEmpty) ...<Widget>[
                          _SectionLabel(
                            label: 'PINNED CHATS',
                            theme: theme,
                            accent: true,
                          ),
                          ...pinned.map(
                            (conversation) => _buildConversationTile(
                              context,
                              conversation,
                              theme,
                              dataStore,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (recent.isNotEmpty) ...<Widget>[
                          if (pinned.isNotEmpty)
                            _SectionLabel(label: 'ALL MESSAGES', theme: theme),
                          ...recent.map(
                            (conversation) => _buildConversationTile(
                              context,
                              conversation,
                              theme,
                              dataStore,
                            ),
                          ),
                        ],
                        const SizedBox(height: 90),
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
            MaterialPageRoute<void>(
              builder: (_) => NewChatScreen(
                theme: theme,
                dataStore: dataStore,
                preferencesController: widget.preferencesController,
              ),
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
    final otherUser =
        otherParticipant.isNotEmpty ? dataStore.getUser(otherParticipant) : null;
    final isOnline = otherUser?.presence == PresenceState.online;
    final presenceText = conversation.type == ConversationType.direct
        ? _formatLastSeen(otherUser)
        : '${conversation.participantIds.length} members';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: conversation.isPinned
            ? theme.cardColor.withValues(alpha: 0.92)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: conversation.isPinned
            ? Border.all(
                color: theme.accentColor.withValues(alpha: 0.22),
              )
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailScreen(
                conversationId: conversation.id,
                theme: theme,
                dataStore: dataStore,
                preferencesController: widget.preferencesController,
                themeController: widget.themeController,
              ),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        leading: Stack(
          children: <Widget>[
            ChatyAvatar(
              initials: conversation.avatarInitials ??
                  conversation.title.characters.take(2).toString().toUpperCase(),
              color: conversation.avatarColorHex != null
                  ? Color(int.parse(conversation.avatarColorHex!))
                  : theme.accentColor,
              size: 50,
              shape: homePrefs.avatarShape,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.backgroundColor, width: 2.5),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                conversation.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 15 * theme.fontScale,
                  fontWeight: conversation.unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? theme.accentColor
                    : theme.secondaryTextColor,
                fontSize: 11.5,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    conversation.lastMessageText.isEmpty
                        ? 'Start a conversation'
                        : conversation.lastMessageText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: conversation.unreadCount > 0
                          ? theme.primaryTextColor
                          : theme.secondaryTextColor,
                      fontSize: 13 * theme.fontScale,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
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
                      style: TextStyle(
                        color: theme.onAccentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (presenceText.isNotEmpty) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                presenceText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOnline ? theme.successColor : theme.secondaryTextColor,
                  fontSize: 10.5 * theme.fontScale,
                  fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final ThemeConfig theme;
  final bool pill;
  final VoidCallback onPressed;

  const _TopAction({
    required this.icon,
    required this.tooltip,
    required this.theme,
    required this.pill,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton(
        icon: Icon(icon, size: 21),
        color: theme.primaryTextColor,
        tooltip: tooltip,
        style: pill
            ? IconButton.styleFrom(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              )
            : null,
        onPressed: onPressed,
      ),
    );
  }
}

class _TopBarProfile {
  final bool filled;
  final bool outlined;
  final bool elevated;
  final bool compact;
  final bool centered;
  final bool largeTitle;
  final bool pillActions;
  final double height;
  final double radius;
  final double horizontalPadding;
  final double verticalPadding;
  final double innerPadding;

  const _TopBarProfile({
    required this.filled,
    required this.outlined,
    required this.elevated,
    required this.compact,
    required this.centered,
    required this.largeTitle,
    required this.pillActions,
    required this.height,
    required this.radius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.innerPadding,
  });

  factory _TopBarProfile.fromStyle(String style) {
    final index = VisualPreferences.topBarStyles.indexOf(style).clamp(0, 19);
    return _TopBarProfile(
      filled: <int>{4, 6, 8, 12, 14, 15, 16, 18, 19}.contains(index),
      outlined: <int>{5, 11, 14, 15, 18}.contains(index),
      elevated: <int>{4, 12, 14, 16, 19}.contains(index),
      compact: <int>{1, 2, 7, 17, 18}.contains(index),
      centered: <int>{3, 9, 14}.contains(index),
      largeTitle: <int>{9, 10, 13}.contains(index),
      pillActions: <int>{8, 14, 15, 17}.contains(index),
      height: <int>{2, 7, 17}.contains(index) ? 48 : 56,
      radius: <int>{4, 6, 14, 15, 16}.contains(index) ? 22 : 14,
      horizontalPadding: <int>{13, 19}.contains(index) ? 8 : 16,
      verticalPadding: <int>{2, 7}.contains(index) ? 4 : 8,
      innerPadding: <int>{1, 2, 13}.contains(index) ? 2 : 6,
    );
  }
}

class _EmptyChats extends StatelessWidget {
  final ThemeConfig theme;
  final VoidCallback onDiscover;

  const _EmptyChats({required this.theme, required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
              'Discover another Chaty account by @username or create a group.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onDiscover,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Discover by @username'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeConfig theme;
  final bool accent;

  const _SectionLabel({
    required this.label,
    required this.theme,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: accent ? theme.accentColor : theme.secondaryTextColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
