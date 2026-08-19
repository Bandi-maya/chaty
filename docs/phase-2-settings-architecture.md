# Phase 2 — Advanced settings information architecture

This phase replaces the legacy flat GB Feature Center with a native categorized Settings experience while preserving the existing feature registry and keys.

## Top-level sections

- Privacy & security
- Chats & messaging
- Appearance & home
- Status & stories
- Calls
- Media & storage
- Notifications & presence
- Navigation & gestures
- Automation & behavior
- Advanced

`GbSettingsTaxonomy` maps every `GbFeatureDefinition` into one section and one subsection. Unknown legacy categories are retained under Advanced rather than being dropped.

## Invariants

- `GbFeatureCatalog.all` remains the source of truth.
- Existing feature keys are not renamed.
- Normal UI no longer displays raw keys.
- Search still indexes title, description, legacy key, legacy category, section, and subsection.
- The legacy giant flat-list screen has been removed from the implementation branch.
- Runtime behavior itself is intentionally audited in Phase 3; Phase 2 does not claim that every historical feature binding is correct merely because it is configurable.

## Verification

`test/gb_settings_taxonomy_test.dart` checks uniqueness, full categorization, and searchability. The repository currently has no GitHub Actions workflow associated with these commits, and this execution environment could not reach github.com from the local container to run Flutter directly. Therefore runtime/analyzer verification remains mandatory before release and is not being falsely reported as executed in this phase.
