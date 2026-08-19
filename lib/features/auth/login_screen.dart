import 'package:flutter/material.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_backend_service.dart';
import '../../ui/core/persistence/preferences_storage.dart';
import '../chats/main_navigation_shell.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'widgets/auth_components.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../injection/locator.dart';

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
  void initState() {
    super.initState();
    if (widget.autoPromptPermissions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestNativePermissions();
      });
    }
  }

  Future<void> _requestNativePermissions() async {
    try {
      await [
        Permission.contacts,
        Permission.notification,
        Permission.camera,
        Permission.microphone,
        Permission.photos,
        Permission.storage,
      ].request();
    } catch (_) {}
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backend = locator<ChatyBackendService>();
      final user = await backend.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // Synchronize session into dataStore and local persistent preferences
      await LocalPreferencesStorage.setStoredUserId(user.id);
      locator<MockDataStore>().switchDemoAccount(user);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
                const SizedBox(height: 28),

                // Welcome Back! Heading matching mockup
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Login to continue using the app.',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 36),

                // Email field
                AuthTextField(
                  label: 'Email',
                  hintText: 'Enter email',
                  controller: _identifierController,
                  theme: theme,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your email or username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password field
                AuthTextField(
                  label: 'Password',
                  hintText: 'Enter password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  theme: theme,
                  textInputAction: TextInputAction.done,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: theme.secondaryTextColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.dangerColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Log In Button
                AuthPrimaryButton(
                  text: 'Log In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  theme: theme,
                ),
                const SizedBox(height: 14),

                // Forgot Password? link aligned below button
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Or Divider
                AuthOrDivider(theme: theme),
                const SizedBox(height: 24),

                // Social Row (Facebook, Google, Apple)
                AuthSocialRow(theme: theme),
                const SizedBox(height: 32),

                // Didn't have account? Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't have account? ",
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 13.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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