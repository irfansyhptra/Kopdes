import 'package:flutter/material.dart';
import 'package:kopdes/core/theme/theme.dart';

class OrderTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statusSteps = [
      {
        'status': 'PENDING',
        'label': 'Menunggu Pembayaran',
        'desc': 'Pesanan telah dibuat dan menunggu pembayaran Anda.',
      },
      {
        'status': 'PAID',
        'label': 'Pembayaran Berhasil',
        'desc': 'Pembayaran terkonfirmasi. Toko sedang menyiapkan barang.',
      },
      {
        'status': 'PROCESSING',
        'label': 'Diproses',
        'desc': 'Pesanan Anda sedang dipersiapkan dan dikemas.',
      },
      {
        'status': 'READY_FOR_DELIVERY',
        'label': 'Siap Dikirim',
        'desc': 'Paket siap diserahkan ke kurir koperasi.',
      },
      {
        'status': 'OUT_FOR_DELIVERY',
        'label': 'Dalam Pengiriman',
        'desc': 'Kurir sedang membawa paket menuju alamat Anda.',
      },
      {
        'status': 'DELIVERED',
        'label': 'Terkirim',
        'desc': 'Pesanan Anda telah sampai di alamat tujuan.',
      },
      {
        'status': 'COMPLETED',
        'label': 'Selesai',
        'desc': 'Transaksi selesai. Terima kasih telah berbelanja!',
      },
    ];

    int currentIndex = statusSteps.indexWhere(
      (step) => step['status'] == currentStatus,
    );
    if (currentIndex == -1) {
      if (currentStatus == 'CANCELLED') {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.error.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel_rounded, color: AppColors.error),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Pesanan Dibatalkan',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.errorText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }
      currentIndex = 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Pengiriman',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statusSteps.length,
          itemBuilder: (context, index) {
            final step = statusSteps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == statusSteps.length - 1;

            final color = isCompleted
                ? (isCurrent ? AppColors.primary : AppColors.success)
                : AppColors.mutedSoft;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon column with lines
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCurrent ? color : AppColors.canvas,
                        border: Border.all(color: color, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCurrent
                            ? const Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.canvas,
                              )
                            : (isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 10,
                                      color: AppColors.success,
                                    )
                                  : null),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 38,
                        color: isCompleted && index < currentIndex
                            ? AppColors.success
                            : AppColors.hairlineSoft,
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.base),
                // Text detail column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['label']!,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                    ? AppColors.success
                                    : AppColors.muted),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 4),
                        Text(
                          step['desc']!,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
