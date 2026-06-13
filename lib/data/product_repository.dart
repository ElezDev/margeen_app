import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/dio_client.dart';
import '../shared/models/paginated_response.dart';
import '../shared/models/product.dart';

class ProductRepository {
  ProductRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Product>> list({
    int page = 1,
    String? query,
    bool activeOnly = false,
    int perPage = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/products',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (query != null && query.isNotEmpty) 'q': query,
          if (activeOnly) 'active_only': 1,
        },
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Product.fromJson,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Product> getById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return Product.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Product> create(CreateProductInput input) async {
    try {
      final response = await _dio.post('/products', data: input.toJson());
      return Product.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Product> update(int id, UpdateProductInput input) async {
    try {
      final response = await _dio.patch('/products/$id', data: input.toJson());
      return Product.fromJson(_extractData(response.data));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/products/$id');
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

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.read(dioProvider));
});
