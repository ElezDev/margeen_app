import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/user.dart';
import 'auth_repository.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthInitial());

  final AuthRepository _repository;

  Future<void> bootstrap() async {
    state = const AuthLoading();

    final hasSession = await _repository.hasSession();
    if (!hasSession) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      final user = await _repository.me();
      state = AuthAuthenticated(user);
    } catch (_) {
      await _repository.logout();
      state = const AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthLoading();

    try {
      final result = await _repository.login(email: email, password: password);
      state = AuthAuthenticated(result.user);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Sesión inválida (token expirado / refresh falló). Sin llamada al API.
  void sessionExpired() {
    state = const AuthUnauthenticated();
  }

  /// Evita quedar bloqueado en [AuthLoading] si el arranque falla o expira.
  void forceUnauthenticated() {
    if (state is AuthInitial || state is AuthLoading) {
      state = const AuthUnauthenticated();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user : null;
});
