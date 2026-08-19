import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChatyPageTransitionsBuilder extends PageTransitionsBuilder {
  final String entryStyle;
  final String exitStyle;

  const ChatyPageTransitionsBuilder({
    required this.entryStyle,
    required this.exitStyle,
  });

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) return child;

    final effectiveStyle = route.popGestureInProgress ? 'Cupertino' : entryStyle;
    Widget incoming = _transition(effectiveStyle, animation, child);

    if (exitStyle == 'None') return incoming;
    final reverse = ReverseAnimation(secondaryAnimation);
    return _transition(exitStyle, reverse, incoming, isExit: true);
  }

  Widget _transition(
    String style,
    Animation<double> animation,
    Widget child, {
    bool isExit = false,
  }) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    switch (style) {
      case 'None':
        return child;
      case 'Fade':
        return FadeTransition(opacity: curved, child: child);
      case 'Slide Left':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      case 'Slide Right':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.12, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      case 'Slide Up':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.10),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      case 'Slide Down':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.10),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      case 'Scale':
      case 'Shared Axis Z':
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      case 'Zoom':
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: child,
          ),
        );
      case 'Shared Axis X':
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      case 'Shared Axis Y':
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.07),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      case 'Flip X':
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX((1 - curved.value) * math.pi * 0.12),
            child: Opacity(opacity: curved.value, child: child),
          ),
        );
      case 'Flip Y':
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((1 - curved.value) * math.pi * 0.12),
            child: Opacity(opacity: curved.value, child: child),
          ),
        );
      case 'Rotate Soft':
        return RotationTransition(
          turns: Tween<double>(begin: -0.012, end: 0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      case 'Rise Fade':
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.035),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      case 'Drop Fade':
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.035),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      case 'Elastic Scale':
        final elastic = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(elastic),
            child: child,
          ),
        );
      case 'Cupertino':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          )),
          child: child,
        );
      case 'Material':
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
            child: child,
          ),
        );
      case 'Fade Through':
      default:
        final fade = Tween<double>(begin: 0, end: 1).animate(curved);
        final scale = Tween<double>(begin: 0.985, end: 1).animate(curved);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
    }
  }

  static PageTransitionsTheme theme({
    required String entryStyle,
    required String exitStyle,
  }) {
    final builder = ChatyPageTransitionsBuilder(
      entryStyle: entryStyle,
      exitStyle: exitStyle,
    );
    return PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: builder,
        TargetPlatform.iOS: builder,
        TargetPlatform.macOS: builder,
        TargetPlatform.windows: builder,
        TargetPlatform.linux: builder,
        TargetPlatform.fuchsia: builder,
      },
    );
  }
}
