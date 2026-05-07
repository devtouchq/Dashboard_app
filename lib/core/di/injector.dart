import 'package:auto_injector/auto_injector.dart';

import '../network/dio_client.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/emr_repository.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/store_repository.dart';

final autoInjector = AutoInjector();

Future<void> setupDependencies() async {
  autoInjector
    // Network
    ..addSingleton<DioClient>(() => DioClient('https://api.ayurliv.example'))
    // Repositories
    ..addSingleton<DashboardRepository>(
      () => DashboardRepository(autoInjector.get<DioClient>()),
    )
    ..addSingleton<EmrRepository>(
      () => EmrRepository(autoInjector.get<DioClient>()),
    )
    ..addSingleton<AccountsRepository>(
      () => AccountsRepository(autoInjector.get<DioClient>()),
    )
    ..addSingleton<StoreRepository>(
      () => StoreRepository(autoInjector.get<DioClient>()),
    );

  // Commit immediately after adding all dependencies
  autoInjector.commit();
}
