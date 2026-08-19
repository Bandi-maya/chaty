import 'package:flutter/material.dart';

import '../controllers/chaty_preferences_controller.dart';
import '../theme/theme_config.dart';

class GbThemeOverrides {
  const GbThemeOverrides._();

  static ThemeConfig resolve(ThemeConfig base, ChatyPreferencesController prefs) {
    Color? firstColor(List<String> keys) {
      for (final key in keys) {
        final value = prefs.gbColor(key);
        if (value != null) return value;
      }
      return null;
    }

    final dark = base.brightness == Brightness.dark;
    final accent = firstColor(<String>[
      if (dark) 'ModDarkConPickColor',
      'ModConPickColor',
      'ModConColor',
      'tabindicator',
    ]);
    final background = firstColor(<String>[
      if (dark) 'ModDarkConPickColorNav',
      'ModConBackColor',
      'list_bg_color',
      'ConvoBack',
    ]);
    final surface = firstColor(<String>['ModChatColor', 'BGColor', 'HomeBarColor']);
    final primaryText = firstColor(<String>['ModConTextColor', 'HomeBarText', 'ModContactNameColor']);
    final secondaryText = firstColor(<String>['ModContactStatusColor', 'ModChatStatusColor', 'ModConTimeColor']);
    final outgoingBubble = firstColor(<String>['ModChatRightBubble']);
    final incomingBubble = firstColor(<String>['ModChatLeftBubble']);
    final outgoingText = firstColor(<String>['ModChatBubbleText', 'date_right_color']);
    final incomingText = firstColor(<String>['ModChatBubbleTextLeft', 'date_left_color']);
    final link = firstColor(<String>['ModChatBubbleHyperlinks']);
    final success = firstColor(<String>['ModOnlineColor', 'online_color']);
    final danger = firstColor(<String>['ModErrorColor', 'error_color']);

    final textSize = prefs.gbDouble('text_size_pick', fallback: 15);
    final fontScale = (base.fontScale * (textSize / 15)).clamp(0.78, 1.6).toDouble();
    final bubbleStyle = _bubbleStyle(prefs.gbString('bubble_style', fallback: '')) ?? base.bubbleStyle;

    final candidate = base.copyWith(
      accentColor: accent,
      backgroundColor: background,
      surfaceColor: surface,
      cardColor: surface == null
          ? null
          : Color.alphaBlend(
              base.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.045) : Colors.black.withValues(alpha: 0.025),
              surface,
            ),
      primaryTextColor: primaryText,
      secondaryTextColor: secondaryText,
      outgoingBubbleColor: outgoingBubble,
      incomingBubbleColor: incomingBubble,
      outgoingTextColor: outgoingText,
      incomingTextColor: incomingText,
      linkColor: link,
      successColor: success,
      dangerColor: danger,
      fontScale: fontScale,
      bubbleStyle: bubbleStyle,
    );

    return candidate.copyWith(
      primaryTextColor: _ensureContrast(candidate.primaryTextColor, candidate.backgroundColor, base.primaryTextColor, 4.5),
      secondaryTextColor: _ensureContrast(candidate.secondaryTextColor, candidate.backgroundColor, base.secondaryTextColor, 3.0),
      outgoingTextColor: _ensureContrast(candidate.outgoingTextColor, candidate.outgoingBubbleColor, base.outgoingTextColor, 3.5),
      incomingTextColor: _ensureContrast(candidate.incomingTextColor, candidate.incomingBubbleColor, base.incomingTextColor, 3.5),
    );
  }

  /// Call-only visual tokens. These legacy GB controls must affect the active
  /// call UI without leaking their colors into unrelated screens.
  static ThemeConfig resolveCalls(ThemeConfig base, ChatyPreferencesController prefs) {
    final background = prefs.gbColor('ModCallsBackground') ?? base.backgroundColor;
    final requestedText = prefs.gbColor('ModCallsTextColor') ?? base.primaryTextColor;
    final requestedIcons = prefs.gbColor('ModCallsIconColors') ?? base.accentColor;
    final safeText = _ensureContrast(requestedText, background, base.primaryTextColor, 4.5);
    final safeIcons = _ensureContrast(requestedIcons, background, base.accentColor, 3.0);
    return base.copyWith(
      backgroundColor: background,
      surfaceColor: Color.alphaBlend(
        base.brightness == Brightness.dark ? Colors.white.withValues(alpha: .08) : Colors.black.withValues(alpha: .04),
        background,
      ),
      cardColor: Color.alphaBlend(
        base.brightness == Brightness.dark ? Colors.white.withValues(alpha: .12) : Colors.black.withValues(alpha: .06),
        background,
      ),
      primaryTextColor: safeText,
      secondaryTextColor: safeText.withValues(alpha: .72),
      accentColor: safeIcons,
    );
  }

  static AppBubbleStyle? _bubbleStyle(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('pill')) return AppBubbleStyle.pill;
    if (value.contains('compact') || value.contains('square') || value.contains('card')) return AppBubbleStyle.softSquare;
    if (value.contains('tail-less') || value.contains('tailless')) return AppBubbleStyle.rounded;
    if (value.contains('tail')) return AppBubbleStyle.sharpTail;
    if (value.contains('round') || value.contains('squircle')) return AppBubbleStyle.rounded;
    return null;
  }

  static Color _ensureContrast(Color foreground, Color background, Color fallback, double minimum) {
    if (ThemeConfig.calculateContrastRatio(foreground, background) >= minimum) return foreground;
    if (ThemeConfig.calculateContrastRatio(fallback, background) >= minimum) return fallback;
    return background.computeLuminance() > 0.45 ? Colors.black : Colors.white;
  }
}
