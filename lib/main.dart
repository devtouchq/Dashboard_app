import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/string_constants.dart';
import 'core/di/injector.dart';
import 'core/di/local_storage_service.dart';
import 'core/utils/app_logger.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/screens/base_url/base_url_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/login/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const AyurlivApp());
}

class AyurlivApp extends StatelessWidget {
  const AyurlivApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc is a singleton so it spans BaseUrl → Login → Branch.
    return BlocProvider<AuthBloc>(
      create: (_) => autoInjector.get<AuthBloc>(),
      child: const MaterialApp(
        title: StringConstants.appName,
        debugShowCheckedModeBanner: false,
       // theme: AppTheme.light,
        home: _RouteGate(),
      ),
    );
  }
}

/// Decides what to show on cold start based on persisted state:
///
///   1. No baseUrl saved              → BaseUrlScreen
///   2. baseUrl + no session          → LoginScreen
///   3. baseUrl + session + no branch → LoginScreen (re-pick branch)
///   4. Fully authenticated           → HomeScreen
///
/// Notes:
///  • This runs ONLY on cold start. Once you're past this gate, normal
///    Navigator pushes/pops apply.
///  • "Remember me" prefilling is handled inside LoginScreen — even if
///    the session was cleared (logout / token expiry), the saved Account
///    ID + Username come back in the form for one-tap login.
class _RouteGate extends StatelessWidget {
  const _RouteGate();

  static const _tag = 'RouteGate';

  @override
  Widget build(BuildContext context) {
    final storage = autoInjector.get<LocalStorageService>();
    final baseUrl = storage.baseUrl;
    final hasSession = storage.hasSession;
    final branch = storage.selectedBranch;

    AppLogger.info(
      _tag,
      'baseUrl="${baseUrl ?? ''}" hasSession=$hasSession branch="${branch ?? ''}"',
    );

    if (baseUrl == null || baseUrl.isEmpty) {
      AppLogger.info(_tag, '→ BaseUrlScreen');
      return const BaseUrlScreen();
    }

    if (!hasSession) {
      AppLogger.info(_tag, '→ LoginScreen (no session)');
      return const LoginScreen();
    }

    if (branch == null || branch.isEmpty) {
      AppLogger.info(_tag, '→ LoginScreen (no branch)');
      return const LoginScreen();
    }

    AppLogger.info(_tag, '→ HomeScreen');
    return BlocProvider<DashboardBloc>(
      create: (_) => autoInjector.get<DashboardBloc>()
        ..add(const DashboardLoadRequested()),
      child: const HomeScreen(),
    );
  }
}
