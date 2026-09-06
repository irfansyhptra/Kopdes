import 'package:dio/dio.dart';
import 'superadmin_models.dart';

// Klien HTTP fitur Super Admin. Envelope backend: { success, data }.
class SuperAdminService {
  final Dio dio;
  SuperAdminService({required this.dio});

  List<Map<String, dynamic>> _list(Response res) {
    final data = (res.data as Map<String, dynamic>)['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<Overview> getOverview() async {
    final res = await dio.get('/super-admin/overview');
    return Overview.fromJson(
      (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>,
    );
  }

  // ── Akun staf Kopdes ──
  Future<List<AppUser>> getStaff() async {
    final res = await dio.get('/super-admin/accounts');
    return _list(res).map(AppUser.fromJson).toList();
  }

  Future<void> createStaff({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    await dio.post(
      '/super-admin/accounts',
      data: {
        'email': email,
        'password': password,
        'name': name,
        if (phone.isNotEmpty) 'phone': phone,
        'role': role,
      },
    );
  }

  Future<void> deleteStaff(String id) async {
    await dio.delete('/super-admin/accounts/$id');
  }

  // ── Direktori pengguna ──
  Future<List<AppUser>> getUsers({String? role, String? search}) async {
    final res = await dio.get(
      '/super-admin/users',
      queryParameters: {
        if (role != null) 'role': role,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _list(res).map(AppUser.fromJson).toList();
  }
}
