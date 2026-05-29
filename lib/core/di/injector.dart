import 'package:auto_injector/auto_injector.dart';

import '../network/dio_client.dart';
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

    // Blocs
    i.addSingleton<AuthBloc>(
      () => AuthBloc(i.get<AuthRepository>(), i.get<LocalStorageService>()),
    );
    i.add<DashboardBloc>(() => DashboardBloc(i.get<DashboardRepository>()));
  },
);

Future<void> setupDependencies() async {
  final storage = LocalStorageService();
  await storage.init();
  autoInjector.addInstance<LocalStorageService>(storage);
  autoInjector.commit();
}
