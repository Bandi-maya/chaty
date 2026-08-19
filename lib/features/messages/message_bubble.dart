import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ui/core/theme/theme_config.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/visual_preferences.dart';
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
  final String bubbleVariant;

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
    this.bubbleVariant = 'Soft Rounded',
  });

  Color _readable(Color background, Color preferred) {
    if (ThemeConfig.calculateContrastRatio(preferred, background) >= 4.5) {
      return preferred;
    }
    final blackRatio = ThemeConfig.calculateContrastRatio(Colors.black, background);
    final whiteRatio = ThemeConfig.calculateContrastRatio(Colors.white, background);
    return blackRatio >= whiteRatio ? Colors.black : Colors.white;
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDeliveryIcon(Color color) {
    final muted = color.withValues(alpha: 0.72);
    Widget icon;
    switch (message.deliveryState) {
      case DeliveryState.queued:
      case DeliveryState.sending:
        icon = Icon(
          Icons.access_time_rounded,
          key: const ValueKey<String>('queued'),
          size: 12,
          color: muted,
        );
      case DeliveryState.sent:
        icon = Icon(
          Icons.done_rounded,
          key: const ValueKey<String>('sent'),
          size: 13,
          color: muted,
        );
      case DeliveryState.delivered:
        icon = Icon(
          Icons.done_all_rounded,
          key: const ValueKey<String>('delivered'),
          size: 14,
          color: muted,
        );
      case DeliveryState.read:
        final blue = const Color(0xFF0284C7);
        icon = Icon(
          Icons.done_all_rounded,
          key: const ValueKey<String>('read'),
          size: 14,
          color: ThemeConfig.calculateContrastRatio(blue, _bubbleBackground()) >= 3
              ? blue
              : color,
        );
      case DeliveryState.failed:
        icon = Icon(
          Icons.error_outline_rounded,
          key: const ValueKey<String>('failed'),
          size: 13,
          color: theme.dangerColor,
        );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: icon,
    );
  }

  Color _bubbleBackground() {
    final base = isMe ? theme.outgoingBubbleColor : theme.incomingBubbleColor;
    final index = VisualPreferences.bubbleStyles.indexOf(bubbleVariant).clamp(0, 19);
    if (index == 17) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF202124)
          : const Color(0xFFF1F3F4);
    }
    if (index == 18) return theme.cardColor;
    if (index == 19) return theme.surfaceColor;
    return base;
  }

  _BubbleProfile get _profile => _BubbleProfile.fromStyle(bubbleVariant, theme);

  BorderRadius _bubbleRadius(_BubbleProfile profile) {
    if (profile.pill) return BorderRadius.circular(28);
    final radius = Radius.circular(profile.radius);
    if (!profile.tail) return BorderRadius.circular(profile.radius);
    return BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: isMe ? radius : Radius.circular(profile.tailRadius),
      bottomRight: isMe ? Radius.circular(profile.tailRadius) : radius,
    );
  }

  Color _subtleSurface(Color bubble, Color text) {
    final amount = theme.brightness == Brightness.dark ? 0.12 : 0.08;
    return Color.alphaBlend(text.withValues(alpha: amount), bubble);
  }

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.secondaryTextColor.withValues(alpha: 0.12),
            ),
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

    if (message.isDeletedForEveryone) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(theme.cornerRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.block_rounded, size: 14, color: theme.secondaryTextColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'This message was deleted by sender',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 13 * theme.fontScale,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    final bubble = _bubbleBackground();
    final preferredText = isMe ? theme.outgoingTextColor : theme.incomingTextColor;
    final textColor = _readable(bubble, preferredText);
    final subtleSurface = _subtleSurface(bubble, textColor);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = math.min(560.0, math.max(220.0, viewportWidth * 0.76));

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: profile.verticalGap,
        horizontal: profile.horizontalGap,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: AppAvatar(
                initials: senderName!
                    .split(' ')
                    .where((part) => part.isNotEmpty)
                    .map((part) => part[0])
                    .take(2)
                    .join(),
                colorHex: '0xFF6366F1',
                size: 28,
              ),
            ),
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    padding: EdgeInsets.symmetric(
                      horizontal: profile.horizontalPadding,
                      vertical: profile.verticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color: bubble,
                      borderRadius: _bubbleRadius(profile),
                      border: profile.outlined
                          ? Border.all(
                              color: profile.accentBorder
                                  ? theme.accentColor.withValues(alpha: 0.55)
                                  : textColor.withValues(alpha: 0.16),
                            )
                          : null,
                      boxShadow: profile.elevated
                          ? <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? 0.20
                                      : 0.08,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : const <BoxShadow>[],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (!isMe && senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              senderName!,
                              style: TextStyle(
                                color: _readable(bubble, theme.accentColor),
                                fontSize: 11.5 * theme.fontScale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (message.replyToMessageId != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: subtleSurface,
                              borderRadius: BorderRadius.circular(7),
                              border: Border(
                                left: BorderSide(
                                  color: _readable(bubble, theme.accentColor),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  message.replyToSenderName ?? 'Reply',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 11 * theme.fontScale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  message.replyToPreviewText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.76),
                                    fontSize: 11 * theme.fontScale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (message.type == MessageType.taskCard)
                          InkWell(
                            onTap: onTaskTap,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: subtleSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: theme.accentColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.task_alt_rounded,
                                    color: _readable(subtleSurface, theme.accentColor),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          message.text,
                                          style: TextStyle(
                                            color: _readable(subtleSurface, textColor),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13 * theme.fontScale,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Linked task • Tap for full details',
                                          style: TextStyle(
                                            color: _readable(subtleSurface, textColor)
                                                .withValues(alpha: 0.72),
                                            fontSize: 11 * theme.fontScale,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: _readable(subtleSurface, textColor)
                                        .withValues(alpha: 0.72),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (message.attachment != null &&
                            (message.attachment!.type == 'image' ||
                                message.attachment!.type == 'video'))
                          GestureDetector(
                            onTap: onMediaTap,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: subtleSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Icon(
                                    message.attachment!.type == 'video'
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.image_rounded,
                                    size: 44,
                                    color: textColor.withValues(alpha: 0.84),
                                  ),
                                  Positioned(
                                    bottom: 7,
                                    right: 8,
                                    child: Text(
                                      message.attachment!.size,
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.70),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (message.attachment != null &&
                            message.attachment!.type == 'audio')
                          InkWell(
                            onTap: onMediaTap,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: subtleSurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: textColor,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: List<Widget>.generate(
                                        16,
                                        (index) => Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 1,
                                            ),
                                            height: (7 + (index % 5) * 3).toDouble(),
                                            decoration: BoxDecoration(
                                              color: textColor.withValues(alpha: 0.62),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '0:${message.attachment!.durationSeconds.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.72),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (message.attachment != null &&
                            message.attachment!.type == 'document')
                          InkWell(
                            onTap: onMediaTap,
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: subtleSurface,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.description_rounded,
                                    color: textColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          message.attachment!.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 12.5 * theme.fontScale,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          message.attachment!.size,
                                          style: TextStyle(
                                            color: textColor.withValues(alpha: 0.7),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (message.type != MessageType.taskCard &&
                            message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14 * theme.fontScale,
                              height: 1.35,
                            ),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            if (message.isPinned) ...<Widget>[
                              Icon(
                                Icons.push_pin_rounded,
                                size: 11,
                                color: textColor.withValues(alpha: 0.72),
                              ),
                              const SizedBox(width: 3),
                            ],
                            if (message.isStarred) ...<Widget>[
                              const Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.66),
                                fontSize: 10.5 * theme.fontScale,
                              ),
                            ),
                            if (isMe) ...<Widget>[
                              const SizedBox(width: 4),
                              _buildDeliveryIcon(textColor),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (message.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                      child: Wrap(
                        spacing: 4,
                        children: message.reactions.map((reaction) {
                          return GestureDetector(
                            onTap: () => onReactionTap?.call(reaction.emoji),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
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
                                children: <Widget>[
                                  Text(
                                    reaction.emoji,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (reaction.userIds.length > 1) ...<Widget>[
                                    const SizedBox(width: 3),
                                    Text(
                                      reaction.userIds.length.toString(),
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

class _BubbleProfile {
  final double radius;
  final double tailRadius;
  final double horizontalPadding;
  final double verticalPadding;
  final double horizontalGap;
  final double verticalGap;
  final bool tail;
  final bool pill;
  final bool outlined;
  final bool accentBorder;
  final bool elevated;

  const _BubbleProfile({
    required this.radius,
    required this.tailRadius,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.horizontalGap,
    required this.verticalGap,
    required this.tail,
    required this.pill,
    required this.outlined,
    required this.accentBorder,
    required this.elevated,
  });

  factory _BubbleProfile.fromStyle(String style, ThemeConfig theme) {
    final index = VisualPreferences.bubbleStyles.indexOf(style).clamp(0, 19);
    return _BubbleProfile(
      radius: switch (index) {
        2 || 5 || 11 => 8,
        3 => 28,
        4 || 13 => 22,
        9 => 12,
        10 => 6,
        _ => theme.cornerRadius,
      },
      tailRadius: <int>{1, 9}.contains(index) ? 2 : 5,
      horizontalPadding: <int>{2, 11}.contains(index)
          ? 9
          : (<int>{12, 13}.contains(index) ? 15 : 12),
      verticalPadding: <int>{2, 11}.contains(index)
          ? 6
          : (<int>{13}.contains(index) ? 11 : 8),
      horizontalGap: <int>{12, 13}.contains(index) ? 16 : 12,
      verticalGap: <int>{2, 11}.contains(index) ? 2 : 3,
      tail: <int>{0, 1, 9}.contains(index),
      pill: index == 3,
      outlined: <int>{6, 16}.contains(index),
      accentBorder: index == 16,
      elevated: <int>{7, 14, 18}.contains(index),
    );
  }
}
