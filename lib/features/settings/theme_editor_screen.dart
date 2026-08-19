import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_config.dart';
import '../../../ui/core/theme/theme_presets.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../messages/message_bubble.dart';
import '../../domain/models/chat_message.dart';

class ThemeEditorScreen extends StatefulWidget {
  final ThemeController themeController;

  const ThemeEditorScreen({super.key, required this.themeController});

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  late ThemeConfig _current;

  @override
  void initState() {
    super.initState();
    _current = widget.themeController.globalTheme;
  }

  void _applyAndSave() {
    widget.themeController.updateThemeConfig(_current);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme customization saved!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _current;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Theme & Appearance Editor (S-017)'),
        actions: [
          TextButton(
            onPressed: _applyAndSave,
            child: Text(
              'Save',
              style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Interactive Chat Preview Box
            Text(
              'LIVE PREVIEW',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(theme.cornerRadius),
                border: Border.all(color: theme.surfaceColor, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10),
                ],
              ),
              child: Column(
                children: [
                  MessageBubble(
                    message: ChatMessage(
                      id: 'prev_1',
                      conversationId: 'prev',
                      senderId: 'other',
                      text: 'Hey Alex! How does this custom bubble palette look?',
                      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
                    ),
                    isMe: false,
                    theme: theme,
                    senderName: 'Dr. Elena Rostova',
                    onLongPress: () {},
                  ),
                  MessageBubble(
                    message: ChatMessage(
                      id: 'prev_2',
                      conversationId: 'prev',
                      senderId: 'me',
                      text: 'It looks crisp and accessible! Full contrast guaranteed.',
                      createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
                      deliveryState: DeliveryState.read,
                    ),
                    isMe: true,
                    theme: theme,
                    onLongPress: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Contrast Warning Card (Accessibility check)
            if (theme.hasContrastIssue)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Warning: The current color combination falls below WCAG contrast guidelines.',
                        style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Preset Selector
            Text(
              'THEME PRESETS',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ThemePresets.all.map((p) {
                  final isSel = p.id == _current.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: isSel,
                      selectedColor: p.accentColor.withValues(alpha: 0.3),
                      backgroundColor: theme.cardColor,
                      labelStyle: TextStyle(
                        color: isSel ? p.accentColor : theme.secondaryTextColor,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _current = p);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // UI Layout Presets (Classic, Compact, Expressive, Focus)
            Text(
              'UI LAYOUT PRESET (PRD 10.2)',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UILayoutMode.values.map((mode) {
                final isSel = _current.layoutMode == mode;
                return ChoiceChip(
                  label: Text(mode.name.toUpperCase()),
                  selected: isSel,
                  selectedColor: theme.accentColor.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _current = _current.copyWith(layoutMode: mode);
                        if (mode == UILayoutMode.compact) {
                          _current = _current.copyWith(density: 0.85, fontScale: 0.9);
                        } else if (mode == UILayoutMode.expressive) {
                          _current = _current.copyWith(density: 1.15, cornerRadius: 20);
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Bubble Geometry & Style
            Text(
              'BUBBLE SHAPE & GEOMETRY',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppBubbleStyle.values.map((s) {
                final isSel = _current.bubbleStyle == s;
                return ChoiceChip(
                  label: Text(s.name),
                  selected: isSel,
                  selectedColor: theme.accentColor.withValues(alpha: 0.3),
                  onSelected: (val) {
                    if (val) setState(() => _current = _current.copyWith(bubbleStyle: s));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Sliders (Corner radius, Font scaling, Density)
            Text(
              'Corner Radius (${_current.cornerRadius.toInt()}px)',
              style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _current.cornerRadius,
              min: 4,
              max: 28,
              divisions: 12,
              activeColor: theme.accentColor,
              onChanged: (v) => setState(() => _current = _current.copyWith(cornerRadius: v)),
            ),

            Text(
              'Font Scale (${_current.fontScale.toStringAsFixed(2)}x)',
              style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _current.fontScale,
              min: 0.85,
              max: 1.3,
              divisions: 9,
              activeColor: theme.accentColor,
              onChanged: (v) => setState(() => _current = _current.copyWith(fontScale: v)),
            ),

            Text(
              'Message Density (${_current.density.toStringAsFixed(2)}x)',
              style: TextStyle(color: theme.primaryTextColor, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _current.density,
              min: 0.7,
              max: 1.4,
              divisions: 7,
              activeColor: theme.accentColor,
              onChanged: (v) => setState(() => _current = _current.copyWith(density: v)),
            ),

            const SizedBox(height: 24),

            // Navigation Modes
            Text(
              'NAVIGATION PATTERN (PRD 7)',
              style: TextStyle(
                color: theme.secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AppNavigationMode>(
              segments: const [
                ButtonSegment(value: AppNavigationMode.bottomNav, label: Text('Bottom Nav')),
                ButtonSegment(value: AppNavigationMode.compactRail, label: Text('Compact Rail')),
                ButtonSegment(value: AppNavigationMode.gestureTabs, label: Text('Gesture Tabs')),
              ],
              selected: {_current.navigationMode},
              onSelectionChanged: (val) {
                setState(() => _current = _current.copyWith(navigationMode: val.first));
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
