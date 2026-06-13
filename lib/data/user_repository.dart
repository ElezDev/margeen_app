import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/dio_client.dart';
import '../shared/models/managed_user.dart';
import '../shared/models/paginated_response.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<ManagedUser>> list({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'page': page},
      );

      final body = response.data;
      if (body is Map<String, dynamic> && body.containsKey('meta')) {
        return PaginatedResponse.fromJson(body, ManagedUser.fromJson);
      }

      final items = _extractList(body);
      return PaginatedResponse(
        data: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ManagedUser> getById(int id) async {
    try {
      final response = await _dio.get('/users/$id');
      return ManagedUser.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ManagedUser> create(CreateUserInput input) async {
    try {
      final response = await _dio.post('/users', data: input.toJson());
      return ManagedUser.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ManagedUser> update(int id, UpdateUserInput input) async {
    try {
      final response = await _dio.patch('/users/$id', data: input.toJson());
      return ManagedUser.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> deactivate(int id) async {
    try {
      await _dio.delete('/users/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  List<ManagedUser> _extractList(dynamic body) {
    if (body is List) {
      return body
          .map((e) => ManagedUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) {
        return data
            .map((e) => ManagedUser.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractData(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioProvider));
});
