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
    final requested = prefs.gbString('bubble_style', fallback: prefs.conversation.bubbleShape).trim().toLowerCase();
    final radius = prefs.conversation.bubbleRadius.clamp(2.0, 32.0).toDouble();
    final horizontalPadding = prefs.conversation.bubblePadding.clamp(7.0, 22.0).toDouble();

    BorderRadius incoming = BorderRadius.circular(radius);
    BorderRadius outgoing = BorderRadius.circular(radius);
    EdgeInsets padding = EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8);
    double width = .78;
    bool elevated = false;

    switch (requested) {
      case 'classic tail':
      case 'tail':
      case 'classic':
        incoming = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
          bottomLeft: const Radius.circular(3),
        );
        outgoing = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: const Radius.circular(3),
        );
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
        padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 9);
        break;
      case 'card':
        incoming = outgoing = BorderRadius.circular(14);
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
        elevated = true;
        width = .82;
        break;
      case 'pill':
        incoming = outgoing = BorderRadius.circular(28);
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        width = .76;
        break;
      case 'minimal':
        incoming = outgoing = BorderRadius.circular(6);
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 7);
        width = .74;
        break;
      case 'sharp':
        incoming = outgoing = BorderRadius.circular(2);
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        width = .77;
        break;
      case 'soft':
        incoming = outgoing = BorderRadius.circular(18);
        padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 11);
        width = .80;
        break;
      case 'wide':
        incoming = outgoing = BorderRadius.circular(16);
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9);
        width = .88;
        break;
      case 'narrow':
        incoming = outgoing = BorderRadius.circular(15);
        padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 8);
        width = .66;
        break;
      case 'dense':
        incoming = outgoing = BorderRadius.circular(8);
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5);
        width = .70;
        break;
      case 'airy':
        incoming = outgoing = BorderRadius.circular(22);
        padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 13);
        width = .84;
        break;
      case 'editorial':
        incoming = BorderRadius.only(
          topLeft: const Radius.circular(4),
          topRight: Radius.circular(radius),
          bottomLeft: const Radius.circular(4),
          bottomRight: Radius.circular(radius),
        );
        outgoing = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: const Radius.circular(4),
          bottomLeft: Radius.circular(radius),
          bottomRight: const Radius.circular(4),
        );
        padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
        width = .80;
        break;
      case 'workspace':
        incoming = outgoing = BorderRadius.circular(12);
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9);
        width = .86;
        elevated = true;
        break;
      case 'focus':
        incoming = outgoing = BorderRadius.circular(10);
        padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 11);
        width = .72;
        break;
      case 'offset tail':
        incoming = const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(8),
        );
        outgoing = const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(8),
        );
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9);
        break;
      case 'flat':
        incoming = outgoing = BorderRadius.circular(0);
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        width = .82;
        break;
      case 'elevated':
        incoming = outgoing = BorderRadius.circular(18);
        padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 10);
        width = .80;
        elevated = true;
        break;
      case 'rounded':
      default:
        incoming = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
          bottomLeft: const Radius.circular(5),
        );
        outgoing = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: const Radius.circular(5),
        );
    }

    Color color(String key, Color fallback) => prefs.gbColor(key) ?? fallback;
    final textSize = prefs.gbDouble('text_size_pick', fallback: 14).clamp(10.0, 24.0).toDouble();
    final avatarSize = prefs.gbDouble('pic_chat_size_pickerV2', fallback: 28).clamp(22.0, 48.0).toDouble();
    final picInside = prefs.gbBool('pic_inside');

    return MessagePresentationStyle(
      outgoingRadius: outgoing,
      incomingRadius: incoming,
      bubblePadding: padding,
      outgoingBackground: color(
        'ModChatRightBubble',
        prefs.conversation.customOutgoingBubbleHex == 0
            ? theme.outgoingBubbleColor
            : Color(prefs.conversation.customOutgoingBubbleHex),
      ),
      incomingBackground: color(
        'ModChatLeftBubble',
        prefs.conversation.customIncomingBubbleHex == 0
            ? theme.incomingBubbleColor
            : Color(prefs.conversation.customIncomingBubbleHex),
      ),
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
