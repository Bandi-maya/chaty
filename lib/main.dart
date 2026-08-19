import 'package:flutter/material.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/ui/core/theme/theme_presets.dart';
import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';
import 'package:chat/data/services/message_automation_service.dart';
import 'package:chat/ui/core/widgets/click_particle_overlay.dart';
import 'package:chat/ui/core/widgets/falling_particles_overlay.dart';
import 'package:chat/features/auth/splash_screen.dart';
import 'package:chat/injection/locator.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupLocator();
  runApp(const ChatyApp());
}

class ChatyApp extends StatefulWidget {
  const ChatyApp({super.key});

  @override
  State<ChatyApp> createState() => _ChatyAppState();
}

class _ChatyAppState extends State<ChatyApp> with WidgetsBindingObserver {
  late final ThemeController _themeController;
  late final ChatyPreferencesController _preferencesController;
  late MessageAutomationService _automationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // setupLocator(); // Removed duplicate call
    _themeController = locator<ThemeController>();
    _preferencesController = locator<ChatyPreferencesController>();
    _automationService = MessageAutomationService(
      preferencesController: locator<ChatyPreferencesController>(),
      dataStore: locator<MockDataStore>(),
    );
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // If current theme is default monochrome, follow system light/dark change
    if (_themeController.globalTheme.id == 'monochrome_dark' ||
        _themeController.globalTheme.id == 'monochrome_light') {
      _themeController.setGlobalTheme(
        ThemePresets.getSystemDefaultTheme(brightness),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _automationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_themeController, _preferencesController]),
      builder: (context, _) {
        final currentTheme = _themeController.globalTheme;
        return MaterialApp(
          title: 'Chaty',
          debugShowCheckedModeBanner: false,
          theme: currentTheme.toThemeData(),
          builder: (context, child) {
            return ClickParticleOverlay(
              preferencesController: _preferencesController,
              child: FallingParticlesOverlay(
                preferencesController: _preferencesController,
                currentScope: 'Home',
                child: child ?? const SizedBox(),
              ),
            );
          },
home: const SplashScreen(),
        );
      },
    );
  }
}