import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/data/services/chaty_backend_service.dart';
import 'package:chat/data/services/chaty_call_service.dart';
import 'package:chat/data/services/message_automation_service.dart';
import 'package:chat/domain/models/user_profile.dart';
import 'package:chat/features/auth/create_new_password_screen.dart';
import 'package:chat/features/auth/welcome_screen.dart';
import 'package:chat/features/calls/chaty_call_screen.dart';
import 'package:chat/features/chats/main_navigation_shell.dart';
import 'package:chat/injection/locator.dart';
import 'package:chat/ui/core/controllers/appearance_variant_controller.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';
import 'package:chat/ui/core/gb/gb_theme_overrides.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/ui/core/widgets/click_particle_overlay.dart';
import 'package:chat/ui/core/widgets/falling_particles_overlay.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://dntnxeanubswyswahdnj.supabase.co');
const String _supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: 'sb_publishable_gFpVYJctaDkRRgttvnUl-A_TKu81hFF');

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabasePublishableKey, debug: !kReleaseMode);
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
  late final AppearanceVariantController _appearanceController;
  late final ChatyBackendService _backend;
  late final MockDataStore _dataStore;
  late final MessageAutomationService _automationService;
  late final ChatyCallService _incomingCallService;
  late final StreamSubscription<AuthState> _authUiSubscription;
  StreamSubscription<ChatyCallSession>? _incomingCallSubscription;
  bool _recoveryRouteOpen = false;
  String? _presentedIncomingCallId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeController = locator<ThemeController>();
    _preferencesController = locator<ChatyPreferencesController>();
    _appearanceController = locator<AppearanceVariantController>();
    _backend = locator<ChatyBackendService>();
    _dataStore = locator<MockDataStore>();
    _automationService = MessageAutomationService(preferencesController: _preferencesController, dataStore: _dataStore);
    _incomingCallService = ChatyCallService();
    _authUiSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(_handleAuthUiEvent);
    if (_backend.isAuthenticated) _startIncomingCallWatch();
  }

  void _startIncomingCallWatch() {
    unawaited(_incomingCallService.watchIncomingCalls());
    _incomingCallSubscription ??= _incomingCallService.incomingCalls.listen(_presentIncomingCall);
  }

  Future<void> _presentIncomingCall(ChatyCallSession call) async {
    if (!mounted || _presentedIncomingCallId == call.id || !_backend.isAuthenticated) return;
    _presentedIncomingCallId = call.id;
    final caller = _dataStore.getUser(call.callerId);
    final title = caller?.displayName ?? 'Incoming Chaty call';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = _rootNavigatorKey.currentState;
      final context = _rootNavigatorKey.currentContext;
      if (navigator == null || context == null || !mounted) {
        _presentedIncomingCallId = null;
        return;
      }
      final accept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final theme = _themeController.globalTheme;
          return AlertDialog(
            title: Text(call.isVideo ? 'Incoming video call' : 'Incoming voice call'),
            content: Text('$title is calling you.'),
            actions: [
              TextButton(
                onPressed: () async {
                  try { await _incomingCallService.declineIncoming(call); } finally { if (dialogContext.mounted) Navigator.of(dialogContext).pop(false); }
                },
                child: Text('Decline', style: TextStyle(color: theme.dangerColor)),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: Icon(call.isVideo ? Icons.videocam_rounded : Icons.call_rounded),
                label: const Text('Accept'),
              ),
            ],
          );
        },
      );
      if (accept == true && mounted) {
        await navigator.push(MaterialPageRoute(
          builder: (_) => ChatyCallScreen(
            theme: _themeController.globalTheme,
            callService: _incomingCallService,
            title: title,
            conversationId: call.conversationId,
            peerUserId: call.callerId,
            isVideo: call.isVideo,
            incomingSession: call,
          ),
        ));
      }
      _presentedIncomingCallId = null;
    });
  }

  void _handleAuthUiEvent(AuthState state) {
    if (state.session != null) _startIncomingCallWatch();
    if (state.event == AuthChangeEvent.passwordRecovery && !_recoveryRouteOpen) {
      _recoveryRouteOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = _rootNavigatorKey.currentState;
        if (navigator == null) { _recoveryRouteOpen = false; return; }
        navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => CreateNewPasswordScreen(email: state.session?.user.email ?? '')), (route) => false);
      });
      return;
    }
    if (state.event == AuthChangeEvent.signedOut) {
      _presentedIncomingCallId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rootNavigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const WelcomeScreen()), (route) => false);
      });
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _themeController.applyPlatformBrightness(WidgetsBinding.instance.platformDispatcher.platformBrightness);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_backend.isAuthenticated) return;
    final airplane = _preferencesController.home.airplaneModeSimulator || _preferencesController.gbBool('yo_want_airplanemode');
    final ghost = _preferencesController.home.ghostMode || _preferencesController.gbBool('yo_want_ghostmode');
    final alwaysOnline = _preferencesController.gbBool('always_online');
    if (airplane || ghost) { unawaited(_backend.setPresence(PresenceState.offline)); return; }
    if (state == AppLifecycleState.resumed || alwaysOnline) {
      unawaited(_backend.setPresence(PresenceState.online));
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {
      unawaited(_backend.setPresence(PresenceState.offline));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_authUiSubscription.cancel());
    unawaited(_incomingCallSubscription?.cancel());
    _incomingCallService.dispose();
    _automationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[_themeController, _preferencesController, _appearanceController, _backend]),
      builder: (context, _) {
        final currentTheme = GbThemeOverrides.resolve(_themeController.baseTheme, _preferencesController);
        _themeController.setRuntimeThemeOverride(currentTheme);
        return MaterialApp(
          navigatorKey: _rootNavigatorKey,
          title: 'Chaty',
          debugShowCheckedModeBanner: false,
          theme: currentTheme.toThemeData(),
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scaled = media.copyWith(textScaler: TextScaler.linear((media.textScaler.scale(1.0) * _appearanceController.textScale).clamp(0.8, 1.6)));
            return MediaQuery(data: scaled, child: ClickParticleOverlay(preferencesController: _preferencesController, child: FallingParticlesOverlay(preferencesController: _preferencesController, currentScope: 'Home', child: child ?? const SizedBox())));
          },
          home: _backend.isAuthenticated ? const MainNavigationShell() : const WelcomeScreen(),
        );
      },
    );
  }
}
