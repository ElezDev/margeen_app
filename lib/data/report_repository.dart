import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exception.dart';
import '../core/api/dio_client.dart';
import '../shared/models/dashboard_report.dart';

class ReportRepository {
  ReportRepository(this._dio);

  final Dio _dio;

  Future<DashboardReport> dashboard({String? day}) async {
    try {
      final response = await _dio.get(
        '/reports/dashboard',
        queryParameters: {
          if (day != null && day.isNotEmpty) 'dia': day,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw ApiException('Respuesta inválida del reporte.');
      }
      return DashboardReport.fromJson(body);
    } on DioException catch (e) {
      throw mapDioError(e);
    } on TypeError catch (e) {
      throw ApiException('Error al leer el reporte: $e');
    }
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.read(dioProvider));
});
