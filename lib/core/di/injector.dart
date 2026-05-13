import 'package:auto_injector/auto_injector.dart';

import '../network/dio_client.dart';

import '../../data/repositories/accounts_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/banquet_repository.dart';
import '../../data/repositories/bar_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/emr_repository.dart';
import '../../data/repositories/frontoffice_repository.dart';
import '../../data/repositories/hr_repository.dart';
import '../../data/repositories/lab_repository.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/repositories/store_repository.dart';
import '../../presentation/blocs/accounts/accounts_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/banquet/banquet_bloc.dart';
import '../../presentation/blocs/bar/bar_bloc.dart';
import '../../presentation/blocs/dashboard/dashboard_bloc.dart';
import '../../presentation/blocs/emr/emr_bloc.dart';
import '../../presentation/blocs/frontoffice/frontoffice_bloc.dart';
import '../../presentation/blocs/hr/hr_bloc.dart';
import '../../presentation/blocs/lab/lab_bloc.dart';
import '../../presentation/blocs/restaurant/restaurant_bloc.dart';
import '../../presentation/blocs/store/store_bloc.dart';
import 'local_storage_service.dart';

final autoInjector = AutoInjector(
  on: (i) {
    // ─── Singletons that need async init ──────────────────
    // LocalStorageService is initialized in setupDependencies()
    // and then registered here as already-initialized.
    // (we use addInstance to provide the pre-built object)

    // Dio depends on storage
    i.addSingleton<DioClient>(() => DioClient(i.get<LocalStorageService>()));

    // ─── Repositories ──────────────────────────────────────
    i.addSingleton<AuthRepository>(() => AuthRepository(i.get<DioClient>()));
    i.addSingleton<DashboardRepository>(
        () => DashboardRepository(i.get<DioClient>()));
    i.addSingleton<EmrRepository>(() => EmrRepository(i.get<DioClient>()));
    i.addSingleton<AccountsRepository>(
        () => AccountsRepository(i.get<DioClient>()));
    i.addSingleton<StoreRepository>(() => StoreRepository(i.get<DioClient>()));
    i.addSingleton<BarRepository>(() => BarRepository(i.get<DioClient>()));
    i.addSingleton<LabRepository>(() => LabRepository(i.get<DioClient>()));
    i.addSingleton<BanquetRepository>(
        () => BanquetRepository(i.get<DioClient>()));
    i.addSingleton<RestaurantRepository>(
        () => RestaurantRepository(i.get<DioClient>()));
    i.addSingleton<HrRepository>(() => HrRepository(i.get<DioClient>()));
    i.addSingleton<FrontofficeRepository>(
        () => FrontofficeRepository(i.get<DioClient>()));

    // ─── Blocs ─────────────────────────────────────────────
    // AuthBloc is a singleton — same instance across BaseUrl / Login / Branch
    i.addSingleton<AuthBloc>(
      () => AuthBloc(i.get<AuthRepository>(), i.get<LocalStorageService>()),
    );

    i.add<DashboardBloc>(() => DashboardBloc(i.get<DashboardRepository>()));
    i.add<EmrBloc>(() => EmrBloc(i.get<EmrRepository>()));
    i.add<AccountsBloc>(() => AccountsBloc(i.get<AccountsRepository>()));
    i.add<StoreBloc>(() => StoreBloc(i.get<StoreRepository>()));
    i.add<BarBloc>(() => BarBloc(i.get<BarRepository>()));
    i.add<LabBloc>(() => LabBloc(i.get<LabRepository>()));
    i.add<BanquetBloc>(() => BanquetBloc(i.get<BanquetRepository>()));
    i.add<RestaurantBloc>(() => RestaurantBloc(i.get<RestaurantRepository>()));
    i.add<HrBloc>(() => HrBloc(i.get<HrRepository>()));
    i.add<FrontofficeBloc>(
        () => FrontofficeBloc(i.get<FrontofficeRepository>()));
  },
);

/// Call from main() before runApp().
/// Initializes async services (storage) and commits the injector.
Future<void> setupDependencies() async {
  // Pre-build & init LocalStorageService asynchronously
  final storage = LocalStorageService();
  await storage.init();
  autoInjector.addInstance<LocalStorageService>(storage);

  autoInjector.commit();
}
