import 'package:flutter/material.dart';
import '../../../ui/core/design_system/chaty_settings_primitives.dart';
import '../../../ui/core/controllers/chaty_preferences_controller.dart';

class UniversalAppearanceScreen extends StatefulWidget {
  final ChatyPreferencesController preferencesController;

  const UniversalAppearanceScreen({
    super.key,
    required this.preferencesController,
  });

  @override
  State<UniversalAppearanceScreen> createState() => _UniversalAppearanceScreenState();
}

class _UniversalAppearanceScreenState extends State<UniversalAppearanceScreen> {
  String _appIconStyle = 'Chaty Original';
  String _emojiStyle = 'System';
  String _fontFamily = 'Inter (Default)';
  double _fontScale = 1.0;
  String _iconThemeStyle = 'Rounded';

  static const List<String> _appIconOptions = [
    'Chaty Original',
    'Outline',
    'Soft',
    'Rounded',
    'Neon Accent',
    'Minimal',
    'Mono',
    'Material',
  ];

  static const List<String> _emojiOptions = [
    'System',
    'Android',
    'iOS-inspired',
    'One-style',
    'Fluent-style',
    'Twemoji-style',
  ];

  static const List<String> _fontOptions = [
    'Inter (Default)',
    'Roboto',
    'Outfit',
    'Monospace',
    'System Default',
  ];

  static const List<String> _iconThemeOptions = [
    'Rounded',
    'Filled',
    'Outlined',
    'Sharp',
    'Minimal',
  ];

  @override
  Widget build(BuildContext context) {
    return ChatySettingsPage(
      title: 'Universal Appearance & Styles',
      subtitle: 'App Icon, Emoji Pack, Typography & Iconography',
      children: [
        // Live Preview Card at Top
        ChatyPreviewCard(
          title: 'Live Typography & Icon Preview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font: $_fontFamily • Scale: ${(_fontScale * 100).toInt()}% • Icon Theme: $_iconThemeStyle • Emojis: $_emojiStyle',
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Previewing Chaty Universal Styling',
                          style: TextStyle(
                            fontSize: 14 * _fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'End-to-end encrypted messaging with delightful theme customization. ✨ 🚀 🔥',
                      style: TextStyle(
                        fontSize: 12.5 * _fontScale,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // App Icon Variant Selector
        ChatySettingsSection(
          title: 'App Icon Customization',
          description: 'Select your preferred visual app icon identifier.',
          children: [
            ChatyChoiceTile<String>(
              title: 'App Icon Variant',
              subtitle: 'Select icon style preset',
              options: _appIconOptions,
              selectedOption: _appIconStyle,
              optionLabel: (s) => s,
              onSelected: (s) {
                setState(() => _appIconStyle = s);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected App Icon Variant: $s'), duration: const Duration(seconds: 1)),
                );
              },
            ),
          ],
        ),

        // Emoji Pack Selector
        ChatySettingsSection(
          title: 'Emoji Set Rendering',
          description: 'Control visual style of emojis rendered in chat timelines & reactions.',
          children: [
            ChatyChoiceTile<String>(
              title: 'Emoji Set',
              options: _emojiOptions,
              selectedOption: _emojiStyle,
              optionLabel: (s) => s,
              onSelected: (s) => setState(() => _emojiStyle = s),
            ),
          ],
        ),

        // Typography Settings
        ChatySettingsSection(
          title: 'Typography & Scaling',
          description: 'Adjust global font family, font scaling and text hierarchy.',
          children: [
            ChatyChoiceTile<String>(
              title: 'Font Family',
              options: _fontOptions,
              selectedOption: _fontFamily,
              optionLabel: (s) => s,
              onSelected: (s) => setState(() => _fontFamily = s),
            ),
            ChatySliderTile(
              icon: Icons.format_size_rounded,
              title: 'Font Scale Factor',
              subtitle: 'Scale text across all screens (0.85x to 1.3x)',
              value: _fontScale,
              min: 0.85,
              max: 1.30,
              divisions: 9,
              valueFormatter: (v) => '${(v * 100).toInt()}%',
              onChanged: (v) => setState(() => _fontScale = v),
            ),
          ],
        ),

        // Icon Style
        ChatySettingsSection(
          title: 'Icon System',
          description: 'Set default icon outline, fill, and corner treatment.',
          children: [
            ChatyChoiceTile<String>(
              title: 'Global Icon Style',
              options: _iconThemeOptions,
              selectedOption: _iconThemeStyle,
              optionLabel: (s) => s,
              onSelected: (s) => setState(() => _iconThemeStyle = s),
            ),
          ],
        ),
      ],
    );
  }
}
