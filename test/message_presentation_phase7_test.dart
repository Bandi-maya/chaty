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

  test('premium bubble supports genuinely different bubble families', () {
    final source = File('lib/ui/core/messages/message_presentation_style.dart').readAsStringSync();
    for (final style in <String>['tail', 'tail-less', 'compact', 'squircle', 'card', 'pill', 'minimal']) {
      expect(source, contains("case '$style':"));
    }
  });

  test('delivery presentation supports multiple tick languages', () {
    final source = File('lib/features/messages/premium_message_bubble.dart').readAsStringSync();
    expect(source, contains("contains('minimal')"));
    expect(source, contains("contains('ios')"));
    expect(source, contains("contains('neon')"));
    expect(source, contains('DeliveryState.sent'));
    expect(source, contains('DeliveryState.delivered'));
    expect(source, contains('DeliveryState.read'));
    expect(source, contains('DeliveryState.failed'));
  });

  test('timeline compatibility entry delegates to premium runtime bubble', () {
    final source = File('lib/features/messages/message_bubble.dart').readAsStringSync();
    expect(source, contains('PremiumMessageBubble('));
    expect(source, contains('locator<ChatyPreferencesController>()'));
  });
}
