import 'gb_feature_catalog.dart';

enum GbRuntimeOwner {
  coreRuntime,
  navigationVariants,
  composerVariants,
  messagePresentation,
  themeSystem,
  callSystem,
}

/// Explicit ownership map for the extracted feature catalogue.
///
/// Phase 3 owns behavioral/runtime features. Visual controls are intentionally
/// assigned to their later component phases instead of being falsely reported
/// as implemented merely because a preference value can be stored.
class GbRuntimeBindingRegistry {
  const GbRuntimeBindingRegistry._();

  static GbRuntimeOwner ownerFor(GbFeatureDefinition definition) {
    switch (definition.category) {
      case 'Navigation & touch effects':
        return GbRuntimeOwner.navigationVariants;
      case 'Composer appearance':
        return GbRuntimeOwner.composerVariants;
      case 'Chat bubbles & ticks':
      case 'Avatars in chat':
      case 'Conversation colors':
      case 'Conversation header':
      case 'Quick contact':
        return GbRuntimeOwner.messagePresentation;
      case 'Fonts & icons':
      case 'Snow & particles':
      case 'Chat list rows':
      case 'Home list visibility':
      case 'Home header':
      case 'Status & stories':
      case 'Universal colors':
      case 'Widget appearance':
      case 'Home FAB & shortcuts':
        return GbRuntimeOwner.themeSystem;
      case 'Calls appearance':
        return GbRuntimeOwner.callSystem;
      default:
        return GbRuntimeOwner.coreRuntime;
    }
  }

  static Map<GbRuntimeOwner, List<GbFeatureDefinition>> grouped() {
    final result = <GbRuntimeOwner, List<GbFeatureDefinition>>{
      for (final owner in GbRuntimeOwner.values) owner: <GbFeatureDefinition>[],
    };
    for (final feature in GbFeatureCatalog.all) {
      result[ownerFor(feature)]!.add(feature);
    }
    return result;
  }

  static bool isPhase3Owned(GbFeatureDefinition definition) =>
      ownerFor(definition) == GbRuntimeOwner.coreRuntime;
}
