import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import 'app_drawer.dart';
import 'app_loading_indicator.dart';
import 'app_navigation.dart';
import 'home_bottom_nav.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: AppLoadingPage(),
      );
    }

    final scaffoldKey = ref.watch(rootScaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: HomeBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelected: _onDestinationSelected,
      ),
    );
  }
}
