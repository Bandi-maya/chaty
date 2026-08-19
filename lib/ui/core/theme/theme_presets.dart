import 'package:flutter/material.dart';
import 'theme_config.dart';

class ThemePresets {
  static const ThemeConfig monochromeDark = ThemeConfig(
    id: 'monochrome_dark', name: 'Monochrome Dark', brightness: Brightness.dark,
    accentColor: Color(0xFFFFFFFF), backgroundColor: Color(0xFF000000), surfaceColor: Color(0xFF121212), cardColor: Color(0xFF1C1C1E),
    primaryTextColor: Color(0xFFFFFFFF), secondaryTextColor: Color(0xFFA1A1AA), outgoingBubbleColor: Color(0xFF27272A), incomingBubbleColor: Color(0xFF18181B),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF4F4F5), linkColor: Color(0xFFE4E4E7), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 16, density: 1, fontScale: 1, wallpaperId: 'none',
  );

  static const ThemeConfig monochromeLight = ThemeConfig(
    id: 'monochrome_light', name: 'Monochrome Light', brightness: Brightness.light,
    accentColor: Color(0xFF000000), backgroundColor: Color(0xFFFFFFFF), surfaceColor: Color(0xFFF4F4F5), cardColor: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF09090B), secondaryTextColor: Color(0xFF71717A), outgoingBubbleColor: Color(0xFF09090B), incomingBubbleColor: Color(0xFFF4F4F5),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF09090B), linkColor: Color(0xFF18181B), dangerColor: Color(0xFFDC2626), successColor: Color(0xFF059669),
    cornerRadius: 16, density: 1, fontScale: 1, wallpaperId: 'none',
  );

  static const ThemeConfig midnight = ThemeConfig(
    id: 'midnight', name: 'Midnight', brightness: Brightness.dark,
    accentColor: Color(0xFF6366F1), backgroundColor: Color(0xFF0B0F19), surfaceColor: Color(0xFF111827), cardColor: Color(0xFF1E293B),
    primaryTextColor: Color(0xFFF9FAFB), secondaryTextColor: Color(0xFF94A3B8), outgoingBubbleColor: Color(0xFF4F46E5), incomingBubbleColor: Color(0xFF1E293B),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF1F5F9), linkColor: Color(0xFF38BDF8), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 16, density: 1, fontScale: 1, wallpaperId: 'subtle_dots',
  );

  static const ThemeConfig paper = ThemeConfig(
    id: 'paper', name: 'Paper', brightness: Brightness.light,
    accentColor: Color(0xFF0F172A), backgroundColor: Color(0xFFF8FAFC), surfaceColor: Color(0xFFFFFFFF), cardColor: Color(0xFFFFFFFF),
    primaryTextColor: Color(0xFF0F172A), secondaryTextColor: Color(0xFF64748B), outgoingBubbleColor: Color(0xFF0F172A), incomingBubbleColor: Color(0xFFE2E8F0),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF0F172A), linkColor: Color(0xFF2563EB), dangerColor: Color(0xFFDC2626), successColor: Color(0xFF059669),
    cornerRadius: 14, density: 1, fontScale: 1, wallpaperId: 'none',
  );

  static const ThemeConfig ocean = ThemeConfig(
    id: 'ocean', name: 'Ocean', brightness: Brightness.dark,
    accentColor: Color(0xFF06B6D4), backgroundColor: Color(0xFF071A2E), surfaceColor: Color(0xFF0B2942), cardColor: Color(0xFF113857),
    primaryTextColor: Color(0xFFECFEFF), secondaryTextColor: Color(0xFF7DD3FC), outgoingBubbleColor: Color(0xFF0284C7), incomingBubbleColor: Color(0xFF0F3656),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFE0F2FE), linkColor: Color(0xFF38BDF8), dangerColor: Color(0xFFF87171), successColor: Color(0xFF34D399),
    cornerRadius: 18, density: 1, fontScale: 1, wallpaperId: 'constellation',
  );

  static const ThemeConfig sunset = ThemeConfig(
    id: 'sunset', name: 'Sunset', brightness: Brightness.dark,
    accentColor: Color(0xFFF43F5E), backgroundColor: Color(0xFF1C1326), surfaceColor: Color(0xFF2B1C3A), cardColor: Color(0xFF3B274F),
    primaryTextColor: Color(0xFFFFF1F2), secondaryTextColor: Color(0xFFFDA4AF), outgoingBubbleColor: Color(0xFFE11D48), incomingBubbleColor: Color(0xFF38234C),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFFFE4E6), linkColor: Color(0xFFFB923C), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 20, density: 1, fontScale: 1, wallpaperId: 'gradient_mesh',
  );

  static const ThemeConfig forest = ThemeConfig(
    id: 'forest', name: 'Forest', brightness: Brightness.dark,
    accentColor: Color(0xFF10B981), backgroundColor: Color(0xFF091E15), surfaceColor: Color(0xFF0E2E20), cardColor: Color(0xFF15402D),
    primaryTextColor: Color(0xFFECFDF5), secondaryTextColor: Color(0xFF6EE7B7), outgoingBubbleColor: Color(0xFF059669), incomingBubbleColor: Color(0xFF163E2C),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFD1FAE5), linkColor: Color(0xFF34D399), dangerColor: Color(0xFFF87171), successColor: Color(0xFF10B981),
    cornerRadius: 16, density: 1, fontScale: 1, wallpaperId: 'geometric',
  );

  static const ThemeConfig highContrast = ThemeConfig(
    id: 'high_contrast', name: 'High Contrast', brightness: Brightness.dark,
    accentColor: Color(0xFFFFFF00), backgroundColor: Color(0xFF000000), surfaceColor: Color(0xFF121212), cardColor: Color(0xFF1E1E1E),
    primaryTextColor: Color(0xFFFFFFFF), secondaryTextColor: Color(0xFFCCCCCC), outgoingBubbleColor: Color(0xFFFFFF00), incomingBubbleColor: Color(0xFF262626),
    outgoingTextColor: Color(0xFF000000), incomingTextColor: Color(0xFFFFFFFF), linkColor: Color(0xFF00E5FF), dangerColor: Color(0xFFFF5252), successColor: Color(0xFF00E676),
    cornerRadius: 8, density: 1.1, fontScale: 1.1, highContrast: true, wallpaperId: 'none',
  );

  static const ThemeConfig graphite = ThemeConfig(
    id: 'graphite', name: 'Graphite', brightness: Brightness.dark,
    accentColor: Color(0xFF94A3B8), backgroundColor: Color(0xFF121212), surfaceColor: Color(0xFF1E1E1E), cardColor: Color(0xFF2B2B2B),
    primaryTextColor: Color(0xFFF8FAFC), secondaryTextColor: Color(0xFF94A3B8), outgoingBubbleColor: Color(0xFF334155), incomingBubbleColor: Color(0xFF1E293B),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF1F5F9), linkColor: Color(0xFF60A5FA), dangerColor: Color(0xFFF87171), successColor: Color(0xFF4ADE80),
    cornerRadius: 12,
  );

  static const ThemeConfig lavender = ThemeConfig(
    id: 'lavender', name: 'Lavender', brightness: Brightness.light,
    accentColor: Color(0xFF8B5CF6), backgroundColor: Color(0xFFF5F3FF), surfaceColor: Color(0xFFFFFFFF), cardColor: Color(0xFFEDE9FE),
    primaryTextColor: Color(0xFF4C1D95), secondaryTextColor: Color(0xFF6D28D9), outgoingBubbleColor: Color(0xFF7C3AED), incomingBubbleColor: Color(0xFFDDD6FE),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF4C1D95), linkColor: Color(0xFF6D28D9), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 18,
  );

  static const ThemeConfig rose = ThemeConfig(
    id: 'rose', name: 'Rose', brightness: Brightness.light,
    accentColor: Color(0xFFF43F5E), backgroundColor: Color(0xFFFFF1F2), surfaceColor: Color(0xFFFFFFFF), cardColor: Color(0xFFFFE4E6),
    primaryTextColor: Color(0xFF881337), secondaryTextColor: Color(0xFF9F1239), outgoingBubbleColor: Color(0xFFE11D48), incomingBubbleColor: Color(0xFFFECDD3),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF881337), linkColor: Color(0xFFE11D48), dangerColor: Color(0xFFE11D48), successColor: Color(0xFF10B981),
    cornerRadius: 18,
  );

  static const ThemeConfig coffee = ThemeConfig(
    id: 'coffee', name: 'Coffee', brightness: Brightness.dark,
    accentColor: Color(0xFFD97706), backgroundColor: Color(0xFF1C1917), surfaceColor: Color(0xFF292524), cardColor: Color(0xFF44403C),
    primaryTextColor: Color(0xFFFAFAF9), secondaryTextColor: Color(0xFFA8A29E), outgoingBubbleColor: Color(0xFFB45309), incomingBubbleColor: Color(0xFF292524),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF5F5F4), linkColor: Color(0xFFF59E0B), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 16,
  );

  static const ThemeConfig arctic = ThemeConfig(
    id: 'arctic', name: 'Arctic', brightness: Brightness.light,
    accentColor: Color(0xFF0284C7), backgroundColor: Color(0xFFF0F9FF), surfaceColor: Color(0xFFFFFFFF), cardColor: Color(0xFFE0F2FE),
    primaryTextColor: Color(0xFF0C4A6E), secondaryTextColor: Color(0xFF0369A1), outgoingBubbleColor: Color(0xFF0284C7), incomingBubbleColor: Color(0xFFBAE6FD),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF0C4A6E), linkColor: Color(0xFF0284C7), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF10B981),
    cornerRadius: 16,
  );

  static const ThemeConfig amoled = ThemeConfig(
    id: 'amoled', name: 'AMOLED', brightness: Brightness.dark,
    accentColor: Color(0xFF38BDF8), backgroundColor: Color(0xFF000000), surfaceColor: Color(0xFF0A0A0A), cardColor: Color(0xFF141414),
    primaryTextColor: Color(0xFFFFFFFF), secondaryTextColor: Color(0xFFA3A3A3), outgoingBubbleColor: Color(0xFF0284C7), incomingBubbleColor: Color(0xFF171717),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFFAFAFA), linkColor: Color(0xFF38BDF8), dangerColor: Color(0xFFEF4444), successColor: Color(0xFF22C55E),
    cornerRadius: 14,
  );

  static const ThemeConfig warmNeutral = ThemeConfig(
    id: 'warm_neutral', name: 'Warm Neutral', brightness: Brightness.light,
    accentColor: Color(0xFF78350F), backgroundColor: Color(0xFFFEF3C7), surfaceColor: Color(0xFFFFFBEB), cardColor: Color(0xFFFDE68A),
    primaryTextColor: Color(0xFF451A03), secondaryTextColor: Color(0xFF78350F), outgoingBubbleColor: Color(0xFF92400E), incomingBubbleColor: Color(0xFFFEF3C7),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF451A03), linkColor: Color(0xFFB45309), dangerColor: Color(0xFFDC2626), successColor: Color(0xFF16A34A),
    cornerRadius: 16,
  );

  static const ThemeConfig solarizedLight = ThemeConfig(
    id: 'solarized_light', name: 'Solarized Light', brightness: Brightness.light,
    accentColor: Color(0xFF006D77), backgroundColor: Color(0xFFFDF6E3), surfaceColor: Color(0xFFFFFBEE), cardColor: Color(0xFFF5EFD9),
    primaryTextColor: Color(0xFF073642), secondaryTextColor: Color(0xFF586E75), outgoingBubbleColor: Color(0xFF006D77), incomingBubbleColor: Color(0xFFE8E2CE),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF073642), linkColor: Color(0xFF005F73), dangerColor: Color(0xFFB91C1C), successColor: Color(0xFF047857),
    cornerRadius: 15,
  );

  static const ThemeConfig solarizedDark = ThemeConfig(
    id: 'solarized_dark', name: 'Solarized Dark', brightness: Brightness.dark,
    accentColor: Color(0xFF2AA198), backgroundColor: Color(0xFF002B36), surfaceColor: Color(0xFF073642), cardColor: Color(0xFF0B3D47),
    primaryTextColor: Color(0xFFFDF6E3), secondaryTextColor: Color(0xFF93A1A1), outgoingBubbleColor: Color(0xFF0F766E), incomingBubbleColor: Color(0xFF164E63),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF8FAFC), linkColor: Color(0xFF67E8F9), dangerColor: Color(0xFFF87171), successColor: Color(0xFF34D399),
    cornerRadius: 15,
  );

  static const ThemeConfig nord = ThemeConfig(
    id: 'nord', name: 'Nord', brightness: Brightness.dark,
    accentColor: Color(0xFF88C0D0), backgroundColor: Color(0xFF2E3440), surfaceColor: Color(0xFF3B4252), cardColor: Color(0xFF434C5E),
    primaryTextColor: Color(0xFFECEFF4), secondaryTextColor: Color(0xFFD8DEE9), outgoingBubbleColor: Color(0xFF5E81AC), incomingBubbleColor: Color(0xFF4C566A),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFECEFF4), linkColor: Color(0xFF8FBCBB), dangerColor: Color(0xFFBF616A), successColor: Color(0xFFA3BE8C),
    cornerRadius: 16,
  );

  static const ThemeConfig sakura = ThemeConfig(
    id: 'sakura', name: 'Sakura', brightness: Brightness.light,
    accentColor: Color(0xFFBE185D), backgroundColor: Color(0xFFFFF7FA), surfaceColor: Color(0xFFFFFFFF), cardColor: Color(0xFFFCE7F3),
    primaryTextColor: Color(0xFF500724), secondaryTextColor: Color(0xFF9D174D), outgoingBubbleColor: Color(0xFFBE185D), incomingBubbleColor: Color(0xFFFBCFE8),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFF500724), linkColor: Color(0xFF9D174D), dangerColor: Color(0xFFBE123C), successColor: Color(0xFF047857),
    cornerRadius: 20,
  );

  static const ThemeConfig royalIndigo = ThemeConfig(
    id: 'royal_indigo', name: 'Royal Indigo', brightness: Brightness.dark,
    accentColor: Color(0xFFA5B4FC), backgroundColor: Color(0xFF11102A), surfaceColor: Color(0xFF1E1B4B), cardColor: Color(0xFF312E81),
    primaryTextColor: Color(0xFFF5F3FF), secondaryTextColor: Color(0xFFC4B5FD), outgoingBubbleColor: Color(0xFF4F46E5), incomingBubbleColor: Color(0xFF29265E),
    outgoingTextColor: Color(0xFFFFFFFF), incomingTextColor: Color(0xFFF5F3FF), linkColor: Color(0xFFC7D2FE), dangerColor: Color(0xFFFB7185), successColor: Color(0xFF6EE7B7),
    cornerRadius: 18,
  );

  static const List<ThemeConfig> all = <ThemeConfig>[
    monochromeDark,
    monochromeLight,
    midnight,
    paper,
    ocean,
    sunset,
    forest,
    highContrast,
    graphite,
    lavender,
    rose,
    coffee,
    arctic,
    amoled,
    warmNeutral,
    solarizedLight,
    solarizedDark,
    nord,
    sakura,
    royalIndigo,
  ];

  static ThemeConfig getSystemDefaultTheme([Brightness? platformBrightness]) {
    final brightness = platformBrightness ??
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.light ? monochromeLight : monochromeDark;
  }

  static ThemeConfig getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => monochromeDark,
    );
  }
}
