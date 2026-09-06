// Model ringan untuk fitur Super Admin.

int _toInt(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
double _toDouble(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);

/// Label peran dalam Bahasa Indonesia.
String roleLabel(String role) {
  switch (role) {
    case 'SUPER_ADMIN':
      return 'Super Admin';
    case 'ADMIN_KOPDES':
      return 'Admin Kopdes';
    case 'PEGAWAI_KOPDES':
      return 'Pegawai Kopdes';
    case 'CUSTOMER':
      return 'Pelanggan';
    case 'UMKM':
      return 'Mitra UMKM';
    case 'COURIER':
      return 'Kurir';
    default:
      return role;
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    name: j['name'] as String? ?? '-',
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String? ?? '',
    role: j['role'] as String? ?? '',
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse('${j['createdAt']}')
        : null,
  );
}

class Overview {
  final int totalUsers;
  final Map<String, int> usersByRole;
  final int totalProducts;
  final int retailProducts;
  final int umkmProducts;
  final int totalOrders;
  final int totalMitra;
  final int pendingMitra;
  final double totalRevenue;

  Overview({
    required this.totalUsers,
    required this.usersByRole,
    required this.totalProducts,
    required this.retailProducts,
    required this.umkmProducts,
    required this.totalOrders,
    required this.totalMitra,
    required this.pendingMitra,
    required this.totalRevenue,
  });

  factory Overview.fromJson(Map<String, dynamic> j) {
    final byRole = <String, int>{};
    for (final r in (j['usersByRole'] as List? ?? [])) {
      final m = r as Map<String, dynamic>;
      byRole[m['role'] as String? ?? '?'] = _toInt(m['count']);
    }
    return Overview(
      totalUsers: _toInt(j['totalUsers']),
      usersByRole: byRole,
      totalProducts: _toInt(j['totalProducts']),
      retailProducts: _toInt(j['retailProducts']),
      umkmProducts: _toInt(j['umkmProducts']),
      totalOrders: _toInt(j['totalOrders']),
      totalMitra: _toInt(j['totalMitra']),
      pendingMitra: _toInt(j['pendingMitra']),
      totalRevenue: _toDouble(j['totalRevenue']),
    );
  }
}
