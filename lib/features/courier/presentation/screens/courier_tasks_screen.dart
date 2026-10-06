import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_models.dart';
import '../../data/courier_repository.dart';
import '../widgets/courier_ui.dart';

/// Tab Tugas: dua daftar yang dipisah tegas.
///
/// "Tersedia" adalah kumpulan terbuka milik Kopdes — siapa pun yang menekan
/// lebih dulu yang mendapat. "Tugas Saya" adalah yang sudah di tangan.
/// Mencampur keduanya dalam satu daftar membuat kurir tidak tahu mana yang
/// sudah jadi tanggung jawabnya.
class CourierTasksScreen extends ConsumerWidget {
  const CourierTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableTasksProvider);
    final mine = ref.watch(myTasksProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surfaceSoft,
        body: SellerPageChrome(
          title: 'Tugas Pengantaran',
          subtitle: 'Ambil tugas sendiri, tanpa menunggu pengurus',
          headerChild: const TabBar(
            labelColor: AppColors.onPrimary,
            unselectedLabelColor: Color(0xCCFFFFFF),
            indicatorColor: AppColors.onPrimary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Tersedia'),
              Tab(text: 'Tugas Saya'),
            ],
          ),
          body: TabBarView(
            children: [
              _TaskList(
                async: available,
                emptyTitle: 'Belum ada tugas yang bisa diambil',
                emptyBody:
                    'Tugas muncul di sini setelah UMKM mengajukan kebutuhan '
                    'pengantaran. Tarik layar ke bawah untuk memeriksa lagi.',
                onRefresh: () => ref.invalidate(availableTasksProvider),
                actionFor: (task) => _ClaimButton(task: task),
              ),
              _TaskList(
                async: mine,
                emptyTitle: 'Anda belum memegang tugas',
                emptyBody:
                    'Buka tab Tersedia dan ambil satu tugas untuk memulai.',
                onRefresh: () => ref.invalidate(myTasksProvider),
                actionFor: (task) => _MineButton(task: task),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final AsyncValue<List<CourierTask>> async;
  final String emptyTitle;
  final String emptyBody;
  final VoidCallback onRefresh;
  final Widget Function(CourierTask) actionFor;

  const _TaskList({
    required this.async,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onRefresh,
    required this.actionFor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh(),
      child: async.when(
        skipLoadingOnRefresh: true,
        loading: () => const StoreSubpageBody(
          children: [
            SectionSkeleton(height: 184),
            SizedBox(height: AppSpacing.md),
            SectionSkeleton(height: 184),
          ],
        ),
        error: (e, _) => StoreSubpageBody(
          children: [
            SectionError(message: networkErrorMessage(e), onRetry: onRefresh),
          ],
        ),
        data: (tasks) => tasks.isEmpty
            ? StoreSubpageBody(
                children: [
                  CourierEmptyState(title: emptyTitle, body: emptyBody),
                ],
              )
            : StoreSubpageBody(
                children: [
                  for (final task in tasks) ...[
                    CourierTaskCard(
                      task: task,
                      onTap: () => context.push('/courier/tugas/${task.id}'),
                      action: actionFor(task),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Mengambil tugas dari kumpulan terbuka.
class _ClaimButton extends ConsumerWidget {
  final CourierTask task;
  const _ClaimButton({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TaskActionButton(
    icon: Icons.pan_tool_alt_rounded,
    label: 'Ambil Tugas',
    onPressed: () async {
      final ok = await runWithFeedback(
        context,
        waiting: 'Mengambil tugas…',
        action: () async {
          await ref.read(courierServiceProvider).claim(task.id);
          return true;
        },
        successTitle: 'Tugas Diambil',
        successMessage:
            'Ambil barangnya di toko, lalu tandai di halaman tugas.',
      );
      refreshCourier(ref);
      if (ok && context.mounted) context.push('/courier/tugas/${task.id}');
    },
  );
}

/// Tombol lanjutan untuk tugas yang sudah dipegang.
class _MineButton extends ConsumerWidget {
  final CourierTask task;
  const _MineButton({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, icon) = switch (task.stage) {
      TaskStage.assigned => ('Terima Tugas', Icons.check_rounded),
      TaskStage.accepted => ('Buka & Ambil Barang', Icons.inventory_2_rounded),
      _ => ('Lanjutkan Pengantaran', Icons.navigation_rounded),
    };
    return TaskActionButton(
      icon: icon,
      label: label,
      onPressed: () => context.push('/courier/tugas/${task.id}'),
    );
  }
}

/// Daftar kosong yang menjelaskan sebabnya, bukan layar putih.
class CourierEmptyState extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const CourierEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Column(
      children: [
        Icon(icon, size: 34, color: AppColors.mutedSoft),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
