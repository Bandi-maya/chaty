import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/app_avatar.dart';

class GroupInfoScreen extends StatelessWidget {
  final ThemeConfig theme;
  final MockDataStore dataStore;
  final String conversationId;

  const GroupInfoScreen({
    super.key,
    required this.theme,
    required this.dataStore,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    final conv = dataStore.conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => dataStore.conversations.first,
    );

    final participants = conv.participantIds.map((id) => dataStore.getUserById(id)).whereType<dynamic>().toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit group name / avatar modal')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Group Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    initials: conv.avatarInitials ?? 'GP',
                    colorHex: conv.avatarColorHex,
                    size: 72,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    conv.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 18 * theme.fontScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${conv.participantIds.length} Participants • End-to-End Encrypted',
                    style: TextStyle(
                      color: theme.secondaryTextColor,
                      fontSize: 12.5 * theme.fontScale,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controls (Disappearing messages, Encryption Safety Number)
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: Color(0xFFF59E0B)),
                    title: Text('Disappearing Messages', style: TextStyle(color: theme.primaryTextColor, fontSize: 14)),
                    subtitle: Text('7 days active', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981)),
                    title: Text('Encryption Verification', style: TextStyle(color: theme.primaryTextColor, fontSize: 14)),
                    subtitle: Text('Group prekeys authenticated', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Participants List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Participants (${participants.length})',
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 14 * theme.fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mock invite link copied to clipboard.')),
                          );
                        },
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('Add Member', style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: participants.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = participants[index];
                      final isAdmin = conv.adminIds.contains(p.id);
                      final isMe = p.id == dataStore.currentUser.id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AppAvatar(
                          initials: p.avatarInitials,
                          colorHex: p.avatarColorHex,
                          size: 38,
                        ),
                        title: Row(
                          children: [
                            Text(
                              isMe ? '${p.displayName} (You)' : p.displayName,
                              style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 13.5 * theme.fontScale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: theme.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '@${p.username}',
                          style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Leave / Delete Actions
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
              ),
              child: ListTile(
                leading: Icon(Icons.exit_to_app_rounded, color: theme.dangerColor),
                title: Text(
                  'Leave Group',
                  style: TextStyle(color: theme.dangerColor, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Left group.')),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
