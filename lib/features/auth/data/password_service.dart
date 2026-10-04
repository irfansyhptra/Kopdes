import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../presentation/providers/auth_provider.dart';

/// Mengganti kata sandi akun yang sedang masuk.
///
/// Server mencabut semua sesi lain dan mengirim token baru untuk perangkat
/// ini; token itu disimpan supaya pengguna tidak terlempar ke layar masuk.
Future<void> changePassword(
  WidgetRef ref, {
  required String currentPassword,
  required String newPassword,
}) async {
  final response = await ref
      .read(dioProvider)
      .put(
        '/auth/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
  final data =
      (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  await ref
      .read(authLocalDataSourceProvider)
      .saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
}
