import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/dio_client.dart';
import '../shared/models/client.dart';
import '../shared/models/paginated_response.dart';

class ClientRepository {
  ClientRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Client>> list({
    int page = 1,
    String? query,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/clients',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Client.fromJson,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> getById(int id) async {
    try {
      final response = await _dio.get('/clients/$id');
      return Client.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> create(CreateClientInput input) async {
    try {
      final response = await _dio.post('/clients', data: input.toJson());
      return Client.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Client> update(int id, UpdateClientInput input) async {
    try {
      final response = await _dio.patch('/clients/$id', data: input.toJson());
      return Client.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/clients/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Map<String, dynamic> _extractData(dynamic body) {
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    return body as Map<String, dynamic>;
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.read(dioProvider));
});
