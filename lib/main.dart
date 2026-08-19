import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/data/services/chaty_backend_service.dart';
import 'package:chat/data/services/message_automation_service.dart';
import 'package:chat/domain/models/user_profile.dart';
import 'package:chat/features/auth/splash_screen.dart';
import 'package:chat/injection/locator.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/ui/core/theme/theme_presets.dart';
import 'package:chat/ui/core/widgets/click_particle_overlay.dart';
import 'package:chat/ui/core/widgets/falling_particles_overlay.dart';

const String _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dntnxeanubswyswahdnj.supabase.co',
);
const String _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_gFpVYJctaDkRRgttvnUl-A_TKu81hFF',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabasePublishableKey,
    debug: !kReleaseMode,
  );

  setupLocator();
  await locator<ChatyBackendService>().initialize();
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
  late final ChatyBackendService _backend;
  late MessageAutomationService _automationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeController = locator<ThemeController>();
    _preferencesController = locator<ChatyPreferencesController>();
    _backend = locator<ChatyBackendService>();
    _automationService = MessageAutomationService(
      preferencesController: _preferencesController,
      dataStore: locator<MockDataStore>(),
    );
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (_themeController.globalTheme.id == 'monochrome_dark' ||
        _themeController.globalTheme.id == 'monochrome_light') {
      _themeController.setGlobalTheme(ThemePresets.getSystemDefaultTheme(brightness));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_backend.isAuthenticated) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_backend.setPresence(PresenceState.online));
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(_backend.setPresence(PresenceState.offline));
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
      listenable: Listenable.merge(<Listenable>[_themeController, _preferencesController]),
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
