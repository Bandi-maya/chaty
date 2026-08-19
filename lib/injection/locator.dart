import 'package:get_it/get_it.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/data/services/chaty_backend_service.dart';
import 'package:chat/data/services/gb_semantic_sync_service.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';
import 'package:chat/ui/core/controllers/appearance_variant_controller.dart';
import 'package:chat/data/services/chaty_notification_service.dart';
import 'package:chat/data/services/message_automation_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  if (locator.isRegistered<ThemeController>()) return;

  locator.registerLazySingleton<ThemeController>(() => ThemeController());
  locator.registerLazySingleton<ChatyBackendService>(() => ChatyBackendService());
  locator.registerLazySingleton<MockDataStore>(() => MockDataStore());
  locator.registerLazySingleton<ChatyPreferencesController>(() => ChatyPreferencesController());
  locator.registerLazySingleton<AppearanceVariantController>(() => AppearanceVariantController());
  locator.registerLazySingleton<ChatyNotificationService>(() => ChatyNotificationService());
  locator.registerLazySingleton<GbSemanticSyncService>(
    () => GbSemanticSyncService(
      preferences: locator<ChatyPreferencesController>(),
      backend: locator<ChatyBackendService>(),
    ),
  );

  // Instantiate the synchronizer eagerly so native Settings and legacy GB keys
  // remain coherent before any screen starts reading either representation.
  locator<GbSemanticSyncService>();

  locator.registerFactory<MessageAutomationService>(
    () => MessageAutomationService(
      preferencesController: locator<ChatyPreferencesController>(),
      dataStore: locator<MockDataStore>(),
    ),
  );
}
