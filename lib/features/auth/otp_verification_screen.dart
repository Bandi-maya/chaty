import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../injection/locator.dart';
import 'widgets/auth_components.dart';
import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default sample OTP as seen in mockup
    _controllers[0].text = '3';
    _controllers[1].text = '3';
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get currentOtp => _controllers.map((c) => c.text).join();

  void _handleVerify() {
    if (currentOtp.isEmpty) return;
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateNewPasswordScreen(email: widget.email),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = locator<ThemeController>().globalTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top circular back button
                  const AuthBackButton(),
              const SizedBox(height: 12),

              // Illustration
              AuthIllustration(
                type: 'otp',
                theme: theme,
                height: 190,
              ),
              const SizedBox(height: 16),

              // Title and Subtitle matching mockup
              Text(
                'Enter OTP!',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter code shared on your email.',
                style: TextStyle(
                  color: theme.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // 4 OTP Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) {
                  return SizedBox(
                    width: 68,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: theme.accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 36),

              // Verify Button
              AuthPrimaryButton(
                text: 'Verify',
                onPressed: _handleVerify,
                isLoading: _isLoading,
                theme: theme,
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'New OTP code sent to your email.',
                          style: TextStyle(color: theme.onAccentColor, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: theme.accentColor,
                      ),
                    );
                  },
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: theme.accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
