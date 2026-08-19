import 'package:flutter/material.dart';

enum UILayoutMode {
  classic,
  compact,
  expressive,
  focus,
  tabletDesktop,
}

enum AppNavigationMode {
  bottomNav,
  compactRail,
  gestureTabs,
}

enum AppBubbleStyle {
  rounded,
  softSquare,
  pill,
  sharpTail,
}

class ThemeConfig {
  final String id;
  final String name;
  final Brightness brightness;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color outgoingBubbleColor;
  final Color incomingBubbleColor;
  final Color outgoingTextColor;
  final Color incomingTextColor;
  final Color linkColor;
  final Color dangerColor;
  final Color successColor;
  final double cornerRadius;
  final double density; // 0.8 to 1.3
  final double fontScale; // 0.85 to 1.3
  final AppNavigationMode navigationMode;
  final UILayoutMode layoutMode;
  final AppBubbleStyle bubbleStyle;
  final String wallpaperId; // 'none', 'subtle_dots', 'geometric', 'gradient_mesh', 'constellation'
  final double animationLevel; // 0.0 to 1.0
  final bool highContrast;

  const ThemeConfig({
    required this.id,
    required this.name,
    required this.brightness,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.outgoingBubbleColor,
    required this.incomingBubbleColor,
    required this.outgoingTextColor,
    required this.incomingTextColor,
    required this.linkColor,
    required this.dangerColor,
    required this.successColor,
    this.cornerRadius = 16.0,
    this.density = 1.0,
    this.fontScale = 1.0,
    this.navigationMode = AppNavigationMode.bottomNav,
    this.layoutMode = UILayoutMode.classic,
    this.bubbleStyle = AppBubbleStyle.rounded,
    this.wallpaperId = 'subtle_dots',
    this.animationLevel = 1.0,
    this.highContrast = false,
  });

