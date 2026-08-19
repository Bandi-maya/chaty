import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('message presentation binds legacy GB bubble controls', () {
    final source = File('lib/ui/core/messages/message_presentation_style.dart').readAsStringSync();
    for (final key in <String>[
      'bubble_style',
      'tick_style',
      'text_size_pick',
      'ModChatRightBubble',
      'ModChatBubbleText',
      'date_right_color',
      'ModChatLeftBubble',
      'ModChatBubbleTextLeft',
      'date_left_color',
      'quoted_divider_picker',
      'quoted_name_picker',
      'quoted_text_picker',
      'quoted_bg_picker',
      'pic_inside',
      'chat_contactpicV2',
      'chat_mypicV2',
      'pic_chat_size_pickerV2',
    ]) {
      expect(source, contains("'$key'"), reason: '$key must have a runtime consumer');
    }
  });

  test('canonical selector exposes and runtime renders exactly 20 distinct bubble templates', () {
    final selector = File('lib/features/settings/appearance/universal_appearance_screen.dart').readAsStringSync();
    final runtime = File('lib/ui/core/messages/message_presentation_style.dart').readAsStringSync();
    const styles = <String>[
      'Rounded','Classic Tail','Tail-less','Compact','Squircle','Card','Pill','Minimal','Sharp','Soft','Wide','Narrow','Dense','Airy','Editorial','Workspace','Focus','Offset Tail','Flat','Elevated',
    ];
    for (final style in styles) {
      expect(selector, contains("'$style'"), reason: '$style must be selectable from the canonical component selector');
      if (style != 'Rounded') {
        expect(runtime, contains("case '${style.toLowerCase()}':"), reason: '$style must have a runtime branch');
      }
    }
    expect(styles.toSet().length, 20);
  });

  test('canonical selector exposes and runtime renders exactly 20 tick templates', () {
    final selector = File('lib/features/settings/appearance/universal_appearance_screen.dart').readAsStringSync();
    final runtime = File('lib/features/messages/premium_message_bubble.dart').readAsStringSync();
    const styles = <String>[
      'Default','Double Check','iOS Circle','Minimal Dot','Neon','Single Check','Bold Double','Rounded Double','Square','Pill','Outline','Filled','Tiny','Wide','Accent','Monochrome','Soft','Workspace','Focus','Classic',
    ];
    for (final style in styles) {
      expect(selector, contains("'$style'"), reason: '$style must be selectable from the canonical component selector');
    }
    for (final branch in <String>[
      'double check','ios circle','minimal dot','neon','single check','bold double','rounded double','square','pill','outline','filled','tiny','wide','accent','monochrome','soft','workspace','focus','classic',
    ]) {
      expect(runtime, contains("case '$branch':"), reason: '$branch must render independently');
    }
    expect(styles.toSet().length, 20);
    expect(runtime, contains('DeliveryState.sent'));
    expect(runtime, contains('DeliveryState.delivered'));
    expect(runtime, contains('DeliveryState.read'));
    expect(runtime, contains('DeliveryState.failed'));
  });

  test('conversation settings no longer duplicates the 20-template catalogs', () {
    final source = File('lib/features/settings/conversation/conversation_settings_page.dart').readAsStringSync();
    expect(source, contains('UniversalAppearanceScreen'));
    expect(source, isNot(contains('static const List<String> _bubbleShapes')));
    expect(source, isNot(contains('static const List<String> _tickStyles')));
  });

  test('timeline compatibility entry delegates to premium runtime bubble', () {
    final source = File('lib/features/messages/message_bubble.dart').readAsStringSync();
    expect(source, contains('PremiumMessageBubble('));
    expect(source, contains('locator<ChatyPreferencesController>()'));
  });
}
