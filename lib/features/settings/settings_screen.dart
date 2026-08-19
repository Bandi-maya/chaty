import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_notification_service.dart';
import 'appearance/universal_appearance_screen.dart';
import 'conversation/conversation_settings_page.dart';
import 'effects/navigation_effects_page.dart';
import 'gb_features/gb_settings_hub_screen.dart';
import 'home/home_screen_settings_page.dart';
import 'message_management/message_management_page.dart';
import 'notifications/notification_settings_page.dart';
import 'permissions/system_permissions_screen.dart';
import 'privacy/privacy_center_screen.dart';
import 'security/security_center_screen.dart';
import 'settings_search_delegate.dart';
import 'themes/chaty_theme_editor_screen.dart';
import '../auth/welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ChatyPreferencesController preferencesController;
  final ThemeController themeController;
  final MockDataStore dataStore;
  final ChatyNotificationService notificationService;

  const SettingsScreen({
    super.key,
    required this.preferencesController,
    required this.themeController,
    required this.dataStore,
    required this.notificationService,
  });

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _featureSection(String section) => GbSettingsHubScreen(
        preferencesController: preferencesController,
        initialSection: section,
      );

  List<SettingsSearchResult> _buildSearchIndex(BuildContext context) => <SettingsSearchResult>[
        SettingsSearchResult(
          title: 'Privacy controls',
          category: 'Privacy & security',
          description: 'Read receipts, stealth, anti-delete and privacy behavior',
          icon: Icons.shield_outlined,
          destination: _featureSection('Privacy & security'),
        ),
        SettingsSearchResult(
          title: 'Chat & messaging options',
          category: 'Chats',
          description: 'Messaging behavior, bubbles, composer, headers and avatars',
          icon: Icons.chat_bubble_outline_rounded,
          destination: _featureSection('Chats & messaging'),
        ),
        SettingsSearchResult(
          title: 'Appearance & home options',
          category: 'Appearance',
          description: 'Home, colors, fonts, icons, FAB and visual customization',
          icon: Icons.palette_outlined,
          destination: _featureSection('Appearance & home'),
        ),
        SettingsSearchResult(
          title: 'Status & stories options',
          category: 'Status',
          description: 'Status layout, story rings, thumbnails and status behavior',
          icon: Icons.auto_stories_outlined,
          destination: _featureSection('Status & stories'),
        ),
        SettingsSearchResult(
          title: 'Call options',
          category: 'Calls',
          description: 'Calling privacy and call appearance',
          icon: Icons.call_outlined,
          destination: _featureSection('Calls'),
        ),
        SettingsSearchResult(
          title: 'Media & storage options',
          category: 'Media',
          description: 'Upload limits, quality, hidden media and cleanup',
          icon: Icons.perm_media_outlined,
          destination: _featureSection('Media & storage'),
        ),
        SettingsSearchResult(
          title: 'Notifications & presence options',
          category: 'Notifications',
          description: 'Presence indicators, alerts, counters and notification behavior',
          icon: Icons.notifications_outlined,
          destination: _featureSection('Notifications & presence'),
        ),
        SettingsSearchResult(
          title: 'Navigation & gestures options',
          category: 'Navigation',
          description: 'Navigation layouts, gestures, transitions and touch effects',
          icon: Icons.swipe_outlined,
          destination: _featureSection('Navigation & gestures'),
        ),
        SettingsSearchResult(
          title: 'Automation & behavior options',
          category: 'Automation',
          description: 'Automation, translation and universal app behavior',
          icon: Icons.bolt_outlined,
          destination: _featureSection('Automation & behavior'),
        ),
        SettingsSearchResult(
          title: 'All customization settings',
          category: 'Settings',
          description: 'Search every customizable setting in one place',
          icon: Icons.tune_rounded,
          destination: GbSettingsHubScreen(preferencesController: preferencesController),
        ),
      ];

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final user = dataStore.currentUser;
    final nameCtrl = TextEditingController(text: user.displayName);
    final aboutCtrl = TextEditingController(text: user.about);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit profile', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: aboutCtrl,
                  maxLength: 160,
                  decoration: const InputDecoration(labelText: 'About', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    dataStore.updateProfile(user.copyWith(displayName: name, about: aboutCtrl.text.trim()));
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Save profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameCtrl.dispose();
    aboutCtrl.dispose();
  }

  Future<void> _showResetOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.restore_rounded),
                title: const Text('Reset theme'),
                subtitle: const Text('Restore the default Chaty theme.'),
                onTap: () {
                  themeController.resetToDefaults();
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Reset privacy settings'),
                subtitle: const Text('Restore privacy controls to their defaults.'),
                onTap: () {
                  preferencesController.resetPrivacy();
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune_rounded),
                title: const Text('Reset customization settings'),
                subtitle: const Text('Restore all component and GB-style customization values.'),
                onTap: () {
                  preferencesController.resetGbFeatures();
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: Colors.redAccent),
                title: const Text('Reset all preferences', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                subtitle: const Text('Reset theme and all local preference values.'),
                onTap: () {
                  preferencesController.resetAll();
                  themeController.resetToDefaults();
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copySettingsBackup(BuildContext context) async {
    final payload = <String, Object?>{
      'format': 'chaty-settings-v1',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'customization': preferencesController.gbFeatures,
    };
    await Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customization backup JSON copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeController.globalTheme;
    final user = dataStore.currentUser;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Settings',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search settings',
                      onPressed: () => showSearch(
                        context: context,
                        delegate: SettingsSearchDelegate(allSettings: _buildSearchIndex(context)),
                      ),
                      icon: const Icon(Icons.search_rounded),
                    ),
                    IconButton(
                      tooltip: 'Reset options',
                      onPressed: () => _showResetOptions(context),
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: ListTile(
                    minTileHeight: 76,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      child: Text(
                        user.avatarInitials.isNotEmpty ? user.avatarInitials : 'CU',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(
                      user.displayName.isNotEmpty ? user.displayName : 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      user.about.isNotEmpty ? user.about : (user.email.isNotEmpty ? user.email : user.username),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel(context, 'PRIVACY & SECURITY'),
                ChatySettingsCard(children: [
                  _tile(Icons.shield_outlined, 'Privacy Center', 'Core privacy, read receipts, last seen and stealth', () => _open(context, PrivacyCenterScreen(preferencesController: preferencesController))),
                  _tile(Icons.lock_outline_rounded, 'Security Center', 'App lock, protected access and security controls', () => _open(context, SecurityCenterScreen(preferencesController: preferencesController))),
                  _tile(Icons.tune_rounded, 'Privacy & security options', 'All additional privacy and security switches in their normal category', () => _open(context, _featureSection('Privacy & security'))),
                  _tile(Icons.vpn_key_outlined, 'Permissions & hardware', 'Camera, microphone, notifications and system access', () => _open(context, SystemPermissionsScreen(preferencesController: preferencesController, notificationService: notificationService))),
                ]),
                const SizedBox(height: 20),
                _sectionLabel(context, 'APPEARANCE & HOME'),
                ChatySettingsCard(children: [
                  _tile(Icons.palette_outlined, 'Themes & colors', 'Theme presets and semantic color engine', () => _open(context, ChatyThemeEditorScreen(themeController: themeController))),
                  _tile(Icons.auto_awesome_mosaic_outlined, 'Component templates', '20-template component selectors, typography, icons and animations', () => _open(context, UniversalAppearanceScreen(preferencesController: preferencesController))),
                  _tile(Icons.space_dashboard_outlined, 'Home screen', 'Home layout, stories strip, avatars and home behavior', () => _open(context, HomeScreenSettingsPage(preferencesController: preferencesController))),
                  _tile(Icons.tune_rounded, 'Appearance & home options', 'FAB, header, list rows, widgets, fonts, colors and visual controls', () => _open(context, _featureSection('Appearance & home'))),
                ]),
                const SizedBox(height: 20),
                _sectionLabel(context, 'CHATS & MESSAGING'),
                ChatySettingsCard(children: [
                  _tile(Icons.chat_bubble_outline_rounded, 'Conversation customization', 'Bubbles, ticks, reply presentation and conversation behavior', () => _open(context, ConversationSettingsPage(preferencesController: preferencesController))),
                  _tile(Icons.tune_rounded, 'Chat & messaging options', 'Composer, message presentation, headers, quick contact and advanced messaging', () => _open(context, _featureSection('Chats & messaging'))),
                  _tile(Icons.smart_toy_outlined, 'Automation & scheduler', 'Auto replies, scheduled messages and workflow behavior', () => _open(context, MessageManagementPage(preferencesController: preferencesController, dataStore: dataStore))),
                  _tile(Icons.bolt_outlined, 'Automation & behavior options', 'Translation, universal behavior and automation controls', () => _open(context, _featureSection('Automation & behavior'))),
                ]),
                const SizedBox(height: 20),
                _sectionLabel(context, 'STATUS, CALLS & MEDIA'),
                ChatySettingsCard(children: [
                  _tile(Icons.auto_stories_outlined, 'Status & stories', 'Status layout, rings, thumbnails and publishing behavior', () => _open(context, _featureSection('Status & stories'))),
                  _tile(Icons.call_outlined, 'Calls', 'Call privacy, video/audio call appearance and call controls', () => _open(context, _featureSection('Calls'))),
                  _tile(Icons.perm_media_outlined, 'Media & storage', 'Upload quality, file limits, hidden media and cleanup', () => _open(context, _featureSection('Media & storage'))),
                ]),
                const SizedBox(height: 20),
                _sectionLabel(context, 'NOTIFICATIONS & NAVIGATION'),
                ChatySettingsCard(children: [
                  _tile(Icons.notifications_none_rounded, 'Notification studio', 'Conversation sounds, heads-up alerts and notification behavior', () => _open(context, NotificationSettingsPage(preferencesController: preferencesController, notificationService: notificationService))),
                  _tile(Icons.notifications_active_outlined, 'Notifications & presence options', 'Presence state, online indicators, badges and alerts', () => _open(context, _featureSection('Notifications & presence'))),
                  _tile(Icons.touch_app_outlined, 'Touch effects', 'Tap effects, particles and navigation effects', () => _open(context, NavigationEffectsPage(preferencesController: preferencesController))),
                  _tile(Icons.swipe_outlined, 'Navigation & gestures options', 'Navigation styles, animations, gestures and movement behavior', () => _open(context, _featureSection('Navigation & gestures'))),
                ]),
                const SizedBox(height: 20),
                _sectionLabel(context, 'DATA & SYSTEM'),
                ChatySettingsCard(children: [
                  _tile(Icons.manage_search_rounded, 'All customization settings', 'Search every retained option without a separate advanced-only hierarchy', () => _open(context, GbSettingsHubScreen(preferencesController: preferencesController))),
                  _tile(Icons.backup_outlined, 'Backup customization settings', 'Copy the current customization configuration as real JSON', () => _copySettingsBackup(context)),
                  _tile(Icons.restore_page_outlined, 'Reset & diagnostics', 'Reset privacy, customization, theme or all preferences', () => _showResetOptions(context)),
                  _tile(Icons.info_outline_rounded, 'About Chaty', 'Version and application information', () => showAboutDialog(context: context, applicationName: 'Chaty', applicationVersion: '1.0.0 (Build 2026)', applicationLegalese: '© 2026 LOGY BYTE. All rights reserved.')),
                ]),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  onPressed: () {
                    dataStore.logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out of Chaty'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
              ),
        ),
      );

  ChatySettingsTile _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => ChatySettingsTile(
        icon: icon,
        iconColor: themeController.globalTheme.accentColor,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
      );
}
