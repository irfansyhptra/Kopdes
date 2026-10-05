import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../courier/data/courier_models.dart';
import '../../../umkm/presentation/widgets/seller_page_ui.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/tracking_repository.dart';
import '../widgets/delivery_map.dart';

/// Lacak Pesanan — peta posisi kurir dan tujuan, untuk pemesan.
///
/// Dulu halaman ini menggambar peta palsu dengan `CustomPaint` dan dua
/// penanda yang tidak berhubungan dengan pesanan mana pun. Sekarang isinya
/// titik yang benar-benar dikirim kurir; bila ia belum mengirim satu pun,
/// halaman mengatakannya apa adanya alih-alih menampilkan peta karangan.
class TrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(trackingPollInterval, (_) {
      if (!mounted) return;
      // Berhenti menyegarkan begitu tidak ada lagi yang berubah: pengantaran
      // yang sudah selesai tidak akan bergerak lagi.
      final t = ref.read(orderTrackingProvider(widget.orderId)).valueOrNull;
      if (t != null && !t.isMoving) return;
      ref.invalidate(orderTrackingProvider(widget.orderId));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderTrackingProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerSubpageHeader(
            title: 'Lacak Pesanan',
            subtitle: async.valueOrNull?.courierName == null
                ? null
                : 'Kurir ${async.valueOrNull!.courierName}',
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/orders/history'),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(orderTrackingProvider(widget.orderId));
                try {
                  await ref.read(orderTrackingProvider(widget.orderId).future);
                } catch (_) {}
              },
              child: async.when(
                skipLoadingOnRefresh: true,
                loading: () => const StoreSubpageBody(
                  children: [
                    SectionSkeleton(height: 240),
                    SizedBox(height: AppSpacing.md),
                    SectionSkeleton(height: 140),
                  ],
                ),
                error: (e, _) => StoreSubpageBody(
                  children: [
                    SectionError(
                      message: networkErrorMessage(e),
                      onRetry: () => ref.invalidate(
                        orderTrackingProvider(widget.orderId),
                      ),
                    ),
                  ],
                ),
                data: (t) => _Body(tracking: t),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OrderTracking tracking;
  const _Body({required this.tracking});

  @override
  Widget build(BuildContext context) {
    final stage = TaskStage.of(tracking.status);
    final points = <MapPoint>[
      if (tracking.hasCourierPoint)
        MapPoint(
          latitude: tracking.courierLat!,
          longitude: tracking.courierLng!,
          icon: Icons.two_wheeler_rounded,
          tint: const Color(0xFF2F6FDB),
          label: 'Posisi kurir',
        ),
      if (tracking.hasDestinationPoint)
        MapPoint(
          latitude: tracking.destinationLat!,
          longitude: tracking.destinationLng!,
          icon: Icons.home_rounded,
          tint: AppColors.primary,
          label: 'Alamat Anda',
        ),
    ];

    final distance =
        (tracking.hasCourierPoint && tracking.hasDestinationPoint)
        ? straightLineDistance(
            tracking.courierLat!,
            tracking.courierLng!,
            tracking.destinationLat!,
            tracking.destinationLng!,
          )
        : null;

    return StoreSubpageBody(
      children: [
        if (points.isNotEmpty)
          DeliveryMap(points: points, height: 240)
        else
          StoreSurface(
            child: Row(
              children: [
                const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    stage.carrying
                        ? 'Kurir belum mengirim posisinya. Peta muncul begitu '
                              'titik pertamanya masuk.'
                        : 'Peta muncul setelah kurir mengambil barang Anda.',
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),

        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusPill(
                icon: stage.icon,
                label: stage.label,
                tint: stage.tint,
                text: stage.textTint,
              ),
              if (distance != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sekitar $distance dari alamat Anda — garis lurus, bukan '
                  'jarak jalan.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    color: AppColors.body,
                  ),
                ),
              ],
              if (tracking.courierSeenAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Posisi terakhir ${dateTimeId(tracking.courierSeenAt!)}.',
                  style: AppTypography.captionSmall.copyWith(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const StoreSectionHeader('Kurir'),
        StoreSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconTile(
                Icons.two_wheeler_rounded,
                tint: Color(0xFF2F6FDB),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tracking.courierName ?? 'Belum ada kurir',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      tracking.courierName == null
                          ? 'Pesanan menunggu diambil kurir Kopdes.'
                          : (tracking.courierPhone ?? 'Nomor tidak tersedia'),
                      style: AppTypography.captionSmall.copyWith(
                        fontSize: 12.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (tracking.courierPhone != null &&
                  tracking.courierPhone!.isNotEmpty)
                IconButton(
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  tooltip: 'Telepon kurir',
                  onPressed: () =>
                      launchUrl(Uri.parse('tel:${tracking.courierPhone}')),
                  icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const StoreSectionHeader('Tujuan'),
        StoreSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tracking.destinationLabel.isEmpty
                    ? 'Alamat pengiriman'
                    : tracking.destinationLabel,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tracking.destinationAddress,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        OutlinedButton.icon(
          onPressed: () => context.push('/orders/${tracking.orderId}'),
          icon: const Icon(Icons.receipt_long_outlined, size: 18),
          label: const Text('Lihat Detail Pesanan'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
