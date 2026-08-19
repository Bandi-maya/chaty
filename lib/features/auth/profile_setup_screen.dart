import 'package:flutter/material.dart';
import '../../../ui/core/theme/theme_controller.dart';
import '../../data/repositories/mock_data_store.dart';
import '../../ui/core/widgets/app_avatar.dart';
import '../../features/chats/main_navigation_shell.dart';
import '../../injection/locator.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final ThemeController themeController;
  late final MockDataStore dataStore;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _aboutCtrl;

  @override
  void initState() {
    super.initState();
    themeController = locator<ThemeController>();
    dataStore = locator<MockDataStore>();
    final user = dataStore.currentUser;
    _nameCtrl = TextEditingController(text: user.displayName);
    _usernameCtrl = TextEditingController(text: user.username);
    _aboutCtrl = TextEditingController(text: user.about);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _aboutCtrl.dispose();
    super.dispose();
  }

  void _saveAndEnterHome() async {
    final updatedUser = dataStore.currentUser.copyWith(
      displayName: _nameCtrl.text,
      username: _usernameCtrl.text,
      about: _aboutCtrl.text,
    );
    await dataStore.updateUser(updatedUser);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeController.globalTheme;
    final user = dataStore.currentUser;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  children: [
                    AppAvatar(
                      initials: user.avatarInitials,
                      colorHex: user.avatarColorHex,
                      size: 96,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.backgroundColor, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: theme.onAccentColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: theme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  prefixIcon: Icon(Icons.person_outline_rounded, color: theme.accentColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameCtrl,
                style: TextStyle(color: theme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  prefixIcon: Icon(Icons.alternate_email_rounded, color: theme.accentColor),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _aboutCtrl,
                maxLines: 3,
                style: TextStyle(color: theme.primaryTextColor),
                decoration: InputDecoration(
                  labelText: 'About / Status',
                  labelStyle: TextStyle(color: theme.secondaryTextColor),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.info_outline_rounded, color: theme.accentColor),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  foregroundColor: theme.onAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saveAndEnterHome,
                child: Text(
                  'Enter Chaty',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.onAccentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}