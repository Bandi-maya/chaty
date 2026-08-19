import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatyAppIconPreset {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const ChatyAppIconPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class ChatyAppIconService extends ChangeNotifier {
  ChatyAppIconService._();

  static final ChatyAppIconService instance = ChatyAppIconService._();
  static const MethodChannel _channel = MethodChannel('chaty/app_icon');
  static const String _selectionKey = 'chaty_app_icon_selection_v1';
  static const String _customPathKey = 'chaty_app_icon_custom_path_v1';
  static const String customSelection = 'custom';

  static const List<ChatyAppIconPreset> presets = <ChatyAppIconPreset>[
    ChatyAppIconPreset(
      id: 'default',
      name: 'Chaty Classic',
      description: 'Original Chaty launcher icon',
      icon: Icons.chat_bubble_rounded,
    ),
    ChatyAppIconPreset(
      id: 'bubble',
      name: 'Chat Bubble',
      description: 'Clean conversation bubble',
      icon: Icons.mode_comment_rounded,
    ),
    ChatyAppIconPreset(
      id: 'messages',
      name: 'Messages',
      description: 'Layered private conversations',
      icon: Icons.forum_rounded,
    ),
    ChatyAppIconPreset(
      id: 'secure',
      name: 'Secure Chat',
      description: 'Messaging with privacy emphasis',
      icon: Icons.lock_rounded,
    ),
    ChatyAppIconPreset(
      id: 'minimal',
      name: 'Minimal',
      description: 'Simple premium message mark',
      icon: Icons.chat_rounded,
    ),
    ChatyAppIconPreset(
      id: 'call',
      name: 'Chat & Call',
      description: 'Messaging and calling identity',
      icon: Icons.call_rounded,
    ),
  ];

  bool _loaded = false;
  String _selection = 'default';
  String? _customPath;

  bool get isLoaded => _loaded;
  String get selection => _selection;
  String? get customPath => _customPath;
  bool get hasCustomIcon => _customPath != null && File(_customPath!).existsSync();

  ChatyAppIconPreset get activePreset => presets.firstWhere(
        (preset) => preset.id == _selection,
        orElse: () => presets.first,
      );

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _selection = prefs.getString(_selectionKey) ?? 'default';
    _customPath = prefs.getString(_customPathKey);
    if (_selection == customSelection && !hasCustomIcon) {
      _selection = 'default';
      _customPath = null;
      await prefs.remove(_customPathKey);
      await prefs.setString(_selectionKey, _selection);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> applyPreset(String id) async {
    if (!presets.any((preset) => preset.id == id)) {
      throw ArgumentError.value(id, 'id', 'Unknown Chaty icon preset');
    }
    await _channel.invokeMethod<void>('setLauncherIcon', <String, Object?>{'id': id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionKey, id);
    _selection = id;
    notifyListeners();
  }

  Future<void> applyCustom(String path) async {
    final file = File(path);
    if (!await file.exists()) throw StateError('The custom icon file no longer exists.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionKey, customSelection);
    await prefs.setString(_customPathKey, path);
    _selection = customSelection;
    _customPath = path;
    notifyListeners();
  }

  Future<void> removeCustom() async {
    final previous = _customPath;
    await _channel.invokeMethod<void>('setLauncherIcon', <String, Object?>{'id': 'default'});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectionKey, 'default');
    await prefs.remove(_customPathKey);
    _selection = 'default';
    _customPath = null;
    notifyListeners();
    if (previous != null) {
      try {
        final file = File(previous);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}

class ChatyAppIcon extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  const ChatyAppIcon({
    super.key,
    this.size = 56,
    this.borderRadius = 16,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = ChatyAppIconService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        Widget child;
        if (service.selection == ChatyAppIconService.customSelection && service.hasCustomIcon) {
          child = Image.file(
            File(service.customPath!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _presetIcon(context, service.activePreset),
          );
        } else {
          child = _presetIcon(context, service.activePreset);
        }
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: showShadow
                ? <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: .2),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
    );
  }

  Widget _presetIcon(BuildContext context, ChatyAppIconPreset preset) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primary, scheme.primaryContainer],
        ),
      ),
      child: Icon(preset.icon, size: size * .52, color: scheme.onPrimary),
    );
  }
}
