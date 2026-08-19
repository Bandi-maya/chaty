import 'package:flutter/material.dart';

class MockNotification {
  final String id;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final DateTime timestamp;

  const MockNotification({
    required this.id,
    required this.title,
    required this.body,
    this.icon = Icons.notifications_active_rounded,
    this.color = const Color(0xFF6366F1),
    required this.timestamp,
  });
}

class ChatyNotificationService extends ChangeNotifier {
  final List<MockNotification> _notifications = [];

  List<MockNotification> get notifications => List.unmodifiable(_notifications);

  void triggerEventNotification({
    required String title,
    required String body,
    IconData icon = Icons.notifications_rounded,
    Color color = const Color(0xFF6366F1),
  }) {
    final notif = MockNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      icon: icon,
      color: color,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
