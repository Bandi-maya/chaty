import 'package:flutter/material.dart';

import '../../../domain/models/chaty_preferences.dart';
import '../../../domain/models/visual_preferences.dart';
import '../persistence/preferences_storage.dart';

class PreferenceHistoryEntry {
  final String key;
  final String title;
  final dynamic previousValue;
  final dynamic newValue;
  final DateTime timestamp;

  const PreferenceHistoryEntry({
    required this.key,
    required this.title,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
  });
}

class ChatyPreferencesController extends ChangeNotifier {
  PrivacyPreferences _privacy = const PrivacyPreferences();
  SecurityPreferences _security = const SecurityPreferences();
  HomePreferences _home = const HomePreferences();
  ConversationPreferences _conversation = const ConversationPreferences();
  NotificationPreferences _notification = const NotificationPreferences();
  MessageAutomationPreferences _automation = const MessageAutomationPreferences();
  NavigationEffectPreferences _effects = const NavigationEffectPreferences();
  VisualPreferences _visual = const VisualPreferences();

  final Set<String> _starredFavorites = <String>{};
  final List<PreferenceHistoryEntry> _history = <PreferenceHistoryEntry>[];

  ChatyPreferencesController() {
    _init();
  }

  PrivacyPreferences get privacy => _privacy;
  SecurityPreferences get security => _security;
  HomePreferences get home => _home;
  ConversationPreferences get conversation => _conversation;
  NotificationPreferences get notification => _notification;
  MessageAutomationPreferences get automation => _automation;
  NavigationEffectPreferences get effects => _effects;
  VisualPreferences get visual => _visual;

  Set<String> get starredFavorites => Set<String>.unmodifiable(_starredFavorites);
  List<PreferenceHistoryEntry> get history =>
      List<PreferenceHistoryEntry>.unmodifiable(_history);

  Future<void> _init() async {
    final data = await LocalPreferencesStorage.loadPreferences();
    if (data.isEmpty) return;

    if (data['privacy'] is Map) {
      _privacy = PrivacyPreferences.fromMap(
        Map<String, dynamic>.from(data['privacy'] as Map),
      );
    }
    if (data['security'] is Map) {
      _security = SecurityPreferences.fromMap(
        Map<String, dynamic>.from(data['security'] as Map),
      );
    }
    if (data['home'] is Map) {
      _home = HomePreferences.fromMap(
        Map<String, dynamic>.from(data['home'] as Map),
      );
    }
    if (data['conversation'] is Map) {
      _conversation = ConversationPreferences.fromMap(
        Map<String, dynamic>.from(data['conversation'] as Map),
      );
    }
    if (data['notification'] is Map) {
      _notification = NotificationPreferences.fromMap(
        Map<String, dynamic>.from(data['notification'] as Map),
      );
    }
    if (data['automation'] is Map) {
      _automation = MessageAutomationPreferences.fromMap(
        Map<String, dynamic>.from(data['automation'] as Map),
      );
    }
    if (data['effects'] is Map) {
      _effects = NavigationEffectPreferences.fromMap(
        Map<String, dynamic>.from(data['effects'] as Map),
      );
    }
    if (data['visual'] is Map) {
      _visual = VisualPreferences.fromMap(
        Map<String, dynamic>.from(data['visual'] as Map),
      );
    }
    if (data['favorites'] is List) {
      _starredFavorites.addAll(
        (data['favorites'] as List).map((e) => e.toString()),
      );
    }
    notifyListeners();
  }

  void _persist() {
    LocalPreferencesStorage.savePreferences(<String, dynamic>{
      'privacy': _privacy.toMap(),
      'security': _security.toMap(),
      'home': _home.toMap(),
      'conversation': _conversation.toMap(),
      'notification': _notification.toMap(),
      'automation': _automation.toMap(),
      'effects': _effects.toMap(),
      'visual': _visual.toMap(),
      'favorites': _starredFavorites.toList(),
    });
  }

  void updatePrivacy(
    PrivacyPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _privacy = newPrefs;
    if (logTitle != null) _logHistory('privacy', logTitle, prevVal, newVal);
    _persist();
    notifyListeners();
  }

  void updateSecurity(
    SecurityPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _security = newPrefs;
    if (logTitle != null) _logHistory('security', logTitle, prevVal, newVal);
    _persist();
    notifyListeners();
  }

  void updateHome(
    HomePreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _home = newPrefs;
    if (logTitle != null) _logHistory('home', logTitle, prevVal, newVal);
    _persist();
    notifyListeners();
  }

  void updateConversation(
    ConversationPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _conversation = newPrefs;
    if (logTitle != null) {
      _logHistory('conversation', logTitle, prevVal, newVal);
    }
    _persist();
    notifyListeners();
  }

  void updateNotification(
    NotificationPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _notification = newPrefs;
    if (logTitle != null) {
      _logHistory('notification', logTitle, prevVal, newVal);
    }
    _persist();
    notifyListeners();
  }

  void updateAutomation(
    MessageAutomationPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _automation = newPrefs;
    if (logTitle != null) {
      _logHistory('automation', logTitle, prevVal, newVal);
    }
    _persist();
    notifyListeners();
  }

  void updateEffects(
    NavigationEffectPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _effects = newPrefs;
    if (logTitle != null) _logHistory('effects', logTitle, prevVal, newVal);
    _persist();
    notifyListeners();
  }

  void updateVisual(
    VisualPreferences newPrefs, {
    String? logTitle,
    dynamic prevVal,
    dynamic newVal,
  }) {
    _visual = newPrefs;
    if (logTitle != null) _logHistory('visual', logTitle, prevVal, newVal);
    _persist();
    notifyListeners();
  }

  void toggleFavorite(String settingKey) {
    if (_starredFavorites.contains(settingKey)) {
      _starredFavorites.remove(settingKey);
    } else {
      _starredFavorites.add(settingKey);
    }
    _persist();
    notifyListeners();
  }

  bool isFavorite(String settingKey) => _starredFavorites.contains(settingKey);

  void _logHistory(
    String key,
    String title,
    dynamic prevVal,
    dynamic newVal,
  ) {
    _history.insert(
      0,
      PreferenceHistoryEntry(
        key: key,
        title: title,
        previousValue: prevVal,
        newValue: newVal,
        timestamp: DateTime.now(),
      ),
    );
    if (_history.length > 25) _history.removeLast();
  }

  void resetPrivacy() {
    _privacy = const PrivacyPreferences();
    _persist();
    notifyListeners();
  }

  void resetHome() {
    _home = const HomePreferences();
    _persist();
    notifyListeners();
  }

  void resetConversation() {
    _conversation = const ConversationPreferences();
    _persist();
    notifyListeners();
  }

  void resetNotifications() {
    _notification = const NotificationPreferences();
    _persist();
    notifyListeners();
  }

  void resetEffects() {
    _effects = const NavigationEffectPreferences();
    _persist();
    notifyListeners();
  }

  void resetVisual() {
    _visual = const VisualPreferences();
    _persist();
    notifyListeners();
  }

  void resetAll() {
    _privacy = const PrivacyPreferences();
    _security = const SecurityPreferences();
    _home = const HomePreferences();
    _conversation = const ConversationPreferences();
    _notification = const NotificationPreferences();
    _automation = const MessageAutomationPreferences();
    _effects = const NavigationEffectPreferences();
    _visual = const VisualPreferences();
    _starredFavorites.clear();
    _history.clear();
    _persist();
    notifyListeners();
  }
}
