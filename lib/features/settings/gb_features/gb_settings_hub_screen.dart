import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui/core/controllers/chaty_preferences_controller.dart';
import '../../../ui/core/gb/gb_feature_catalog.dart';
import '../../../ui/core/gb/gb_settings_taxonomy.dart';

class GbSettingsHubScreen extends StatefulWidget {
  final ChatyPreferencesController preferencesController;
  const GbSettingsHubScreen({super.key, required this.preferencesController});

  @override
  State<GbSettingsHubScreen> createState() => _GbSettingsHubScreenState();
}

class _GbSettingsHubScreenState extends State<GbSettingsHubScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bySection = GbSettingsTaxonomy.bySection();
    final searching = _query.trim().isNotEmpty;
    final matches = searching
        ? GbFeatureCatalog.all.where((f) => GbSettingsTaxonomy.matches(f, _query)).toList(growable: false)
        : const <GbFeatureDefinition>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced settings'),
        actions: [
          IconButton(
            tooltip: 'Reset advanced settings',
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search settings',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searching
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: searching
                  ? _SearchResults(
                      results: matches,
                      controller: widget.preferencesController,
                      onColor: _editColor,
                      onAction: _runAction,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                      itemCount: GbSettingsTaxonomy.sections.length,
                      itemBuilder: (context, index) {
                        final section = GbSettingsTaxonomy.sections[index];
                        final count = bySection[section]?.length ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(_iconFor(section), size: 20)),
                            title: Text(section, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('$count settings'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _GbSettingsSectionScreen(
                                  section: section,
                                  controller: widget.preferencesController,
                                  onColor: _editColor,
                                  onAction: _runAction,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String section) {
    switch (section) {
      case 'Privacy & security': return Icons.shield_outlined;
      case 'Chats & messaging': return Icons.chat_bubble_outline_rounded;
      case 'Appearance & home': return Icons.palette_outlined;
      case 'Status & stories': return Icons.auto_stories_outlined;
      case 'Calls': return Icons.call_outlined;
      case 'Media & storage': return Icons.perm_media_outlined;
      case 'Notifications & presence': return Icons.notifications_outlined;
      case 'Navigation & gestures': return Icons.swipe_outlined;
      case 'Automation & behavior': return Icons.bolt_outlined;
      default: return Icons.tune_rounded;
    }
  }

  Future<void> _editColor(GbFeatureDefinition item) async {
    final current = widget.preferencesController.gbInt(item.key);
    final controller = TextEditingController(
      text: current == 0 ? '' : '#${current.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );
    final selected = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'ARGB hex', hintText: '#FF6366F1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              var text = controller.text.trim().replaceFirst('#', '').replaceFirst('0x', '');
              if (text.length == 6) text = 'FF$text';
              Navigator.pop(dialogContext, int.tryParse(text, radix: 16));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (selected != null) widget.preferencesController.updateGbFeature(item.key, selected);
  }

  Future<void> _runAction(GbFeatureDefinition item) async {
    if (item.key == 'clear_logs') {
      widget.preferencesController.clearPreferenceHistory();
      return;
    }
    if (item.key == 'mas_key_cleanlog_blocklist') {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('blocked_users').delete().eq('blocker_id', user.id);
      return;
    }
    final input = TextEditingController(text: widget.preferencesController.gbString(item.key));
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item.title),
        content: TextField(controller: input, decoration: const InputDecoration(labelText: 'Value')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, input.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    input.dispose();
    if (result != null) widget.preferencesController.updateGbFeature(item.key, result);
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset advanced settings?'),
        content: const Text('This restores advanced settings to their defaults without deleting chats or account data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) widget.preferencesController.resetGbFeatures();
  }
}

class _GbSettingsSectionScreen extends StatelessWidget {
  final String section;
  final ChatyPreferencesController controller;
  final Future<void> Function(GbFeatureDefinition) onColor;
  final Future<void> Function(GbFeatureDefinition) onAction;

  const _GbSettingsSectionScreen({
    required this.section,
    required this.controller,
    required this.onColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final groups = GbSettingsTaxonomy.bySubsection(section);
    return Scaffold(
      appBar: AppBar(title: Text(section)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
          children: [
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                child: Text(entry.key.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              for (final feature in entry.value)
                _FeatureRow(feature: feature, controller: controller, onColor: onColor, onAction: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<GbFeatureDefinition> results;
  final ChatyPreferencesController controller;
  final Future<void> Function(GbFeatureDefinition) onColor;
  final Future<void> Function(GbFeatureDefinition) onAction;

  const _SearchResults({required this.results, required this.controller, required this.onColor, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const Center(child: Text('No matching settings'));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        itemCount: results.length,
        itemBuilder: (context, index) => _FeatureRow(
          feature: results[index],
          controller: controller,
          onColor: onColor,
          onAction: onAction,
          showLocation: true,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final GbFeatureDefinition feature;
  final ChatyPreferencesController controller;
  final Future<void> Function(GbFeatureDefinition) onColor;
  final Future<void> Function(GbFeatureDefinition) onAction;
  final bool showLocation;

  const _FeatureRow({
    required this.feature,
    required this.controller,
    required this.onColor,
    required this.onAction,
    this.showLocation = false,
  });

  @override
  Widget build(BuildContext context) {
    final location = GbSettingsTaxonomy.locationFor(feature);
    Widget trailing;
    VoidCallback? tap;

    switch (feature.kind) {
      case GbFeatureKind.toggle:
        trailing = Switch.adaptive(
          value: controller.gbBool(feature.key, fallback: feature.defaultValue == true),
          onChanged: (value) => controller.updateGbFeature(feature.key, value),
        );
        break;
      case GbFeatureKind.slider:
        final value = controller.gbDouble(
          feature.key,
          fallback: (feature.defaultValue as num?)?.toDouble() ?? feature.min,
        ).clamp(feature.min, feature.max);
        trailing = SizedBox(
          width: 136,
          child: Slider(
            min: feature.min,
            max: feature.max,
            value: value,
            onChanged: (next) => controller.updateGbFeature(feature.key, next),
          ),
        );
        break;
      case GbFeatureKind.choice:
        final current = controller.gbString(feature.key, fallback: feature.defaultValue?.toString() ?? '');
        trailing = Text(current, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700));
        tap = () => _choose(context, current);
        break;
      case GbFeatureKind.color:
        final color = controller.gbColor(feature.key);
        trailing = CircleAvatar(backgroundColor: color ?? Theme.of(context).colorScheme.surfaceContainerHighest, radius: 16, child: color == null ? const Icon(Icons.palette_outlined, size: 16) : null);
        tap = () => onColor(feature);
        break;
      case GbFeatureKind.action:
        trailing = const Icon(Icons.chevron_right_rounded);
        tap = () => onAction(feature);
        break;
    }

    final description = showLocation
        ? '${location.section} • ${location.subsection}\n${feature.description}'
        : feature.description;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description, maxLines: showLocation ? 3 : 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: tap,
      ),
    );
  }

  Future<void> _choose(BuildContext context, String current) async {
    if (feature.options.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in feature.options)
              RadioListTile<String>(
                value: option,
                groupValue: current,
                title: Text(option),
                onChanged: (value) => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (selected != null) controller.updateGbFeature(feature.key, selected);
  }
}
