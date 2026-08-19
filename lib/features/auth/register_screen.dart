import 'package:flutter/material.dart';
import '../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../data/services/chaty_backend_service.dart';
import '../../ui/core/persistence/preferences_storage.dart';
import '../chats/main_navigation_shell.dart';
import 'widgets/auth_components.dart';
import '../../injection/locator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backend = locator<ChatyBackendService>();
      final user = await backend.registerUser(
        displayName: _usernameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        email: _emailController.text.trim(),
      );

      // Save persistent preference and activate session in mock data store
      await LocalPreferencesStorage.setStoredUserId(user.id);
      locator<MockDataStore>().switchDemoAccount(user);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
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

                // Everything You Need! Heading matching mockup
                Text(
                  'Everything You Need!',
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create account and start exploring.',
                  style: TextStyle(
                    color: theme.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

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
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // User Name field
                AuthTextField(
                  label: 'User Name',
                  hintText: 'Enter User Name',
                  controller: _usernameController,
                  theme: theme,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (val.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

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

                // Register Button
                AuthPrimaryButton(
                  text: 'Register',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  theme: theme,
                ),
                const SizedBox(height: 20),

                // Or Divider
                AuthOrDivider(theme: theme),
                const SizedBox(height: 20),

                // Social Row
                AuthSocialRow(theme: theme),
                const SizedBox(height: 28),

                // Already have an account? Log In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: theme.secondaryTextColor,
                        fontSize: 13.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Log In',
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