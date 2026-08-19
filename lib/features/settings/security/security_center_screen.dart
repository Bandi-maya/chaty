import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import 'app_lock_overlay.dart';

class SecurityCenterScreen extends StatefulWidget {
  final ChatyPreferencesController preferencesController;

  const SecurityCenterScreen({
    super.key,
    required this.preferencesController,
  });

  @override
  State<SecurityCenterScreen> createState() => _SecurityCenterScreenState();
}

class _SecurityCenterScreenState extends State<SecurityCenterScreen> {
  static const List<String> _lockMethods = [
    'Biometric',
    'PIN',
    'Pattern',
    'Password',
  ];

  static const List<String> _autoLockOptions = [
    'Immediately',
    '15s',
    '30s',
    '1m',
    '5m',
    '15m',
  ];

  void _promptCodeChange(String type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change $type'),
        content: TextField(
          controller: controller,
          obscureText: type != 'PIN',
          keyboardType: type == 'PIN' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Enter new $type',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newCode = controller.text.trim();
              if (newCode.isNotEmpty) {
                final sec = widget.preferencesController.security;
                if (type == 'PIN') {
                  widget.preferencesController.updateSecurity(sec.copyWith(pinCode: newCode), logTitle: 'Change PIN');
                } else if (type == 'Password') {
                  widget.preferencesController.updateSecurity(sec.copyWith(password: newCode), logTitle: 'Change Password');
                } else if (type == 'Pattern') {
                  widget.preferencesController.updateSecurity(sec.copyWith(patternCode: newCode), logTitle: 'Change Pattern');
                }
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated $type successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSafetyNumberDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Safety Number Verification'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '05423 89104 33812 77192\n44901 88321 00192 44381',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Demo Security Model • End-to-end encryption state verified with prekey identity.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Verified')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sec = widget.preferencesController.security;

    return ChatySettingsPage(
      title: 'Security & App Lock',
      subtitle: 'Encryption Status, Authentication & Chaty Lock',
      children: [
        // Encryption Status Card
        ChatySettingsSection(
          title: 'Encryption & Trust Model',
          description: 'All conversations in Chaty utilize local end-to-end encryption simulation.',
          children: [
            ChatySettingsTile(
              icon: Icons.shield_rounded,
              iconColor: Colors.greenAccent,
              title: 'Demo Security Model',
              subtitle: 'Double-ratchet session status: Active & Verified',
              badgeText: 'ENCRYPTED',
              badgeColor: Colors.greenAccent,
              onTap: _showSafetyNumberDialog,
            ),
            ChatySettingsTile(
              icon: Icons.qr_code_2_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Verify Safety Number QR',
              subtitle: 'Simulate key fingerprints for security auditing',
              onTap: _showSafetyNumberDialog,
            ),
          ],
        ),

        // Chaty App Lock
        ChatySettingsSection(
          title: 'Chaty App Lock',
          description: 'Require passcode or biometric verification to access Chaty.',
          children: [
            ChatySwitchTile(
              icon: Icons.lock_rounded,
              iconColor: Colors.amberAccent,
              title: 'Enable Chaty Lock',
              subtitle: sec.isAppLockEnabled ? 'App lock active (${sec.lockMethod})' : 'Protect application with passcode or biometrics',
              value: sec.isAppLockEnabled,
              onChanged: (val) {
                widget.preferencesController.updateSecurity(
                  sec.copyWith(isAppLockEnabled: val),
                  logTitle: 'Enable App Lock',
                );
              },
            ),
            if (sec.isAppLockEnabled) ...[
              ChatyChoiceTile<String>(
                title: 'Lock Method',
                options: _lockMethods,
                selectedOption: sec.lockMethod,
                optionLabel: (s) => s,
                onSelected: (m) {
                  widget.preferencesController.updateSecurity(sec.copyWith(lockMethod: m), logTitle: 'Lock Method');
                },
              ),
              if (sec.lockMethod == 'PIN')
                ChatySettingsTile(
                  icon: Icons.pin_rounded,
                  title: 'Change PIN Code',
                  subtitle: 'Current PIN: ****',
                  onTap: () => _promptCodeChange('PIN'),
                ),
              if (sec.lockMethod == 'Password')
                ChatySettingsTile(
                  icon: Icons.password_rounded,
                  title: 'Change Lock Password',
                  subtitle: 'Current Password: ********',
                  onTap: () => _promptCodeChange('Password'),
                ),
              if (sec.lockMethod == 'Pattern') ...[
                ChatySettingsTile(
                  icon: Icons.pattern_rounded,
                  title: 'Change Pattern Code',
                  onTap: () => _promptCodeChange('Pattern'),
                ),
                ChatySwitchTile(
                  title: 'Make Pattern Invisible',
                  subtitle: 'Hide pattern lines while drawing',
                  value: sec.makePatternInvisible,
                  onChanged: (val) => widget.preferencesController.updateSecurity(sec.copyWith(makePatternInvisible: val)),
                ),
                ChatySwitchTile(
                  title: 'Disable Pattern Vibration',
                  subtitle: 'Turn off haptic feedback on pattern drag',
                  value: sec.disablePatternVibration,
                  onChanged: (val) => widget.preferencesController.updateSecurity(sec.copyWith(disablePatternVibration: val)),
                ),
              ],
              ChatyChoiceTile<String>(
                title: 'Auto Lock Timeout',
                options: _autoLockOptions,
                selectedOption: sec.autoLockTimeout,
                optionLabel: (s) => s,
                onSelected: (t) => widget.preferencesController.updateSecurity(sec.copyWith(autoLockTimeout: t)),
              ),
              ChatySwitchTile(
                icon: Icons.notifications_paused_rounded,
                title: 'Hide Notification Content when Locked',
                subtitle: 'Conceal message body text on lock screen overlays',
                value: sec.hideLockNotificationContent,
                onChanged: (val) => widget.preferencesController.updateSecurity(sec.copyWith(hideLockNotificationContent: val)),
              ),
              ChatySettingsTile(
                icon: Icons.lock_open_rounded,
                iconColor: Colors.deepOrangeAccent,
                title: 'Test Lock Screen Overlay',
                subtitle: 'Simulate app lock entry screen',
                onTap: () {
                  AppLockOverlayModal.show(context, preferencesController: widget.preferencesController);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
