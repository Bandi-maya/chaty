import 'package:flutter/material.dart';

/// Global UX rules shared across Chaty surfaces.
///
/// These values intentionally centralize interaction and layout constraints so
/// individual visual variants cannot shrink critical controls below accessible
/// sizes or expand content indefinitely on tablets/desktop windows.
class ChatyUx {
  const ChatyUx._();

  static const double minTouchTarget = 48;
  static const double compactHorizontalPadding = 12;
  static const double regularHorizontalPadding = 16;
  static const double largeHorizontalPadding = 24;
  static const double readableContentWidth = 760;
  static const double wideContentWidth = 1120;

  static double horizontalPaddingFor(double width) {
    if (width < 360) return compactHorizontalPadding;
    if (width < 840) return regularHorizontalPadding;
    return largeHorizontalPadding;
  }

  static bool reducedMotion(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    return media?.disableAnimations ?? false;
  }

  static Duration motionDuration(
    BuildContext context, {
    Duration standard = const Duration(milliseconds: 200),
  }) {
    return reducedMotion(context) ? Duration.zero : standard;
  }
}

class ChatyResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ChatyResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = ChatyUx.readableContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: ChatyUx.horizontalPaddingFor(width)),
          child: child,
        ),
      ),
    );
  }
}

enum ChatyStateKind { loading, empty, error }

/// Consistent loading/empty/error presentation with screen-reader semantics and
/// an optional recovery action. This is deliberately content-agnostic so each
/// feature can keep domain-specific copy without inventing another state UI.
class ChatyStateView extends StatelessWidget {
  final ChatyStateKind kind;
  final String title;
  final String? message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ChatyStateView({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = kind == ChatyStateKind.loading;
    final isError = kind == ChatyStateKind.error;
    final stateIcon = icon ?? (isError ? Icons.error_outline_rounded : Icons.inbox_outlined);

    return Semantics(
      container: true,
      liveRegion: true,
      label: [title, if (message != null) message!].join('. '),
      child: Center(
        child: ChatyResponsiveContent(
          maxWidth: 520,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 3, color: theme.colorScheme.primary),
                  )
                else
                  Icon(
                    stateIcon,
                    size: 48,
                    color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Gives arbitrary visual content an accessible minimum hit region without
/// forcing the visual itself to grow.
class ChatyTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool selected;

  const ChatyTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: ChatyUx.minTouchTarget,
          minHeight: ChatyUx.minTouchTarget,
        ),
        child: onTap == null
            ? child
            : InkWell(
                onTap: onTap,
                canRequestFocus: true,
                child: Center(child: child),
              ),
      ),
    );
  }
}
