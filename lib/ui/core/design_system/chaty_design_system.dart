import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized Design System Tokens for Chaty
/// Establishes mathematical rhythm, restrained motion, hierarchy, and accessible touch targets.

class ChatySpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double base = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;
  static const double jumbo = 64.0;
}

class ChatyRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  static const BorderRadius roundedXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(full));
}

class ChatyTouchTargets {
  static const double minTouchTarget = 44.0;
  static const double preferredTouchTarget = 48.0;
}

class ChatyIconSize {
  static const double xs = 14.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 28.0;
}

class ChatyMotion {
  // Motion Durations
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  // Easing Curves
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standardEasing = Curves.easeInOutCubic;
  static const Curve springDecel = Curves.easeOutQuad;
  static const Curve subtleSpring = Curves.easeOutBack;

  // Haptic feedback helpers
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  static void selectionFeedback() {
    HapticFeedback.selectionClick();
  }

  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }
}

/// Standardized Chaty Button Components with tactile micro-interactions
class ChatyPrimaryButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? width;

  const ChatyPrimaryButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 46.0,
    this.width,
  });

  @override
  State<ChatyPrimaryButton> createState() => _ChatyPrimaryButtonState();
}

class _ChatyPrimaryButtonState extends State<ChatyPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final bg = widget.backgroundColor ?? theme.colorScheme.primary;
    final fg = widget.foregroundColor ?? Colors.white;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: ChatyMotion.instant,
      curve: ChatyMotion.enter,
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: ElevatedButton(
          onPressed: isEnabled
              ? () {
                  ChatyMotion.selectionFeedback();
                  widget.onPressed?.call();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            disabledBackgroundColor: bg.withValues(alpha: 0.4),
            disabledForegroundColor: fg.withValues(alpha: 0.6),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: ChatySpacing.xl),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ChatyRadius.md),
            ),
          ),
          onFocusChange: (focus) {},
          child: Listener(
            onPointerDown: (_) {
              if (isEnabled) setState(() => _isPressed = true);
            },
            onPointerUp: (_) {
              if (_isPressed) setState(() => _isPressed = false);
            },
            onPointerCancel: (_) {
              if (_isPressed) setState(() => _isPressed = false);
            },
            child: AnimatedSwitcher(
              duration: ChatyMotion.fast,
              child: widget.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: ChatyIconSize.md, color: fg),
                          const SizedBox(width: ChatySpacing.md),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatyIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const ChatyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = ChatyTouchTargets.minTouchTarget,
    this.iconSize = ChatyIconSize.md,
  });

  @override
  State<ChatyIconButton> createState() => _ChatyIconButtonState();
}

class _ChatyIconButtonState extends State<ChatyIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.color ?? theme.iconTheme.color ?? theme.colorScheme.onSurface;

    Widget button = InkWell(
      onTap: widget.onPressed != null
          ? () {
              ChatyMotion.selectionFeedback();
              widget.onPressed!();
            }
          : null,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      borderRadius: BorderRadius.circular(ChatyRadius.full),
      child: AnimatedContainer(
        duration: ChatyMotion.fast,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: ChatyMotion.instant,
          curve: ChatyMotion.enter,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.onPressed != null ? iconColor : iconColor.withValues(alpha: 0.35),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