  ThemeConfig copyWith({
    String? id,
    String? name,
    Brightness? brightness,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? outgoingBubbleColor,
    Color? incomingBubbleColor,
    Color? outgoingTextColor,
    Color? incomingTextColor,
    Color? linkColor,
    Color? dangerColor,
    Color? successColor,
    double? cornerRadius,
    double? density,
    double? fontScale,
    AppNavigationMode? navigationMode,
    UILayoutMode? layoutMode,
    AppBubbleStyle? bubbleStyle,
    String? wallpaperId,
    double? animationLevel,
    bool? highContrast,
  }) {
    return ThemeConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      outgoingBubbleColor: outgoingBubbleColor ?? this.outgoingBubbleColor,
      incomingBubbleColor: incomingBubbleColor ?? this.incomingBubbleColor,
      outgoingTextColor: outgoingTextColor ?? this.outgoingTextColor,
      incomingTextColor: incomingTextColor ?? this.incomingTextColor,
      linkColor: linkColor ?? this.linkColor,
      dangerColor: dangerColor ?? this.dangerColor,
      successColor: successColor ?? this.successColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      density: density ?? this.density,
      fontScale: fontScale ?? this.fontScale,
      navigationMode: navigationMode ?? this.navigationMode,
      layoutMode: layoutMode ?? this.layoutMode,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      wallpaperId: wallpaperId ?? this.wallpaperId,
      animationLevel: animationLevel ?? this.animationLevel,
      highContrast: highContrast ?? this.highContrast,
    );
  }

  // Calculate contrast ratio helper (L1 + 0.05) / (L2 + 0.05)
  static double calculateContrastRatio(Color foreground, Color background) {
    double lum1 = foreground.computeLuminance();
    double lum2 = background.computeLuminance();
    double brightest = lum1 > lum2 ? lum1 : lum2;
    double darkest = lum1 > lum2 ? lum2 : lum1;
    return (brightest + 0.05) / (darkest + 0.05);
  }

  bool get hasContrastIssue {
    final double textRatio = calculateContrastRatio(primaryTextColor, backgroundColor);
    final double outgoingBubbleRatio = calculateContrastRatio(outgoingTextColor, outgoingBubbleColor);
    final double incomingBubbleRatio = calculateContrastRatio(incomingTextColor, incomingBubbleColor);
    return textRatio < 4.5 || outgoingBubbleRatio < 3.5 || incomingBubbleRatio < 3.5;
  }

  Color get onAccentColor => accentColor.computeLuminance() > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color get onSurfaceColor => primaryTextColor;
  Color get onBackgroundColor => primaryTextColor;

  /// Dynamically inverts brightness and adapts all colors without hardcoding presets.
  ThemeConfig toggleBrightness() {
    final bool isDark = brightness == Brightness.dark;
    final targetBrightness = isDark ? Brightness.light : Brightness.dark;

    if (isDark) {
      // Transition from Dark -> Light
      final lightBg = const Color(0xFFFFFFFF);
      final lightSurface = const Color(0xFFF4F4F5);
      final lightCard = const Color(0xFFFFFFFF);
      final lightPrimaryText = const Color(0xFF09090B);
      final lightSecondaryText = const Color(0xFF71717A);
      
      final adaptedAccent = accentColor.computeLuminance() > 0.85
          ? const Color(0xFF09090B)
          : accentColor;

      return copyWith(
        brightness: targetBrightness,
        backgroundColor: lightBg,
        surfaceColor: lightSurface,
        cardColor: lightCard,
        primaryTextColor: lightPrimaryText,
        secondaryTextColor: lightSecondaryText,
        accentColor: adaptedAccent,
        incomingBubbleColor: const Color(0xFFF4F4F5),
        incomingTextColor: const Color(0xFF09090B),
        outgoingBubbleColor: adaptedAccent,
        outgoingTextColor: adaptedAccent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      );
    } else {
      // Transition from Light -> Dark
      final darkBg = const Color(0xFF000000);
      final darkSurface = const Color(0xFF121212);
      final darkCard = const Color(0xFF1C1C1E);
      final darkPrimaryText = const Color(0xFFFFFFFF);
      final darkSecondaryText = const Color(0xFFA1A1AA);

      final adaptedAccent = accentColor.computeLuminance() < 0.15
          ? const Color(0xFFFFFFFF)
          : accentColor;

      return copyWith(
        brightness: targetBrightness,
        backgroundColor: darkBg,
        surfaceColor: darkSurface,
        cardColor: darkCard,
        primaryTextColor: darkPrimaryText,
        secondaryTextColor: darkSecondaryText,
        accentColor: adaptedAccent,
        incomingBubbleColor: const Color(0xFF18181B),
        incomingTextColor: const Color(0xFFF4F4F5),
        outgoingBubbleColor: adaptedAccent.computeLuminance() > 0.85
            ? const Color(0xFF27272A)
            : adaptedAccent,
        outgoingTextColor: Colors.white,
      );
    }
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accentColor,
        onPrimary: onAccentColor,
        secondary: accentColor.withValues(alpha: 0.8),
        onSecondary: onAccentColor,
        error: dangerColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: primaryTextColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 1.0,
        iconTheme: IconThemeData(color: primaryTextColor),
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 19 * fontScale,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: onAccentColor,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius > 14 ? cornerRadius : 16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(
            color: brightness == Brightness.dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius > 14 ? cornerRadius : 16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: (brightness == Brightness.dark && accentColor.computeLuminance() > 0.8)
              ? primaryTextColor
              : accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: onAccentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius > 14 ? cornerRadius : 16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: onAccentColor,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: accentColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brightness == Brightness.dark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: brightness == Brightness.dark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: primaryTextColor, fontSize: 28 * fontScale, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: primaryTextColor, fontSize: 22 * fontScale, fontWeight: FontWeight.bold, letterSpacing: -0.3),
        titleLarge: TextStyle(color: primaryTextColor, fontSize: 18 * fontScale, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: primaryTextColor, fontSize: 15 * fontScale, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryTextColor, fontSize: 15 * fontScale, height: 1.35),
        bodyMedium: TextStyle(color: secondaryTextColor, fontSize: 13.5 * fontScale, height: 1.35),
        labelLarge: TextStyle(color: primaryTextColor, fontSize: 13.5 * fontScale, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: secondaryTextColor, fontSize: 11 * fontScale),
      ),
    );
  }
}
