import '../../domain/entities/user.dart';
import '../../domain/entities/auth_session.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String role;
  final String? kopdesId;
  final String? kopdesName;
  final String? kopdesVillage;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.role,
    this.kopdesId,
    this.kopdesName,
    this.kopdesVillage,
    this.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend mengirim relasi `kopdes` pada login dan /auth/me; bentuk datar
    // (`kopdesName`) dipakai saat model ini dibaca kembali dari cache lokal.
    final kopdes = json['kopdes'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'CUSTOMER',
      kopdesId: json['kopdesId'] as String? ?? kopdes?['id'] as String?,
      kopdesName: kopdes?['name'] as String? ?? json['kopdesName'] as String?,
      kopdesVillage:
          kopdes?['village'] as String? ?? json['kopdesVillage'] as String?,
      permissions:
          (json['permissions'] as List?)?.whereType<String>().toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role,
      'kopdesId': kopdesId,
      'kopdesName': kopdesName,
      'kopdesVillage': kopdesVillage,
      'permissions': permissions,
    };
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      role: role,
      kopdesId: kopdesId,
      kopdesName: kopdesName,
      kopdesVillage: kopdesVillage,
      permissions: permissions,
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken:
          json['accessToken'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user.toEntity(),
    );
  }
}
