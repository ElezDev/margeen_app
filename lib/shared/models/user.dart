import 'company.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.permissions,
    required this.isActive,
    this.document,
    this.phone,
    this.company,
  });

  final int id;
  final String name;
  final String email;
  final List<String> roles;
  final List<String> permissions;
  final bool isActive;
  final String? document;
  final String? phone;
  final Company? company;

  bool get isAdmin => roles.contains('admin');

  bool can(String permission) => permissions.contains(permission);

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: json['roles'] != null
          ? (json['roles'] as List<dynamic>).cast<String>()
          : const <String>[],
      permissions: json['permissions'] != null
          ? (json['permissions'] as List<dynamic>).cast<String>()
          : const <String>[],
      isActive: json['is_active'] as bool,
      document: json['document'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] != null
          ? Company.fromJson(json['company'] as Map<String, dynamic>)
          : null,
    );
  }
}
