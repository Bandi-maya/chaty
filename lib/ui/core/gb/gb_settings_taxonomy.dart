import 'gb_feature_catalog.dart';

class GbSettingsLocation {
  final String section;
  final String subsection;
  const GbSettingsLocation(this.section, this.subsection);
}

class GbSettingsTaxonomy {
  const GbSettingsTaxonomy._();

  static const List<String> sections = <String>[
    'Privacy & security',
    'Chats & messaging',
    'Appearance & home',
    'Status & stories',
    'Calls',
    'Media & storage',
    'Notifications & presence',
    'Navigation & gestures',
    'Automation & behavior',
    'Advanced',
  ];

  static GbSettingsLocation locationFor(GbFeatureDefinition feature) {
    switch (feature.category) {
      case 'Privacy':
        return const GbSettingsLocation('Privacy & security', 'Privacy controls');
      case 'Block list maintenance':
        return const GbSettingsLocation('Privacy & security', 'Blocked contacts');
      case 'Advanced messaging':
        return const GbSettingsLocation('Chats & messaging', 'Advanced messaging');
      case 'Chat bubbles & ticks':
        return const GbSettingsLocation('Chats & messaging', 'Bubbles, ticks & text');
      case 'Avatars in chat':
        return const GbSettingsLocation('Chats & messaging', 'Chat avatars');
      case 'Conversation behavior':
        return const GbSettingsLocation('Chats & messaging', 'Conversation behavior');
      case 'Conversation colors':
        return const GbSettingsLocation('Chats & messaging', 'Conversation colors');
      case 'Conversation header':
        return const GbSettingsLocation('Chats & messaging', 'Conversation header');
      case 'Quick contact':
        return const GbSettingsLocation('Chats & messaging', 'Quick contact');
      case 'Composer appearance':
        return const GbSettingsLocation('Chats & messaging', 'Message composer');
      case 'Home FAB & shortcuts':
        return const GbSettingsLocation('Appearance & home', 'FAB & shortcuts');
      case 'Chat list rows':
        return const GbSettingsLocation('Appearance & home', 'Chat list');
      case 'Home list visibility':
        return const GbSettingsLocation('Appearance & home', 'Home visibility');
      case 'Home header':
        return const GbSettingsLocation('Appearance & home', 'Home header');
      case 'Fonts & icons':
        return const GbSettingsLocation('Appearance & home', 'Fonts & icons');
      case 'Snow & particles':
        return const GbSettingsLocation('Appearance & home', 'Visual effects');
      case 'Universal colors':
        return const GbSettingsLocation('Appearance & home', 'Global colors');
      case 'Widget appearance':
        return const GbSettingsLocation('Appearance & home', 'Widgets');
      case 'Status & stories':
        return const GbSettingsLocation('Status & stories', 'Status & stories');
      case 'Calls appearance':
        return const GbSettingsLocation('Calls', 'Call appearance');
      case 'Media visibility':
        return const GbSettingsLocation('Media & storage', 'Media visibility');
      case 'Media limits & quality':
        return const GbSettingsLocation('Media & storage', 'Quality & limits');
      case 'Storage & cleanup':
        return const GbSettingsLocation('Media & storage', 'Storage & cleanup');
      case 'Presence & activity alerts':
        return const GbSettingsLocation('Notifications & presence', 'Presence & activity');
      case 'Navigation & touch effects':
        return const GbSettingsLocation('Navigation & gestures', 'Navigation & touch');
      case 'Universal behavior':
        return const GbSettingsLocation('Automation & behavior', 'General behavior');
      default:
        return GbSettingsLocation('Advanced', feature.category.isEmpty ? 'Other' : feature.category);
    }
  }

  static Map<String, List<GbFeatureDefinition>> bySection() {
    final result = <String, List<GbFeatureDefinition>>{
      for (final section in sections) section: <GbFeatureDefinition>[],
    };
    for (final feature in GbFeatureCatalog.all) {
      final location = locationFor(feature);
      (result[location.section] ??= <GbFeatureDefinition>[]).add(feature);
    }
    return result;
  }

  static Map<String, List<GbFeatureDefinition>> bySubsection(String section) {
    final result = <String, List<GbFeatureDefinition>>{};
    for (final feature in GbFeatureCatalog.all) {
      final location = locationFor(feature);
      if (location.section != section) continue;
      (result[location.subsection] ??= <GbFeatureDefinition>[]).add(feature);
    }
    return result;
  }

  static bool matches(GbFeatureDefinition feature, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final location = locationFor(feature);
    return feature.title.toLowerCase().contains(q) ||
        feature.description.toLowerCase().contains(q) ||
        feature.key.toLowerCase().contains(q) ||
        feature.category.toLowerCase().contains(q) ||
        location.section.toLowerCase().contains(q) ||
        location.subsection.toLowerCase().contains(q);
  }
}
