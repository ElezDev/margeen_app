import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/auth/auth_provider.dart';
import 'core/auth/session_expired_handler.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MargeenApp()));
}

class MargeenApp extends ConsumerStatefulWidget {
  const MargeenApp({super.key});

  @override
  ConsumerState<MargeenApp> createState() => _MargeenAppState();
}

class _MargeenAppState extends ConsumerState<MargeenApp> {
  @override
  void initState() {
    super.initState();
    ref.read(sessionExpiredHandlerProvider).onExpired =
        () => ref.read(authProvider.notifier).sessionExpired();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await ref.read(themeModeProvider.notifier).initialize();
    await ref.read(authProvider.notifier).bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isBootstrapping =
        authState is AuthInitial || authState is AuthLoading;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [
        Locale('es', 'CO'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        if (isBootstrapping && authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
