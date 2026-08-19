import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';

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
  static const List<String> _bubbleShapes = <String>[
    'Rounded','Classic Tail','Tail-less','Compact','Squircle','Card','Pill','Minimal','Sharp','Soft','Wide','Narrow','Dense','Airy','Editorial','Workspace','Focus','Offset Tail','Flat','Elevated',
  ];

  static const List<String> _tickStyles = <String>[
    'Default','Double Check','iOS Circle','Minimal Dot','Neon','Single Check','Bold Double','Rounded Double','Square','Pill','Outline','Filled','Tiny','Wide','Accent','Monochrome','Soft','Workspace','Focus','Classic',
  ];

  static const List<String> _reactionEmojis = ['❤️', '👍', '🔥', '😂', '😮', '🙏'];
  static const List<String> _wallpaperTypes = ['Pattern', 'Solid', 'Gradient', 'Image', 'ProfileBlur'];
  static const List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    final controller = widget.preferencesController;
    final conv = controller.conversation;
    final rawBubbleStyle = controller.gbString('bubble_style', fallback: conv.bubbleShape);
    final rawTickStyle = controller.gbString('tick_style', fallback: conv.tickStyle);
    final bubbleStyle = _bubbleShapes.contains(rawBubbleStyle) ? rawBubbleStyle : _bubbleShapes.first;
    final tickStyle = _tickStyles.contains(rawTickStyle) ? rawTickStyle : _tickStyles.first;

    return ChatySettingsPage(
      title: 'Conversation customization',
      subtitle: 'Message templates, ticks, wallpaper, actions and quick contacts',
      children: [
        ChatyPreviewCard(
          title: 'Active message template',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('$bubbleStyle • $tickStyle • ${conv.bubbleRadius.toInt()}px radius', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.all(conv.bubblePadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(conv.bubbleRadius),
                  ),
                  child: const Text('Incoming message preview', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(conv.bubblePadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(conv.bubbleRadius),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Outgoing reply', style: TextStyle(color: Colors.white, fontSize: 13)),
                      SizedBox(width: 6),
                      Icon(Icons.done_all_rounded, size: 14, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ChatySettingsSection(
          title: 'Message components',
          description: 'Each message component has 20 distinct runtime templates. Selection is persisted and applied to the real timeline.',
          children: [
            ChatyChoiceTile<String>(
              title: 'Bubble template — 20 styles',
              options: _bubbleShapes,
              selectedOption: bubbleStyle,
              optionLabel: (value) => value,
              onSelected: (shape) {
                controller.updateConversation(conv.copyWith(bubbleShape: shape), logTitle: 'Bubble Template');
                controller.updateGbFeature('bubble_style', shape);
              },
            ),
            ChatySliderTile(
              icon: Icons.rounded_corner_rounded,
              title: 'Bubble corner radius',
              value: conv.bubbleRadius,
              min: 4.0,
              max: 32.0,
              divisions: 28,
              valueFormatter: (value) => '${value.toInt()}px',
              onChanged: (value) => controller.updateConversation(
                conv.copyWith(bubbleRadius: value),
                logTitle: 'Bubble Radius',
              ),
            ),
            ChatyChoiceTile<String>(
              title: 'Delivery tick template — 20 styles',
              options: _tickStyles,
              selectedOption: tickStyle,
              optionLabel: (value) => value,
              onSelected: (tick) {
                controller.updateConversation(conv.copyWith(tickStyle: tick), logTitle: 'Tick Template');
                controller.updateGbFeature('tick_style', tick);
              },
            ),
          ],
        ),
        ChatySettingsSection(
          title: 'Quick contact sidebar',
          description: 'Docked participant navigation for active conversations.',
          children: [
            ChatySwitchTile(
              icon: Icons.dock_rounded,
              iconColor: Colors.tealAccent,
              title: 'Enable quick contact sidebar',
              subtitle: 'Show a participant switcher inside active conversations',
              value: conv.enableQuickContactSidebar,
              onChanged: (value) => controller.updateConversation(
                conv.copyWith(enableQuickContactSidebar: value),
                logTitle: 'Quick Contact Sidebar',
              ),
            ),
            if (conv.enableQuickContactSidebar) ...[
              ChatyChoiceTile<String>(
                title: 'Sidebar position',
                options: const ['Left', 'Right'],
                selectedOption: conv.sidebarPosition,
                optionLabel: (value) => value,
                onSelected: (position) => controller.updateConversation(
                  conv.copyWith(sidebarPosition: position),
                  logTitle: 'Sidebar Position',
                ),
              ),
              ChatySliderTile(
                icon: Icons.opacity_rounded,
                title: 'Sidebar opacity',
                value: conv.sidebarOpacity,
                min: 0.3,
                max: 1.0,
                divisions: 14,
                valueFormatter: (value) => '${(value * 100).toInt()}%',
                onChanged: (value) => controller.updateConversation(
                  conv.copyWith(sidebarOpacity: value),
                  logTitle: 'Sidebar Opacity',
                ),
              ),
            ],
          ],
        ),
        ChatySettingsSection(
          title: 'Reactions & interaction',
          children: [
            ChatySwitchTile(
              icon: Icons.touch_app_rounded,
              iconColor: Colors.amberAccent,
              title: 'iOS-style context popup',
              subtitle: 'Use the floating message action menu on long press',
              value: conv.iosStylePopupMenu,
              onChanged: (value) => controller.updateConversation(
                conv.copyWith(iosStylePopupMenu: value),
                logTitle: 'iOS Popup Menu',
              ),
            ),
            ChatyChoiceTile<String>(
              title: 'Double-tap reaction',
              options: _reactionEmojis,
              selectedOption: conv.doubleTapReactionEmoji,
              optionLabel: (value) => value,
              onSelected: (emoji) => controller.updateConversation(
                conv.copyWith(doubleTapReactionEmoji: emoji),
                logTitle: 'Double Tap Reaction',
              ),
            ),
          ],
        ),
        ChatySettingsSection(
          title: 'Wallpaper & audio playback',
          children: [
            ChatyChoiceTile<String>(
              title: 'Background wallpaper',
              options: _wallpaperTypes,
              selectedOption: conv.wallpaperType,
              optionLabel: (value) => value,
              onSelected: (wallpaper) => controller.updateConversation(
                conv.copyWith(wallpaperType: wallpaper),
                logTitle: 'Wallpaper Type',
              ),
            ),
            ChatyChoiceTile<double>(
              title: 'Voice note speed',
              options: _playbackSpeeds,
              selectedOption: conv.voicePlaybackSpeed,
              optionLabel: (value) => '${value}x',
              onSelected: (speed) => controller.updateConversation(
                conv.copyWith(voicePlaybackSpeed: speed),
                logTitle: 'Voice Speed',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
