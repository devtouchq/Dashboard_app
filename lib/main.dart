import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/string_constants.dart';
import 'core/di/injector.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/accounts_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/emr_repository.dart';
import 'data/repositories/store_repository.dart';
import 'presentation/blocs/accounts/accounts_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/emr/emr_bloc.dart';
import 'presentation/blocs/navigation/navigation_bloc.dart';
import 'presentation/blocs/store/store_bloc.dart';
import 'presentation/screens/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => NavigationBloc()),
        BlocProvider(
          create: (_) => DashboardBloc(autoInjector.get<DashboardRepository>())
            ..add(const DashboardLoadRequested()),
        ),
        BlocProvider(
          create: (_) => EmrBloc(autoInjector.get<EmrRepository>())
            ..add(const EmrLoadRequested()),
        ),
        BlocProvider(
          create: (_) => AccountsBloc(autoInjector.get<AccountsRepository>())
            ..add(const AccountsLoadRequested()),
        ),
        BlocProvider(
          create: (_) => StoreBloc(autoInjector.get<StoreRepository>())
            ..add(const StoreLoadRequested()),
        ),
      ],
      child: MaterialApp(
        title: StringConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainShell(),
      ),
    );
  }
}
