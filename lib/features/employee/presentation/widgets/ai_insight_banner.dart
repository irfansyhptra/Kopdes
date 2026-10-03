import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';

/// Banner AI Assistant Kopdes.
///
/// Insight yang ditampilkan diambil dari ringkasan stok yang sudah dimuat —
/// bukan dari panggilan LLM tersendiri. Menghitung "7 produk perlu direstok"
/// tidak membutuhkan model bahasa, dan memanggil AI hanya untuk mengisi satu
/// baris banner berarti membayar latensi model di jalur pemuatan dashboard.
/// Analisis yang sesungguhnya baru dijalankan setelah banner ditekan.
class KopdesAiInsightBanner extends ConsumerWidget {
  const KopdesAiInsightBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(hasPermissionProvider(Permissions.aiAssist));
    if (!allowed) return const SizedBox.shrink();

    final stock = ref.watch(stockSummaryProvider);
    final insight = stock.when(
      loading: () => 'Menyiapkan ringkasan operasional…',
      error: (_, _) => 'Ringkasan operasional belum tersedia',
      data: (data) {
        if (data.outOfStock > 0) {
          return '${data.outOfStock} produk habis dan '
              '${data.lowStock} perlu segera direstok';
        }
        if (data.lowStock > 0) {
          return '${data.lowStock} produk perlu segera direstok';
        }
        return 'Stok aman — tanyakan prioritas pesanan hari ini';
      },
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
        horizontal: KopdesSpacing.base,
        vertical: KopdesSpacing.md,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEF0),
        borderRadius: BorderRadius.circular(KopdesRadii.surface),
        border: Border.all(color: const Color(0x22D7192D)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KopdesEmployeeColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: KopdesEmployeeColors.primary,
            ),
          ),
          const SizedBox(width: KopdesSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant Kopdes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: KopdesEmployeeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: KopdesEmployeeColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KopdesSpacing.sm),
          FilledButton(
            onPressed: () => context.push('/pegawai/ai'),
            style: FilledButton.styleFrom(
              backgroundColor: KopdesEmployeeColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: KopdesSpacing.md,
                vertical: 10,
              ),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KopdesRadii.pill),
              ),
            ),
            child: const Text(
              'Lihat Analisis',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
