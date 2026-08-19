import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../data/services/chaty_notification_service.dart';
import 'chats_home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../calls/calls_screen.dart';
import '../updates/updates_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'package:chat/injection/locator.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<_NavDestinationItem> _navItems = const [
    _NavDestinationItem(
      label: 'Chats',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavDestinationItem(
      label: 'Updates',
      icon: Icons.update_rounded,
      activeIcon: Icons.update_rounded,
    ),
    _NavDestinationItem(
      label: 'Tasks',
      icon: Icons.checklist_rtl_rounded,
      activeIcon: Icons.checklist_rounded,
    ),
    _NavDestinationItem(
      label: 'Calls',
      icon: Icons.call_outlined,
      activeIcon: Icons.call_rounded,
    ),
    _NavDestinationItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = locator<ThemeController>();
    final dataStore = locator<MockDataStore>();
    final preferencesController = locator<ChatyPreferencesController>();
    final notificationService = locator<ChatyNotificationService>();

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = themeController.globalTheme;

        final screens = [
          ChatsHomeScreen(
            theme: theme,
            dataStore: dataStore,
            preferencesController: preferencesController,
            themeController: themeController,
            notificationService: notificationService,
          ),
          UpdatesScreen(
            theme: theme,
            dataStore: dataStore,
            preferencesController: preferencesController,
          ),
          TasksScreen(theme: theme, dataStore: dataStore),
          CallsScreen(theme: theme, dataStore: dataStore),
          SettingsScreen(
            preferencesController: preferencesController,
            themeController: themeController,
            dataStore: dataStore,
            notificationService: notificationService,
          ),
        ];

        return Scaffold(
          extendBody: true,
          backgroundColor: theme.backgroundColor,
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0E14), // Deep obsidian background matching image
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;

                return _buildNavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => setState(() => _currentIndex = index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  },
);
  }

  Widget _buildNavItem({
    required _NavDestinationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (isSelected) {
      // Active item: Expanded rounded pill with vibrant circular badge & bold white label
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: 52,
          padding: const EdgeInsets.only(left: 6, right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2633), // Soft dark-blue slate background
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Vibrant circular badge (Mint / Emerald / Turquoise) matching image
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2DD4BF), // Bright mint turquoise as shown in image
                ),
                child: Icon(
                  item.activeIcon,
                  size: 20,
                  color: const Color(0xFF0F172A), // Dark contrast icon inside badge
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Inactive item: Clean circular dark button with minimalist icon
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF141922), // Subtle circular background
        ),
        child: Center(
          child: Icon(
            item.icon,
            size: 21,
            color: const Color(0xFF94A3B8), // Muted slate gray
          ),
        ),
      ),
    );
  }
}

class _NavDestinationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavDestinationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}