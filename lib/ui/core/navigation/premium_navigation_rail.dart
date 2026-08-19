import 'package:flutter/material.dart';

import '../layout/adaptive_window_metrics.dart';
import 'premium_navigation_bar.dart';

class PremiumNavigationRail extends StatelessWidget {
  final int styleIndex;
  final int selectedIndex;
  final List<PremiumNavDestination> destinations;
  final ValueChanged<int> onSelected;
  final dynamic theme;
  final AdaptiveWindowMetrics metrics;

  const PremiumNavigationRail({
    super.key,
    required this.styleIndex,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
    required this.theme,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return switch (styleIndex.clamp(0, 19)) {
      0 => _adaptiveRail(),
      1 => _compactRail(),
      2 => _minimalRail(),
      3 => _pillRail(),
      4 => _outlinedRail(),
      5 => _floatingRail(),
      6 => _denseRail(),
      7 => _iconRail(),
      8 => _labelRail(),
      9 => _softRail(),
      10 => _classicTabs(),
      11 => _segmentedTabs(),
      12 => _underlineTabs(),
      13 => _pillTabs(),
      14 => _iconTabs(),
      15 => _compactTabs(),
      16 => _floatingTabs(),
      17 => _sidebarTabs(),
      18 => _workspaceTabs(),
      _ => _focusTabs(),
    };
  }

  Widget _adaptiveRail() => _rail(width: 76, extended: metrics.width >= 1050, indicatorRadius: 18, alignment: -.72);
  Widget _compactRail() => _rail(width: 58, iconSize: 19, indicatorRadius: 10, alignment: -.65);
  Widget _minimalRail() => _rail(width: 60, indicatorAlpha: .06, indicatorRadius: 8, showLabels: false, alignment: 0);
  Widget _pillRail() => _rail(width: 72, indicatorRadius: 30, indicatorAlpha: .16, alignment: -.5);
  Widget _outlinedRail() => _framed(_rail(width: 74, indicatorRadius: 10, indicatorAlpha: .08, alignment: -.72), outline: true, margin: 8);
  Widget _floatingRail() => _framed(_rail(width: 70, indicatorRadius: 22, alignment: 0), shadow: true, margin: 12, radius: 24);
  Widget _denseRail() => _rail(width: 54, iconSize: 18, indicatorRadius: 8, showLabels: false, alignment: -.25);
  Widget _iconRail() => _framed(_rail(width: 64, iconSize: 22, indicatorRadius: 30, showLabels: false, alignment: 0), margin: 10, radius: 18);
  Widget _labelRail() => _customVertical(labelFirst: true, width: 104, radius: 12);
  Widget _softRail() => _framed(_rail(width: 74, indicatorRadius: 20, indicatorAlpha: .10, alignment: -.6), soft: true, margin: 8, radius: 20);
  Widget _classicTabs() => _topTabs(mode: _TopTabMode.classic);
  Widget _segmentedTabs() => _topTabs(mode: _TopTabMode.segmented);
  Widget _underlineTabs() => _topTabs(mode: _TopTabMode.underline);
  Widget _pillTabs() => _topTabs(mode: _TopTabMode.pill);
  Widget _iconTabs() => _topTabs(mode: _TopTabMode.icons);
  Widget _compactTabs() => _topTabs(mode: _TopTabMode.compact);
  Widget _floatingTabs() => _topTabs(mode: _TopTabMode.floating);
  Widget _sidebarTabs() => _customVertical(labelFirst: false, width: 164, radius: 10);
  Widget _workspaceTabs() => _workspaceSidebar();
  Widget _focusTabs() => _focusSidebar();

  Widget _rail({
    required double width,
    bool extended = false,
    double iconSize = 21,
    double indicatorRadius = 16,
    double indicatorAlpha = .14,
    bool showLabels = true,
    double alignment = -.7,
  }) {
    final actuallyExtended = extended && metrics.width >= 900;
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      minWidth: width,
      minExtendedWidth: 188,
      extended: actuallyExtended,
      groupAlignment: metrics.isShort ? 0 : alignment,
      backgroundColor: theme.surfaceColor,
      indicatorColor: theme.accentColor.withValues(alpha: indicatorAlpha),
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(indicatorRadius)),
      selectedIconTheme: IconThemeData(color: theme.accentColor, size: iconSize + 1),
      unselectedIconTheme: IconThemeData(color: theme.secondaryTextColor, size: iconSize),
      selectedLabelTextStyle: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.w800),
      unselectedLabelTextStyle: TextStyle(color: theme.secondaryTextColor, fontWeight: FontWeight.w500),
      labelType: actuallyExtended || !showLabels ? NavigationRailLabelType.none : NavigationRailLabelType.selected,
      destinations: destinations
          .map((item) => NavigationRailDestination(icon: Icon(item.icon), selectedIcon: Icon(item.activeIcon), label: Text(item.label)))
          .toList(growable: false),
    );
  }

  Widget _framed(Widget child, {bool outline = false, bool shadow = false, bool soft = false, double margin = 8, double radius = 16}) {
    return Padding(
      padding: EdgeInsets.all(margin),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: soft ? theme.accentColor.withValues(alpha: .06) : theme.surfaceColor,
            borderRadius: BorderRadius.circular(radius),
            border: outline ? Border.all(color: theme.accentColor.withValues(alpha: .32)) : null,
            boxShadow: shadow
                ? [BoxShadow(color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? .28 : .10), blurRadius: 20, offset: const Offset(0, 8))]
                : const [],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _customVertical({required bool labelFirst, required double width, required double radius}) {
    return Container(
      width: width,
      color: theme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(destinations.length, (i) {
          final item = destinations[i];
          final selected = i == selectedIndex;
          final icon = Icon(selected ? item.activeIcon : item.icon, color: selected ? theme.accentColor : theme.secondaryTextColor, size: 20);
          final label = Flexible(
            child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: selected ? theme.primaryTextColor : theme.secondaryTextColor, fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Semantics(
              button: true,
              selected: selected,
              label: item.label,
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(radius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: selected ? theme.accentColor.withValues(alpha: .12) : Colors.transparent, borderRadius: BorderRadius.circular(radius)),
                  child: labelFirst
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(item.label, style: TextStyle(color: selected ? theme.accentColor : theme.secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w700)), const SizedBox(height: 3), icon])
                      : Row(children: [icon, const SizedBox(width: 10), label]),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _topTabs({required _TopTabMode mode}) {
    final floating = mode == _TopTabMode.floating;
    final compact = mode == _TopTabMode.compact;
    final iconsOnly = mode == _TopTabMode.icons;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.fromLTRB(floating ? 18 : 0, floating ? 12 : 0, floating ? 18 : 0, 0),
        height: compact ? 48 : 58,
        padding: EdgeInsets.symmetric(horizontal: floating ? 8 : 12, vertical: floating ? 5 : 0),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: floating ? BorderRadius.circular(18) : BorderRadius.zero,
          border: mode == _TopTabMode.classic ? Border(bottom: BorderSide(color: theme.cardColor)) : null,
          boxShadow: floating ? [BoxShadow(color: Colors.black.withValues(alpha: .09), blurRadius: 16, offset: const Offset(0, 6))] : const [],
        ),
        child: Row(
          children: List.generate(destinations.length, (i) {
            final item = destinations[i];
            final selected = i == selectedIndex;
            final segmented = mode == _TopTabMode.segmented;
            final pill = mode == _TopTabMode.pill;
            final underline = mode == _TopTabMode.underline;
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 170),
                    constraints: const BoxConstraints(minHeight: 44),
                    margin: EdgeInsets.symmetric(horizontal: segmented || pill ? 3 : 0),
                    decoration: BoxDecoration(
                      color: selected && (segmented || pill) ? theme.accentColor.withValues(alpha: segmented ? .10 : .14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(pill ? 22 : segmented ? 10 : 0),
                      border: underline ? Border(bottom: BorderSide(color: selected ? theme.accentColor : Colors.transparent, width: 2.5)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(selected ? item.activeIcon : item.icon, color: selected ? theme.accentColor : theme.secondaryTextColor, size: compact ? 18 : 20),
                        if (!iconsOnly && !metrics.isVeryNarrow) ...[
                          const SizedBox(width: 5),
                          Flexible(child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(color: selected ? theme.primaryTextColor : theme.secondaryTextColor, fontSize: compact ? 10 : 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _workspaceSidebar() {
    return Container(
      width: metrics.width >= 1100 ? 210 : 172,
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 14), child: Text('CHATY', style: TextStyle(color: theme.secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2))),
          ...List.generate(destinations.length, (i) {
            final selected = i == selectedIndex;
            final item = destinations[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ListTile(
                dense: true,
                minTileHeight: 48,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                selected: selected,
                selectedTileColor: theme.accentColor.withValues(alpha: .11),
                leading: Icon(selected ? item.activeIcon : item.icon, color: selected ? theme.accentColor : theme.secondaryTextColor, size: 20),
                title: Text(item.label, style: TextStyle(color: selected ? theme.primaryTextColor : theme.secondaryTextColor, fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
                onTap: () => onSelected(i),
              ),
            );
          }),
          const Spacer(),
          Divider(color: theme.cardColor),
          Padding(padding: const EdgeInsets.all(8), child: Text('Workspace navigation', style: TextStyle(color: theme.secondaryTextColor, fontSize: 9.5))),
        ],
      ),
    );
  }

  Widget _focusSidebar() {
    return Container(
      width: 66,
      color: theme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(destinations.length, (i) {
          final selected = i == selectedIndex;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: destinations[i].label,
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : .48,
                  child: Center(child: Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? theme.accentColor : theme.secondaryTextColor, size: selected ? 23 : 20)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum _TopTabMode { classic, segmented, underline, pill, icons, compact, floating }
