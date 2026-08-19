import 'package:flutter/material.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../injection/locator.dart';
import 'widgets/auth_components.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: _emailController.text.trim(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top circular back button
                    const AuthBackButton(),
                const SizedBox(height: 12),

                // Top Illustration
                AuthIllustration(
                  type: 'forgot_password',
                  theme: theme,
                  height: 190,
                ),
                const SizedBox(height: 16),

                // Title and Subtitle matching design
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Don't worry, it happens! Please enter registered email.",
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Email field
                AuthTextField(
                  label: 'Email',
                  hintText: 'Enter email',
                  controller: _emailController,
                  theme: theme,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!val.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Send Code Button
                AuthPrimaryButton(
                  text: 'Send Code',
                  onPressed: _handleSendCode,
                  isLoading: _isLoading,
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);
  }
}
