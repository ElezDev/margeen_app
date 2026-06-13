import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/models/user.dart';

/// Evita renderizar hijos si aún no hay sesión autenticada.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.builder});

  final Widget Function(BuildContext context, AppUser user) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState) {
      AuthAuthenticated(:final user) => builder(context, user),
      _ => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
    };
  }
}
