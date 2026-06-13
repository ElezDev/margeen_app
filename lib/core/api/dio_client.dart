import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_expired_handler.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      dio: dio,
      tokenStorage: ref.read(tokenStorageProvider),
      onUnauthorized: () {
        ref.read(tokenStorageProvider).clear();
        ref.read(sessionExpiredHandlerProvider).notify();
      },
    ),
  );

  return dio;
});

ApiException mapDioError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    var message = data['message'] as String?;

    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        message = first.first.toString();
      }
    }

    if (message != null && message.isNotEmpty) {
      return ApiException(message, statusCode: error.response?.statusCode);
    }
  }

  return ApiException(
    'Error de conexión. Verifica que la API esté corriendo.',
    statusCode: error.response?.statusCode,
  );
}
