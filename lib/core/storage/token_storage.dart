import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;
  static const _readTimeout = Duration(seconds: 5);

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> getAccessToken() => _read(_accessKey);

  Future<String?> getRefreshToken() => _read(_refreshKey);

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key).timeout(_readTimeout);
    } on TimeoutException catch (e, st) {
      debugPrint('TokenStorage: timeout leyendo $key: $e\n$st');
      return null;
    } catch (e, st) {
      debugPrint('TokenStorage: error leyendo $key: $e\n$st');
      return null;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (e, st) {
      debugPrint('TokenStorage: error al limpiar tokens: $e\n$st');
    }
  }
}
