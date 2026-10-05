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

  Future<MitraIncomePage> mitraIncome({int page = 1}) async {
    final d =
        _data(
              await dio.get(
                '/admin/kopdes/mitra-income',
                queryParameters: {'page': page, 'limit': 20},
              ),
            )
            as Map<String, dynamic>;
    final meta = (d['meta'] as Map<String, dynamic>?) ?? const {};
    return MitraIncomePage(
      entries: ((d['entries'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(MitraIncomeEntry.fromJson)
          .toList(),
      summary: MitraIncomeSummary.fromJson(
        (d['summary'] as Map<String, dynamic>?) ?? const {},
      ),
      page: (meta['page'] as num?)?.toInt() ?? 1,
      totalPages: (meta['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

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

/// Satu baris catatan uang masuk dari barang mitra yang laku.
///
/// Sengaja tidak memuat pembeli, alamat, maupun nomor pesanan: pesanan
/// mitra bukan urusan pengurus, hanya fee-nya yang menjadi hak koperasi.
class MitraIncomeEntry {
  final String id;
  final DateTime soldAt;
  final String umkmName;
  final String productName;
  final String? variantName;
  final int quantity;
  final double gross;
  final double fee;

  const MitraIncomeEntry({
    required this.id,
    required this.soldAt,
    required this.umkmName,
    required this.productName,
    required this.quantity,
    required this.gross,
    required this.fee,
    this.variantName,
  });

  factory MitraIncomeEntry.fromJson(Map<String, dynamic> j) => MitraIncomeEntry(
    id: j['id'] as String? ?? '',
    soldAt: DateTime.tryParse('${j['soldAt']}')?.toLocal() ?? DateTime.now(),
    umkmName: j['umkmName'] as String? ?? 'Mitra UMKM',
    productName: j['productName'] as String? ?? 'Barang mitra',
    variantName: j['variantName'] as String?,
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
    gross: (j['gross'] as num?)?.toDouble() ?? 0,
    fee: (j['fee'] as num?)?.toDouble() ?? 0,
  );
}

/// Ringkasan fee yang sudah menjadi hak koperasi.
class MitraIncomeSummary {
  final int feePercent;
  final int itemsSold;
  final double grossAllTime;
  final double feeAllTime;
  final double grossThisMonth;
  final double feeThisMonth;

  const MitraIncomeSummary({
    required this.feePercent,
    required this.itemsSold,
    required this.grossAllTime,
    required this.feeAllTime,
    required this.grossThisMonth,
    required this.feeThisMonth,
  });

  factory MitraIncomeSummary.fromJson(Map<String, dynamic> j) =>
      MitraIncomeSummary(
        feePercent: (j['feePercent'] as num?)?.toInt() ?? 0,
        itemsSold: (j['itemsSold'] as num?)?.toInt() ?? 0,
        grossAllTime: (j['grossAllTime'] as num?)?.toDouble() ?? 0,
        feeAllTime: (j['feeAllTime'] as num?)?.toDouble() ?? 0,
        grossThisMonth: (j['grossThisMonth'] as num?)?.toDouble() ?? 0,
        feeThisMonth: (j['feeThisMonth'] as num?)?.toDouble() ?? 0,
      );
}

class MitraIncomePage {
  final List<MitraIncomeEntry> entries;
  final MitraIncomeSummary summary;
  final int page;
  final int totalPages;

  const MitraIncomePage({
    required this.entries,
    required this.summary,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;
}

/// Catatan uang masuk dari mitra, bertahap per halaman.
class MitraIncomeNotifier extends StateNotifier<AsyncValue<MitraIncomePage>> {
  final KopdesConsoleService _service;
  bool _loadingMore = false;

  MitraIncomeNotifier(this._service) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = await AsyncValue.guard(() => _service.mitraIncome());
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await _service.mitraIncome(page: current.page + 1);
      state = AsyncData(
        MitraIncomePage(
          entries: [...current.entries, ...next.entries],
          summary: next.summary,
          page: next.page,
          totalPages: next.totalPages,
        ),
      );
    } catch (_) {
      // Halaman berikutnya gagal: yang sudah tampil dibiarkan.
    } finally {
      _loadingMore = false;
    }
  }
}

final mitraIncomeProvider =
    StateNotifierProvider.autoDispose<
      MitraIncomeNotifier,
      AsyncValue<MitraIncomePage>
    >((ref) => MitraIncomeNotifier(ref.watch(kopdesConsoleServiceProvider)));
