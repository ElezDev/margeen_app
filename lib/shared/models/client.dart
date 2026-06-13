class Client {
  const Client({
    required this.id,
    required this.name,
    this.document,
    this.phone,
    this.address,
    this.notes,
  });

  final int id;
  final String name;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;

  String get subtitle {
    final parts = <String>[
      if (document != null && document!.isNotEmpty) document!,
      if (phone != null && phone!.isNotEmpty) phone!,
    ];
    return parts.isEmpty ? 'Sin datos de contacto' : parts.join(' · ');
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int,
      name: json['name'] as String,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class CreateClientInput {
  const CreateClientInput({
    required this.name,
    this.document,
    this.phone,
    this.address,
    this.notes,
  });

  final String name;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (document != null && document!.isNotEmpty) 'document': document,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class UpdateClientInput {
  const UpdateClientInput({
    this.name,
    this.document,
    this.phone,
    this.address,
    this.notes,
  });

  final String? name;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (document != null) map['document'] = document;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}
