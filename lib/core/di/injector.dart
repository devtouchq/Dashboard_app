import 'package:auto_injector/auto_injector.dart';

import '../../data/repositories/chat_repo.dart';
import '../../data/repositories/device_token_repo.dart';
import '../../presentation/blocs/chat/chat_bloc.dart';
import '../network/dio_client.dart';
import '../services/speech_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/dashboard/dashboard_bloc.dart';
import 'local_storage_service.dart';

final autoInjector = AutoInjector(
  on: (i) {
    // Dio depends on storage
    i.addSingleton<DioClient>(() => DioClient(i.get<LocalStorageService>()));

    // Repositories
    i.addSingleton<AuthRepository>(() => AuthRepository(i.get<DioClient>()));
    i.addSingleton<DashboardRepository>(() => DashboardRepository(
          i.get<DioClient>(),
          i.get<LocalStorageService>(),
        ));

    // AI chat
    i.addSingleton<ChatRepository>(
      () => ChatRepository(
        i.get<DioClient>(),
        i.get<LocalStorageService>(),
      ),
    );
    // Voice input for the AI chat — one instance so the plugin is only
    // initialised once per app run.
    i.addSingleton<SpeechService>(() => SpeechService());

    i.addSingleton<DeviceTokenRepository>(
      // ← ADD THIS
      () => DeviceTokenRepository(i.get<DioClient>()), // ← ADD THIS
    );
    // Blocs
    i.addSingleton<AuthBloc>(
      () => AuthBloc(
        i.get<AuthRepository>(),
        i.get<LocalStorageService>(),
        i.get<DeviceTokenRepository>(),
      ),
    );

    i.add<DashboardBloc>(() => DashboardBloc(i.get<DashboardRepository>()));
// NOT singleton — a fresh bloc per chat session so the conversation
// resets when the user reopens the chat.
    i.add<ChatBloc>(() => ChatBloc(i.get<ChatRepository>()));
  },
);

Future<void> setupDependencies() async {
  final storage = LocalStorageService();
  await storage.init();
  autoInjector.addInstance<LocalStorageService>(storage);
  autoInjector.commit();
}
