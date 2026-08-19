import 'package:flutter/material.dart';

import '../../domain/models/chat_message.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/messages/message_presentation_style.dart';
import '../../ui/core/theme/theme_config.dart';
import '../../ui/core/widgets/app_avatar.dart';

class PremiumMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ThemeConfig theme;
  final ChatyPreferencesController preferencesController;
  final String? senderName;
  final VoidCallback onLongPress;
  final VoidCallback? onTaskTap;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onMediaTap;

  const PremiumMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    required this.preferencesController,
    this.senderName,
    required this.onLongPress,
    this.onTaskTap,
    this.onReactionTap,
    this.onMediaTap,
  });

  String _time(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _delivery(MessagePresentationStyle style) {
    final normalized = style.tickStyle.toLowerCase();
    final readColor = preferencesController.gbColor('ModOnlineColor') ?? const Color(0xFF38BDF8);
    final base = isMe ? style.outgoingTime : style.incomingTime;
    if (message.deliveryState == DeliveryState.failed) {
      return const Icon(Icons.error_outline_rounded, size: 13, color: Colors.redAccent);
    }
    if (message.deliveryState == DeliveryState.queued || message.deliveryState == DeliveryState.sending) {
      return Icon(Icons.schedule_rounded, size: 13, color: base);
    }
    final isRead = message.deliveryState == DeliveryState.read;
    final color = isRead ? readColor : base;
    if (normalized.contains('minimal')) {
      return Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
    }
    if (normalized.contains('ios')) {
      return Icon(isRead ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded, size: 14, color: color);
    }
    if (normalized.contains('neon')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(6)),
        child: Icon(Icons.done_all_rounded, size: 11, color: color),
      );
    }
    if (message.deliveryState == DeliveryState.sent) return Icon(Icons.done_rounded, size: 14, color: color);
    return Icon(Icons.done_all_rounded, size: 15, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final style = MessagePresentationStyle.resolve(theme, preferencesController);
    if (message.type == MessageType.system) {
      return Semantics(
        label: 'System message: ${message.text}',
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
            decoration: BoxDecoration(color: theme.surfaceColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.cardColor)),
            child: Text(message.text, textAlign: TextAlign.center, style: TextStyle(color: theme.secondaryTextColor, fontSize: 11.5 * theme.fontScale)),
          ),
        ),
      );
    }

    if (message.isDeletedForEveryone) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(color: theme.surfaceColor.withValues(alpha: .65), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.block_rounded, size: 14, color: theme.secondaryTextColor),
            const SizedBox(width: 6),
            Flexible(child: Text('This message was deleted by sender', style: TextStyle(color: theme.secondaryTextColor, fontStyle: FontStyle.italic))),
          ]),
        ),
      );
    }

    final background = isMe ? style.outgoingBackground : style.incomingBackground;
    final textColor = isMe ? style.outgoingText : style.incomingText;
    final timeColor = isMe ? style.outgoingTime : style.incomingTime;
    final showAvatar = isMe ? style.showOutgoingAvatar : style.showIncomingAvatar;
    final avatarName = isMe ? 'ME' : (senderName ?? 'CH');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) ...[
            AppAvatar(initials: _initials(avatarName), colorHex: '0xFF6366F1', size: style.avatarSize),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * style.maxWidthFraction),
                    padding: style.bubblePadding,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: isMe ? style.outgoingRadius : style.incomingRadius,
                      boxShadow: style.elevated ? [BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 10, offset: const Offset(0, 3))] : const [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMe && senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(senderName!, style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.w800, fontSize: 11.5 * theme.fontScale)),
                          ),
                        if (message.replyToMessageId != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(color: style.quoteBackground, borderRadius: BorderRadius.circular(8), border: Border(left: BorderSide(color: style.quoteDivider, width: 3))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(message.replyToSenderName ?? 'Reply', style: TextStyle(color: style.quoteName, fontSize: 11 * theme.fontScale, fontWeight: FontWeight.w800)),
                              Text(message.replyToPreviewText ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: style.quoteText, fontSize: 11 * theme.fontScale)),
                            ]),
                          ),
                        if (message.type == MessageType.taskCard) _taskCard(textColor),
                        if (message.attachment != null) _attachment(textColor),
                        if (message.type != MessageType.taskCard && message.text.isNotEmpty)
                          SelectableText(message.text, style: TextStyle(color: textColor, fontSize: style.textSize * theme.fontScale, height: 1.35)),
                        const SizedBox(height: 3),
                        Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (message.isPinned) ...[Icon(Icons.push_pin_rounded, size: 11, color: timeColor), const SizedBox(width: 3)],
                          if (message.isStarred) ...[const Icon(Icons.star_rounded, size: 11, color: Colors.amber), const SizedBox(width: 3)],
                          Text(_time(message.createdAt), style: TextStyle(color: timeColor, fontSize: 10.5 * theme.fontScale)),
                          if (isMe) ...[const SizedBox(width: 4), AnimatedSwitcher(duration: const Duration(milliseconds: 160), child: KeyedSubtree(key: ValueKey(message.deliveryState), child: _delivery(style)))],
                        ]),
                      ],
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: message.reactions.map((reaction) => InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onReactionTap?.call(reaction.emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.accentColor.withValues(alpha: .25))),
                            child: Text('${reaction.emoji}${reaction.userIds.length > 1 ? ' ${reaction.userIds.length}' : ''}', style: TextStyle(color: theme.primaryTextColor, fontSize: 11)),
                          ),
                        )).toList(growable: false),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar) ...[
            const SizedBox(width: 7),
            AppAvatar(initials: 'ME', colorHex: '0xFF6366F1', size: style.avatarSize),
          ],
        ],
      ),
    );
  }

  Widget _taskCard(Color textColor) => InkWell(
        onTap: onTaskTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.cardColor.withValues(alpha: .4), borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.accentColor.withValues(alpha: .35))),
          child: Row(children: [
            Icon(Icons.task_alt_rounded, color: theme.accentColor, size: 20),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.text, style: TextStyle(color: textColor, fontWeight: FontWeight.w800)),
              Text('Linked task • Tap to open', style: TextStyle(color: textColor.withValues(alpha: .7), fontSize: 10.5)),
            ])),
          ]),
        ),
      );

  Widget _attachment(Color textColor) {
    final attachment = message.attachment!;
    if (attachment.type == 'image' || attachment.type == 'video') {
      return InkWell(
        onTap: onMediaTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Icon(attachment.type == 'video' ? Icons.play_circle_fill_rounded : Icons.image_rounded, size: 42, color: theme.accentColor)),
        ),
      );
    }
    if (attachment.type == 'audio') {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: theme.cardColor.withValues(alpha: .4), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(Icons.play_circle_fill_rounded, color: theme.accentColor, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text('Voice message • 0:${attachment.durationSeconds.toString().padLeft(2, '0')}', style: TextStyle(color: textColor, fontSize: 11.5))),
        ]),
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: theme.cardColor.withValues(alpha: .4), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.insert_drive_file_rounded, color: theme.accentColor, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Text(attachment.size, style: TextStyle(color: textColor.withValues(alpha: .7), fontSize: 10)),
      ]),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'CH';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }
}
