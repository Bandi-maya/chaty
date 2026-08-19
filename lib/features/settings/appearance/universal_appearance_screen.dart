import 'package:flutter/material.dart';

import '../../../../ui/core/theme/theme_controller.dart';
import '../../../domain/models/visual_preferences.dart';
import '../../../injection/locator.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../ui/core/theme/theme_config.dart';

class UniversalAppearanceScreen extends StatelessWidget {
  final ChatyPreferencesController preferencesController;
  final ThemeController? themeController;

  const UniversalAppearanceScreen({
    super.key,
    required this.preferencesController,
    this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = themeController ?? locator<ThemeController>();
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[preferencesController, controller]),
      builder: (context, _) {
        final theme = controller.globalTheme;
        final visual = preferencesController.visual;
        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: theme.backgroundColor,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Universal Appearance',
              style: TextStyle(
                color: theme.primaryTextColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: preferencesController.resetVisual,
                child: const Text('Reset'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              _AppearancePreview(
                theme: theme,
                visual: visual,
                onToggleBrightness: controller.toggleBrightness,
              ),
              const SizedBox(height: 18),
              _sectionTitle('NAVIGATION', theme),
              _VariantPicker(
                title: 'Top navigation',
                subtitle: '20 header treatments used by the Chats home bar',
                icon: Icons.web_asset_outlined,
                value: visual.topBarStyle,
                options: VisualPreferences.topBarStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(topBarStyle: value),
                  'Top navigation',
                  visual.topBarStyle,
                  value,
                ),
              ),
              _VariantPicker(
                title: 'Bottom navigation',
                subtitle: '20 dock/navigation profiles; wide windows adapt to a rail',
                icon: Icons.dock_outlined,
                value: visual.bottomBarStyle,
                options: VisualPreferences.bottomBarStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(bottomBarStyle: value),
                  'Bottom navigation',
                  visual.bottomBarStyle,
                  value,
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('CHAT & ICONS', theme),
              _VariantPicker(
                title: 'Chat bubble',
                subtitle: '20 spacing, radius, border, tail and elevation profiles',
                icon: Icons.chat_bubble_outline_rounded,
                value: visual.bubbleStyle,
                options: VisualPreferences.bubbleStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(bubbleStyle: value),
                  'Chat bubble',
                  visual.bubbleStyle,
                  value,
                ),
              ),
              _VariantPicker(
                title: 'App icon treatment',
                subtitle: 'In-app Chaty icon treatment; launcher icons require native resources',
                icon: Icons.apps_rounded,
                value: visual.appIconStyle,
                options: VisualPreferences.appIconStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(appIconStyle: value),
                  'App icon treatment',
                  visual.appIconStyle,
                  value,
                ),
              ),
              _VariantPicker(
                title: 'Notification icon treatment',
                subtitle: 'In-app notification glyph profile and notification preview',
                icon: Icons.notifications_outlined,
                value: visual.notificationIconStyle,
                options: VisualPreferences.notificationIconStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(notificationIconStyle: value),
                  'Notification icon treatment',
                  visual.notificationIconStyle,
                  value,
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('TYPE & MOTION', theme),
              _VariantPicker(
                title: 'Typography',
                subtitle: '20 global type profiles; accessibility profiles increase scale',
                icon: Icons.text_fields_rounded,
                value: visual.typographyStyle,
                options: VisualPreferences.typographyStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(typographyStyle: value),
                  'Typography',
                  visual.typographyStyle,
                  value,
                ),
              ),
              _VariantPicker(
                title: 'Entry animation',
                subtitle: '20 route-entry transition types',
                icon: Icons.login_rounded,
                value: visual.entryAnimation,
                options: VisualPreferences.animationStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(entryAnimation: value),
                  'Entry animation',
                  visual.entryAnimation,
                  value,
                ),
              ),
              _VariantPicker(
                title: 'Exit animation',
                subtitle: '20 route-exit transition types',
                icon: Icons.logout_rounded,
                value: visual.exitAnimation,
                options: VisualPreferences.animationStyles,
                theme: theme,
                onChanged: (value) => _update(
                  visual.copyWith(exitAnimation: value),
                  'Exit animation',
                  visual.exitAnimation,
                  value,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info_outline_rounded, color: theme.accentColor, size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'All changes are persisted immediately. The preview above is intentionally always visible so you can evaluate the selection before leaving this page. Native launcher-icon swapping is not faked: that requires platform-specific alternate icon resources.',
                        style: TextStyle(
                          color: theme.secondaryTextColor,
                          fontSize: 11.8,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _update(
    VisualPreferences next,
    String title,
    String previous,
    String value,
  ) {
    preferencesController.updateVisual(
      next,
      logTitle: title,
      prevVal: previous,
      newVal: value,
    );
  }

  Widget _sectionTitle(String text, ThemeConfig theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          color: theme.secondaryTextColor,
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  final ThemeConfig theme;
  final VisualPreferences visual;
  final VoidCallback onToggleBrightness;

  const _AppearancePreview({
    required this.theme,
    required this.visual,
    required this.onToggleBrightness,
  });

  @override
  Widget build(BuildContext context) {
    final bottomIndex = VisualPreferences.bottomBarStyles
        .indexOf(visual.bottomBarStyle)
        .clamp(0, 19);
    final bubbleIndex =
        VisualPreferences.bubbleStyles.indexOf(visual.bubbleStyle).clamp(0, 19);
    final topIndex =
        VisualPreferences.topBarStyles.indexOf(visual.topBarStyle).clamp(0, 19);
    final bubbleRadius = switch (bubbleIndex) {
      2 || 5 || 11 => 8.0,
      3 => 26.0,
      4 || 13 => 22.0,
      10 => 6.0,
      _ => 16.0,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.secondaryTextColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Preview light / dark',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  theme.brightness == Brightness.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  size: 18,
                ),
                onPressed: onToggleBrightness,
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: topIndex == 2 ? 8 : 12,
              vertical: topIndex == 2 ? 7 : 10,
            ),
            decoration: BoxDecoration(
              color: <int>{4, 6, 8, 12, 14, 15, 16, 18, 19}.contains(topIndex)
                  ? theme.surfaceColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(topIndex == 14 ? 20 : 12),
              border: <int>{5, 11, 14, 15, 18}.contains(topIndex)
                  ? Border.all(
                      color: theme.secondaryTextColor.withValues(alpha: 0.16),
                    )
                  : null,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  'Chaty',
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(Icons.search_rounded, color: theme.primaryTextColor, size: 18),
                const SizedBox(width: 10),
                Icon(Icons.more_horiz_rounded, color: theme.primaryTextColor, size: 18),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: theme.incomingBubbleColor,
                borderRadius: BorderRadius.circular(bubbleRadius),
                border: <int>{6, 16}.contains(bubbleIndex)
                    ? Border.all(color: theme.accentColor.withValues(alpha: 0.45))
                    : null,
              ),
              child: Text(
                'Incoming bubble preview',
                style: TextStyle(color: theme.incomingTextColor, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: theme.outgoingBubbleColor,
                borderRadius: BorderRadius.circular(bubbleRadius),
              ),
              child: Text(
                'Outgoing bubble preview',
                style: TextStyle(color: theme.outgoingTextColor, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(
                <int>{0, 6, 8, 9, 14, 15}.contains(bottomIndex) ? 24 : 12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (final icon in const <IconData>[
                  Icons.chat_bubble_rounded,
                  Icons.update_rounded,
                  Icons.checklist_rounded,
                  Icons.call_rounded,
                  Icons.settings_rounded,
                ])
                  Icon(
                    icon,
                    size: 18,
                    color: icon == Icons.chat_bubble_rounded
                        ? theme.accentColor
                        : theme.secondaryTextColor,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _previewTag('Top: ${visual.topBarStyle}', theme),
              _previewTag('Bottom: ${visual.bottomBarStyle}', theme),
              _previewTag('Bubble: ${visual.bubbleStyle}', theme),
              _previewTag('Type: ${visual.typographyStyle}', theme),
              _previewTag('In: ${visual.entryAnimation}', theme),
              _previewTag('Out: ${visual.exitAnimation}', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewTag(String text, ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: theme.secondaryTextColor, fontSize: 9.8),
      ),
    );
  }
}

class _VariantPicker extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final List<String> options;
  final ThemeConfig theme;
  final ValueChanged<String> onChanged;

  const _VariantPicker({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.options,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.accentColor, size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 10.8,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null && next != value) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}
