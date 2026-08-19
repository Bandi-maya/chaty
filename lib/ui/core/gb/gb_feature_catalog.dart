enum GbFeatureKind { toggle, choice, slider, color, action }

class GbFeatureDefinition {
  final String key;
  final String title;
  final String category;
  final GbFeatureKind kind;
  final Object? defaultValue;
  final String description;
  final double min;
  final double max;
  final List<String> options;

  const GbFeatureDefinition({
    required this.key,
    required this.title,
    required this.category,
    required this.kind,
    required this.defaultValue,
    required this.description,
    this.min = 0,
    this.max = 100,
    this.options = const <String>[],
  });
}

class GbFeatureCatalog {
  const GbFeatureCatalog._();

  static const List<GbFeatureDefinition> all = <GbFeatureDefinition>[];

  static Map<String, Object?> get defaults => <String, Object?>{
    for (final item in all) item.key: item.defaultValue,
  };

  static List<String> get categories {
    final result = <String>[];
    for (final item in all) {
      if (!result.contains(item.category)) result.add(item.category);
    }
    return result;
  }

  static List<GbFeatureDefinition> inCategory(String category) =>
      all.where((item) => item.category == category).toList(growable: false);

  static GbFeatureDefinition? byKey(String key) {
    for (final item in all) {
      if (item.key == key) return item;
    }
    return null;
  }
}
