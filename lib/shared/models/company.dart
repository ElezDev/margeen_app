class Company {
  const Company({
    required this.id,
    required this.name,
    this.document,
    this.phone,
    this.address,
    this.invoicePrefix,
  });

  final int id;
  final String name;
  final String? document;
  final String? phone;
  final String? address;
  final String? invoicePrefix;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      invoicePrefix: json['invoice_prefix'] as String?,
    );
  }
}
