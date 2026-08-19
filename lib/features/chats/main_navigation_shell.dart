import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  DateTime? _lastExitAttempt;

  final List<_NavDestinationItem> _navItems = const [
    _NavDestinationItem(label: 'Chats', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    _NavDestinationItem(label: 'Updates', icon: Icons.update_outlined, activeIcon: Icons.update_rounded),
    _NavDestinationItem(label: 'Tasks', icon: Icons.checklist_rtl_rounded, activeIcon: Icons.checklist_rounded),
    _NavDestinationItem(label: 'Calls', icon: Icons.call_outlined, activeIcon: Icons.call_rounded),
    _NavDestinationItem(label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded),
  ];

  Future<void> _handleRootBack() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();
    final previous = _lastExitAttempt;
    if (previous == null || now.difference(previous) > const Duration(seconds: 2)) {
      _lastExitAttempt = now;
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit Chaty'),
              duration: Duration(seconds: 2),
            ),
          );
      }
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = locator<ThemeController>();
    final dataStore = locator<MockDataStore>();
    final preferencesController = locator<ChatyPreferencesController>();
    final notificationService = locator<ChatyNotificationService>();

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        themeController,
        preferencesController,
        dataStore,
      ]),
      builder: (context, _) {
        final theme = themeController.globalTheme;
        final screens = <Widget>[
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

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _handleRootBack();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useRail = constraints.maxWidth >= 760;
              final content = IndexedStack(index: _currentIndex, children: screens);

              if (useRail) {
                return Scaffold(
                  backgroundColor: theme.backgroundColor,
                  body: SafeArea(
                    child: Row(
                      children: [
                        NavigationRail(
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) => setState(() => _currentIndex = index),
                          backgroundColor: theme.surfaceColor,
                          indicatorColor: theme.accentColor.withValues(alpha: 0.16),
                          selectedIconTheme: IconThemeData(color: theme.accentColor),
                          unselectedIconTheme: IconThemeData(color: theme.secondaryTextColor),
                          selectedLabelTextStyle: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w700),
                          unselectedLabelTextStyle: TextStyle(color: theme.secondaryTextColor),
                          labelType: constraints.maxWidth >= 980 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
                          destinations: _navItems
                              .map(
                                (item) => NavigationRailDestination(
                                  icon: Icon(item.icon),
                                  selectedIcon: Icon(item.activeIcon),
                                  label: Text(item.label),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        VerticalDivider(width: 1, color: theme.cardColor),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                );
              }

              return Scaffold(
                extendBody: true,
                backgroundColor: theme.backgroundColor,
                body: content,
                bottomNavigationBar: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: theme.cardColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.30 : 0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_navItems.length, (index) {
                          final item = _navItems[index];
                          return _buildNavItem(
                            item: item,
                            isSelected: _currentIndex == index,
                            theme: themeController,
                            onTap: () => setState(() => _currentIndex = index),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required _NavDestinationItem item,
    required bool isSelected,
    required ThemeController theme,
    required VoidCallback onTap,
  }) {
    final config = theme.globalTheme;
    if (isSelected) {
      return Flexible(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: config.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: config.accentColor.withValues(alpha: 0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: config.accentColor),
                  child: Icon(item.activeIcon, size: 19, color: config.onAccentColor),
                ),
                if (MediaQuery.sizeOf(context).width >= 390) ...[
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(color: config.primaryTextColor, fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(item.icon, size: 21, color: config.secondaryTextColor),
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
