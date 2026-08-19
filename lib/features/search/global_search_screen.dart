import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/conversation.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/services/chaty_backend_service.dart';
import '../../ui/core/design_system/chaty_settings_primitives.dart';
import '../chats/chat_detail_screen.dart';



class GlobalSearchScreen extends StatefulWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final ChatyPreferencesController preferencesController;
  final ThemeController themeController;

  const GlobalSearchScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.preferencesController,
    required this.themeController,
  });

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _matchedUsers = [];
  List<Conversation> _matchedConversations = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matchedUsers = [];
        _matchedConversations = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final backend = ChatyBackendService();
    final users = backend.searchUsers(query, includeSelf: true);
    final convs = backend.conversations.where((c) {
      return c.title.toLowerCase().contains(query.toLowerCase()) ||
             c.lastMessageText.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _matchedUsers = users;
      _matchedConversations = convs;
      _isSearching = false;
    });
  }

  void _startConversationWithUser(UserProfile user) {
    final backend = ChatyBackendService();
    final conv = backend.getOrCreateDirectConversation(user);

    // Sync into dataStore if missing
    if (!widget.dataStore.conversations.any((c) => c.id == conv.id)) {
      widget.dataStore.conversations.insert(0, conv);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId: conv.id,
          theme: widget.theme,
          dataStore: widget.dataStore,
          preferencesController: widget.preferencesController,
          themeController: widget.themeController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.primaryTextColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: theme.primaryTextColor, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search @username, people, groups...',
            hintStyle: TextStyle(color: theme.secondaryTextColor.withValues(alpha: 0.6)),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                ),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded, color: theme.secondaryTextColor),
              onPressed: () => _searchController.clear(),
            ),
        ],

      ),
      body: _searchController.text.trim().isEmpty
          ? _buildEmptyPrompt(theme)
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                if (_matchedUsers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'PEOPLE & USERNAMES',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._matchedUsers.map((user) => _buildUserTile(user, theme)),
                  const SizedBox(height: 12),
                ],
                if (_matchedConversations.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'CHATS & GROUPS',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ..._matchedConversations.map((conv) => _buildConversationTile(conv, theme)),
                ],
                if (_matchedUsers.isEmpty && _matchedConversations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: theme.secondaryTextColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No matches found for "${_searchController.text}"',
                            style: TextStyle(color: theme.secondaryTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyPrompt(ThemeConfig theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.alternate_email_rounded, size: 40, color: theme.accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Username-First Discovery',
            style: TextStyle(color: theme.primaryTextColor, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Type any @username to find & message someone without exposing phone numbers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserProfile user, ThemeConfig theme) {
    final currentUserId = ChatyBackendService().currentUser?.id;
    final isMe = user.id == currentUserId;

    return ListTile(
      leading: Stack(
        children: [
          ChatyAvatar(
            initials: user.avatarInitials,
            color: Color(int.parse(user.avatarColorHex)),
            size: 46,
          ),
          if (isMe)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_rounded, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            isMe ? '${user.displayName} (You)' : user.displayName,
            style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.bold),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified_rounded, size: 16, color: theme.accentColor),
          ],
        ],
      ),
      subtitle: Text(
        isMe ? '@${user.username} • Save notes, data & files here' : '@${user.username} • ${user.about}',
        style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isMe ? const Color(0xFF10B981) : theme.accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () => _startConversationWithUser(user),
        icon: Icon(isMe ? Icons.bookmark_add_rounded : Icons.chat_bubble_outline_rounded, size: 16),
        label: Text(
          isMe ? 'Share / Save' : 'Message',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv, ThemeConfig theme) {
    return ListTile(
      leading: ChatyAvatar(
        initials: conv.avatarInitials ?? 'CH',
        color: conv.avatarColorHex != null ? Color(int.parse(conv.avatarColorHex!)) : theme.accentColor,
        size: 46,
      ),
      title: Text(
        conv.title,
        style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conv.lastMessageText,
        style: TextStyle(color: theme.secondaryTextColor, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              conversationId: conv.id,
              theme: theme,
              dataStore: widget.dataStore,
              preferencesController: widget.preferencesController,
              themeController: widget.themeController,
            ),
          ),
        );
      },
    );
  }
}
