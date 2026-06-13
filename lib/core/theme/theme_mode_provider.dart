import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  bool _initialized = false;

  /// Llamar desde main después de [WidgetsFlutterBinding.ensureInitialized].
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e, st) {
      debugPrint('ThemeMode: no se pudo abrir SharedPreferences: $e\n$st');
      return null;
    }
  }

  Future<void> _load() async {
    final prefs = await _prefs();
    if (prefs == null) return;

    final stored = prefs.getString(_themeKey);
    state = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;

    final prefs = await _prefs();
    if (prefs == null) return;

    try {
      await prefs.setString(
        _themeKey,
        switch (mode) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        },
      );
    } catch (e, st) {
      debugPrint('ThemeMode: no se pudo guardar preferencia: $e\n$st');
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
