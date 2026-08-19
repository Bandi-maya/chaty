import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../domain/models/user_profile.dart';
import 'profile_setup_screen.dart';
import '../../injection/locator.dart';

class DemoAccountChooserScreen extends StatelessWidget {
  const DemoAccountChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = locator<ThemeController>();
    final dataStore = locator<MockDataStore>();
    final theme = themeController.globalTheme;
    final allUsers = <UserProfile>[
      UserProfile(
        id: 'user_bandi_maya',
        displayName: 'Bandi Maya',
        username: '@bandi_maya',
        avatarInitials: 'BM',
        avatarColorHex: '0xFF6366F1',
        about: 'Hey there! I am using Chaty.',
        presence: PresenceState.online,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 2)),
        isVerified: false,
        email: 'bandi.maya@example.com',
        phone: '',
        safetyNumber: '58291 04928 11948 29384 10293 88472',
      ),
      UserProfile(
        id: 'user_lisa_kim',
        displayName: 'Lisa Kim',
        username: '@lisakim',
        avatarInitials: 'LK',
        avatarColorHex: '0xFF6366F1',
        about: 'Exploring new features!',
        presence: PresenceState.offline,
        lastSeenAt: DateTime.now().subtract(const Duration(hours: 3)),
        isVerified: false,
        email: 'lisa.kim@example.com',
        phone: '',
        safetyNumber: '58291 04928 11948 29384 10293 88472',
      ),
      UserProfile(
        id: 'user_raj_patel',
        displayName: 'Raj Patel',
        username: '@rajpatel',
        avatarInitials: 'RP',
        avatarColorHex: '0xFF6366F1',
        about: 'Busy in meetings',
        presence: PresenceState.online,
        lastSeenAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isVerified: false,
        email: 'raj.patel@example.com',
        phone: '',
        safetyNumber: '58291 04928 11948 29384 10293 88472',
      ),
      UserProfile(
        id: 'user_sofia_garcia',
        displayName: 'Sofia Garcia',
        username: '@sofiagarcia',
        avatarInitials: 'SG',
        avatarColorHex: '0xFF6366F1',
        about: 'On my way!',
        presence: PresenceState.offline,
        lastSeenAt: DateTime.now().subtract(const Duration(days: 1)),
        isVerified: false,
        email: 'sofia.garcia@example.com',
        phone: '',
        safetyNumber: '58291 04928 11948 29384 10293 88472',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Choose Demo Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a demo account to explore Chaty',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final user = allUsers[index];
                    return _DemoAccountTile(
                      user: user,
                      onTap: () {
                        // Simulate login by setting current user in data store
                        dataStore.switchDemoAccount(user);
                        // Navigate to profile setup to complete the demo
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileSetupScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onTap;

  const _DemoAccountTile({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    return ListTile(
      leading: AppAvatar(
        initials: user.avatarInitials,
        colorHex: user.avatarColorHex,
        presence: user.presence,
        showOnlineBadge: true,
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          color: theme.primaryTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        user.about,
        style: TextStyle(
          color: theme.secondaryTextColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16.0, color: theme.secondaryTextColor),
      onTap: onTap,
    );
  }
}