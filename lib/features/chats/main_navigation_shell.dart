import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_notification_service.dart';
import '../../domain/models/visual_preferences.dart';
import '../../features/settings/settings_screen.dart';
import '../../injection/locator.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../calls/calls_screen.dart';
import '../tasks/tasks_screen.dart';
import '../updates/updates_screen.dart';
import 'chats_home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressedAt;

  static const List<_NavDestinationItem> _navItems = <_NavDestinationItem>[
    _NavDestinationItem(
      label: 'Chats',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavDestinationItem(
      label: 'Updates',
      icon: Icons.update_outlined,
      activeIcon: Icons.update_rounded,
    ),
    _NavDestinationItem(
      label: 'Tasks',
      icon: Icons.checklist_rtl_outlined,
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

  Future<void> _handleRootBack() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    final now = DateTime.now();
    final previous = _lastBackPressedAt;
    if (previous == null || now.difference(previous) > const Duration(seconds: 2)) {
      _lastBackPressedAt = now;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tap back again to exit Chaty'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    await SystemNavigator.pop();
  }

  void _select(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
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
        final visual = preferencesController.visual;
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
              final wide = constraints.maxWidth >= 840;
              final compact = constraints.maxWidth < 390;
              final body = IndexedStack(index: _currentIndex, children: screens);

              if (wide) {
                return Scaffold(
                  backgroundColor: theme.backgroundColor,
                  body: SafeArea(
                    child: Row(
                      children: <Widget>[
                        _buildRail(theme, visual),
                        VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: theme.secondaryTextColor.withValues(alpha: 0.12),
                        ),
                        Expanded(child: body),
                      ],
                    ),
                  ),
                );
              }

              return Scaffold(
                backgroundColor: theme.backgroundColor,
                body: body,
                bottomNavigationBar: _buildBottomBar(
                  theme,
                  visual,
                  compact: compact,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRail(dynamic theme, VisualPreferences visual) {
    return NavigationRail(
      backgroundColor: theme.surfaceColor,
      selectedIndex: _currentIndex,
      onDestinationSelected: _select,
      extended: visual.bottomBarStyle == 'Workspace',
      labelType: visual.bottomBarStyle == 'Workspace'
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      indicatorColor: theme.accentColor.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: theme.accentColor),
      unselectedIconTheme: IconThemeData(color: theme.secondaryTextColor),
      selectedLabelTextStyle: TextStyle(
        color: theme.primaryTextColor,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: theme.secondaryTextColor),
      destinations: _navItems
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }

  Widget _buildBottomBar(
    dynamic theme,
    VisualPreferences visual, {
    required bool compact,
  }) {
    final profile = _BottomBarProfile.fromStyle(visual.bottomBarStyle);
    final showLabels = !compact && profile.showLabels;
    final horizontalPadding = compact ? 8.0 : profile.horizontalInset;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          0,
          horizontalPadding,
          profile.floating ? 10 : 0,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 58),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 6,
            vertical: profile.dense ? 3 : 6,
          ),
          decoration: BoxDecoration(
            color: profile.transparent
                ? theme.backgroundColor
                : theme.surfaceColor,
            borderRadius: BorderRadius.circular(
              profile.floating ? profile.radius : 0,
            ),
            border: profile.outlined
                ? Border.all(
                    color: theme.secondaryTextColor.withValues(alpha: 0.18),
                  )
                : null,
            boxShadow: profile.elevated
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: theme.brightness == Brightness.dark ? 0.28 : 0.10,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            children: List<Widget>.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final selected = index == _currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: InkWell(
                    onTap: () => _select(index),
                    borderRadius: BorderRadius.circular(profile.itemRadius),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: EdgeInsets.symmetric(
                        horizontal: showLabels ? 6 : 2,
                        vertical: profile.dense ? 7 : 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected && profile.selectedFill
                            ? theme.accentColor.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(profile.itemRadius),
                        border: selected && profile.itemOutline
                            ? Border.all(
                                color: theme.accentColor.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          AnimatedScale(
                            scale: selected ? profile.selectedScale : 1,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              size: compact ? 20 : profile.iconSize,
                              color: selected
                                  ? theme.accentColor
                                  : theme.secondaryTextColor,
                            ),
                          ),
                          if (showLabels) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? theme.primaryTextColor
                                    : theme.secondaryTextColor,
                                fontSize: profile.labelSize,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                          if (selected && profile.indicator) ...<Widget>[
                            const SizedBox(height: 3),
                            Container(
                              width: 18,
                              height: 2,
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomBarProfile {
  final bool floating;
  final bool outlined;
  final bool elevated;
  final bool transparent;
  final bool dense;
  final bool showLabels;
  final bool selectedFill;
  final bool itemOutline;
  final bool indicator;
  final double radius;
  final double itemRadius;
  final double iconSize;
  final double selectedScale;
  final double labelSize;
  final double horizontalInset;

  const _BottomBarProfile({
    required this.floating,
    required this.outlined,
    required this.elevated,
    required this.transparent,
    required this.dense,
    required this.showLabels,
    required this.selectedFill,
    required this.itemOutline,
    required this.indicator,
    required this.radius,
    required this.itemRadius,
    required this.iconSize,
    required this.selectedScale,
    required this.labelSize,
    required this.horizontalInset,
  });

  factory _BottomBarProfile.fromStyle(String style) {
    final index = VisualPreferences.bottomBarStyles.indexOf(style).clamp(0, 19);
    return _BottomBarProfile(
      floating: <int>{0, 6, 7, 8, 9, 14, 15, 18, 19}.contains(index),
      outlined: <int>{5, 8, 11, 15, 18}.contains(index),
      elevated: <int>{0, 6, 7, 9, 14, 15, 18, 19}.contains(index),
      transparent: <int>{2, 10, 16}.contains(index),
      dense: <int>{2, 3, 4, 17}.contains(index),
      showLabels: !<int>{2, 4, 10}.contains(index),
      selectedFill: !<int>{2, 10, 11, 16}.contains(index),
      itemOutline: <int>{5, 8, 18}.contains(index),
      indicator: <int>{10, 11, 16, 19}.contains(index),
      radius: <int>{0, 6, 8, 9, 14, 15}.contains(index) ? 30 : 18,
      itemRadius: <int>{0, 8, 9, 14}.contains(index) ? 22 : 14,
      iconSize: index == 3 ? 20 : (index == 9 ? 24 : 22),
      selectedScale: <int>{7, 9, 19}.contains(index) ? 1.12 : 1.04,
      labelSize: index == 17 ? 10.0 : 11.0,
      horizontalInset: <int>{14, 15}.contains(index) ? 22 : 12,
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
