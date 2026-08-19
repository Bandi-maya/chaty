import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../data/services/chaty_notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  final ChatyPreferencesController preferencesController;
  final ChatyNotificationService notificationService;

  const NotificationSettingsPage({
    super.key,
    required this.preferencesController,
    required this.notificationService,
  });

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final notif = widget.preferencesController.notification;

    return ChatySettingsPage(
      title: 'Notification Customization',
      subtitle: 'Category Profiles, Privacy & Event Simulators',
      children: [
        // Live Preview Card at Top
        ChatyPreviewCard(
          title: 'Live Notification Banner Preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Global Alerts: ${notif.enableGlobalNotifications ? "Enabled" : "Muted"} • Avatar: ${notif.showSenderAvatar ? "Shown" : "Hidden"} • Preview: ${notif.showMessagePreview ? "Visible" : "Hidden"}',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    if (notif.showSenderAvatar) ...[
                      ChatyAvatar(initials: 'ER', color: const Color(0xFFEC4899), size: 36),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.showSenderName ? 'Dr. Elena Rostova' : 'Chaty Notification',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notif.showMessagePreview ? 'Kyber-1024 encryption keys refreshed.' : 'New encrypted message',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.notifications_active_rounded, size: 18, color: Colors.indigoAccent),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Global & Preview Settings
        ChatySettingsSection(
          title: 'Global Notifications',
          children: [
            ChatySwitchTile(
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.indigoAccent,
              title: 'Enable Notifications',
              subtitle: 'Allow Chaty to emit mock in-app banner alerts',
              value: notif.enableGlobalNotifications,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(enableGlobalNotifications: val),
                  logTitle: 'Enable Notifications',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.account_circle_rounded,
              title: 'Show Sender Avatar',
              subtitle: 'Display contact profile picture in notification banners',
              value: notif.showSenderAvatar,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(showSenderAvatar: val),
                  logTitle: 'Show Sender Avatar',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.subtitles_rounded,
              title: 'Show Message Preview',
              subtitle: 'Include message text content in banners',
              value: notif.showMessagePreview,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(showMessagePreview: val),
                  logTitle: 'Show Message Preview',
                );
              },
            ),
          ],
        ),

        // Event Specific Notification Toggles
        ChatySettingsSection(
          title: 'Special Event Notifications',
          description: 'Receive notifications when contacts perform specific actions.',
          children: [
            ChatySwitchTile(
              icon: Icons.online_prediction_rounded,
              iconColor: Colors.greenAccent,
              title: 'Contact Online Alert',
              subtitle: 'Notify when selected contacts come online',
              value: notif.notifyContactOnline,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(notifyContactOnline: val),
                  logTitle: 'Contact Online Alert',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.visibility_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Status / Story Viewed Alert',
              subtitle: 'Notify when a contact views your story',
              value: notif.notifyStatusViewed,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(notifyStatusViewed: val),
                  logTitle: 'Status Viewed Alert',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.delete_sweep_rounded,
              iconColor: Colors.redAccent,
              title: 'Message Revoked Alert',
              subtitle: 'Notify when a contact revokes or deletes a message',
              value: notif.notifyMessageDeleted,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(notifyMessageDeleted: val),
                  logTitle: 'Message Revoked Alert',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.auto_delete_rounded,
              iconColor: Colors.orangeAccent,
              title: 'Story Revoked Alert',
              subtitle: 'Notify when a contact deletes a story update',
              value: notif.notifyStatusDeleted,
              onChanged: (val) {
                widget.preferencesController.updateNotification(
                  notif.copyWith(notifyStatusDeleted: val),
                  logTitle: 'Story Revoked Alert',
                );
              },
            ),
          ],
        ),

        // Event Simulator Suite
        ChatySettingsSection(
          title: 'Notification Event Simulator',
          description: 'Simulate incoming event notifications to test your settings.',
          children: [
            ChatySettingsTile(
              icon: Icons.play_circle_fill_rounded,
              iconColor: Colors.greenAccent,
              title: 'Simulate "Contact Online"',
              subtitle: 'Trigger: Elena Rostova is now online',
              onTap: () {
                widget.notificationService.triggerEventNotification(
                  title: 'Contact Online',
                  body: 'Elena Rostova is now active in Chaty.',
                  icon: Icons.online_prediction_rounded,
                  color: Colors.greenAccent,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered "Contact Online" event!')));
              },
            ),
            ChatySettingsTile(
              icon: Icons.play_circle_fill_rounded,
              iconColor: Colors.redAccent,
              title: 'Simulate "Message Revoked"',
              subtitle: 'Trigger: Marcus Vance deleted a message',
              onTap: () {
                widget.notificationService.triggerEventNotification(
                  title: 'Message Revoked',
                  body: 'Marcus Vance deleted a message in "🛡️ Nexa Security Working Group".',
                  icon: Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered "Message Revoked" event!')));
              },
            ),
            ChatySettingsTile(
              icon: Icons.play_circle_fill_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Simulate "Story Viewed"',
              subtitle: 'Trigger: Dr. Sarah Chen viewed your status',
              onTap: () {
                widget.notificationService.triggerEventNotification(
                  title: 'Story Viewed',
                  body: 'Dr. Sarah Chen viewed your story update.',
                  icon: Icons.remove_red_eye_rounded,
                  color: Colors.purpleAccent,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggered "Story Viewed" event!')));
              },
            ),
          ],
        ),
      ],
    );
  }
}
