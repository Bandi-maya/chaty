import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../domain/models/other_models.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/app_avatar.dart';
import 'mock_call_screen.dart';

import '../../injection/locator.dart';
import '../../../ui/core/theme/theme_controller.dart';

class CallsScreen extends StatelessWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;

  const CallsScreen({
    super.key,
    required this.theme,
    required this.dataStore,
  });

  String _formatCallTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final calls = dataStore.calls;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Calls & Audio Logs',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 24 * theme.fontScale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: calls.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: theme.accentColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone_callback_rounded,
                                size: 54,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No calls yet',
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Voice and end-to-end encrypted video call logs will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.secondaryTextColor,
                                fontSize: 13.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: calls.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {

                  final call = calls[index];
                  final caller = dataStore.getUserById(call.callerId);
                  final isMissed = call.direction == CallDirection.missed;

                  return ListTile(
                    leading: AppAvatar(
                      initials: caller?.avatarInitials ?? 'U',
                      colorHex: caller?.avatarColorHex,
                      size: 44,
                    ),
                    title: Text(
                      caller?.displayName ?? 'Secure Caller',
                      style: TextStyle(
                        color: isMissed ? theme.dangerColor : theme.primaryTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5 * theme.fontScale,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          call.direction == CallDirection.incoming
                              ? Icons.call_received_rounded
                              : call.direction == CallDirection.outgoing
                                  ? Icons.call_made_rounded
                                  : Icons.call_missed_rounded,
                          size: 13,
                          color: isMissed ? theme.dangerColor : theme.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_formatCallTime(call.timestamp)} • ${call.durationSeconds > 0 ? '${call.durationSeconds}s' : 'Missed'}',
                          style: TextStyle(color: theme.secondaryTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        call.type == CallType.video ? Icons.videocam_rounded : Icons.call_rounded,
                        color: theme.accentColor,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MockCallScreen(
                              theme: theme,
                              title: caller?.displayName ?? 'Contact',
                              isVideo: call.type == CallType.video,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.onAccentColor,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Starting new encrypted call... Select contact.')),
            );
          },
          child: const Icon(Icons.add_call),
        ),
      ),
    );
  }
}
