/// Permission operasional Kopdes.
///
/// Cerminan `backend/src/common/permissions.ts`. Dipakai hanya untuk
/// menyembunyikan tindakan yang memang akan ditolak server — pembatasan
/// sesungguhnya tetap `PermissionsGuard` di backend, karena apa pun yang
/// hanya disembunyikan di layar masih bisa dipanggil langsung ke API.
class Permissions {
  static const productCreate = 'product:create';
  static const productUpdate = 'product:update';
  static const productDelete = 'product:delete';
  static const categoryManage = 'category:manage';

  static const orderRead = 'order:read';
  static const orderProcess = 'order:process';
  static const orderCancel = 'order:cancel';

  static const deliveryRead = 'delivery:read';
  static const deliveryAssign = 'delivery:assign';
  static const deliveryUnassign = 'delivery:unassign';

  static const inventoryRead = 'inventory:read';
  static const inventoryAdjust = 'inventory:adjust';
  static const inventoryOpname = 'inventory:opname';

  static const financeReadSummary = 'finance:read:summary';
  static const financeReadFull = 'finance:read:full';

  static const mitraRead = 'mitra:read';
  static const mitraVerify = 'mitra:verify';
  static const umkmProductTakedown = 'umkm:product:takedown';

  static const aiAssist = 'ai:assist';
  static const aiExecutive = 'ai:executive';
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String
  role; // SUPER_ADMIN, ADMIN_KOPDES, PEGAWAI_KOPDES, CUSTOMER, UMKM, COURIER

  /// Kopdes penugasan staf. Null untuk pelanggan, mitra, kurir, super admin.
  final String? kopdesId;
  final String? kopdesName;
  final String? kopdesVillage;

  /// Permission efektif yang dikirim backend — sudah memperhitungkan bawaan
  /// role dan penyempitan per akun, jadi klien tidak menghitungnya sendiri.
  final List<String> permissions;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.kopdesId,
    this.kopdesName,
    this.kopdesVillage,
    this.permissions = const [],
  });

  bool can(String permission) => permissions.contains(permission);

  bool get isKopdesStaff => role == 'ADMIN_KOPDES' || role == 'PEGAWAI_KOPDES';

  /// Label peran untuk header dashboard.
  String get roleLabel => switch (role) {
    'SUPER_ADMIN' => 'Super Admin',
    'ADMIN_KOPDES' => 'Admin Kopdes',
    'PEGAWAI_KOPDES' => 'Pegawai Kopdes',
    'COURIER' => 'Kurir',
    'UMKM' => 'Mitra UMKM',
    _ => 'Pelanggan',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          role == other.role &&
          kopdesId == other.kopdesId &&
          kopdesName == other.kopdesName &&
          kopdesVillage == other.kopdesVillage &&
          _sameList(permissions, other.permissions);

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    email,
    phone,
    role,
    kopdesId,
    kopdesName,
    kopdesVillage,
    Object.hashAll(permissions),
  );

  @override
  String toString() =>
      'User{id: $id, name: $name, email: $email, phone: $phone, '
      'role: $role, kopdesId: $kopdesId, permissions: ${permissions.length}}';
}
