import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/report_repository.dart';
import '../../shared/models/dashboard_report.dart';

enum DashboardScope { day, month }

final dashboardScopeProvider =
    StateProvider<DashboardScope>((ref) => DashboardScope.month);

final dashboardDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dashboardReportProvider = FutureProvider<DashboardReport>((ref) {
  final scope = ref.watch(dashboardScopeProvider);
  final date = ref.watch(dashboardDateProvider);
  final formatter = DateFormat('yyyy-MM-dd');

  final to = formatter.format(date);
  final from = scope == DashboardScope.day
      ? to
      : formatter.format(DateTime(date.year, date.month, 1));

  return ref.read(reportRepositoryProvider).dashboard(from: from, to: to);
});
