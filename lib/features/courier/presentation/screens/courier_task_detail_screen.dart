import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/chat_launcher.dart';
import '../../../delivery/presentation/widgets/delivery_map.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_models.dart';
import '../../data/courier_repository.dart';
import '../../data/courier_tracking.dart';
import '../widgets/courier_ui.dart';

/// Rincian satu tugas pengantaran: peta, isi paket, kontak, dan tombol
/// yang menggerakkan statusnya.
class CourierTaskDetailScreen extends ConsumerWidget {
  final String deliveryId;

  const CourierTaskDetailScreen({super.key, required this.deliveryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(courierTaskProvider(deliveryId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: async.valueOrNull == null
                ? 'Tugas Pengantaran'
                : '#${async.valueOrNull!.shortCode}',
            subtitle: async.valueOrNull?.destination.recipientName,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(courierTaskProvider(deliveryId));
                try {
                  await ref.read(courierTaskProvider(deliveryId).future);
                } catch (_) {}
              },
              child: async.when(
                skipLoadingOnRefresh: true,
                loading: () => const StoreSubpageBody(
                  children: [
                    SectionSkeleton(height: 220),
                    SizedBox(height: AppSpacing.md),
                    SectionSkeleton(height: 160),
                  ],
                ),
                error: (e, _) => StoreSubpageBody(
                  children: [
                    SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () =>
                          ref.invalidate(courierTaskProvider(deliveryId)),
                    ),
                  ],
                ),
                data: (task) => _Body(task: task),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final CourierTask task;
  const _Body({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(courierPositionProvider);
    final dest = task.destination;
    final tracking = ref.watch(courierTrackingProvider);

    final points = <MapPoint>[
      if (me != null)
        MapPoint(
          latitude: me.lat,
          longitude: me.lng,
          icon: Icons.two_wheeler_rounded,
          tint: const Color(0xFF2F6FDB),
          label: 'Posisi Anda',
        ),
      for (final p in task.pickups)
        if (p.hasPoint)
          MapPoint(
            latitude: p.latitude!,
            longitude: p.longitude!,
            icon: Icons.storefront_rounded,
            tint: AppColors.warning,
            label: 'Ambil di ${p.name}',
          ),
      if (dest.hasPoint)
        MapPoint(
          latitude: dest.latitude!,
          longitude: dest.longitude!,
          icon: Icons.home_rounded,
          tint: AppColors.primary,
          label: 'Tujuan: ${dest.recipientName}',
        ),
    ];

    return StoreSubpageBody(
      children: [
        if (points.isNotEmpty) ...[
          DeliveryMap(points: points),
          const SizedBox(height: AppSpacing.xs),
          Text(
            dest.hasPoint
                ? 'Garis lurus, bukan jarak berkendara. Ketuk Navigasi untuk rute jalan.'
                : 'Pembeli belum menyimpan titik rumahnya — ikuti alamat tertulis.',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Keadaan tugas, dan kejujuran soal siaran posisi.
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  taskStagePill(task.stage),
                  if (task.isCod) CodBadge(amount: task.codAmount),
                ],
              ),
              if (task.stage.carrying) ...[
                const SizedBox(height: AppSpacing.md),
                _BroadcastNote(state: tracking),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Ambil barang.
        const StoreSectionHeader('Ambil barang'),
        for (final p in task.pickups) ...[
          _PlaceCard(
            icon: p.isKopdes
                ? Icons.store_mall_directory_rounded
                : Icons.storefront_rounded,
            title: p.name,
            address: p.address,
            phone: p.phone,
            latitude: p.latitude,
            longitude: p.longitude,
            from: me,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),

        // Antar ke.
        const StoreSectionHeader('Antar ke'),
        _PlaceCard(
          icon: Icons.home_rounded,
          title: '${dest.recipientName} · ${dest.title}',
          address: dest.fullAddress,
          phone: dest.phone ?? task.customerPhone,
          latitude: dest.latitude,
          longitude: dest.longitude,
          from: me,
          onChat: () => openChatWith(
            context,
            ref,
            task.customerId,
            task.customerName,
            channel: ChatChannel.delivery,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Isi paket — supaya kurir tahu yang dibawanya benar.
        const StoreSectionHeader('Isi paket'),
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in task.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${item.quantity}×',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.variantName == null
                              ? item.name
                              : '${item.name} (${item.variantName})',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13.5,
                            color: AppColors.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(
                height: AppSpacing.lg,
                color: AppColors.hairlineSoft,
              ),
              _MoneyRow(
                label: task.isCod
                    ? 'Tagih ke pembeli'
                    : 'Nilai pesanan (sudah dibayar)',
                value: formatRupiah(
                  task.isCod ? task.codAmount : task.totalAmount,
                ),
                strong: task.isCod,
              ),
              if (!task.isCod)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Jangan menagih apa pun. Pesanan ini sudah lunas.',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12,
                      color: AppColors.successText,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Jejak waktu — log pengiriman tugas ini.
        const StoreSectionHeader('Riwayat tugas'),
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Step('Pesanan dibuat', task.createdAt, done: true),
              _Step('Tugas diambil', task.acceptedAt),
              _Step('Barang diambil dari toko', task.pickedUpAt),
              _Step('Ditandai sudah diantar', task.deliveredAt),
              _Step('Dikonfirmasi pembeli', task.confirmedAt, last: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        _Actions(task: task),
      ],
    );
  }
}

/// Memberi tahu kurir apakah posisinya benar-benar sedang terkirim.
class _BroadcastNote extends StatelessWidget {
  final TrackingState state;
  const _BroadcastNote({required this.state});

  @override
  Widget build(BuildContext context) {
    final problem = state.problem;
    final ok = state.isBroadcasting;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ok ? Icons.podcasts_rounded : Icons.location_off_outlined,
          size: 17,
          color: ok ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            problem ??
                (ok
                    ? 'Posisi Anda terkirim ke pembeli selama aplikasi terbuka. '
                          'Menutup aplikasi menghentikannya.'
                    : 'Menyiapkan pengiriman posisi…'),
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              color: problem == null ? AppColors.body : AppColors.warningText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu tempat: alamat, jarak, tombol telepon, navigasi, dan chat.
class _PlaceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final ({double lat, double lng})? from;
  final VoidCallback? onChat;

  const _PlaceCard({
    required this.icon,
    required this.title,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.from,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final hasPoint = latitude != null && longitude != null;
    final distance = (from != null && hasPoint)
        ? straightLineDistance(from!.lat, from!.lng, latitude!, longitude!)
        : null;

    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(icon, tint: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      distance == null ? address : '$address · $distance',
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Membungkus, bukan mengecil: tiga tombol pada layar 320 dp dengan
          // teks 2× tidak muat sebaris, dan area sentuh tidak boleh dikorbankan.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (hasPoint)
                _MiniAction(
                  icon: Icons.navigation_rounded,
                  label: 'Navigasi',
                  onTap: () => openDirections(latitude!, longitude!),
                ),
              if (phone != null && phone!.isNotEmpty)
                _MiniAction(
                  icon: Icons.call_rounded,
                  label: 'Telepon',
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                ),
              if (onChat != null)
                _MiniAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Pesan',
                  onTap: onChat!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 17),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(44, 44),
      foregroundColor: AppColors.primaryText,
      side: const BorderSide(color: AppColors.hairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),
  );
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _MoneyRow({
    required this.label,
    required this.value,
    required this.strong,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 13.5,
            color: AppColors.body,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        value,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w800,
          color: strong ? AppColors.warningText : AppColors.ink,
        ),
      ),
    ],
  );
}

/// Satu baris jejak waktu. Yang belum terjadi ditulis "belum", bukan
/// dikosongkan — baris kosong terbaca seperti data yang hilang.
class _Step extends StatelessWidget {
  final String label;
  final DateTime? at;
  final bool done;
  final bool last;

  const _Step(this.label, this.at, {this.done = false, this.last = false});

  @override
  Widget build(BuildContext context) {
    final reached = done || at != null;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            reached
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: reached ? AppColors.success : AppColors.mutedSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Waktu ditaruh di bawah labelnya, bukan di sebelahnya: pada skala
          // teks 2× keduanya tidak muat sebaris di layar 320 dp, dan
          // mengecilkan hurufnya bukan pilihan.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    color: reached ? AppColors.ink : AppColors.muted,
                  ),
                ),
                Text(
                  at == null ? 'Belum' : dateTimeId(at!),
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol yang menggerakkan status tugas.
class _Actions extends ConsumerWidget {
  final CourierTask task;
  const _Actions({required this.task});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref, {
    required String waiting,
    required Future<void> Function() action,
    required String successTitle,
    String? successMessage,
  }) async {
    final ok = await runWithFeedback(
      context,
      waiting: waiting,
      action: () async {
        await action();
        return true;
      },
      successTitle: successTitle,
      successMessage: successMessage,
    );
    if (!ok) return;
    refreshCourier(ref);
    ref.invalidate(courierTaskProvider(task.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(courierServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        switch (task.stage) {
          TaskStage.assigned => TaskActionButton(
            icon: Icons.check_rounded,
            label: 'Terima Tugas',
            onPressed: () => _run(
              context,
              ref,
              waiting: 'Menerima tugas…',
              action: () => service.accept(task.id),
              successTitle: 'Tugas Diterima',
              successMessage: 'Ambil barangnya di toko, lalu tandai di sini.',
            ),
          ),
          TaskStage.accepted => TaskActionButton(
            icon: Icons.inventory_2_rounded,
            label: 'Barang Sudah Diambil',
            onPressed: () => _run(
              context,
              ref,
              waiting: 'Menandai barang diambil…',
              action: () => service.pickUp(task.id),
              successTitle: 'Barang Diambil',
              successMessage:
                  'Pembeli kini melihat pesanannya dalam pengiriman.',
            ),
          ),
          TaskStage.pickedUp || TaskStage.inTransit => TaskActionButton(
            icon: Icons.task_alt_rounded,
            label: 'Barang Sudah Diantar',
            onPressed: () => _confirmDelivered(context, ref),
          ),
          _ => const _DoneNote(),
        },
        if (!task.stage.isDone && !task.stage.carrying) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _confirmRelease(context, ref),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Lepas Tugas Ini'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.errorText,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  /// Menandai sudah diantar adalah langkah yang tidak bisa ditarik kembali,
  /// jadi ia selalu lewat satu pertanyaan — terutama untuk COD, yang berarti
  /// uangnya sudah diterima.
  Future<void> _confirmDelivered(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barang sudah diterima pembeli?'),
        content: Text(
          task.isCod
              ? 'Pastikan Anda sudah menerima uang '
                    '${formatRupiah(task.codAmount)} dari '
                    '${task.destination.recipientName}.'
              : 'Pesanan ini sudah dibayar. Jangan menagih apa pun.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Belum'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sudah, Tandai Selesai'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;

    // Posisi kurir ikut dikirim sebagai bukti. GPS yang mati tidak menahan
    // penandaan: kurir di depan pintu tidak boleh terjebak dengan pesanan
    // yang tidak bisa diselesaikan.
    Position? at;
    try {
      at = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      at = null;
    }
    if (!context.mounted) return;

    await _run(
      context,
      ref,
      waiting: 'Menandai sudah diantar…',
      action: () => ref
          .read(courierServiceProvider)
          .markDelivered(task.id, lat: at?.latitude, lng: at?.longitude),
      successTitle: 'Ditandai Sudah Diantar',
      successMessage:
          'Menunggu pembeli menekan "Barang Sudah Diterima" di aplikasinya.',
    );
  }

  Future<void> _confirmRelease(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lepas tugas ini?'),
        content: const Text(
          'Tugas kembali ke daftar tersedia dan bisa diambil kurir lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorText),
            child: const Text('Lepas'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    await _run(
      context,
      ref,
      waiting: 'Melepas tugas…',
      action: () => ref.read(courierServiceProvider).release(task.id),
      successTitle: 'Tugas Dilepas',
    );
    if (context.mounted) context.pop();
  }
}

class _DoneNote extends StatelessWidget {
  const _DoneNote();

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Tugas ini sudah selesai dari sisi Anda.',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.body,
            ),
          ),
        ),
      ],
    ),
  );
}
