import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/chaty_backend_service.dart';
import '../../injection/locator.dart';
import '../../ui/core/persistence/preferences_storage.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../chats/main_navigation_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_components.dart';

class LoginScreen extends StatefulWidget {
  final bool autoPromptPermissions;

  const LoginScreen({
    super.key,
    this.autoPromptPermissions = true,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _resolveLoginIdentifier(String rawIdentifier, String password) async {
    final value = rawIdentifier.trim();
    if (value.contains('@')) return value.toLowerCase();

    final resolved = await Supabase.instance.client.rpc(
      'resolve_login_email',
      params: <String, dynamic>{
        'p_identifier': value,
        'p_password': password,
      },
    );
    final email = resolved?.toString().trim() ?? '';
    if (email.isEmpty) {
      throw Exception('Invalid username/email or password.');
    }
    return email.toLowerCase();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final password = _passwordController.text;
      final resolvedEmail = await _resolveLoginIdentifier(
        _identifierController.text,
        password,
      );
      final backend = locator<ChatyBackendService>();
      final user = await backend.login(
        identifier: resolvedEmail,
        password: password,
      );
      await LocalPreferencesStorage.setStoredUserId(user.id);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final value = error.toString().replaceFirst('Exception: ', '');
    if (value.contains('Invalid login credentials') ||
        value.contains('invalid_credentials') ||
        value.contains('Invalid username/email or password')) {
      return 'Incorrect username/email or password.';
    }
    if (value.contains('Email not confirmed')) {
      return 'Confirm your email first, then sign in.';
    }
    return value;
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AuthBackButton(),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: theme.primaryTextColor,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your username or registered email.',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 38),
                    AuthTextField(
                      label: 'Username or email',
                      hintText: 'username or name@example.com',
                      controller: _identifierController,
                      theme: theme,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final identifier = value?.trim() ?? '';
                        if (identifier.isEmpty) {
                          return 'Enter your username or email';
                        }
                        if (identifier.contains('@')) {
                          if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(identifier)) {
                            return 'Enter a valid email address';
                          }
                        } else {
                          final normalized = identifier.replaceFirst('@', '');
                          if (normalized.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (!RegExp(r'^[A-Za-z0-9._]+$').hasMatch(normalized)) {
                            return 'Use letters, numbers, dots or underscores';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    AuthTextField(
                      label: 'Password',
                      hintText: 'Enter your password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      theme: theme,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: theme.secondaryTextColor.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter your password';
                        if (value.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.dangerColor.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dangerColor.withValues(alpha: .25)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: theme.dangerColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    AuthPrimaryButton(
                      text: 'Log In',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      theme: theme,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: theme.secondaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthOrDivider(theme: theme),
                    const SizedBox(height: 24),
                    AuthSocialRow(theme: theme),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: theme.secondaryTextColor, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: theme.accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
