import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../data/models/store_model.dart';
import '../../data/payout_repository.dart';
import '../controllers/store_controller.dart';
import '../widgets/seller_page_ui.dart';
import '../widgets/store_page_ui.dart';
import '../widgets/withdraw_sheet.dart';

/// Rute halaman turunan Toko.
abstract final class StoreRoutes {
  static const edit = '/umkm/store/edit';
  static const settings = '/umkm/store/settings';
  static const bankAccount = '/umkm/store/bank-account';
  static const payouts = '/umkm/store/payouts';
  static const security = '/umkm/store/security';
  static const help = '/info/bantuan-penjual';
  static String publicStore(String id) => '/mitra/$id';
}

/// Tab "Toko": ringkasan identitas, saldo, profil usaha, dan menu kelola.
///
/// Halaman ini hanya meringkas. Isian ada di halaman turunannya, supaya
/// tidak ada kolom kosong yang tampak bisa diketik di sini.
class StoreProfileScreen extends ConsumerWidget {
  const StoreProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: SellerPageChrome(
        title: 'Toko Anda',
        subtitle: 'Profil, pencairan, dan pengaturan usaha',
        actions: [
          GlassIconButton(
            icon: Icons.edit_outlined,
            label: 'Edit profil toko',
            onDark: true,
            onTap: () => context.push(StoreRoutes.edit),
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(storeProfileProvider);
            ref.invalidate(payoutSummaryProvider);
            // Galat ditampilkan section-nya sendiri; di sini cukup menunggu.
            try {
              await ref.read(storeProfileProvider.future);
            } catch (_) {}
          },
          child: LayoutBuilder(
            builder: (context, c) {
              final side = math.max(0.0, (c.maxWidth - storePageMaxWidth) / 2);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.base + side,
                  AppSpacing.base,
                  AppSpacing.base + side,
                  // Bilah bawah mengambang di atas isi.
                  math.max(112.0, MediaQuery.paddingOf(context).bottom + 24),
                ),
                children: const [
                  _IdentitySection(),
                  SizedBox(height: AppSpacing.md),
                  _BalanceSection(),
                  SizedBox(height: AppSpacing.xl),
                  _ProfileSection(),
                  SizedBox(height: AppSpacing.xl),
                  _ManageSection(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. Identitas
// ─────────────────────────────────────────────────────────────

class _IdentitySection extends ConsumerWidget {
  const _IdentitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(storeProfileProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const SectionSkeleton(height: 132),
          error: (e, _) => SectionError(
            message: 'Profil toko belum termuat. ${networkErrorMessage(e)}',
            onRetry: () => ref.invalidate(storeProfileProvider),
          ),
          data: (store) => _IdentityCard(store: store),
        );
  }
}

class _IdentityCard extends StatelessWidget {
  final StoreModel store;
  const _IdentityCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final verification = verificationPill(store.status);
    final operational = switch (store.isOpen) {
      true => const StatusPill(
        icon: Icons.circle,
        label: 'Buka sekarang',
        tint: AppColors.success,
        text: AppColors.successText,
      ),
      false => const StatusPill(
        icon: Icons.nightlight_outlined,
        label: 'Sedang tutup',
        tint: AppColors.muted,
        text: AppColors.body,
      ),
      null => const StatusPill(
        icon: Icons.schedule_rounded,
        label: 'Jam buka belum diisi',
        tint: AppColors.muted,
        text: AppColors.body,
      ),
    };

    return StoreSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StoreLogo(photoUrl: store.photoUrl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.businessName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (store.kopdesName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Mitra ${store.kopdesName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [verification, operational],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (store.status == 'REJECTED' &&
              (store.rejectionReason?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Alasan: ${store.rejectionReason}',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.errorText,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: store.isVerified
                ? TextButton.icon(
                    onPressed: () =>
                        context.push(StoreRoutes.publicStore(store.id)),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      foregroundColor: AppColors.body,
                    ),
                    label: const Text('Lihat toko'),
                  )
                // Toko yang belum terverifikasi tidak tampil untuk pembeli:
                // tombolnya akan membuka halaman "tidak ditemukan".
                : Text(
                    'Toko tampil untuk pembeli setelah diverifikasi.',
                    textAlign: TextAlign.right,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Badge verifikasi dari `UMKMStatus` — "terverifikasi" hanya untuk ACTIVE.
StatusPill verificationPill(String status) => switch (status) {
  'ACTIVE' => const StatusPill(
    icon: Icons.verified_rounded,
    label: 'Toko terverifikasi',
    tint: AppColors.success,
    text: AppColors.successText,
  ),
  'REJECTED' => const StatusPill(
    icon: Icons.cancel_outlined,
    label: 'Verifikasi ditolak',
    tint: AppColors.error,
    text: AppColors.errorText,
  ),
  'SUSPENDED' => const StatusPill(
    icon: Icons.block_rounded,
    label: 'Toko ditangguhkan',
    tint: AppColors.error,
    text: AppColors.errorText,
  ),
  _ => const StatusPill(
    icon: Icons.hourglass_top_rounded,
    label: 'Menunggu verifikasi',
    tint: AppColors.warning,
    text: AppColors.warningText,
  ),
};

class _StoreLogo extends StatelessWidget {
  final String? photoUrl;
  const _StoreLogo({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: AppColors.primary,
        size: 30,
      ),
    );
    if (photoUrl == null || photoUrl!.isEmpty) {
      return ExcludeSemantics(child: placeholder);
    }
    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        semanticLabel: 'Logo toko',
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. Saldo
// ─────────────────────────────────────────────────────────────

class _BalanceSection extends ConsumerWidget {
  const _BalanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(payoutSummaryProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const SectionSkeleton(height: 168),
          // Gagal berarti TIDAK TAHU, bukan nol: "Rp0" terbaca seperti
          // uangnya habis.
          error: (e, _) => SectionError(
            message: 'Saldo belum termuat. ${networkErrorMessage(e)}',
            onRetry: () => ref.invalidate(payoutSummaryProvider),
          ),
          data: (s) => BalanceCard(
            summary: s,
            onHistory: () => context.push(StoreRoutes.payouts),
            onWithdraw: () => showWithdrawSheet(context, summary: s),
            onAddBankAccount: () => context.push(StoreRoutes.bankAccount),
          ),
        );
  }
}

class BalanceCard extends StatelessWidget {
  final PayoutSummary summary;
  final VoidCallback onHistory;
  final VoidCallback onWithdraw;
  final VoidCallback onAddBankAccount;

  const BalanceCard({
    super.key,
    required this.summary,
    required this.onHistory,
    required this.onWithdraw,
    required this.onAddBankAccount,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    // Alasan pertama yang paling bisa ditindaklanjuti ditampilkan sebagai
    // teks — tombol yang mati tanpa penjelasan membuat orang menekannya
    // berulang-ulang.
    final reason = s.canWithdraw ? null : s.blockers.firstOrNull;

    final withdraw = FilledButton(
      onPressed: s.canWithdraw ? onWithdraw : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 46),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primarySoft,
        disabledForegroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      child: const Text('Tarik saldo'),
    );

    final history = TextButton.icon(
      onPressed: onHistory,
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.chevron_right_rounded, size: 20),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.primaryText,
      ),
      label: const Text('Riwayat'),
    );

    return StoreSurface(
      child: LayoutBuilder(
        builder: (context, c) {
          // "Riwayat" di samping nominal selama muat; di layar sempit atau
          // teks besar ia turun ke bawah nominal, bukan menghimpitnya.
          final wide =
              c.maxWidth >= 340 * MediaQuery.textScalerOf(context).scale(1);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconTile(
                    Icons.account_balance_wallet_rounded,
                    tint: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      label: 'Saldo tersedia ${formatRupiah(s.available)}',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo tersedia',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            formatRupiah(s.available),
                            style: AppTypography.titleLarge.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (wide) history,
                ],
              ),
              if (!wide) Align(alignment: Alignment.centerLeft, child: history),
              const SizedBox(height: AppSpacing.md),
              _Breakdown(summary: s),
              const SizedBox(height: AppSpacing.md),
              Builder(
                builder: (context) {
                  final note = reason == null
                      ? Text(
                          'Minimal ${formatRupiah(s.minWithdrawal)} per penarikan.',
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 12.5,
                            color: AppColors.muted,
                          ),
                        )
                      : _BlockerNote(
                          blocker: reason,
                          available: s.available,
                          onAddBankAccount: onAddBankAccount,
                        );
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: note),
                            const SizedBox(width: AppSpacing.md),
                            withdraw,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [note, const SizedBox(height: 8), withdraw],
                        );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tertahan & pesanan berjalan — terpisah dari saldo yang bisa ditarik.
class _Breakdown extends StatelessWidget {
  final PayoutSummary summary;
  const _Breakdown({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final items = <(String, String, String)>[
      (
        'Tertahan',
        formatRupiah(s.held),
        'Sudah dibayar, menunggu pesanan selesai',
      ),
      (
        'Pesanan berjalan',
        '${s.openOrderCount} pesanan',
        s.openOrderCount == 0
            ? 'Tidak ada pesanan yang belum selesai'
            : 'Senilai ${formatRupiah(s.openOrderAmount)} setelah fee',
      ),
      if (s.pendingPayout > 0)
        (
          'Sedang dicairkan',
          formatRupiah(s.pendingPayout),
          'Menunggu transfer pengurus Kopdes',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppleRadii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            Semantics(
              label: '${items[i].$1} ${items[i].$2}. ${items[i].$3}',
              excludeSemantics: true,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppSpacing.sm,
                children: [
                  Text(
                    items[i].$1,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.body,
                    ),
                  ),
                  Text(
                    items[i].$2,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              items[i].$3,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Saldo tersedia dihitung dari pesanan selesai setelah fee Kopdes '
            '${s.feePercent.toStringAsFixed(0)}%.',
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockerNote extends StatelessWidget {
  final PayoutBlocker blocker;
  final double available;
  final VoidCallback onAddBankAccount;

  const _BlockerNote({
    required this.blocker,
    required this.available,
    required this.onAddBankAccount,
  });

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.captionSmall.copyWith(
      fontSize: 12.5,
      color: AppColors.body,
    );
    final text = blocker.code == 'BELOW_MINIMUM' && available == 0
        ? 'Belum ada saldo yang bisa ditarik. ${blocker.message}'
        : blocker.message;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: blocker.code == 'NO_BANK_ACCOUNT'
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(text, style: style),
                    TextButton(
                      onPressed: onAddBankAccount,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text('Isi rekening'),
                    ),
                  ],
                )
              : Text(text, style: style),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. Profil usaha
// ─────────────────────────────────────────────────────────────

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final header = StoreSectionHeader(
      'Profil usaha',
      subtitle: 'Informasi yang dilihat pembeli.',
      action: TextButton.icon(
        onPressed: () => context.push(StoreRoutes.edit),
        icon: const Icon(Icons.edit_outlined, size: 18),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: AppColors.primaryText,
          backgroundColor: AppColors.primaryTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        label: const Text('Edit'),
      ),
    );

    final body = ref
        .watch(storeProfileProvider)
        .when(
          skipLoadingOnRefresh: true,
          loading: () => const SectionSkeleton(height: 220),
          error: (e, _) => SectionError(
            message: 'Profil usaha belum termuat.',
            onRetry: () => ref.invalidate(storeProfileProvider),
          ),
          data: (store) {
            const empty = 'Lengkapi informasi';
            final contact = contactSummary(store);
            return StoreRowGroup(
              rows: [
                StoreRow(
                  icon: Icons.description_outlined,
                  title: 'Tentang toko',
                  value: store.description.trim().isEmpty
                      ? empty
                      : store.description.trim(),
                  placeholder: store.description.trim().isEmpty,
                  onTap: () => context.push(StoreRoutes.edit),
                ),
                StoreRow(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat toko',
                  value: store.address.trim().isEmpty
                      ? empty
                      : store.address.trim(),
                  placeholder: store.address.trim().isEmpty,
                  onTap: () => context.push(StoreRoutes.edit),
                ),
                StoreRow(
                  icon: Icons.phone_outlined,
                  title: 'Kontak & jam buka',
                  value: contact ?? empty,
                  placeholder: contact == null,
                  onTap: () => context.push(StoreRoutes.settings),
                ),
              ],
            );
          },
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, body],
    );
  }
}

/// "0813… · Buka 07.00–21.00 hari ini" — null bila keduanya kosong.
String? contactSummary(StoreModel store, {DateTime? now}) {
  final parts = <String>[];
  if (store.phone.trim().isNotEmpty) parts.add(store.phone.trim());
  final hours = store.operatingHours;
  if (hours != null) {
    final today = weekDays[((now ?? DateTime.now()).weekday - 1) % 7];
    final h = hours[today];
    parts.add(
      h == null
          ? 'Tutup hari ini'
          : 'Buka ${hhmm(h.open)}–${hhmm(h.close)} hari ini',
    );
  }
  return parts.isEmpty ? null : parts.join(' · ');
}

/// "07:00" → "07.00", penulisan jam baku bahasa Indonesia.
String hhmm(String v) => v.replaceAll(':', '.');

// ─────────────────────────────────────────────────────────────
// 4. Kelola toko
// ─────────────────────────────────────────────────────────────

class _ManageSection extends ConsumerWidget {
  const _ManageSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(payoutSummaryProvider).valueOrNull?.bankAccount;
    final tiles = [
      _ManageTile(
        icon: Icons.account_balance_outlined,
        tint: AppColors.primary,
        title: 'Rekening pencairan',
        subtitle: bank == null
            ? 'Atur rekening untuk pencairan'
            : '${bank.bankName} ${bank.accountNumber}',
        onTap: () => context.push(StoreRoutes.bankAccount),
      ),
      _ManageTile(
        icon: Icons.settings_outlined,
        tint: const Color(0xFF2F6FDB),
        title: 'Pengaturan toko',
        subtitle: 'Kontak dan jam buka',
        onTap: () => context.push(StoreRoutes.settings),
      ),
      _ManageTile(
        icon: Icons.help_outline_rounded,
        tint: AppColors.warning,
        title: 'Pusat bantuan',
        subtitle: 'Panduan saldo, produk, dan stok',
        onTap: () => context.push(StoreRoutes.help),
      ),
      _ManageTile(
        icon: Icons.shield_outlined,
        tint: AppColors.success,
        title: 'Keamanan akun',
        subtitle: 'Kata sandi dan keluar',
        onTap: () => context.push(StoreRoutes.security),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StoreSectionHeader(
          'Kelola toko',
          subtitle: 'Atur dan kelola toko Anda.',
        ),
        LayoutBuilder(
          builder: (context, c) {
            // Dua kolom selama satu kolom masih selebar ±170dp pada skala
            // teks saat ini; selebihnya satu kolom, bukan teks yang mengecil.
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final twoColumns = (c.maxWidth - AppSpacing.md) / 2 >= 170 * scale;
            if (!twoColumns) {
              return Column(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    tiles[i],
                  ],
                ],
              );
            }
            return Column(
              children: [
                for (var i = 0; i < tiles.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: tiles[i]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: tiles[i + 1]),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.98,
      semanticLabel: '$title. $subtitle',
      child: StoreSurface(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            IconTile(icon, tint: tint, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
