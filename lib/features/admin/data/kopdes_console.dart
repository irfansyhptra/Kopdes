import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../umkm/data/models/seller_model.dart';

/// Dasbor Kopdes: angka penjualan berbentuk sama dengan dasbor penjual UMKM
/// (supaya kartunya dipakai bersama) ditambah antrean khas pengurus.
class KopdesDashboard {
  final SellerDashboardStats stats;
  final int pendingMitra;
  final int pendingPayouts;

  const KopdesDashboard({
    required this.stats,
    required this.pendingMitra,
    required this.pendingPayouts,
  });

  factory KopdesDashboard.fromJson(Map<String, dynamic> json) =>
      KopdesDashboard(
        stats: SellerDashboardStats.fromJson(json),
        pendingMitra: (json['pendingMitra'] as num?)?.toInt() ?? 0,
        pendingPayouts: (json['pendingPayouts'] as num?)?.toInt() ?? 0,
      );
}

/// Akun pegawai atau kurir milik Kopdes (`/admin/staff`).
class StaffAccount {
  final String id;
  final String name;
  final String email;
  final String? phone;

  /// `PEGAWAI_KOPDES` atau `COURIER`.
  final String role;

  /// Kosong = bawaan peran.
  final List<String> permissions;
  final List<String> effectivePermissions;

  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.permissions = const [],
    this.effectivePermissions = const [],
  });

  bool get isCourier => role == 'COURIER';

  factory StaffAccount.fromJson(Map<String, dynamic> j) => StaffAccount(
    id: j['id'] as String,
    name: j['name'] as String? ?? '',
    email: j['email'] as String? ?? '',
    phone: j['phone'] as String?,
    role: j['role'] as String? ?? 'PEGAWAI_KOPDES',
    permissions: (j['permissions'] as List? ?? const []).cast<String>(),
    effectivePermissions: (j['effectivePermissions'] as List? ?? const [])
        .cast<String>(),
  );
}

class PermissionInfo {
  final String key;
  final String label;
  final String group;
  final String description;

  const PermissionInfo(this.key, this.label, this.group, this.description);

  factory PermissionInfo.fromJson(Map<String, dynamic> j) => PermissionInfo(
    j['key'] as String,
    j['label'] as String? ?? j['key'] as String,
    j['group'] as String? ?? '',
    j['description'] as String? ?? '',
  );
}

/// Pengajuan Mitra UMKM milik akun ini (`/umkm-applications/me`).
class UmkmApplication {
  final String businessName;

  /// `UMKMStatus`.
  final String status;
  final String? rejectionReason;
  final String? kopdesName;

  const UmkmApplication({
    required this.businessName,
    required this.status,
    this.rejectionReason,
    this.kopdesName,
  });

  factory UmkmApplication.fromJson(Map<String, dynamic> j) => UmkmApplication(
    businessName: j['businessName'] as String? ?? '',
    status: j['status'] as String? ?? 'PENDING_VERIFICATION',
    rejectionReason: j['rejectionReason'] as String?,
    kopdesName: (j['kopdes'] as Map?)?['name'] as String?,
  );
}

class KopdesConsoleService {
  final Dio dio;
  KopdesConsoleService(this.dio);

  dynamic _data(Response res) => (res.data as Map<String, dynamic>)['data'];

  Future<KopdesDashboard> dashboard() async => KopdesDashboard.fromJson(
    _data(await dio.get('/admin/kopdes/dashboard')) as Map<String, dynamic>,
  );

  Future<List<StaffAccount>> staff() async =>
      (_data(await dio.get('/admin/staff')) as List)
          .cast<Map<String, dynamic>>()
          .map(StaffAccount.fromJson)
          .toList();

  Future<List<PermissionInfo>> permissionCatalog() async {
    final d = _data(await dio.get('/admin/staff/permissions')) as Map;
    final assignable = (d['assignable'] as List).cast<String>().toSet();
    return (d['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(PermissionInfo.fromJson)
        .where((p) => assignable.contains(p.key))
        .toList();
  }

  Future<void> createStaff(Map<String, dynamic> body) =>
      dio.post('/admin/staff', data: body);

  Future<void> updateStaff(String id, Map<String, dynamic> body) =>
      dio.patch('/admin/staff/$id', data: body);

  Future<void> deleteStaff(String id) => dio.delete('/admin/staff/$id');

  Future<UmkmApplication?> myApplication() async {
    final d = _data(await dio.get('/umkm-applications/me'));
    return d == null
        ? null
        : UmkmApplication.fromJson(d as Map<String, dynamic>);
  }

  Future<void> applyUmkm(Map<String, dynamic> body) =>
      dio.post('/umkm-applications', data: body);
}

final kopdesConsoleServiceProvider = Provider<KopdesConsoleService>(
  (ref) => KopdesConsoleService(ref.watch(dioProvider)),
);

final kopdesDashboardProvider = FutureProvider<KopdesDashboard>(
  (ref) => ref.watch(kopdesConsoleServiceProvider).dashboard(),
);

final staffAccountsProvider = FutureProvider.autoDispose<List<StaffAccount>>(
  (ref) => ref.watch(kopdesConsoleServiceProvider).staff(),
);

final permissionCatalogProvider =
    FutureProvider.autoDispose<List<PermissionInfo>>(
      (ref) => ref.watch(kopdesConsoleServiceProvider).permissionCatalog(),
    );

final myUmkmApplicationProvider = FutureProvider.autoDispose<UmkmApplication?>(
  (ref) => ref.watch(kopdesConsoleServiceProvider).myApplication(),
);
