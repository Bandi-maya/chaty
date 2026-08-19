import 'package:flutter_test/flutter_test.dart';
import 'package:chat/ui/core/gb/gb_feature_catalog.dart';
import 'package:chat/ui/core/gb/gb_runtime_binding_registry.dart';
import 'package:chat/data/services/gb_semantic_sync_service.dart';

void main() {
  test('every GB feature has an explicit runtime owner', () {
    final grouped = GbRuntimeBindingRegistry.grouped();
    final classified = grouped.values.expand((items) => items).toList(growable: false);

    expect(classified.length, GbFeatureCatalog.all.length);
    expect(classified.map((item) => item.key).toSet().length, GbFeatureCatalog.all.length);
  });

  test('semantic alias keys still exist in the feature catalog', () {
    final catalogKeys = GbFeatureCatalog.all.map((item) => item.key).toSet();
    expect(
      GbSemanticSyncService.semanticAliasKeys.difference(catalogKeys),
      isEmpty,
    );
  });

  test('visual features are not falsely marked as phase-3 runtime complete', () {
    expect(
      GbRuntimeBindingRegistry.ownerFor(GbFeatureCatalog.byKey('ModFabNormalColor')!),
      GbRuntimeOwner.themeSystem,
    );
    expect(
      GbRuntimeBindingRegistry.ownerFor(GbFeatureCatalog.byKey('ModChatEntry')!),
      GbRuntimeOwner.composerVariants,
    );
    expect(
      GbRuntimeBindingRegistry.ownerFor(GbFeatureCatalog.byKey('tick_style')!),
      GbRuntimeOwner.messagePresentation,
    );
    expect(
      GbRuntimeBindingRegistry.ownerFor(GbFeatureCatalog.byKey('ModCallsBackground')!),
      GbRuntimeOwner.callSystem,
    );
  });
}
