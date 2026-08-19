import 'package:flutter/material.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../injection/locator.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_components.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24.0),

              // Hero Illustration Card matching top-right screen
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthIllustration(
                        type: 'welcome',
                        theme: theme,
                        height: 240,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Chaty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 30.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'Private, customizable, and lightning-fast messaging.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.secondaryTextColor,
                          fontSize: 15.0,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons at bottom
              AuthPrimaryButton(
                text: 'Log In',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                theme: theme,
              ),
              const SizedBox(height: 14.0),

              AuthSecondaryButton(
                text: 'Register',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                theme: theme,
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}