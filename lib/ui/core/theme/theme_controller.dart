import 'package:flutter/material.dart';
import 'theme_config.dart';
import 'theme_presets.dart';

class ThemeController extends ChangeNotifier {
  ThemeConfig _globalTheme = ThemePresets.getSystemDefaultTheme();
  ThemeConfig? _runtimeThemeOverride;
  final Map<String, ThemeConfig> _perChatThemes = {};
  UILayoutMode _layoutMode = UILayoutMode.classic;
  AppNavigationMode _navigationMode = AppNavigationMode.bottomNav;
  bool _useReducedMotion = false;
  double _fontScale = 1.0;
  double _density = 1.0;

  /// Theme currently consumed by runtime widgets. Phase 8 allows GB/advanced
  /// semantic overrides to sit on top of the selected base theme without
  /// destructively rewriting the user's actual theme selection.
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

  /// Applies a transient resolved theme used by widgets that consume
  /// [globalTheme]. This intentionally does not notify listeners because the
  /// caller already rebuilds from the preferences/theme listenable pair.
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

    // Check if there is an exact registered preset counterpart.
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

    // For any custom or arbitrary theme, dynamically adapt colors.
    setGlobalTheme(selected.toggleBrightness());
  }

  /// Keeps the system-default monochrome pair in sync with Android/iOS system
  /// appearance while leaving explicit/custom theme choices untouched.
  void applyPlatformBrightness(Brightness brightness) {
    final id = _globalTheme.id.toLowerCase();
    if (id == 'monochrome_dark' || id == 'monochrome_light') {
      setGlobalTheme(ThemePresets.getSystemDefaultTheme(brightness));
    }
  }

  void resetToDefaults() {
    _runtimeThemeOverride = null;
    _globalTheme = ThemePresets.getSystemDefaultTheme();
    _perChatThemes.clear();
    _layoutMode = UILayoutMode.classic;
    _navigationMode = AppNavigationMode.bottomNav;
    _useReducedMotion = false;
    _fontScale = 1.0;
    _density = 1.0;
    notifyListeners();
  }
}
