String _jsonString(dynamic value, {String fallback = '0'}) {
  if (value == null) return fallback;
  return value.toString();
}

int _jsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class InvoiceClient {
  const InvoiceClient({
    required this.id,
    required this.name,
    this.phone,
  });

  final int id;
  final String name;
  final String? phone;

  factory InvoiceClient.fromJson(Map<String, dynamic> json) {
    return InvoiceClient(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class InvoiceSeller {
  const InvoiceSeller({required this.id, required this.name});

  final int id;
  final String name;

  factory InvoiceSeller.fromJson(Map<String, dynamic> json) {
    return InvoiceSeller(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.unitCost,
    required this.lineTotal,
    required this.lineProfit,
    this.productId,
  });

  final int id;
  final int? productId;
  final String description;
  final String quantity;
  final String unit;
  final String unitPrice;
  final String unitCost;
  final String lineTotal;
  final String lineProfit;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: _jsonInt(json['id']),
      productId: json['product_id'] as int?,
      description: json['description'] as String,
      quantity: _jsonString(json['quantity']),
      unit: json['unit'] as String,
      unitPrice: _jsonString(json['unit_price']),
      unitCost: _jsonString(json['unit_cost']),
      lineTotal: _jsonString(json['line_total']),
      lineProfit: _jsonString(json['line_profit']),
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.totalCost,
    required this.totalProfit,
    required this.profitMarginPercent,
    this.notes,
    this.pdfUrl,
    this.issuedAt,
    this.client,
    this.seller,
    this.items = const [],
  });

  final int id;
  final String number;
  final String status;
  final String subtotal;
  final String discount;
  final String total;
  final String totalCost;
  final String totalProfit;
  final int profitMarginPercent;
  final String? notes;
  final String? pdfUrl;
  final String? issuedAt;
  final InvoiceClient? client;
  final InvoiceSeller? seller;
  final List<InvoiceItem> items;

  bool get isCancelled => status == 'cancelled';
  bool get isIssued => status == 'issued';

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: _jsonInt(json['id']),
      number: json['number'] as String,
      status: json['status'] as String,
      subtotal: _jsonString(json['subtotal']),
      discount: _jsonString(json['discount']),
      total: _jsonString(json['total']),
      totalCost: _jsonString(json['total_cost']),
      totalProfit: _jsonString(json['total_profit']),
      profitMarginPercent: _jsonInt(json['profit_margin_percent']),
      notes: json['notes'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      issuedAt: json['issued_at'] as String?,
      client: json['client'] != null
          ? InvoiceClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? InvoiceSeller.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>)
              .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class CreateInvoiceItemInput {
  const CreateInvoiceItemInput({
    this.productId,
    this.description,
    this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
  });

  final int? productId;
  final String? description;
  final String? unit;
  final num quantity;
  final num unitPrice;
  final num unitCost;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'quantity': quantity,
      'unit_price': unitPrice,
      'unit_cost': unitCost,
    };
    if (productId != null) map['product_id'] = productId;
    if (description != null) map['description'] = description;
    if (unit != null) map['unit'] = unit;
    return map;
  }
}

class CreateInvoiceInput {
  const CreateInvoiceInput({
    required this.clientId,
    required this.items,
    this.discount = 0,
    this.notes,
  });

  final int clientId;
  final List<CreateInvoiceItemInput> items;
  final num discount;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'discount': discount,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'items': items.map((e) => e.toJson()).toList(),
      };
}
