import 'package:flutter/material.dart';

import '../../data/repositories/mock_data_store.dart';
import '../../domain/models/chat_message.dart';
import '../../injection/locator.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../ui/core/theme/theme_config.dart';
import 'premium_message_bubble.dart';

/// Compatibility entry point used by the conversation timeline.
/// Presentation is delegated to [PremiumMessageBubble] so legacy call sites keep
/// their behavior while GB/typed appearance preferences are applied at runtime.
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final ThemeConfig theme;
  final String? senderName;
  final VoidCallback onLongPress;
  final VoidCallback? onTaskTap;
  final Function(String emoji)? onReactionTap;
  final VoidCallback? onMediaTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    this.senderName,
    required this.onLongPress,
    this.onTaskTap,
    this.onReactionTap,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    var effectiveMessage = message;
    final linkedTaskId = message.linkedTaskId;
    if (message.type == MessageType.taskCard && linkedTaskId != null && locator.isRegistered<MockDataStore>()) {
      final store = locator<MockDataStore>();
      final task = store.tasks.where((item) => item.id == linkedTaskId).firstOrNull;
      if (task != null && task.title != message.text) {
        effectiveMessage = message.copyWith(text: task.title);
      }
    }

    return PremiumMessageBubble(
      message: effectiveMessage,
      isMe: isMe,
      theme: theme,
      preferencesController: locator<ChatyPreferencesController>(),
      senderName: senderName,
      onLongPress: onLongPress,
      onTaskTap: onTaskTap,
      onReactionTap: onReactionTap,
      onMediaTap: onMediaTap,
    );
  }
}
