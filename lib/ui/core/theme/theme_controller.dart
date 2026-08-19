import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'theme_presets.dart';

class ThemeController extends ChangeNotifier {
  static const double _defaultFontScale = 1.06;
  static const double _defaultDensity = 1.04;

  ThemeConfig _globalTheme = ThemePresets.getSystemDefaultTheme().copyWith(
    fontScale: _defaultFontScale,
    density: _defaultDensity,
  );
  ThemeConfig? _runtimeThemeOverride;
  final Map<String, ThemeConfig> _perChatThemes = {};
  UILayoutMode _layoutMode = UILayoutMode.classic;
  AppNavigationMode _navigationMode = AppNavigationMode.bottomNav;
  bool _useReducedMotion = false;
  double _fontScale = _defaultFontScale;
  double _density = _defaultDensity;

  ThemeConfig get globalTheme => _runtimeThemeOverride ?? _globalTheme;
  ThemeConfig get baseTheme => _globalTheme;
  UILayoutMode get layoutMode => _layoutMode;
  AppNavigationMode get navigationMode => _navigationMode;
  bool get useReducedMotion => _useReducedMotion;
  double get fontScale => _fontScale;
  double get density => _density;

  ThemeConfig getThemeForChat(String conversationId) {
    return _perChatThemes[conversationId] ?? globalTheme;
  }

  void setRuntimeThemeOverride(ThemeConfig? resolvedTheme) {
    _runtimeThemeOverride = resolvedTheme;
  }

  void setGlobalTheme(ThemeConfig newTheme) {
    _runtimeThemeOverride = null;
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
    _runtimeThemeOverride = null;
    _globalTheme = customConfig.copyWith(
      fontScale: _fontScale,
      density: _density,
      animationLevel: _useReducedMotion ? 0.0 : customConfig.animationLevel,
    );
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
    _runtimeThemeOverride = null;
    _globalTheme = _globalTheme.copyWith(layoutMode: mode);
    notifyListeners();
  }

  void setNavigationMode(AppNavigationMode mode) {
    _navigationMode = mode;
    _runtimeThemeOverride = null;
    _globalTheme = _globalTheme.copyWith(navigationMode: mode);
    notifyListeners();
  }

  void setFontScale(double scale) {
    _fontScale = scale.clamp(0.8, 1.6).toDouble();
    _runtimeThemeOverride = null;
    _globalTheme = _globalTheme.copyWith(fontScale: _fontScale);
    notifyListeners();
  }

  void setDensity(double density) {
    _density = density.clamp(0.8, 1.3).toDouble();
    _runtimeThemeOverride = null;
    _globalTheme = _globalTheme.copyWith(density: _density);
    notifyListeners();
  }

  void setReducedMotion(bool reduced) {
    _useReducedMotion = reduced;
    _runtimeThemeOverride = null;
    _globalTheme = _globalTheme.copyWith(animationLevel: reduced ? 0.0 : 1.0);
    notifyListeners();
  }

  void toggleBrightness() {
    final selected = _globalTheme;
    final currentId = selected.id.toLowerCase();

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

    setGlobalTheme(selected.toggleBrightness());
  }

  void applyPlatformBrightness(Brightness brightness) {
    final id = _globalTheme.id.toLowerCase();
    if (id == 'monochrome_dark' || id == 'monochrome_light') {
      setGlobalTheme(ThemePresets.getSystemDefaultTheme(brightness));
    }
  }

  void resetToDefaults() {
    _runtimeThemeOverride = null;
    _globalTheme = ThemePresets.getSystemDefaultTheme().copyWith(
      fontScale: _defaultFontScale,
      density: _defaultDensity,
    );
    _perChatThemes.clear();
    _layoutMode = UILayoutMode.classic;
    _navigationMode = AppNavigationMode.bottomNav;
    _useReducedMotion = false;
    _fontScale = _defaultFontScale;
    _density = _defaultDensity;
    notifyListeners();
  }
}
