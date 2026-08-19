import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'theme_presets.dart';

class ThemeController extends ChangeNotifier {
  ThemeConfig _globalTheme = ThemePresets.getSystemDefaultTheme();
  final Map<String, ThemeConfig> _perChatThemes = {};
  UILayoutMode _layoutMode = UILayoutMode.classic;
  AppNavigationMode _navigationMode = AppNavigationMode.bottomNav;
  bool _useReducedMotion = false;
  double _fontScale = 1.0;
  double _density = 1.0;

  ThemeConfig get globalTheme => _globalTheme;
  UILayoutMode get layoutMode => _layoutMode;
  AppNavigationMode get navigationMode => _navigationMode;
  bool get useReducedMotion => _useReducedMotion;
  double get fontScale => _fontScale;
  double get density => _density;

  ThemeConfig getThemeForChat(String conversationId) {
    return _perChatThemes[conversationId] ?? _globalTheme;
  }

  void setGlobalTheme(ThemeConfig newTheme) {
    _globalTheme = newTheme.copyWith(
      layoutMode: _layoutMode,
      navigationMode: _navigationMode,
      fontScale: _fontScale,
      density: _density,
      animationLevel: _useReducedMotion ? 0.0 : 1.0,
    );
    notifyListeners();
  }

  void updateThemeConfig(ThemeConfig customConfig) {
    _globalTheme = customConfig;
    notifyListeners();
  }

  void setChatTheme(String conversationId, ThemeConfig? customTheme) {
    if (customTheme == null) {
      _perChatThemes.remove(conversationId);
    } else {
      _perChatThemes[conversationId] = customTheme;
    }
    notifyListeners();
  }

  void setLayoutMode(UILayoutMode mode) {
    _layoutMode = mode;
    _globalTheme = _globalTheme.copyWith(layoutMode: mode);
    notifyListeners();
  }

  void setNavigationMode(AppNavigationMode mode) {
    _navigationMode = mode;
    _globalTheme = _globalTheme.copyWith(navigationMode: mode);
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale;
    _globalTheme = _globalTheme.copyWith(fontScale: scale);
    notifyListeners();
  }

  void setDensity(double density) {
    _density = density;
    _globalTheme = _globalTheme.copyWith(density: density);
    notifyListeners();
  }

  void setReducedMotion(bool reduced) {
    _useReducedMotion = reduced;
    _globalTheme = _globalTheme.copyWith(animationLevel: reduced ? 0.0 : 1.0);
    notifyListeners();
  }

  void toggleBrightness() {
    final currentId = _globalTheme.id.toLowerCase();
    
    // Check if there is an exact registered preset counterpart
    if (currentId.contains('dark') || currentId.contains('light')) {
      final targetId = currentId.contains('dark')
          ? currentId.replaceAll('dark', 'light')
          : currentId.replaceAll('light', 'dark');

      final match = ThemePresets.all.where((p) => p.id.toLowerCase() == targetId).firstOrNull;
      if (match != null) {
        setGlobalTheme(match);
        return;
      }
    }

    // For any custom or arbitrary theme, dynamically invert & adapt colors
    setGlobalTheme(_globalTheme.toggleBrightness());
  }

  void resetToDefaults() {
    _globalTheme = ThemePresets.monochromeDark;
    _perChatThemes.clear();
    _layoutMode = UILayoutMode.classic;
    _navigationMode = AppNavigationMode.bottomNav;
    _useReducedMotion = false;
    _fontScale = 1.0;
    _density = 1.0;
    notifyListeners();
  }
}
