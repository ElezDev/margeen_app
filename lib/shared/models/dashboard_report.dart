int _jsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _jsonNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

String _jsonString(dynamic value, {String fallback = '0'}) {
  if (value == null) return fallback;
  return value.toString();
}

class DashboardReport {
  const DashboardReport({
    required this.periodFrom,
    required this.periodTo,
    required this.summary,
    required this.topClients,
    required this.topProducts,
    required this.recentInvoices,
  });

  final String periodFrom;
  final String periodTo;
  final DashboardSummary summary;
  final List<DashboardTopClient> topClients;
  final List<DashboardTopProduct> topProducts;
  final List<DashboardRecentInvoice> recentInvoices;

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    if (data.containsKey('summary')) {
      final period = data['period'] as Map<String, dynamic>? ?? {};
      return DashboardReport(
        periodFrom: period['from']?.toString() ?? '',
        periodTo: period['to']?.toString() ?? '',
        summary: DashboardSummary.fromJson(
          data['summary'] as Map<String, dynamic>? ?? {},
        ),
        topClients: _parseTopClients(data['top_clients']),
        topProducts: _parseTopProducts(data['top_products']),
        recentInvoices: _parseRecentInvoices(data['recent_invoices']),
      );
    }

    return _fromLegacyJson(data);
  }

  static DashboardReport _fromLegacyJson(Map<String, dynamic> data) {
    final periodData =
        data['periodo_consultado'] as Map<String, dynamic>? ?? {};
    final dayStats = DashboardSummary.fromLegacyStats(
      data['del_dia'] as Map<String, dynamic>? ?? {},
    );
    final monthStats = DashboardSummary.fromLegacyStats(
      data['del_mes_completo'] as Map<String, dynamic>? ?? {},
    );
    final summary = monthStats.invoiceCount > 0 ? monthStats : dayStats;

    return DashboardReport(
      periodFrom: periodData['dia']?.toString() ?? '',
      periodTo: periodData['dia']?.toString() ?? '',
      summary: summary,
      topClients: _parseTopClients(data['top_clientes_del_mes']),
      topProducts: const [],
      recentInvoices: const [],
    );
  }

  static List<DashboardTopClient> _parseTopClients(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => DashboardTopClient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<DashboardTopProduct> _parseTopProducts(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => DashboardTopProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<DashboardRecentInvoice> _parseRecentInvoices(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => DashboardRecentInvoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.invoiceCount,
    required this.totalSales,
    required this.totalProfit,
    required this.profitMarginPercent,
    this.pendingCollection = 0,
  });

  final int invoiceCount;
  final num totalSales;
  final num totalProfit;
  final int profitMarginPercent;
  final num pendingCollection;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final margin = json['profit_margin_percent'];
    return DashboardSummary(
      invoiceCount: _jsonInt(json['invoice_count']),
      totalSales: _jsonNum(json['total_sales']),
      totalProfit: _jsonNum(json['total_profit']),
      profitMarginPercent: margin is num ? margin.round() : _jsonInt(margin),
    );
  }

  factory DashboardSummary.fromLegacyStats(Map<String, dynamic> json) {
    final sales = _jsonNum(json['ventas_totales']);
    final profit = _jsonNum(json['ganancias_totales']);
    return DashboardSummary(
      invoiceCount: _jsonInt(json['total_facturas']),
      totalSales: sales,
      totalProfit: profit,
      profitMarginPercent:
          sales > 0 ? ((profit / sales) * 100).round() : 0,
      pendingCollection: _jsonNum(json['pendiente_por_cobrar']),
    );
  }
}

class DashboardTopClient {
  const DashboardTopClient({
    required this.clientId,
    required this.clientName,
    required this.totalSales,
    required this.invoiceCount,
  });

  final int clientId;
  final String clientName;
  final num totalSales;
  final int invoiceCount;

  factory DashboardTopClient.fromJson(Map<String, dynamic> json) {
    return DashboardTopClient(
      clientId: _jsonInt(json['client_id']),
      clientName: json['client_name'] as String? ?? '',
      totalSales: _jsonNum(json['total_sales'] ?? json['total_comprado']),
      invoiceCount: _jsonInt(json['invoice_count']),
    );
  }
}

class DashboardTopProduct {
  const DashboardTopProduct({
    required this.productId,
    required this.description,
    required this.totalQuantity,
    required this.totalSales,
    required this.totalProfit,
  });

  final int productId;
  final String description;
  final String totalQuantity;
  final num totalSales;
  final num totalProfit;

  factory DashboardTopProduct.fromJson(Map<String, dynamic> json) {
    return DashboardTopProduct(
      productId: _jsonInt(json['product_id']),
      description: json['description'] as String? ?? '',
      totalQuantity: _jsonString(json['total_quantity']),
      totalSales: _jsonNum(json['total_sales']),
      totalProfit: _jsonNum(json['total_profit']),
    );
  }
}

class DashboardRecentInvoice {
  const DashboardRecentInvoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.total,
    required this.totalProfit,
    this.issuedAt,
  });

  final int id;
  final String number;
  final String clientName;
  final num total;
  final num totalProfit;
  final String? issuedAt;

  factory DashboardRecentInvoice.fromJson(Map<String, dynamic> json) {
    return DashboardRecentInvoice(
      id: _jsonInt(json['id']),
      number: json['number'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      total: _jsonNum(json['total']),
      totalProfit: _jsonNum(json['total_profit']),
      issuedAt: json['issued_at'] as String?,
    );
  }
}
