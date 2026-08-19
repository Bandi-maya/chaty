import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../domain/models/chat_message.dart';
import '../../ui/core/widgets/app_avatar.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ThemeConfig theme;
  final String? senderName;
  final VoidCallback onLongPress;
  final VoidCallback? onTaskTap;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onMediaTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    this.senderName,
    required this.onLongPress,
    this.onTaskTap,
    this.onReactionTap,
    this.onMediaTap,
  });

  BorderRadius _getBubbleBorderRadius() {
    final r = Radius.circular(theme.cornerRadius);
    switch (theme.bubbleStyle) {
      case AppBubbleStyle.rounded:
        return BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: isMe ? r : const Radius.circular(3),
          bottomRight: isMe ? const Radius.circular(3) : r,
        );
      case AppBubbleStyle.softSquare:
        return BorderRadius.circular(6);
      case AppBubbleStyle.pill:
        return BorderRadius.circular(24);
      case AppBubbleStyle.sharpTail:
        return BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: isMe ? r : Radius.zero,
          bottomRight: isMe ? Radius.zero : r,
        );
    }
  }

  Widget _buildDeliveryIcon() {
    Widget icon;
    switch (message.deliveryState) {
      case DeliveryState.queued:
      case DeliveryState.sending:
        icon = const Icon(Icons.access_time_rounded, key: ValueKey('queued'), size: 12, color: Colors.white70);
        break;
      case DeliveryState.sent:
        icon = const Icon(Icons.done_rounded, key: ValueKey('sent'), size: 13, color: Colors.white70);
        break;
      case DeliveryState.delivered:
        icon = const Icon(Icons.done_all_rounded, key: ValueKey('delivered'), size: 14, color: Colors.white70);
        break;
      case DeliveryState.read:
        icon = const Icon(Icons.done_all_rounded, key: ValueKey('read'), size: 14, color: Color(0xFF38BDF8));
        break;
      case DeliveryState.failed:
        icon = const Icon(Icons.error_outline_rounded, key: ValueKey('failed'), size: 12, color: Colors.redAccent);
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: icon,
    );
  }


  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    // System Event Banner
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.surfaceColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.cardColor),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.secondaryTextColor,
              fontSize: 11.5 * theme.fontScale,
            ),
          ),
        ),
      );
    }

    // Deleted for everyone
    if (message.isDeletedForEveryone) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: theme.surfaceColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(theme.cornerRadius),
            border: Border.all(color: theme.surfaceColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, size: 14, color: theme.secondaryTextColor),
              const SizedBox(width: 6),
              Text(
                'This message was deleted by sender',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 13 * theme.fontScale,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bubbleBg = isMe ? theme.outgoingBubbleColor : theme.incomingBubbleColor;
    final textColor = isMe ? theme.outgoingTextColor : theme.incomingTextColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Avatar for incoming group messages
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 2.0),
              child: AppAvatar(
                initials: senderName!.split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join(),
                colorHex: '0xFF6366F1',
                size: 28,
              ),
            ),

          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bubbleBg,
                      borderRadius: _getBubbleBorderRadius(),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Sender Name Header
                        if (!isMe && senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3.0),
                            child: Text(
                              senderName!,
                              style: TextStyle(
                                color: theme.accentColor,
                                fontSize: 11.5 * theme.fontScale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                        // Reply Context Quote Header
                        if (message.replyToMessageId != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border(
                                left: BorderSide(
                                  color: isMe ? Colors.white70 : theme.accentColor,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToSenderName ?? 'Reply',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : theme.accentColor,
                                    fontSize: 11 * theme.fontScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  message.replyToPreviewText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.8),
                                    fontSize: 11 * theme.fontScale,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Task Card Message Type
                        if (message.type == MessageType.taskCard)
                          InkWell(
                            onTap: onTaskTap,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.accentColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.task_alt_rounded, color: theme.accentColor, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13 * theme.fontScale,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Linked Task • Tap to open board',
                                          style: TextStyle(
                                            color: textColor.withValues(alpha: 0.7),
                                            fontSize: 11 * theme.fontScale,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Image / Video Attachment
                        if (message.attachment != null &&
                            (message.attachment!.type == 'image' || message.attachment!.type == 'video'))
                          GestureDetector(
                            onTap: onMediaTap,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    message.attachment!.type == 'video' ? Icons.play_circle_fill_rounded : Icons.image_rounded,
                                    size: 44,
                                    color: Colors.white,
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        message.attachment!.size,
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Audio Voice Note Attachment
                        if (message.attachment != null && message.attachment!.type == 'audio')
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          16,
                                          (i) => Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 1),
                                              height: (8 + (i % 5) * 4).toDouble(),
                                              decoration: BoxDecoration(
                                                color: textColor.withValues(alpha: 0.7),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '0:${message.attachment!.durationSeconds.toString().padLeft(2, '0')}',
                                        style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Document Attachment
                        if (message.attachment != null && message.attachment!.type == 'document')
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_rounded, color: Colors.redAccent, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.attachment!.name,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12.5 * theme.fontScale,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        message.attachment!.size,
                                        style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Text Body
                        if (message.type != MessageType.taskCard && message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14 * theme.fontScale,
                              height: 1.35,
                            ),
                          ),

                        const SizedBox(height: 3),

                        // Timestamp & Delivery State Row
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.isPinned) ...[
                              Icon(Icons.push_pin_rounded, size: 11, color: textColor.withValues(alpha: 0.7)),
                              const SizedBox(width: 3),
                            ],
                            if (message.isStarred) ...[
                              const Icon(Icons.star_rounded, size: 11, color: Colors.amber),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.65),
                                fontSize: 10.5 * theme.fontScale,
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              _buildDeliveryIcon(),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reactions Bar
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, left: 4.0, right: 4.0),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.map((r) {
                          return GestureDetector(
                            onTap: () => onReactionTap?.call(r.emoji),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.accentColor.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(r.emoji, style: const TextStyle(fontSize: 12)),
                                  if (r.userIds.length > 1) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      r.userIds.length.toString(),
                                      style: TextStyle(
                                        color: theme.primaryTextColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
