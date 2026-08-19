import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/features/auth/welcome_screen.dart';
import 'package:chat/features/chats/main_navigation_shell.dart';
import 'package:chat/injection/locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacityAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);

    _animCtrl.forward();

    Timer(const Duration(milliseconds: 1400), () async {
      if (!mounted) return;
      final dataStore = locator<MockDataStore>();
      if (dataStore.currentUser.id == 'usr_guest') {
        // Direct to new auth flow
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        // Logged in user, go to main navigation
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationShell(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = locator<ThemeController>();
    final theme = themeController.globalTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Center whatsapp-style enlarged rounded icon
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: theme.accentColor.withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 2,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(34),
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 124,
                          height: 124,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(34),
                              gradient: LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _opacityAnim,
                    child: Text(
                      'Chaty',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom loading & branding footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: FadeTransition(
                opacity: _opacityAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'from',
                      style: TextStyle(
                        color: theme.secondaryTextColor.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LOGY BYTE',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}