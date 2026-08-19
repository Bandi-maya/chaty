import 'package:flutter/material.dart';

import '../layout/adaptive_window_metrics.dart';

class PremiumNavDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const PremiumNavDestination({required this.label, required this.icon, required this.activeIcon});
}

class PremiumNavigationBar extends StatelessWidget {
  final int styleIndex;
  final int selectedIndex;
  final List<PremiumNavDestination> destinations;
  final ValueChanged<int> onSelected;
  final dynamic theme;
  final AdaptiveWindowMetrics metrics;

  const PremiumNavigationBar({
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
    final index = styleIndex.clamp(0, 19);
    return switch (index) {
      0 => _floatingPill(context),
      1 => _classicBar(context),
      2 => _compactPill(context),
      3 => _floatingCards(context),
      4 => _outlinedPill(context),
      5 => _softCapsule(context),
      6 => _iconDock(context),
      7 => _labelDock(context),
      8 => _minimalDock(context),
      9 => _raisedCenter(context),
      10 => _segmentedBar(context),
      11 => _insetBar(context),
      12 => _flatIndicatorBar(context),
      13 => _denseBar(context),
      14 => _wideCapsule(context),
      15 => _slimCapsule(context),
      16 => _cardDock(context),
      17 => _edgeDock(context),
      18 => _workspaceDock(context),
      _ => _focusDock(context),
    };
  }

  bool get _labels => metrics.showNavigationLabels && !metrics.isShort && !metrics.isVeryNarrow;
  Color get _surface => theme.surfaceColor;
  Color get _accent => theme.accentColor;
  Color get _muted => theme.secondaryTextColor;
  Color get _text => theme.primaryTextColor;

  Widget _shell(Widget child, {double horizontal = 12, double bottom = 10, bool extend = true}) {
    return SafeArea(
      minimum: EdgeInsets.only(bottom: metrics.isShort ? 0 : 2),
      child: Padding(
        padding: EdgeInsets.fromLTRB(metrics.isVeryNarrow ? 4 : horizontal, 0, metrics.isVeryNarrow ? 4 : horizontal, metrics.isShort ? 2 : bottom),
        child: child,
      ),
    );
  }

  Widget _floatingPill(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.cardColor),
            boxShadow: [_shadow(16)],
          ),
          child: _row((i) => _pillItem(i, expanded: true)),
        ),
      );

  Widget _classicBar(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: theme.cardColor))),
          child: _row((i) => _verticalItem(i, selectedMarker: false, alwaysLabel: true)),
        ),
      );

  Widget _compactPill(BuildContext context) => _shell(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(25), border: Border.all(color: theme.cardColor)),
            child: _row((i) => _iconItem(i, size: 18, selectedCircle: true)),
          ),
        ),
        horizontal: 26,
      );

  Widget _floatingCards(BuildContext context) => _shell(
        Row(
          children: List.generate(destinations.length, (i) {
            final selected = i == selectedIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _tap(
                  i,
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(minHeight: 50),
                    decoration: BoxDecoration(
                      color: selected ? _accent.withValues(alpha: .14) : _surface,
                      borderRadius: BorderRadius.circular(selected ? 18 : 14),
                      border: Border.all(color: selected ? _accent.withValues(alpha: .35) : theme.cardColor),
                      boxShadow: selected ? [_shadow(12)] : const [],
                    ),
                    child: _verticalCore(i, label: selected && _labels),
                  ),
                ),
              ),
            );
          }),
        ),
        horizontal: 8,
      );

  Widget _outlinedPill(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(28), border: Border.all(color: _accent.withValues(alpha: .45), width: 1.2)),
          child: _row((i) => _pillItem(i, expanded: false, outlineSelected: true)),
        ),
      );

  Widget _softCapsule(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(color: _accent.withValues(alpha: .07), borderRadius: BorderRadius.circular(30)),
          child: _row((i) => _pillItem(i, expanded: true, soft: true)),
        ),
        horizontal: 18,
      );

  Widget _iconDock(BuildContext context) => _shell(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(18), boxShadow: [_shadow(18)]),
            child: _row((i) => _iconItem(i, size: 21, selectedSquare: true)),
          ),
        ),
        horizontal: 34,
      );

  Widget _labelDock(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.cardColor)),
          child: _row((i) => _labelForwardItem(i)),
        ),
        horizontal: 8,
        bottom: 6,
      );

  Widget _minimalDock(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _row((i) => _verticalItem(i, selectedMarker: true, alwaysLabel: false)),
        ),
      );

  Widget _raisedCenter(BuildContext context) => _shell(
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.fromLTRB(6, 7, 6, 5),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(22), boxShadow: [_shadow(16)]),
              child: _row((i) => i == 2 ? const SizedBox(height: 48) : _verticalItem(i, selectedMarker: false, alwaysLabel: false)),
            ),
            Positioned(top: -4, child: _tap(2, _centerOrb(2))),
          ],
        ),
        horizontal: 18,
      );

  Widget _segmentedBar(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16)),
          child: _row((i) {
            final selected = i == selectedIndex;
            return _tap(
              i,
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 46),
                decoration: BoxDecoration(color: selected ? _surface : Colors.transparent, borderRadius: BorderRadius.circular(13)),
                child: _horizontalCore(i, showLabel: selected && _labels),
              ),
            );
          }),
        ),
        horizontal: 8,
        bottom: 7,
      );

  Widget _insetBar(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.cardColor)),
          child: _row((i) => _verticalItem(i, selectedMarker: true, alwaysLabel: _labels)),
        ),
        horizontal: 16,
        bottom: 12,
      );

  Widget _flatIndicatorBar(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          color: _surface,
          child: _row((i) {
            final selected = i == selectedIndex;
            return _tap(
              i,
              Container(
                constraints: const BoxConstraints(minHeight: 54),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: selected ? _accent : Colors.transparent, width: 2.5))),
                child: _verticalCore(i, label: _labels),
              ),
            );
          }),
        ),
      );

  Widget _denseBar(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10)),
          child: _row((i) => _iconItem(i, size: 18, selectedUnderline: true)),
        ),
        horizontal: 4,
        bottom: 4,
      );

  Widget _wideCapsule(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(34), boxShadow: [_shadow(14)]),
          child: _row((i) => _pillItem(i, expanded: true, bold: true)),
        ),
        horizontal: 8,
      );

  Widget _slimCapsule(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(27), border: Border.all(color: theme.cardColor)),
          child: _row((i) => _iconItem(i, size: 18, selectedCircle: true)),
        ),
        horizontal: 24,
        bottom: 12,
      );

  Widget _cardDock(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18)),
          child: _row((i) {
            final selected = i == selectedIndex;
            return _tap(
              i,
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
                decoration: BoxDecoration(color: selected ? _surface : Colors.transparent, borderRadius: BorderRadius.circular(13)),
                child: _verticalCore(i, label: selected && _labels),
              ),
            );
          }),
        ),
        horizontal: 14,
      );

  Widget _edgeDock(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(color: _surface, border: Border(top: BorderSide(color: theme.cardColor))),
          child: _row((i) {
            final selected = i == selectedIndex;
            return _tap(
              i,
              Container(
                constraints: const BoxConstraints(minHeight: 56),
                decoration: BoxDecoration(color: selected ? _accent.withValues(alpha: .08) : Colors.transparent),
                child: _verticalCore(i, label: _labels),
              ),
            );
          }),
        ),
      );

  Widget _workspaceDock(BuildContext context) => _shell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: theme.cardColor), boxShadow: [_shadow(10)]),
          child: _row((i) {
            final selected = i == selectedIndex;
            return _tap(
              i,
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: selected ? _accent.withValues(alpha: .12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: selected ? Border.all(color: _accent.withValues(alpha: .25)) : null,
                ),
                child: _horizontalCore(i, showLabel: _labels),
              ),
            );
          }),
        ),
        horizontal: 10,
        bottom: 8,
      );

  Widget _focusDock(BuildContext context) => _shell(
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12)),
            child: _row((i) {
              final selected = i == selectedIndex;
              return _tap(
                i,
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: selected ? 1 : .55,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: selected ? _horizontalCore(i, showLabel: _labels) : _verticalCore(i, label: false),
                  ),
                ),
              );
            }),
          ),
        ),
        horizontal: 18,
        bottom: 5,
      );

  Widget _row(Widget Function(int) builder) => Row(
        children: List.generate(destinations.length, (i) => Expanded(child: builder(i))),
      );

  Widget _pillItem(int i, {required bool expanded, bool outlineSelected = false, bool soft = false, bool bold = false}) {
    final selected = i == selectedIndex;
    return _tap(
      i,
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 46),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: soft ? .10 : .14) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: outlineSelected && selected ? Border.all(color: _accent.withValues(alpha: .45)) : null,
        ),
        child: _horizontalCore(i, showLabel: selected && _labels && expanded, bold: bold),
      ),
    );
  }

  Widget _iconItem(int i, {required double size, bool selectedCircle = false, bool selectedSquare = false, bool selectedUnderline = false}) {
    final selected = i == selectedIndex;
    return _tap(
      i,
      AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected && (selectedCircle || selectedSquare) ? _accent.withValues(alpha: .14) : Colors.transparent,
          shape: selectedCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: selectedCircle ? null : BorderRadius.circular(selectedSquare ? 10 : 0),
          border: selectedUnderline ? Border(bottom: BorderSide(color: selected ? _accent : Colors.transparent, width: 2)) : null,
        ),
        child: Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? _accent : _muted, size: size),
      ),
    );
  }

  Widget _labelForwardItem(int i) {
    final selected = i == selectedIndex;
    return _tap(
      i,
      Container(
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(destinations[i].label, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(color: selected ? _accent : _muted, fontSize: 10.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
            const SizedBox(height: 3),
            AnimatedContainer(duration: const Duration(milliseconds: 160), width: selected ? 18 : 3, height: 3, decoration: BoxDecoration(color: selected ? _accent : Colors.transparent, borderRadius: BorderRadius.circular(3))),
          ],
        ),
      ),
    );
  }

  Widget _verticalItem(int i, {required bool selectedMarker, required bool alwaysLabel}) {
    final selected = i == selectedIndex;
    return _tap(
      i,
      Container(
        constraints: const BoxConstraints(minHeight: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedMarker)
              AnimatedContainer(duration: const Duration(milliseconds: 160), width: selected ? 18 : 0, height: 2, margin: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
            Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? _accent : _muted, size: 20),
            if ((alwaysLabel || _labels) && !metrics.isVeryNarrow) ...[
              const SizedBox(height: 2),
              Text(destinations[i].label, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(color: selected ? _accent : _muted, fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _verticalCore(int i, {required bool label}) {
    final selected = i == selectedIndex;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? _accent : _muted, size: 20),
        if (label) ...[
          const SizedBox(height: 2),
          Text(destinations[i].label, maxLines: 1, overflow: TextOverflow.fade, style: TextStyle(color: selected ? _accent : _muted, fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _horizontalCore(int i, {required bool showLabel, bool bold = false}) {
    final selected = i == selectedIndex;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? _accent : _muted, size: 20),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Flexible(child: Text(destinations[i].label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: TextStyle(color: selected ? _text : _muted, fontSize: 10.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w700))),
        ],
      ],
    );
  }

  Widget _centerOrb(int i) {
    final selected = i == selectedIndex;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: selected ? _accent : _surface, shape: BoxShape.circle, border: Border.all(color: selected ? _accent : theme.cardColor, width: 2), boxShadow: [_shadow(14)]),
      child: Icon(selected ? destinations[i].activeIcon : destinations[i].icon, color: selected ? theme.onAccentColor : _muted, size: 23),
    );
  }

  Widget _tap(int i, Widget child) => Semantics(
        button: true,
        selected: i == selectedIndex,
        label: destinations[i].label,
        child: InkWell(onTap: () => onSelected(i), borderRadius: BorderRadius.circular(24), child: child),
      );

  BoxShadow _shadow(double blur) => BoxShadow(
        color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? .28 : .09),
        blurRadius: blur,
        offset: const Offset(0, 6),
      );
}
