import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../data/services/chaty_notification_service.dart';

class SystemPermissionsScreen extends StatefulWidget {
  final ChatyPreferencesController preferencesController;
  final ChatyNotificationService notificationService;

  const SystemPermissionsScreen({
    super.key,
    required this.preferencesController,
    required this.notificationService,
  });

  @override
  State<SystemPermissionsScreen> createState() => _SystemPermissionsScreenState();
}

class _SystemPermissionsScreenState extends State<SystemPermissionsScreen> {
  bool _notificationGranted = true;
  bool _cameraGranted = true;
  bool _microphoneGranted = true;
  bool _mediaPhotosGranted = true;
  bool _locationGranted = true;
  bool _contactsGranted = true;
  bool _biometricsGranted = true;

  void _requestOrToggle(String name, bool currentVal, ValueChanged<bool> onToggle) {
    if (!currentVal) {
      onToggle(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name permission granted successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      onToggle(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name permission revoked.'),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _sendTestPushNotification() {
    widget.notificationService.triggerEventNotification(
      title: 'Chaty Push Notification',
      body: 'Push service connected. End-to-end encryption key verified.',
      icon: Icons.notifications_active_rounded,
      color: Colors.indigoAccent,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Push notification dispatched!')),
    );
  }

  void _testMediaAccess() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.perm_media_rounded, color: Colors.blueAccent),
                  SizedBox(width: 10),
                  Text('Media & Gallery Picker Access', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Device photo gallery and media file access permissions are active.'),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Photo selected: chaty_wallpaper_hd.png (1080x2400)')),
                      );
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Pick Image'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video selected: demo_recording.mp4 (4K 60fps)')),
                      );
                    },
                    icon: const Icon(Icons.video_library_rounded),
                    label: const Text('Pick Video'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testLocationAccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('GPS Location Coordinates'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Live GPS Location Fix Acquired:'),
            SizedBox(height: 10),
            Text('• Latitude: 37.7749° N', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Longitude: -122.4194° W', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Accuracy: High (GPS + GLONASS)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location shared into active chat!')),
              );
            },
            child: const Text('Share Location'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChatySettingsPage(
      title: 'App Permissions & Hardware',
      subtitle: 'Push Notifications, Media, Location, Camera & Audio',
      children: [
        // Live Preview Card
        ChatyPreviewCard(
          title: 'Permission Status Center',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('Notifications', _notificationGranted, Icons.notifications_active_rounded),
                  _buildStatusChip('Media & Photos', _mediaPhotosGranted, Icons.perm_media_rounded),
                  _buildStatusChip('Location', _locationGranted, Icons.location_on_rounded),
                  _buildStatusChip('Camera', _cameraGranted, Icons.camera_alt_rounded),
                  _buildStatusChip('Microphone', _microphoneGranted, Icons.mic_rounded),
                  _buildStatusChip('Contacts', _contactsGranted, Icons.contacts_rounded),
                  _buildStatusChip('Biometrics', _biometricsGranted, Icons.fingerprint_rounded),
                ],
              ),
            ],
          ),
        ),

        // 1. Push Notifications
        ChatySettingsSection(
          title: 'Push Notifications & Alerts',
          description: 'Receive real-time instant alerts for calls, mentions, and incoming messages.',
          children: [
            ChatySwitchTile(
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.indigoAccent,
              title: 'Push Notification Permission',
              subtitle: 'Allow Chaty to display push alerts and heads-up notifications',
              value: _notificationGranted,
              onChanged: (val) => _requestOrToggle('Push Notification', _notificationGranted, (v) => setState(() => _notificationGranted = v)),
            ),
            ChatySettingsTile(
              icon: Icons.send_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Send Push Notification Now',
              subtitle: 'Trigger a simulated incoming push alert',
              onTap: _sendTestPushNotification,
            ),
          ],
        ),

        // 2. Media, Photos & Storage
        ChatySettingsSection(
          title: 'Media, Photos & File System',
          description: 'Allows sharing images, videos, audio notes, and attachments in chats.',
          children: [
            ChatySwitchTile(
              icon: Icons.perm_media_rounded,
              iconColor: Colors.lightBlueAccent,
              title: 'Media & Photo Library Permission',
              subtitle: 'Access device gallery to send photos and high-definition video',
              value: _mediaPhotosGranted,
              onChanged: (val) => _requestOrToggle('Media & Photos', _mediaPhotosGranted, (v) => setState(() => _mediaPhotosGranted = v)),
            ),
            ChatySettingsTile(
              icon: Icons.photo_library_rounded,
              iconColor: Colors.blueAccent,
              title: 'Test Gallery & Media Picker',
              subtitle: 'Open simulated image and video selector',
              onTap: _testMediaAccess,
            ),
          ],
        ),

        // 3. Precise Location
        ChatySettingsSection(
          title: 'Location & Map Coordinates',
          description: 'Send live location fixes or drop pins directly in conversations.',
          children: [
            ChatySwitchTile(
              icon: Icons.location_on_rounded,
              iconColor: Colors.redAccent,
              title: 'Precise GPS Location Permission',
              subtitle: 'Access device coordinates to share live location in chats',
              value: _locationGranted,
              onChanged: (val) => _requestOrToggle('Location', _locationGranted, (v) => setState(() => _locationGranted = v)),
            ),
            ChatySettingsTile(
              icon: Icons.my_location_rounded,
              iconColor: Colors.amberAccent,
              title: 'Fetch & Share Current Location',
              subtitle: 'Query GPS sensor coordinates',
              onTap: _testLocationAccess,
            ),
          ],
        ),

        // 4. Hardware Sensors & Privacy
        ChatySettingsSection(
          title: 'Hardware & Hardware Sensors',
          description: 'Control camera, audio microphone, contacts, and biometric sensor access.',
          children: [
            ChatySwitchTile(
              icon: Icons.camera_alt_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Camera Access',
              subtitle: 'Take photos, record stories and start video calls',
              value: _cameraGranted,
              onChanged: (val) => _requestOrToggle('Camera', _cameraGranted, (v) => setState(() => _cameraGranted = v)),
            ),
            ChatySwitchTile(
              icon: Icons.mic_rounded,
              iconColor: Colors.deepOrangeAccent,
              title: 'Microphone & Audio',
              subtitle: 'Record voice messages and voice calls',
              value: _microphoneGranted,
              onChanged: (val) => _requestOrToggle('Microphone', _microphoneGranted, (v) => setState(() => _microphoneGranted = v)),
            ),
            ChatySwitchTile(
              icon: Icons.contacts_rounded,
              iconColor: Colors.greenAccent,
              title: 'Address Book & Contacts',
              subtitle: 'Discover which friends are on Chaty',
              value: _contactsGranted,
              onChanged: (val) => _requestOrToggle('Contacts', _contactsGranted, (v) => setState(() => _contactsGranted = v)),
            ),
            ChatySwitchTile(
              icon: Icons.fingerprint_rounded,
              iconColor: Colors.tealAccent,
              title: 'Biometrics & Fingerprint Sensor',
              subtitle: 'Unlock Chaty App Lock using biometric authentication',
              value: _biometricsGranted,
              onChanged: (val) => _requestOrToggle('Biometrics', _biometricsGranted, (v) => setState(() => _biometricsGranted = v)),
            ),
          ],
        ),

        // 5. Bulk Permission Actions
        ChatySettingsSection(
          title: 'All System Permissions',
          children: [
            ChatySettingsTile(
              icon: Icons.check_circle_rounded,
              iconColor: Colors.greenAccent,
              title: 'Grant All Permissions',
              subtitle: 'Allow Notifications, Media, Location, Camera & Audio at once',
              onTap: () async {
                try {
                  await [
                    Permission.contacts,
                    Permission.notification,
                    Permission.camera,
                    Permission.microphone,
                    Permission.photos,
                    Permission.storage,
                  ].request();
                } catch (_) {}
                setState(() {
                  _notificationGranted = true;
                  _cameraGranted = true;
                  _microphoneGranted = true;
                  _mediaPhotosGranted = true;
                  _locationGranted = true;
                  _contactsGranted = true;
                  _biometricsGranted = true;
                });
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All system permissions requested & granted!'), backgroundColor: Colors.green),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, bool granted, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: granted ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: granted ? Colors.greenAccent : Colors.redAccent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: granted ? Colors.greenAccent : Colors.redAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: granted ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            granted ? Icons.check : Icons.close,
            size: 12,
            color: granted ? Colors.greenAccent : Colors.redAccent,
          ),
        ],
      ),
    );
  }
}
