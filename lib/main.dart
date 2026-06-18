import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/auth/auth_provider.dart';
import 'core/auth/session_expired_handler.dart';
import 'core/config/app_config.dart';
import 'core/onboarding/onboarding_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'shared/widgets/app_splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO', null);
  runApp(const ProviderScope(child: MargeenApp()));
}

class MargeenApp extends ConsumerStatefulWidget {
  const MargeenApp({super.key});

  @override
  ConsumerState<MargeenApp> createState() => _MargeenAppState();
}

class _MargeenAppState extends ConsumerState<MargeenApp> {
  bool _splashMinTimeDone = false;

  @override
  void initState() {
    super.initState();
    final authNotifier = ref.read(authProvider.notifier);
    ref.read(sessionExpiredHandlerProvider).onExpired =
        authNotifier.sessionExpired;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  static const _minSplashDuration = Duration(milliseconds: 1400);
  static const _bootstrapTimeout = Duration(seconds: 18);

  Future<void> _bootstrap() async {
    final started = DateTime.now();
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final onboardingNotifier = ref.read(onboardingProvider.notifier);
    final authNotifier = ref.read(authProvider.notifier);

    try {
      await Future.wait([
        themeNotifier.initialize(),
        onboardingNotifier.initialize(),
      ]).timeout(_bootstrapTimeout);

      if (!mounted) return;

      await authNotifier.bootstrap().timeout(_bootstrapTimeout);
    } on TimeoutException catch (e, st) {
      debugPrint('Bootstrap: tiempo de espera agotado: $e\n$st');
      onboardingNotifier.forceReady();
      authNotifier.forceUnauthenticated();
    } catch (e, st) {
      debugPrint('Bootstrap: error inesperado: $e\n$st');
      onboardingNotifier.forceReady();
      authNotifier.forceUnauthenticated();
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = _minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (mounted) {
      setState(() => _splashMinTimeDone = true);
    }
  }

  bool _showSplash(AuthState authState) {
    if (_splashMinTimeDone) return false;
    if (authState is AuthAuthenticated) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final showSplash = _showSplash(authState);

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
        final content = child;
        if (content == null) {
          return const AppSplashScreen();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (showSplash)
              const Positioned.fill(
                child: AppSplashScreen(),
              ),
          ],
        );
      },
    );
  }
}
