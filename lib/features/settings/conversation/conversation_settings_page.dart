import 'package:flutter/material.dart';

import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../appearance/universal_appearance_screen.dart';

class ConversationSettingsPage extends StatefulWidget {
  final ChatyPreferencesController preferencesController;

  const ConversationSettingsPage({
    super.key,
    required this.preferencesController,
  });

  @override
  State<ConversationSettingsPage> createState() => _ConversationSettingsPageState();
}

class _ConversationSettingsPageState extends State<ConversationSettingsPage> {
  static const List<String> _reactionEmojis = ['❤️', '👍', '🔥', '😂', '😮', '🙏'];
  static const List<String> _wallpaperTypes = ['Pattern', 'Solid', 'Gradient', 'Image', 'ProfileBlur'];
  static const List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final controller = widget.preferencesController;
    final conv = controller.conversation;
    final bubbleStyle = controller.gbString('bubble_style', fallback: conv.bubbleShape);
    final tickStyle = controller.gbString('tick_style', fallback: conv.tickStyle);

    return ChatySettingsPage(
      title: 'Conversation settings',
      subtitle: 'Message layout, interactions, wallpaper and quick contacts',
      children: [
        ChatyPreviewCard(
          title: 'Current message presentation',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$bubbleStyle • $tickStyle • ${conv.bubbleRadius.toInt()}px radius', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.all(conv.bubblePadding),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(conv.bubbleRadius)),
                  child: const Text('Incoming message preview', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(conv.bubblePadding),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(conv.bubbleRadius)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Outgoing reply', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 15)),
                    const SizedBox(width: 7),
                    Icon(Icons.done_all_rounded, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                  ]),
                ),
              ),
            ],
          ),
        ),
        ChatySettingsSection(
          title: 'Message presentation',
          description: 'Template selection is centralized so each component has one canonical selector and one runtime implementation.',
          children: [
            ChatySettingsTile(
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Bubble, ticks & composer templates',
              subtitle: 'Choose the canonical 20-template designs for message components',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => UniversalAppearanceScreen(preferencesController: controller))),
            ),
            ChatySliderTile(
              icon: Icons.rounded_corner_rounded,
              title: 'Bubble corner radius',
              value: conv.bubbleRadius,
              min: 4.0,
              max: 32.0,
              divisions: 28,
              valueFormatter: (value) => '${value.toInt()}px',
              onChanged: (value) => controller.updateConversation(conv.copyWith(bubbleRadius: value), logTitle: 'Bubble Radius'),
            ),
            ChatySliderTile(
              icon: Icons.padding_rounded,
              title: 'Bubble padding',
              value: conv.bubblePadding,
              min: 7,
              max: 22,
              divisions: 15,
              valueFormatter: (value) => '${value.toInt()}px',
              onChanged: (value) => controller.updateConversation(conv.copyWith(bubblePadding: value), logTitle: 'Bubble Padding'),
            ),
          ],
        ),
        ChatySettingsSection(
          title: 'Quick contact sidebar',
          description: 'Docked participant navigation for active conversations.',
          children: [
            ChatySwitchTile(
              icon: Icons.dock_rounded,
              title: 'Enable quick contact sidebar',
              subtitle: 'Show a participant switcher inside active conversations',
              value: conv.enableQuickContactSidebar,
              onChanged: (value) => controller.updateConversation(conv.copyWith(enableQuickContactSidebar: value), logTitle: 'Quick Contact Sidebar'),
            ),
            if (conv.enableQuickContactSidebar) ...[
              ChatyChoiceTile<String>(
                title: 'Sidebar position',
                options: const ['Left', 'Right'],
                selectedOption: conv.sidebarPosition,
                optionLabel: (value) => value,
                onSelected: (position) => controller.updateConversation(conv.copyWith(sidebarPosition: position), logTitle: 'Sidebar Position'),
              ),
              ChatySliderTile(
                icon: Icons.opacity_rounded,
                title: 'Sidebar opacity',
                value: conv.sidebarOpacity,
                min: 0.3,
                max: 1.0,
                divisions: 14,
                valueFormatter: (value) => '${(value * 100).toInt()}%',
                onChanged: (value) => controller.updateConversation(conv.copyWith(sidebarOpacity: value), logTitle: 'Sidebar Opacity'),
              ),
            ],
          ],
        ),
        ChatySettingsSection(
          title: 'Reactions & interaction',
          children: [
            ChatySwitchTile(
              icon: Icons.touch_app_rounded,
              title: 'Floating context menu',
              subtitle: 'Use the modern message action menu on long press',
              value: conv.iosStylePopupMenu,
              onChanged: (value) => controller.updateConversation(conv.copyWith(iosStylePopupMenu: value), logTitle: 'Context Popup Menu'),
            ),
            ChatyChoiceTile<String>(
              title: 'Double-tap reaction',
              options: _reactionEmojis,
              selectedOption: conv.doubleTapReactionEmoji,
              optionLabel: (value) => value,
              onSelected: (emoji) => controller.updateConversation(conv.copyWith(doubleTapReactionEmoji: emoji), logTitle: 'Double Tap Reaction'),
            ),
          ],
        ),
        ChatySettingsSection(
          title: 'Wallpaper & audio',
          children: [
            ChatyChoiceTile<String>(
              title: 'Background wallpaper',
              options: _wallpaperTypes,
              selectedOption: conv.wallpaperType,
              optionLabel: (value) => value,
              onSelected: (wallpaper) => controller.updateConversation(conv.copyWith(wallpaperType: wallpaper), logTitle: 'Wallpaper Type'),
            ),
            ChatyChoiceTile<double>(
              title: 'Voice note speed',
              options: _playbackSpeeds,
              selectedOption: conv.voicePlaybackSpeed,
              optionLabel: (value) => '${value}x',
              onSelected: (speed) => controller.updateConversation(conv.copyWith(voicePlaybackSpeed: speed), logTitle: 'Voice Speed'),
            ),
          ],
        ),
      ],
    );
  }
}
