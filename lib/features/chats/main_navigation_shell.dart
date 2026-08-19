import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/controllers/appearance_variant_controller.dart';
import '../../ui/core/gb/gb_theme_overrides.dart';
import '../../ui/core/layout/adaptive_window_metrics.dart';
import '../../ui/core/navigation/premium_navigation_bar.dart';
import '../../ui/core/navigation/premium_navigation_rail.dart';
import '../../data/services/chaty_notification_service.dart';
import 'chats_home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../calls/calls_screen.dart';
import '../updates/updates_screen.dart';
import '../settings/settings_root_screen.dart';
import 'package:chat/injection/locator.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  DateTime? _lastExitAttempt;

  final List<PremiumNavDestination> _navItems = const <PremiumNavDestination>[
    PremiumNavDestination(label: 'Chats', icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    PremiumNavDestination(label: 'Updates', icon: Icons.update_outlined, activeIcon: Icons.update_rounded),
    PremiumNavDestination(label: 'Tasks', icon: Icons.checklist_rtl_rounded, activeIcon: Icons.checklist_rounded),
    PremiumNavDestination(label: 'Calls', icon: Icons.call_outlined, activeIcon: Icons.call_rounded),
    PremiumNavDestination(label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded),
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
          ..showSnackBar(const SnackBar(content: Text('Press back again to exit Chaty'), duration: Duration(seconds: 2)));
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
    final appearanceController = locator<AppearanceVariantController>();
    final notificationService = locator<ChatyNotificationService>();

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[themeController, preferencesController, appearanceController, dataStore]),
      builder: (context, _) {
        final theme = GbThemeOverrides.resolve(themeController.globalTheme, preferencesController);
        final screens = <Widget>[
          ChatsHomeScreen(
            theme: theme,
            dataStore: dataStore,
            preferencesController: preferencesController,
            themeController: themeController,
            notificationService: notificationService,
          ),
          UpdatesScreen(theme: theme, dataStore: dataStore, preferencesController: preferencesController),
          TasksScreen(theme: theme, dataStore: dataStore),
          CallsScreen(theme: theme, dataStore: dataStore),
          SettingsRootScreen(
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
              final metrics = AdaptiveWindowMetrics.fromSize(Size(constraints.maxWidth, constraints.maxHeight));
              final content = IndexedStack(index: _currentIndex, children: screens);
              if (metrics.useNavigationRail) {
                return _buildWideShell(
                  theme: theme,
                  content: content,
                  appearance: appearanceController,
                  metrics: metrics,
                );
              }
              return Scaffold(
                extendBody: true,
                backgroundColor: theme.backgroundColor,
                body: content,
                bottomNavigationBar: PremiumNavigationBar(
                  styleIndex: appearanceController.bottomBarIndex,
                  selectedIndex: _currentIndex,
                  destinations: _navItems,
                  onSelected: (next) => setState(() => _currentIndex = next),
                  theme: theme,
                  metrics: metrics,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWideShell({
    required dynamic theme,
    required Widget content,
    required AppearanceVariantController appearance,
    required AdaptiveWindowMetrics metrics,
  }) {
    final tabStyle = appearance.navigationIndex >= 10 && appearance.navigationIndex <= 16;
    if (tabStyle) {
      return Scaffold(
        backgroundColor: theme.backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(top: appearance.navigationIndex == 15 ? 48 : 58),
                child: content,
              ),
              PremiumNavigationRail(
                styleIndex: appearance.navigationIndex,
                selectedIndex: _currentIndex,
                destinations: _navItems,
                onSelected: (next) => setState(() => _currentIndex = next),
                theme: theme,
                metrics: metrics,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Row(
          children: [
            PremiumNavigationRail(
              styleIndex: appearance.navigationIndex,
              selectedIndex: _currentIndex,
              destinations: _navItems,
              onSelected: (next) => setState(() => _currentIndex = next),
              theme: theme,
              metrics: metrics,
            ),
            VerticalDivider(width: 1, color: theme.cardColor),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
