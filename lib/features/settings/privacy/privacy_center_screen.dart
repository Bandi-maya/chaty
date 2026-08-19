import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';

class PrivacyCenterScreen extends StatefulWidget {
  final ChatyPreferencesController preferencesController;

  const PrivacyCenterScreen({
    super.key,
    required this.preferencesController,
  });

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  static const List<String> _audienceOptions = [
    'Everyone',
    'My Contacts',
    'My Contacts Except…',
    'Nobody',
  ];

  static const List<String> _whoCanCallMeOptions = [
    'Everyone',
    'My Contacts',
    'My Contacts Except…',
    'Nobody',
  ];

  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferencesController.privacy;

    return ChatySettingsPage(
      title: 'Privacy Center',
      subtitle: 'Granular Last Seen, Receipts, Status & Chat Privacy',
      children: [
        // Freeze & Hide Last Seen Section
        ChatySettingsSection(
          title: 'Last Seen & Online Presence',
          description: 'Freeze your last seen timestamp or restrict audience visibility.',
          children: [
            ChatySwitchTile(
              icon: Icons.ac_unit_rounded,
              iconColor: Colors.lightBlueAccent,
              title: 'Freeze Last Seen',
              subtitle: prefs.freezeLastSeen
                  ? 'Frozen at ${prefs.frozenLastSeenTime.isNotEmpty ? prefs.frozenLastSeenTime : "now"}. Contacts will not see updated timestamps.'
                  : 'Stops updating your last visible timestamp to contacts.',
              value: prefs.freezeLastSeen,
              onChanged: (val) {
                final timestamp = val ? DateTime.now().toLocal().toString().substring(0, 16) : '';
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(freezeLastSeen: val, frozenLastSeenTime: timestamp),
                  logTitle: 'Freeze Last Seen',
                  prevVal: prefs.freezeLastSeen,
                  newVal: val,
                );
              },
            ),
            ChatyChoiceTile<String>(
              title: 'Who Can See My Last Seen',
              options: _audienceOptions,
              selectedOption: prefs.hideLastSeenAudience,
              optionLabel: (s) => s,
              onSelected: (aud) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(hideLastSeenAudience: aud),
                  logTitle: 'Hide Last Seen Audience',
                );
              },
            ),
            ChatyChoiceTile<String>(
              title: 'Who Can See When I\'m Online',
              options: const ['Everyone', 'Same as Last Seen'],
              selectedOption: prefs.hideOnlineAudience,
              optionLabel: (s) => s,
              onSelected: (aud) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(hideOnlineAudience: aud),
                  logTitle: 'Hide Online Audience',
                );
              },
            ),
          ],
        ),

        // Read Receipts & Indicators
        ChatySettingsSection(
          title: 'Read Receipts & Presence Simulation',
          children: [
            ChatySwitchTile(
              icon: Icons.done_all_rounded,
              iconColor: Colors.blueAccent,
              title: 'Read Receipts (Blue Ticks)',
              subtitle: 'Send and receive read receipts in direct conversations',
              value: prefs.readReceipts,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(readReceipts: val),
                  logTitle: 'Read Receipts',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.mark_chat_read_rounded,
              iconColor: Colors.indigoAccent,
              title: 'Show Blue Ticks After Reply',
              subtitle: 'Delay read receipt visualization until you reply to a message',
              value: prefs.showBlueTicksAfterReply,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(showBlueTicksAfterReply: val),
                  logTitle: 'Show Blue Ticks After Reply',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.edit_note_rounded,
              iconColor: Colors.orangeAccent,
              title: 'Typing Indicators',
              subtitle: 'Show when you are typing a message',
              value: prefs.typingIndicators,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(typingIndicators: val),
                  logTitle: 'Typing Indicators',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.mic_none_rounded,
              iconColor: Colors.redAccent,
              title: 'Recording Indicators',
              subtitle: 'Show presence when recording a voice note',
              value: prefs.recordingIndicators,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(recordingIndicators: val),
                  logTitle: 'Recording Indicators',
                );
              },
            ),
          ],
        ),

        // Anti-Delete & View Once Protection
        ChatySettingsSection(
          title: 'Anti-Delete & View-Once Safeguards',
          description: 'Prototype simulation: retain deleted messages and status updates locally.',
          children: [
            ChatySwitchTile(
              icon: Icons.delete_forever_rounded,
              iconColor: Colors.deepOrangeAccent,
              title: 'Anti-Delete Messages',
              subtitle: 'Deleted messages remain visible locally marked "Deleted by sender"',
              value: prefs.antiDeleteMessages,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(antiDeleteMessages: val),
                  logTitle: 'Anti-Delete Messages',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.history_toggle_off_rounded,
              iconColor: Colors.amberAccent,
              title: 'Anti-Delete Status / Stories',
              subtitle: 'Deleted contact stories remain locally viewable marked "Deleted by author"',
              value: prefs.antiDeleteStatus,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(antiDeleteStatus: val),
                  logTitle: 'Anti-Delete Status',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.remove_red_eye_rounded,
              iconColor: Colors.tealAccent,
              title: 'Anti View-Once Media',
              subtitle: 'View-once photos and videos remain viewable after opening (Demo behavior)',
              value: prefs.antiViewOnce,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(antiViewOnce: val),
                  logTitle: 'Anti View Once',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.notification_important_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Message & Status Revoke Alerts',
              subtitle: 'Generate in-app notifications whenever a mock message or story is revoked',
              value: prefs.messageRevokeAlert,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(
                    messageRevokeAlert: val,
                    statusRevocationAlert: val,
                  ),
                  logTitle: 'Revoke Alerts',
                );
              },
            ),
          ],
        ),

        // Calling & Forwarding Privacy
        ChatySettingsSection(
          title: 'Call & Forwarding Controls',
          children: [
            ChatyChoiceTile<String>(
              title: 'Who Can Call Me',
              options: _whoCanCallMeOptions,
              selectedOption: prefs.whoCanCallMe,
              optionLabel: (s) => s,
              onSelected: (aud) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(whoCanCallMe: aud),
                  logTitle: 'Who Can Call Me',
                );
              },
            ),
            ChatySwitchTile(
              icon: Icons.shortcut_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Disable Forwarded Tag',
              subtitle: 'Remove the "Forwarded" label from forwarded outgoing messages',
              value: prefs.disableForwardedLabel,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(disableForwardedLabel: val),
                  logTitle: 'Disable Forwarded Label',
                );
              },
            ),
          ],
        ),

        // Advanced Privacy & Recovery
        ChatySettingsSection(
          title: 'Advanced Settings & Recovery',
          children: [
            ChatySwitchTile(
              icon: Icons.visibility_off_rounded,
              iconColor: Colors.grey,
              title: 'Hide Privacy Option from Main Settings',
              subtitle: 'Hide this Privacy entry. Restore via Settings → Restore Hidden Settings.',
              value: prefs.hidePrivacyOption,
              onChanged: (val) {
                widget.preferencesController.updatePrivacy(
                  prefs.copyWith(hidePrivacyOption: val),
                  logTitle: 'Hide Privacy Option',
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
