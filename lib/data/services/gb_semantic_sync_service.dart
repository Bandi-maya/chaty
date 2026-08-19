import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/user_profile.dart';
import '../../ui/core/controllers/chaty_preferences_controller.dart';
import 'chaty_backend_service.dart';

/// Keeps legacy GB keys and Chaty's typed preferences consistent in both
/// directions and applies cross-cutting runtime side effects that are not tied
/// to one widget (for example presence policy).
class GbSemanticSyncService {
  GbSemanticSyncService({
    required ChatyPreferencesController preferences,
    required ChatyBackendService backend,
  })  : _preferences = preferences,
        _backend = backend {
    _preferences.addListener(_scheduleSync);
    _scheduleSync();
  }

  final ChatyPreferencesController _preferences;
  final ChatyBackendService _backend;
  Timer? _debounce;
  bool _syncing = false;
  bool _disposed = false;

  static const Set<String> semanticAliasKeys = <String>{
    'yoHideSeen',
    'anti_vw_once',
    'yoDisableFwd',
    'yoCallsPrivacy',
    'Saleh_HidePrivacy',
    'Saleh_HideCUpdates',
    'abu_saleh_channels',
    'yoHideStatViewV2',
    'yoAntiRevokeStatus',
    'AntiRevokeStatusNotif',
    'disappearing_message_key',
    'key_chat_editview',
    'yoAntiRevoke',
    'AntiRevokeMsgNotif',
    'yoBlueOnReply',
    'home_stories_key',
    'home_stories_style',
    'enable_grp_separationV2',
    'my_name',
    'yo_want_ghostmode',
    'yo_want_airplanemode',
    'yo_want_toolbar_cam',
    'yo_multi_account_menu',
    'ui_home_styleV3',
    'bubble_style',
    'tick_style',
    'abu_saleh_quickcontact',
    'inconvo_trans_option',
    'trans_def_to',
    'key_pager_animation',
    'tap_effect_enabled',
    'tap_emoji',
    'fall_effect_enabled',
    'fall_emoji',
    'Pop_Heds',
    'abu_saleh_toast_online',
    'abu_saleh_toast_status',
    'abu_saleh_toast_typing',
  };

  void _scheduleSync() {
    if (_disposed || _syncing) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () => unawaited(_sync()));
  }

  Future<void> _sync() async {
    if (_disposed || _syncing) return;
    _syncing = true;
    try {
      final privacy = _preferences.privacy;
      final home = _preferences.home;
      final conversation = _preferences.conversation;
      final effects = _preferences.effects;
      final notification = _preferences.notification;

      final desired = <String, Object?>{
        'yoHideSeen': !privacy.readReceipts,
        'anti_vw_once': privacy.antiViewOnce,
        'yoDisableFwd': privacy.disableForwardedLabel,
        'yoCallsPrivacy': privacy.whoCanCallMe,
        'Saleh_HidePrivacy': privacy.hidePrivacyOption,
        'Saleh_HideCUpdates': privacy.hideUpdateOption,
        'abu_saleh_channels': privacy.disableChannels,
        'yoHideStatViewV2': privacy.hideViewStatus,
        'yoAntiRevokeStatus': privacy.antiDeleteStatus,
        'AntiRevokeStatusNotif': privacy.statusRevocationAlert,
        'disappearing_message_key': privacy.antiDisappearingMessages,
        'key_chat_editview': privacy.showEditedMessage,
        'yoAntiRevoke': privacy.antiDeleteMessages,
        'AntiRevokeMsgNotif': privacy.messageRevokeAlert,
        'yoBlueOnReply': privacy.showBlueTicksAfterReply,
        'home_stories_key': home.enableStoriesStrip,
        'home_stories_style': home.storiesStyle,
        'enable_grp_separationV2': home.separateChatsAndGroups,
        'my_name': home.myNameOverride,
        'yo_want_ghostmode': home.ghostMode,
        'yo_want_airplanemode': home.airplaneModeSimulator,
        'yo_want_toolbar_cam': home.showCameraIcon,
        'yo_multi_account_menu': home.showAddAccount,
        'ui_home_styleV3': home.homeStyle,
        'bubble_style': conversation.bubbleShape,
        'tick_style': conversation.tickStyle,
        'abu_saleh_quickcontact': conversation.enableQuickContactSidebar
            ? (conversation.sidebarPosition == 'Left' ? 'Left' : 'Right')
            : 'Off',
        'inconvo_trans_option': conversation.enableTranslation ? 'Inline' : 'Off',
        'trans_def_to': conversation.targetLanguage,
        'key_pager_animation': effects.pageTransitionStyle,
        'tap_effect_enabled': effects.enableClickParticles,
        'tap_emoji': effects.clickParticleSymbol,
        'fall_effect_enabled': effects.enableFallingParticles,
        'fall_emoji': effects.fallingParticleObject,
        'Pop_Heds': notification.enableGlobalNotifications,
        'abu_saleh_toast_online': notification.notifyContactOnline,
        'abu_saleh_toast_status': notification.notifyStatusViewed,
        'abu_saleh_toast_typing': notification.notifyTypingStarted,
      };

      final changed = <String, Object?>{};
      for (final entry in desired.entries) {
        if (_preferences.gbFeatures[entry.key] != entry.value) {
          changed[entry.key] = entry.value;
        }
      }
      if (changed.isNotEmpty) {
        _preferences.updateGbFeatures(changed, logTitle: 'Synchronize settings aliases');
      }

      final auth = Supabase.instance.client.auth.currentUser;
      if (auth != null) {
        final shouldBeOffline = home.ghostMode || home.airplaneModeSimulator;
        final alwaysOnline = _preferences.gbBool('always_online');
        await _backend.setPresence(
          shouldBeOffline
              ? PresenceState.offline
              : alwaysOnline
                  ? PresenceState.online
                  : PresenceState.online,
        );
      }
    } catch (_) {
      // Persistence already retains the desired state. Runtime synchronization
      // retries on the next preference mutation/session lifecycle event.
    } finally {
      _syncing = false;
    }
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _preferences.removeListener(_scheduleSync);
  }
}
