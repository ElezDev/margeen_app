import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../onboarding/onboarding_provider.dart';
import '../../features/clients/client_form_screen.dart';
import '../../features/clients/client_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/invoices/create_invoice_screen.dart';
import '../../features/invoices/invoice_detail_screen.dart';
import '../../features/invoices/invoice_list_screen.dart';
import '../../features/products/product_form_screen.dart';
import '../../features/products/product_list_screen.dart';
import '../../features/reports/dashboard_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/users/user_form_screen.dart';
import '../../features/users/user_list_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../auth/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _routerRefreshProvider = Provider<Listenable>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => notifier.value++);
  ref.listen(onboardingProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final onboardingState = ref.read(onboardingProvider);
      final location = state.matchedLocation;

      final isAuthLoading =
          authState is AuthInitial || authState is AuthLoading;
      final isOnboardingLoading = onboardingState is OnboardingInitial ||
          onboardingState is OnboardingLoading;
      final isLoggedIn = authState is AuthAuthenticated;
      final onboardingDone = onboardingState is OnboardingReady &&
          onboardingState.completed;

      final isOnboardingRoute = location == '/onboarding';
      final isLoginRoute = location == '/login';
      final isPublicRoute = isOnboardingRoute || isLoginRoute;

      if (isAuthLoading || isOnboardingLoading) {
        return isPublicRoute ? null : '/login';
      }

      if (!onboardingDone && !isOnboardingRoute) return '/onboarding';

      if (onboardingDone && isOnboardingRoute) {
        return isLoggedIn ? '/' : '/login';
      }

      if (!isLoggedIn && !isLoginRoute && !isOnboardingRoute) {
        return '/login';
      }

      if (isLoggedIn && isLoginRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoiceListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/invoices/new',
        builder: (context, state) => const CreateInvoiceScreen(),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return InvoiceDetailScreen(invoiceId: id);
        },
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UserListScreen(),
      ),
      GoRoute(
        path: '/users/new',
        builder: (context, state) => const UserFormScreen(),
      ),
      GoRoute(
        path: '/users/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return UserFormScreen(userId: id);
        },
      ),
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientListScreen(),
      ),
      GoRoute(
        path: '/clients/new',
        builder: (context, state) => const ClientFormScreen(),
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ClientFormScreen(clientId: id);
        },
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/:id/edit',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
