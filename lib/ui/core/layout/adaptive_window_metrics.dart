import 'package:flutter/widgets.dart';

enum ChatyWindowClass { compact, medium, expanded, large }

class AdaptiveWindowMetrics {
  final double width;
  final double height;
  final ChatyWindowClass windowClass;
  final bool isShort;
  final bool isVeryNarrow;
  final bool useNavigationRail;
  final bool showNavigationLabels;
  final double horizontalPadding;
  final double contentMaxWidth;

  const AdaptiveWindowMetrics._({
    required this.width,
    required this.height,
    required this.windowClass,
    required this.isShort,
    required this.isVeryNarrow,
    required this.useNavigationRail,
    required this.showNavigationLabels,
    required this.horizontalPadding,
    required this.contentMaxWidth,
  });

  factory AdaptiveWindowMetrics.fromSize(Size size) {
    final width = size.width;
    final height = size.height;
    final windowClass = width < 360
        ? ChatyWindowClass.compact
        : width < 600
            ? ChatyWindowClass.medium
            : width < 840
                ? ChatyWindowClass.expanded
                : ChatyWindowClass.large;

    return AdaptiveWindowMetrics._(
      width: width,
      height: height,
      windowClass: windowClass,
      isShort: height < 520,
      isVeryNarrow: width < 330,
      useNavigationRail: width >= 600,
      showNavigationLabels: width >= 360,
      horizontalPadding: width < 330
          ? 8
          : width < 600
              ? 12
              : width < 840
                  ? 16
                  : 20,
      contentMaxWidth: width < 840 ? width : 760,
    );
  }

  factory AdaptiveWindowMetrics.of(BuildContext context) => AdaptiveWindowMetrics.fromSize(MediaQuery.sizeOf(context));

  bool get isCompact => windowClass == ChatyWindowClass.compact;
  bool get isExpanded => windowClass == ChatyWindowClass.expanded || windowClass == ChatyWindowClass.large;
}

class AdaptiveConstrainedContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;

  const AdaptiveConstrainedContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = AdaptiveWindowMetrics.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? metrics.contentMaxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          child: child,
        ),
      ),
    );
  }
}
