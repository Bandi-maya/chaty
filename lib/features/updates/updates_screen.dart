import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/widgets/app_avatar.dart';

import '../../injection/locator.dart';
import '../../../ui/core/theme/theme_controller.dart';

class UpdatesScreen extends StatelessWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final ChatyPreferencesController preferencesController;

  const UpdatesScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.preferencesController,
  });

  @override
  Widget build(BuildContext context) {
    final liveTheme = locator<ThemeController>().globalTheme;
    final stories = dataStore.stories;
    final priv = preferencesController.privacy;

    return Scaffold(
      backgroundColor: liveTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Status & Ephemeral Updates',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 22 * theme.fontScale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // My Status Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create status update modal triggered.')),
                  );
                },
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AppAvatar(
                          initials: dataStore.currentUser.avatarInitials,
                          colorHex: dataStore.currentUser.avatarColorHex,
                          size: 52,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.backgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Status', style: TextStyle(color: theme.primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Tap to add status update', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Text(
                'RECENT UPDATES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: theme.secondaryTextColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            Expanded(
              child: stories.isEmpty
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
                                Icons.auto_awesome_rounded,
                                size: 54,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No updates yet',
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Status updates shared by your contacts will appear here for 24 hours.',
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
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: stories.length,
                      itemBuilder: (context, idx) {
                        final story = stories[idx];
                        final user = dataStore.getUser(story.userId);
                        final userName = user?.displayName ?? 'Chaty User';
                        final userInitials = user?.avatarInitials ?? 'CU';
                        final userColor = user?.avatarColorHex ?? '0xFF3B82F6';


                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: story.isViewed ? theme.secondaryTextColor.withValues(alpha: 0.5) : theme.accentColor,
                          width: 2.5,
                        ),
                      ),
                      child: AppAvatar(
                        initials: userInitials,
                        colorHex: userColor,
                        size: 44,
                      ),
                    ),
                    title: Text(userName, style: TextStyle(color: theme.primaryTextColor, fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            story.content,
                            style: TextStyle(color: theme.secondaryTextColor, fontSize: 12.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (priv.antiDeleteStatus && idx == 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amberAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Deleted by author',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: theme.secondaryTextColor),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing status for $userName')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
