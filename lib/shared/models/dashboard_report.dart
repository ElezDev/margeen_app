int _jsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _jsonNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

class DashboardReport {
  const DashboardReport({
    required this.period,
    required this.dayStats,
    required this.monthStats,
    required this.topClients,
  });

  final DashboardPeriod period;
  final DashboardStats dayStats;
  final DashboardStats monthStats;
  final List<DashboardTopClient> topClients;

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final periodData =
        data['periodo_consultado'] as Map<String, dynamic>? ?? {};

    return DashboardReport(
      period: DashboardPeriod.fromJson(periodData),
      dayStats: DashboardStats.fromJson(
        data['del_dia'] as Map<String, dynamic>? ?? {},
      ),
      monthStats: DashboardStats.fromJson(
        data['del_mes_completo'] as Map<String, dynamic>? ?? {},
      ),
      topClients: (data['top_clientes_del_mes'] as List<dynamic>? ?? [])
          .map((e) => DashboardTopClient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardPeriod {
  const DashboardPeriod({
    required this.day,
    required this.monthLabel,
  });

  final String day;
  final String monthLabel;

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      day: json['dia']?.toString() ?? '',
      monthLabel: json['mes_correspondiente']?.toString() ?? '',
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.totalSales,
    required this.totalProfit,
    required this.pendingCollection,
    required this.invoiceCount,
  });

  final num totalSales;
  final num totalProfit;
  final num pendingCollection;
  final int invoiceCount;

  int get profitMarginPercent {
    if (totalSales <= 0) return 0;
    return ((totalProfit / totalSales) * 100).round();
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalSales: _jsonNum(json['ventas_totales']),
      totalProfit: _jsonNum(json['ganancias_totales']),
      pendingCollection: _jsonNum(json['pendiente_por_cobrar']),
      invoiceCount: _jsonInt(json['total_facturas']),
    );
  }
}

class DashboardTopClient {
  const DashboardTopClient({
    required this.clientId,
    required this.clientName,
    required this.totalPurchased,
  });

  final int clientId;
  final String clientName;
  final num totalPurchased;

  factory DashboardTopClient.fromJson(Map<String, dynamic> json) {
    return DashboardTopClient(
      clientId: _jsonInt(json['client_id']),
      clientName: json['client_name'] as String? ?? '',
      totalPurchased: _jsonNum(json['total_comprado']),
    );
  }
}
