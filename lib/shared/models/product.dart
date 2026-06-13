class Product {
  const Product({
    required this.id,
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    required this.isActive,
  });

  final int id;
  final String name;
  final String unit;
  final String costPrice;
  final String salePrice;
  final bool isActive;

  double get costNum => double.tryParse(costPrice) ?? 0;
  double get saleNum => double.tryParse(salePrice) ?? 0;

  String get subtitle => '$unit · venta';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      unit: json['unit'] as String,
      costPrice: json['cost_price']?.toString() ?? '0',
      salePrice: json['sale_price']?.toString() ?? '0',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class CreateProductInput {
  const CreateProductInput({
    required this.name,
    required this.unit,
    required this.costPrice,
    required this.salePrice,
    this.isActive = true,
  });

  final String name;
  final String unit;
  final num costPrice;
  final num salePrice;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'unit': unit,
        'cost_price': costPrice,
        'sale_price': salePrice,
        'is_active': isActive,
      };
}

class UpdateProductInput {
  const UpdateProductInput({
    this.name,
    this.unit,
    this.costPrice,
    this.salePrice,
    this.isActive,
  });

  final String? name;
  final String? unit;
  final num? costPrice;
  final num? salePrice;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (unit != null) map['unit'] = unit;
    if (costPrice != null) map['cost_price'] = costPrice;
    if (salePrice != null) map['sale_price'] = salePrice;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
