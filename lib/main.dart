import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/string_constants.dart';
import 'core/di/injector.dart';
import 'core/di/local_storage_service.dart';

import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/screens/base_url/base_url_screen.dart';

// ─────────────────────────────────────────────────────────────
// DEV FLAG
// Set to `true` while you're developing so every restart begins at the
// BaseUrl screen. Set to `false` for production / real testing so users
// don't lose their session on every relaunch.
// ─────────────────────────────────────────────────────────────
const bool kAlwaysStartFromBaseUrl = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  if (kAlwaysStartFromBaseUrl) {
    final storage = autoInjector.get<LocalStorageService>();
    await storage.clearAll();
  }

  runApp(const AyurlivApp());
}

class AyurlivApp extends StatelessWidget {
  const AyurlivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => autoInjector.get<AuthBloc>(),
      child: MaterialApp(
        title: StringConstants.appName,
        debugShowCheckedModeBanner: false,
        // theme: AppTheme.light,
        home: const BaseUrlScreen(),
      ),
    );
  }
}
