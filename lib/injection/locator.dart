import 'package:get_it/get_it.dart';
import 'package:chat/ui/core/theme/theme_controller.dart';
import 'package:chat/data/repositories/mock_data_store.dart';
import 'package:chat/data/services/chaty_backend_service.dart';
import 'package:chat/ui/core/controllers/chaty_preferences_controller.dart';
import 'package:chat/data/services/chaty_notification_service.dart';
import 'package:chat/data/services/message_automation_service.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  if (locator.isRegistered<ThemeController>()) return;

  // Register theme controller
  locator.registerLazySingleton<ThemeController>(
    () => ThemeController(),
  );

  // Register core services as singletons
  locator.registerLazySingleton<ChatyBackendService>(
    () => ChatyBackendService(),
  );

  locator.registerLazySingleton<MockDataStore>(
    () => MockDataStore(),
  );

  locator.registerLazySingleton<ChatyPreferencesController>(
    () => ChatyPreferencesController(),
  );

  locator.registerLazySingleton<ChatyNotificationService>(
    () => ChatyNotificationService(),
  );

  // Register services with dependencies as factories
  locator.registerFactory<MessageAutomationService>(
    () => MessageAutomationService(
      preferencesController: locator<ChatyPreferencesController>(),
      dataStore: locator<MockDataStore>(),
    ),
  );
}