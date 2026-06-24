class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // SUPER_ADMIN, ADMIN_KOPDES, CUSTOMER, UMKM, COURIER

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      role.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phone: $phone, role: $role}';
  }
}
