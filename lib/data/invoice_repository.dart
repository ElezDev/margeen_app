import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_client.dart';
import '../shared/models/invoice.dart';
import '../shared/models/paginated_response.dart';

class InvoiceFilters {
  const InvoiceFilters({
    this.clientId,
    this.status,
    this.from,
    this.to,
  });

  final int? clientId;
  final String? status;
  final String? from;
  final String? to;

  Map<String, dynamic> toQueryParams(int page) {
    return {
      'page': page,
      if (clientId != null) 'client_id': clientId,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (from != null && from!.isNotEmpty) 'from': from,
      if (to != null && to!.isNotEmpty) 'to': to,
    };
  }

  InvoiceFilters copyWith({
    int? clientId,
    String? status,
    String? from,
    String? to,
  }) {
    return InvoiceFilters(
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

class InvoiceRepository {
  InvoiceRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<Invoice>> list({
    int page = 1,
    InvoiceFilters filters = const InvoiceFilters(),
  }) async {
    try {
      final response = await _dio.get(
        '/invoices',
        queryParameters: filters.toQueryParams(page),
      );

      return PaginatedResponse.fromJson(
        response.data as Map<String, dynamic>,
        Invoice.fromJson,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Invoice> getById(int id) async {
    try {
      final response = await _dio.get('/invoices/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      return Invoice.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Invoice> create(CreateInvoiceInput input) async {
    try {
      final response = await _dio.post('/invoices', data: input.toJson());
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiException('Respuesta inválida al crear la factura.');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw ApiException('Respuesta inválida al crear la factura.');
      }
      return Invoice.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    } on TypeError catch (e) {
      throw ApiException('Error al leer la factura creada: $e');
    }
  }

  Future<Invoice> cancel(int id) async {
    try {
      final response = await _dio.patch('/invoices/$id/cancel');
      final data = response.data['data'] as Map<String, dynamic>;
      return Invoice.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Uint8List> downloadPdf(int id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/invoices/$id/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );
      return Uint8List.fromList(response.data ?? []);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.read(dioProvider));
});
