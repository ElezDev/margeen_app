import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/report_repository.dart';
import '../../shared/models/dashboard_report.dart';

enum DashboardScope { day, month }

final dashboardScopeProvider =
    StateProvider<DashboardScope>((ref) => DashboardScope.day);

final dashboardDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dashboardReportProvider = FutureProvider<DashboardReport>((ref) {
  final date = ref.watch(dashboardDateProvider);
  final day = DateFormat('yyyy-MM-dd').format(date);
  return ref.read(reportRepositoryProvider).dashboard(day: day);
});
