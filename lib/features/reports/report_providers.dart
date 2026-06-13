import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_repository.dart';
import '../../shared/models/dashboard_report.dart';

final dashboardReportProvider =
    FutureProvider.family<DashboardReport, ReportPeriod>((ref, period) {
  return ref.read(reportRepositoryProvider).dashboard(
        from: period.from,
        to: period.to,
      );
});

class ReportPeriod {
  const ReportPeriod({this.from, this.to});

  final String? from;
  final String? to;

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final currentReportPeriodProvider = StateProvider<ReportPeriod>((ref) {
  return const ReportPeriod();
});
