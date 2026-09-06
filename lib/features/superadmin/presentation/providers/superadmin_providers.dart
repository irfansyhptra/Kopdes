import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/error_message.dart';
import '../../data/superadmin_service.dart';
import '../../data/superadmin_models.dart';

final superAdminServiceProvider = Provider<SuperAdminService>(
  (ref) => SuperAdminService(dio: ref.watch(dioProvider)),
);

final overviewProvider = FutureProvider<Overview>((ref) async {
  return ref.watch(superAdminServiceProvider).getOverview();
});

final staffProvider = FutureProvider<List<AppUser>>((ref) async {
  return ref.watch(superAdminServiceProvider).getStaff();
});

// Filter peran untuk direktori pengguna (null = semua).
final userRoleFilterProvider = StateProvider<String?>((ref) => null);

final usersProvider = FutureProvider<List<AppUser>>((ref) async {
  final role = ref.watch(userRoleFilterProvider);
  return ref.watch(superAdminServiceProvider).getUsers(role: role);
});

class SuperAdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  SuperAdminActionNotifier(this._ref) : super(const AsyncData(null));
  final Ref _ref;

  Future<bool> createStaff({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref
          .read(superAdminServiceProvider)
          .createStaff(
            email: email,
            password: password,
            name: name,
            phone: phone,
            role: role,
          );
      _ref.invalidate(staffProvider);
      _ref.invalidate(overviewProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteStaff(String id) async {
    state = const AsyncLoading();
    try {
      await _ref.read(superAdminServiceProvider).deleteStaff(id);
      _ref.invalidate(staffProvider);
      _ref.invalidate(overviewProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Ambil pesan error backend (mis. email sudah terdaftar) jika ada.
  String errorMessage(Object error) {
    return extractDioMessage(error);
  }
}

final superAdminActionProvider =
    StateNotifierProvider<SuperAdminActionNotifier, AsyncValue<void>>(
      (ref) => SuperAdminActionNotifier(ref),
    );
