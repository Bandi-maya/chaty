import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/gb/gb_feature_catalog.dart';
import 'package:chat/ui/core/gb/gb_settings_taxonomy.dart';

void main() {
  group('GB settings taxonomy integrity', () {
    test('preserves every registered feature exactly once', () {
      final all = GbFeatureCatalog.all;
      final keys = all.map((feature) => feature.key).toList(growable: false);
      expect(keys.toSet().length, keys.length, reason: 'Feature keys must remain unique.');

      final categorized = GbSettingsTaxonomy.bySection().values.expand((items) => items).toList(growable: false);
      expect(categorized.length, all.length, reason: 'No advanced setting may be dropped during categorization.');
      expect(categorized.map((feature) => feature.key).toSet(), keys.toSet());
    });

    test('every feature resolves to a visible section and subsection', () {
      for (final feature in GbFeatureCatalog.all) {
        final location = GbSettingsTaxonomy.locationFor(feature);
        expect(GbSettingsTaxonomy.sections, contains(location.section), reason: feature.key);
        expect(location.subsection.trim(), isNotEmpty, reason: feature.key);
        expect(feature.title.trim(), isNotEmpty, reason: feature.key);
      }
    });

    test('search covers title, key, legacy category and semantic location', () {
      for (final feature in GbFeatureCatalog.all) {
        expect(GbSettingsTaxonomy.matches(feature, feature.title), isTrue, reason: feature.key);
        expect(GbSettingsTaxonomy.matches(feature, feature.key), isTrue, reason: feature.key);
        expect(GbSettingsTaxonomy.matches(feature, feature.category), isTrue, reason: feature.key);
        final location = GbSettingsTaxonomy.locationFor(feature);
        expect(GbSettingsTaxonomy.matches(feature, location.section), isTrue, reason: feature.key);
      }
    });
  });
}
