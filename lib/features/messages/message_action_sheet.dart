import 'package:flutter/material.dart';
import '../../domain/models/chat_message.dart';
import '../../ui/core/theme/theme_config.dart';


class MessageActionSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ThemeConfig theme;
  final Function(String emoji) onReact;
  final VoidCallback onReply;
  final VoidCallback onCreateTask;
  final VoidCallback onPin;
  final VoidCallback onStar;
  final VoidCallback onCopy;
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final VoidCallback onReport;

  const MessageActionSheet({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    required this.onReact,
    required this.onReply,
    required this.onCreateTask,
    required this.onPin,
    required this.onStar,
    required this.onCopy,
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final quickEmojis = ['👍', '❤️', '🔥', '🎉', '🛡️', '👀', '🚀', '⚡'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.secondaryTextColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick reactions row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: quickEmojis.map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onReact(emoji);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Action Items
            _buildActionTile(
              icon: Icons.reply_rounded,
              label: 'Reply',
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            _buildActionTile(
              icon: Icons.task_alt_rounded,
              label: 'Create Task from Message',
              color: theme.accentColor,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onCreateTask();
              },
            ),
            _buildActionTile(
              icon: message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
              label: message.isPinned ? 'Unpin Message' : 'Pin Message',
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onPin();
              },
            ),
            _buildActionTile(
              icon: message.isStarred ? Icons.star_border_rounded : Icons.star_rounded,
              label: message.isStarred ? 'Unstar' : 'Star Message',
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onStar();
              },
            ),
            _buildActionTile(
              icon: Icons.content_copy_rounded,
              label: 'Copy Text',
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onCopy();
              },
            ),
            _buildActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete for me',
              color: theme.dangerColor,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onDeleteForMe();
              },
            ),
            if (isMe && onDeleteForEveryone != null)
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                label: 'Delete for everyone',
                color: theme.dangerColor,
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  onDeleteForEveryone!();
                },
              ),
            _buildActionTile(
              icon: Icons.report_problem_outlined,
              label: 'Report Message (consented disclosure)',
              color: theme.secondaryTextColor,
              theme: theme,
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    Color? color,
    required ThemeConfig theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? theme.primaryTextColor, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? theme.primaryTextColor,
          fontSize: 14 * theme.fontScale,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: onTap,
    );
  }
}
