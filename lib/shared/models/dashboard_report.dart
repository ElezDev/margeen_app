int _jsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
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
  final List<TopClient> topClients;
  final List<TopProduct> topProducts;
  final List<RecentInvoice> recentInvoices;

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final period = data['period'] as Map<String, dynamic>? ?? {};
    return DashboardReport(
      periodFrom: period['from']?.toString() ?? '',
      periodTo: period['to']?.toString() ?? '',
      summary: DashboardSummary.fromJson(
        data['summary'] as Map<String, dynamic>? ?? {},
      ),
      topClients: (data['top_clients'] as List<dynamic>? ?? [])
          .map((e) => TopClient.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProducts: (data['top_products'] as List<dynamic>? ?? [])
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentInvoices: (data['recent_invoices'] as List<dynamic>? ?? [])
          .map((e) => RecentInvoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.invoiceCount,
    required this.totalSales,
    required this.totalProfit,
    required this.profitMarginPercent,
  });

  final int invoiceCount;
  final String totalSales;
  final String totalProfit;
  final int profitMarginPercent;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      invoiceCount: _jsonInt(json['invoice_count']),
      totalSales: _jsonString(json['total_sales']),
      totalProfit: _jsonString(json['total_profit']),
      profitMarginPercent: _jsonInt(json['profit_margin_percent']),
    );
  }
}

class TopClient {
  const TopClient({
    required this.clientId,
    required this.clientName,
    required this.totalSales,
    required this.invoiceCount,
  });

  final int clientId;
  final String clientName;
  final String totalSales;
  final int invoiceCount;

  factory TopClient.fromJson(Map<String, dynamic> json) {
    return TopClient(
      clientId: _jsonInt(json['client_id']),
      clientName: json['client_name'] as String? ?? '',
      totalSales: _jsonString(json['total_sales']),
      invoiceCount: _jsonInt(json['invoice_count']),
    );
  }
}

class TopProduct {
  const TopProduct({
    required this.productId,
    required this.description,
    required this.totalQuantity,
    required this.totalSales,
    required this.totalProfit,
  });

  final int productId;
  final String description;
  final String totalQuantity;
  final String totalSales;
  final String totalProfit;

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: _jsonInt(json['product_id']),
      description: json['description'] as String? ?? '',
      totalQuantity: _jsonString(json['total_quantity']),
      totalSales: _jsonString(json['total_sales']),
      totalProfit: _jsonString(json['total_profit']),
    );
  }
}

class RecentInvoice {
  const RecentInvoice({
    required this.id,
    required this.number,
    required this.clientName,
    required this.total,
    required this.totalProfit,
  });

  final int id;
  final String number;
  final String clientName;
  final String total;
  final String totalProfit;

  factory RecentInvoice.fromJson(Map<String, dynamic> json) {
    return RecentInvoice(
      id: _jsonInt(json['id']),
      number: json['number'] as String? ?? '',
      clientName: json['client_name'] as String? ?? '',
      total: _jsonString(json['total']),
      totalProfit: _jsonString(json['total_profit']),
    );
  }
}
