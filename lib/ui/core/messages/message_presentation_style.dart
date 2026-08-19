import 'package:flutter/material.dart';

import '../controllers/chaty_preferences_controller.dart';
import '../theme/theme_config.dart';

class MessagePresentationStyle {
  final BorderRadius outgoingRadius;
  final BorderRadius incomingRadius;
  final EdgeInsets bubblePadding;
  final Color outgoingBackground;
  final Color incomingBackground;
  final Color outgoingText;
  final Color incomingText;
  final Color outgoingTime;
  final Color incomingTime;
  final Color quoteDivider;
  final Color quoteName;
  final Color quoteText;
  final Color quoteBackground;
  final double textSize;
  final String tickStyle;
  final bool showIncomingAvatar;
  final bool showOutgoingAvatar;
  final double avatarSize;
  final double maxWidthFraction;
  final bool elevated;

  const MessagePresentationStyle({
    required this.outgoingRadius,
    required this.incomingRadius,
    required this.bubblePadding,
    required this.outgoingBackground,
    required this.incomingBackground,
    required this.outgoingText,
    required this.incomingText,
    required this.outgoingTime,
    required this.incomingTime,
    required this.quoteDivider,
    required this.quoteName,
    required this.quoteText,
    required this.quoteBackground,
    required this.textSize,
    required this.tickStyle,
    required this.showIncomingAvatar,
    required this.showOutgoingAvatar,
    required this.avatarSize,
    required this.maxWidthFraction,
    required this.elevated,
  });

  factory MessagePresentationStyle.resolve(ThemeConfig theme, ChatyPreferencesController prefs) {
    final requested = prefs.gbString('bubble_style', fallback: prefs.conversation.bubbleShape).toLowerCase();
    final radius = prefs.conversation.bubbleRadius.clamp(2.0, 32.0);
    BorderRadius incoming;
    BorderRadius outgoing;
    EdgeInsets padding = EdgeInsets.symmetric(horizontal: prefs.conversation.bubblePadding.clamp(7.0, 22.0), vertical: 8);
    double width = .78;
    bool elevated = false;

    switch (requested) {
      case 'tail':
      case 'classic':
        incoming = BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius), bottomRight: Radius.circular(radius), bottomLeft: const Radius.circular(3));
        outgoing = BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius), bottomLeft: Radius.circular(radius), bottomRight: const Radius.circular(3));
        break;
      case 'tail-less':
        incoming = outgoing = BorderRadius.circular(radius);
        break;
      case 'compact':
        incoming = outgoing = BorderRadius.circular(10);
        padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 6);
        width = .72;
        break;
      case 'squircle':
        incoming = outgoing = BorderRadius.circular(20);
        break;
      case 'card':
        incoming = outgoing = BorderRadius.circular(14);
        elevated = true;
        width = .82;
        break;
      case 'pill':
        incoming = outgoing = BorderRadius.circular(28);
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        break;
      case 'minimal':
        incoming = outgoing = BorderRadius.circular(6);
        elevated = false;
        break;
      default:
        incoming = BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius), bottomRight: Radius.circular(radius), bottomLeft: const Radius.circular(5));
        outgoing = BorderRadius.only(topLeft: Radius.circular(radius), topRight: Radius.circular(radius), bottomLeft: Radius.circular(radius), bottomRight: const Radius.circular(5));
    }

    Color color(String key, Color fallback) => prefs.gbColor(key) ?? fallback;
    final textSize = prefs.gbDouble('text_size_pick', fallback: 14).clamp(10.0, 24.0);
    final avatarSize = prefs.gbDouble('pic_chat_size_pickerV2', fallback: 28).clamp(22.0, 48.0);
    final picInside = prefs.gbBool('pic_inside');

    return MessagePresentationStyle(
      outgoingRadius: outgoing,
      incomingRadius: incoming,
      bubblePadding: padding,
      outgoingBackground: color('ModChatRightBubble', prefs.conversation.customOutgoingBubbleHex == 0 ? theme.outgoingBubbleColor : Color(prefs.conversation.customOutgoingBubbleHex)),
      incomingBackground: color('ModChatLeftBubble', prefs.conversation.customIncomingBubbleHex == 0 ? theme.incomingBubbleColor : Color(prefs.conversation.customIncomingBubbleHex)),
      outgoingText: color('ModChatBubbleText', theme.outgoingTextColor),
      incomingText: color('ModChatBubbleTextLeft', theme.incomingTextColor),
      outgoingTime: color('date_right_color', theme.outgoingTextColor.withValues(alpha: .65)),
      incomingTime: color('date_left_color', theme.incomingTextColor.withValues(alpha: .65)),
      quoteDivider: color('quoted_divider_picker', theme.accentColor),
      quoteName: color('quoted_name_picker', theme.accentColor),
      quoteText: color('quoted_text_picker', theme.secondaryTextColor),
      quoteBackground: color('quoted_bg_picker', theme.cardColor.withValues(alpha: .55)),
      textSize: textSize,
      tickStyle: prefs.gbString('tick_style', fallback: prefs.conversation.tickStyle),
      showIncomingAvatar: picInside || prefs.gbBool('chat_contactpicV2'),
      showOutgoingAvatar: picInside || prefs.gbBool('chat_mypicV2'),
      avatarSize: avatarSize,
      maxWidthFraction: width,
      elevated: elevated,
    );
  }
}
