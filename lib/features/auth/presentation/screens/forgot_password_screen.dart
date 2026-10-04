import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';

/// Lupa kata sandi.
///
/// Backend belum punya pengaturan ulang lewat email. Versi sebelumnya
/// menunggu 1,5 detik lalu menulis "tautan pemulihan telah dikirim" tanpa
/// mengirim apa pun — orang menunggu email yang tidak pernah datang. Sampai
/// fiturnya ada, layar ini menyebut jalan yang benar-benar bisa ditempuh.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Lupa Kata Sandi?',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pengaturan ulang kata sandi lewat email belum tersedia di '
              'aplikasi. Hubungi pengurus Kopdes desa Anda dengan menyebut '
              'email akun Anda; pengurus meneruskannya ke pengelola sistem '
              'KOMIT, yang dapat mengatur kata sandi baru.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Kembali ke Halaman Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
