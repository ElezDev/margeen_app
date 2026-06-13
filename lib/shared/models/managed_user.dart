class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.isActive,
    this.document,
    this.phone,
    this.address,
    this.notes,
  });

  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final bool isActive;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;

  String get primaryRole => roles.isNotEmpty ? roles.first : 'vendedor';

  bool get isAdmin => roles.contains('admin');

  String get roleLabel => isAdmin ? 'Administrador' : 'Vendedor';

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'] != null
        ? (json['roles'] as List<dynamic>).cast<String>()
        : json['role'] != null
            ? [json['role'] as String]
            : <String>[];

    return ManagedUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: roles,
      isActive: json['is_active'] as bool,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class CreateUserInput {
  const CreateUserInput({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.document,
    this.phone,
    this.address,
    this.notes,
    this.isActive = true,
  });

  final String name;
  final String email;
  final String password;
  final String role;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'is_active': isActive,
        if (document != null && document!.isNotEmpty) 'document': document,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class UpdateUserInput {
  const UpdateUserInput({
    this.name,
    this.email,
    this.password,
    this.role,
    this.document,
    this.phone,
    this.address,
    this.notes,
    this.isActive,
  });

  final String? name;
  final String? email;
  final String? password;
  final String? role;
  final String? document;
  final String? phone;
  final String? address;
  final String? notes;
  final bool? isActive;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (email != null) map['email'] = email;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (role != null) map['role'] = role;
    if (document != null) map['document'] = document;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (notes != null) map['notes'] = notes;
    if (isActive != null) map['is_active'] = isActive;
    return map;
  }
}
