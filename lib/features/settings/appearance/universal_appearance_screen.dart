import 'package:flutter/material.dart';

import '../../../injection/locator.dart';
import '../../../ui/core/controllers/appearance_variant_controller.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../ui/core/theme/theme_controller.dart';

class UniversalAppearanceScreen extends StatelessWidget {
  final ChatyPreferencesController preferencesController;

  static const List<String> _bubbleStyles = <String>[
    'Rounded','Classic Tail','Tail-less','Compact','Squircle','Card','Pill','Minimal','Sharp','Soft','Wide','Narrow','Dense','Airy','Editorial','Workspace','Focus','Offset Tail','Flat','Elevated',
  ];

  static const List<String> _tickStyles = <String>[
    'Default','Double Check','iOS Circle','Minimal Dot','Neon','Single Check','Bold Double','Rounded Double','Square','Pill','Outline','Filled','Tiny','Wide','Accent','Monochrome','Soft','Workspace','Focus','Classic',
  ];

  const UniversalAppearanceScreen({
    super.key,
    required this.preferencesController,
  });

  @override
  Widget build(BuildContext context) {
    final controller = locator<AppearanceVariantController>();
    final themeController = locator<ThemeController>();

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[controller, themeController, preferencesController]),
      builder: (context, _) {
        final theme = themeController.globalTheme;
        final rawBubble = preferencesController.gbString('bubble_style', fallback: preferencesController.conversation.bubbleShape);
        final rawTick = preferencesController.gbString('tick_style', fallback: preferencesController.conversation.tickStyle);
        final bubble = _bubbleStyles.contains(rawBubble) ? rawBubble : _bubbleStyles.first;
        final tick = _tickStyles.contains(rawTick) ? rawTick : _tickStyles.first;

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            backgroundColor: theme.surfaceColor,
            foregroundColor: theme.primaryTextColor,
            title: const Text('Component templates'),
          ),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                  children: [
                    _AppearancePreview(controller: controller, bubbleStyle: bubble, tickStyle: tick),
                    const SizedBox(height: 18),
                    _VariantSection(
                      title: 'Navigation rail / tabs',
                      subtitle: '20 genuinely different wide-screen navigation templates.',
                      value: controller.navigationStyle,
                      options: AppearanceVariantController.navigationStyles,
                      icon: Icons.view_sidebar_outlined,
                      onSelected: controller.setNavigationStyle,
                    ),
                    _VariantSection(
                      title: 'Bottom navigation',
                      subtitle: '20 mobile bottom navigation templates applied to the root shell.',
                      value: controller.bottomBarStyle,
                      options: AppearanceVariantController.bottomBarStyles,
                      icon: Icons.space_bar_rounded,
                      onSelected: controller.setBottomBarStyle,
                    ),
                    _VariantSection(
                      title: 'Message composer',
                      subtitle: '20 input-box templates while preserving attachment, emoji, voice and send behavior.',
                      value: controller.composerStyle,
                      options: AppearanceVariantController.composerStyles,
                      icon: Icons.edit_note_rounded,
                      onSelected: controller.setComposerStyle,
                    ),
                    _VariantSection(
                      title: 'Message bubble',
                      subtitle: '20 runtime bubble geometries with distinct spacing, width and elevation.',
                      value: bubble,
                      options: _bubbleStyles,
                      icon: Icons.chat_bubble_outline_rounded,
                      onSelected: (value) async {
                        final current = preferencesController.conversation;
                        await preferencesController.updateConversation(current.copyWith(bubbleShape: value), logTitle: 'Bubble Template');
                        await preferencesController.updateGbFeature('bubble_style', value);
                      },
                    ),
                    _VariantSection(
                      title: 'Delivery ticks',
                      subtitle: '20 distinct sent/delivered/read marker templates used by the real message timeline.',
                      value: tick,
                      options: _tickStyles,
                      icon: Icons.done_all_rounded,
                      onSelected: (value) async {
                        final current = preferencesController.conversation;
                        await preferencesController.updateConversation(current.copyWith(tickStyle: value), logTitle: 'Tick Template');
                        await preferencesController.updateGbFeature('tick_style', value);
                      },
                    ),
                    _VariantSection(
                      title: 'Audio / video call controls',
                      subtitle: '20 call-control templates while keeping microphone, speaker, camera, flip and end actions wired.',
                      value: controller.callUiStyle,
                      options: AppearanceVariantController.callUiStyles,
                      icon: Icons.video_call_outlined,
                      onSelected: controller.setCallUiStyle,
                    ),
                    _VariantSection(
                      title: 'App icon language',
                      subtitle: '20 in-app branded icon identities used by Chaty surfaces.',
                      value: controller.appIconStyle,
                      options: AppearanceVariantController.appIconStyles,
                      icon: Icons.apps_rounded,
                      onSelected: controller.setAppIconStyle,
                    ),
                    _VariantSection(
                      title: 'Notification icon language',
                      subtitle: '20 notification visual identities.',
                      value: controller.notificationIconStyle,
                      options: AppearanceVariantController.notificationIconStyles,
                      icon: Icons.notifications_active_outlined,
                      onSelected: controller.setNotificationIconStyle,
                    ),
                    _VariantSection(
                      title: 'Typography',
                      subtitle: '20 persistent density and scale profiles applied globally.',
                      value: controller.typographyStyle,
                      options: AppearanceVariantController.typographyStyles,
                      icon: Icons.text_fields_rounded,
                      onSelected: controller.setTypographyStyle,
                    ),
                    _VariantSection(
                      title: 'Entry animation',
                      subtitle: '20 incoming route/motion profiles.',
                      value: controller.entryAnimation,
                      options: AppearanceVariantController.entryAnimations,
                      icon: Icons.login_rounded,
                      onSelected: controller.setEntryAnimation,
                    ),
                    _VariantSection(
                      title: 'Exit animation',
                      subtitle: '20 outgoing route/motion profiles.',
                      value: controller.exitAnimation,
                      options: AppearanceVariantController.exitAnimations,
                      icon: Icons.logout_rounded,
                      onSelected: controller.setExitAnimation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppearancePreview extends StatelessWidget {
  final AppearanceVariantController controller;
  final String bubbleStyle;
  final String tickStyle;

  const _AppearancePreview({
    required this.controller,
    required this.bubbleStyle,
    required this.tickStyle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bottomIndex = controller.bottomBarIndex;
    final radius = <double>[30,14,24,22,28,30,18,12,8,20,16,20,4,10,32,26,18,0,14,10][bottomIndex];
    final compact = <int>{2, 6, 8, 13, 15, 19}.contains(bottomIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.visibility_outlined, color: scheme.primary, size: 19),
            const SizedBox(width: 8),
            Text('Active template preview', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Container(
            height: compact ? 50 : 58,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PreviewNavIcon(icon: Icons.chat_bubble_rounded, selected: true),
                _PreviewNavIcon(icon: Icons.update_rounded),
                _PreviewNavIcon(icon: Icons.checklist_rounded),
                _PreviewNavIcon(icon: Icons.call_rounded),
                _PreviewNavIcon(icon: Icons.settings_rounded),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Navigation: ${controller.navigationStyle}\nComposer: ${controller.composerStyle}\nBubble: $bubbleStyle • Ticks: $tickStyle\nCalls: ${controller.callUiStyle}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PreviewNavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const _PreviewNavIcon({required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 19, color: selected ? scheme.primary : scheme.onSurfaceVariant),
    );
  }
}

class _VariantSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final List<String> options;
  final IconData icon;
  final Future<void> Function(String) onSelected;

  const _VariantSection({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .6)),
      ),
      child: ListTile(
        minTileHeight: 72,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: scheme.onPrimaryContainer, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(subtitle),
            const SizedBox(height: 5),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showSelector(context),
      ),
    );
  }

  Future<void> _showSelector(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
              child: Row(children: [
                Expanded(child: Text('$title — 20 templates', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  final active = option == value;
                  return ListTile(
                    minTileHeight: 52,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    selected: active,
                    selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .5),
                    leading: SizedBox(width: 30, child: Text('${index + 1}'.padLeft(2, '0'))),
                    title: Text(option, style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
                    trailing: active ? const Icon(Icons.check_circle_rounded) : null,
                    onTap: () => Navigator.pop(context, option),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await onSelected(selected);
  }
}
