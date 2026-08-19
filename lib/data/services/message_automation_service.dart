import 'dart:async';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import '../repositories/mock_data_store.dart';
import '../../domain/models/chaty_preferences.dart';

class MessageAutomationService {
  final ChatyPreferencesController preferencesController;
  final MockDataStore dataStore;
  Timer? _schedulerTimer;

  MessageAutomationService({
    required this.preferencesController,
    required this.dataStore,
  }) {
    _startSchedulerLoop();
  }

  void dispose() {
    _schedulerTimer?.cancel();
  }

  void _startSchedulerLoop() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkAndExecuteScheduledMessages();
    });
  }

  void _checkAndExecuteScheduledMessages() {
    final auto = preferencesController.automation;
    final now = DateTime.now();
    bool updated = false;
    final List<ScheduledMessageEntry> nextList = [];

    for (final entry in auto.scheduledMessages) {
      if (!entry.isExecuted && entry.scheduledAt.isBefore(now)) {
        // Execute message insertion into chat timeline
        dataStore.sendMessage(
          conversationId: entry.recipientId,
          text: '⏰ [Scheduled Message] ${entry.text}',
        );
        nextList.add(entry.copyWith(isExecuted: true));
        updated = true;
      } else {
        nextList.add(entry);
      }
    }

    if (updated) {
      preferencesController.updateAutomation(
        auto.copyWith(scheduledMessages: nextList),
      );
    }
  }

  void handleIncomingMessageAutoReply(String conversationId, String text) {
    final auto = preferencesController.automation;
    if (!auto.enableAutoReply) return;

    final lower = text.toLowerCase();
    for (final rule in auto.autoReplyRules) {
      if (rule.enabled && lower.contains(rule.keyword.toLowerCase())) {
        Timer(const Duration(milliseconds: 800), () {
          dataStore.sendMessage(
            conversationId: conversationId,
            text: '🤖 [Auto-Reply] ${rule.responseMessage}',
          );
        });
        break;
      }
    }
  }
}
