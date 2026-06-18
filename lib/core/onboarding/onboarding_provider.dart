import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _onboardingKey = 'onboarding_completed';

sealed class OnboardingState {
  const OnboardingState();
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

class OnboardingReady extends OnboardingState {
  const OnboardingReady({required this.completed});

  final bool completed;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingInitial());

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    state = const OnboardingLoading();

    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      final completed = prefs.getBool(_onboardingKey) ?? false;
      state = OnboardingReady(completed: completed);
    } on TimeoutException catch (e, st) {
      debugPrint('Onboarding: timeout cargando preferencia: $e\n$st');
      state = const OnboardingReady(completed: false);
    } catch (e, st) {
      debugPrint('Onboarding: no se pudo cargar preferencia: $e\n$st');
      state = const OnboardingReady(completed: false);
    }
  }

  /// Evita quedar bloqueado si SharedPreferences tarda o falla al inicio.
  void forceReady({bool completed = false}) {
    if (state is! OnboardingReady) {
      state = OnboardingReady(completed: completed);
    }
  }

  Future<void> complete() async {
    state = const OnboardingReady(completed: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (e, st) {
      debugPrint('Onboarding: no se pudo guardar preferencia: $e\n$st');
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

final onboardingCompletedProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingProvider);
  return state is OnboardingReady && state.completed;
});
