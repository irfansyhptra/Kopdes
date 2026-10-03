import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/seller_ref.dart';
import '../providers/cart_provider.dart';
import '../providers/orders_page_provider.dart';
import 'orders_chrome.dart';
import 'orders_responsive.dart';

// ─────────────────────────────────────────────────────────────
// Aksi keranjang
// ─────────────────────────────────────────────────────────────

/// Mengubah jumlah satu baris.
///
/// Penjaga [mutatingCartItemsProvider] membuat ketukan kedua pada baris yang
/// sama diabaikan selama permintaan pertama masih berjalan — tanpa itu, dua
/// ketukan cepat mengirim dua PUT dan yang terakhir menang secara acak.
Future<void> _changeQuantity(
  BuildContext context,
  WidgetRef ref,
  CartItem item,
  int next,
) async {
  if (next < 1 || next > item.stock) return;

  final busy = ref.read(mutatingCartItemsProvider);
  if (busy.contains(item.id)) return;
  ref.read(mutatingCartItemsProvider.notifier).state = {...busy, item.id};

  final error = await ref
      .read(cartProvider.notifier)
      .setItemQuantity(item, next);

  ref.read(mutatingCartItemsProvider.notifier).state = {
    ...ref.read(mutatingCartItemsProvider),
  }..remove(item.id);

  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

/// Konfirmasi lalu hapus satu baris. Dialognya menyebut nama produknya supaya
/// tidak ada yang terhapus karena salah tekan.
Future<void> _confirmRemove(
  BuildContext context,
  WidgetRef ref,
  CartItem item,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppleRadii.group),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Hapus dari keranjang?',
              style: AppTypography.titleMedium.copyWith(fontSize: 17),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${item.name}" akan dikeluarkan dari keranjang. Produk lain '
              'tidak terpengaruh.',
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirmed != true) return;

  final busy = ref.read(mutatingCartItemsProvider);
  if (busy.contains(item.id)) return;
  ref.read(mutatingCartItemsProvider.notifier).state = {...busy, item.id};

  final error = await ref.read(cartProvider.notifier).removeCartItem(item);

  ref.read(mutatingCartItemsProvider.notifier).state = {
    ...ref.read(mutatingCartItemsProvider),
  }..remove(item.id);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(error ?? '${item.name} dihapus dari keranjang'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

// ─────────────────────────────────────────────────────────────
// Kotak centang tiga keadaan
// ─────────────────────────────────────────────────────────────

/// Kotak centang dengan keadaan "sebagian".
///
/// [Checkbox] bawaan bisa tristate, tetapi keadaan ketiganya adalah `null`
/// yang juga bisa dipilih pengguna. Di sini "sebagian" adalah hasil turunan,
/// bukan pilihan — menekannya selalu memilih atau melepas seluruhnya.
class TriStateCheckbox extends StatelessWidget {
  final CheckState state;
  final String semanticLabel;
  final VoidCallback onTap;

  const TriStateCheckbox({
    super.key,
    required this.state,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = state != CheckState.none;

    return Semantics(
      checked: state == CheckState.all,
      mixed: state == CheckState.some,
      label: semanticLabel,
      child: ApplePressable(
        onTap: onTap,
        pressedScale: 0.88,
        child: SizedBox(
          // Kotaknya 22dp, targetnya tetap 44dp.
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: filled ? AppColors.primary : AppColors.canvas,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: filled ? AppColors.primary : AppColors.hairline,
                  width: 1.5,
                ),
              ),
              child: state == CheckState.none
                  ? null
                  : Icon(
                      state == CheckState.all
                          ? Icons.check_rounded
                          : Icons.remove_rounded,
                      size: 15,
                      color: AppColors.onPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kartu grup penjual
// ─────────────────────────────────────────────────────────────

class CartSellerGroupCard extends ConsumerWidget {
  final CartSellerGroup group;
  final OrdersSpec spec;

  const CartSellerGroupCard({
    super.key,
    required this.group,
    required this.spec,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(
      collapsedSellerGroupsProvider.select((s) => s.contains(group.key)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppleCard(
        radius: AppleRadii.tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SellerHeader(
              group: group,
              collapsed: collapsed,
              onToggleCollapse: () {
                final current = ref.read(collapsedSellerGroupsProvider);
                ref
                    .read(collapsedSellerGroupsProvider.notifier)
                    .state = current.contains(group.key)
                    ? (Set<String>.from(current)..remove(group.key))
                    : (Set<String>.from(current)..add(group.key));
              },
            ),
            if (!collapsed)
              for (var i = 0; i < group.items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.hairlineSoft,
                  ),
                CartProductRow(item: group.items[i], spec: spec),
              ],
          ],
        ),
      ),
    );
  }
}

class _SellerHeader extends ConsumerWidget {
  final CartSellerGroup group;
  final bool collapsed;
  final VoidCallback onToggleCollapse;

  const _SellerHeader({
    required this.group,
    required this.collapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkState = ref.watch(sellerGroupCheckStateProvider(group.key));
    final seller = group.seller;

    void toggleGroup() {
      final notifier = ref.read(selectedCartItemsProvider.notifier);
      // Sebagian terpilih dianggap belum lengkap: menekannya melengkapi,
      // bukan mengosongkan.
      if (checkState == CheckState.all) {
        notifier.unselectSeller(group.itemIds);
      } else {
        notifier.selectSeller(group.itemIds);
      }
    }

    final selectAll = ApplePressable(
      onTap: toggleGroup,
      pressedScale: 1.0,
      semanticLabel: 'Pilih semua produk dari ${seller.label}',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Text(
          'Pilih Semua',
          maxLines: 1,
          style: AppTypography.buttonSm.copyWith(
            fontSize: 11.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pada lebar sempit, nama toko dan "Pilih Semua" berebut ruang dan
          // salah satunya pasti terpotong. Di situ tombolnya turun ke baris
          // kedua — labelnya tetap utuh, yang penting justru itu.
          final narrow = constraints.maxWidth < 340;

          final identity = Row(
            children: [
              TriStateCheckbox(
                state: checkState,
                semanticLabel: 'Pilih semua produk dari ${seller.label}',
                onTap: toggleGroup,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Lencana boleh menyusut: "MITRA UMKM" lebih lebar
                        // daripada "KOPDES", dan pada teks besar keduanya
                        // tumbuh lagi.
                        Flexible(child: SellerTypeChip(seller: seller)),
                        if (seller.verified) ...[
                          const SizedBox(width: 5),
                          Semantics(
                            label: seller.isUmkm
                                ? 'Mitra terverifikasi'
                                : 'Koperasi resmi',
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      seller.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (!narrow) ...[const SizedBox(width: AppSpacing.sm), selectAll],
              ApplePressable(
                onTap: onToggleCollapse,
                pressedScale: 0.9,
                semanticLabel: collapsed
                    ? 'Buka daftar produk ${seller.label}'
                    : 'Lipat daftar produk ${seller.label}',
                child: SizedBox(
                  width: 32,
                  height: 44,
                  child: Icon(
                    collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: AppColors.mutedSoft,
                  ),
                ),
              ),
            ],
          );

          if (!narrow) return identity;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              identity,
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.base + 4),
                child: selectAll,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lencana jenis penjual. Teksnya selalu ditulis, tidak hanya diwarnai.
class SellerTypeChip extends StatelessWidget {
  final SellerRef seller;

  const SellerTypeChip({super.key, required this.seller});

  @override
  Widget build(BuildContext context) {
    final umkm = seller.isUmkm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: umkm
            ? SellerBadgeColors.umkmSurface
            : SellerBadgeColors.kopdesSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        seller.badge,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.3,
          color: umkm
              ? SellerBadgeColors.umkmText
              : SellerBadgeColors.kopdesText,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Baris produk
// ─────────────────────────────────────────────────────────────

class CartProductRow extends ConsumerWidget {
  final CartItem item;
  final OrdersSpec spec;

  const CartProductRow({super.key, required this.item, required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dua provider granular: mencentang atau memperbarui satu baris tidak
    // membangun ulang baris lain, apalagi seluruh halaman.
    final selected = ref.watch(isCartItemSelectedProvider(item.id));
    final busy = ref.watch(isCartItemBusyProvider(item.id));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Di bawah lebar ini, harga dan stepper berdampingan menghimpit
        // keduanya; stepper turun ke baris sendiri.
        final narrow = constraints.maxWidth < 340;
        final thumb = narrow ? 62.0 : spec.thumbnailSize;

        // Yang ditulis besar adalah total baris, bukan harga satuan.
        // Sebelumnya baris ini menampilkan harga satuan saja, sehingga
        // keranjang berisi 3 item seharga Rp65.000 terbaca "Rp65.000"
        // sementara yang dibayar Rp195.000.
        final price = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatRupiah(item.lineTotal),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                height: 1.15,
                color: AppColors.primary,
              ),
            ),
            // Perkaliannya hanya ditulis saat memang ada yang dikalikan.
            if (item.quantity > 1)
              Text(
                '${formatRupiah(item.price)} × ${item.quantity}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11.5,
                  color: AppColors.muted,
                ),
              ),
          ],
        );

        final stepper = _QuantityStepper(item: item, busy: busy);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TriStateCheckbox(
                  state: selected ? CheckState.all : CheckState.none,
                  semanticLabel: selected
                      ? 'Batalkan pilihan ${item.name}'
                      : 'Pilih ${item.name}',
                  onTap: () => ref
                      .read(selectedCartItemsProvider.notifier)
                      .toggleItem(item.id),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppleRadii.tile),
                child: SizedBox(
                  width: thumb,
                  height: thumb,
                  child: ColoredBox(
                    color: AppColors.surfaceSoft,
                    child: ProductImageLoader(
                      imageUrl: item.imageUrl,
                      placeholderIconSize: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _StockLine(stock: item.stock),
                    const SizedBox(height: AppSpacing.sm),
                    if (narrow) ...[
                      price,
                      const SizedBox(height: AppSpacing.sm),
                      Align(alignment: Alignment.centerLeft, child: stepper),
                    ] else
                      Row(
                        children: [
                          Expanded(child: price),
                          const SizedBox(width: AppSpacing.sm),
                          stepper,
                        ],
                      ),
                  ],
                ),
              ),
              ApplePressable(
                onTap: busy ? null : () => _confirmRemove(context, ref, item),
                pressedScale: 0.85,
                semanticLabel: 'Hapus ${item.name} dari keranjang',
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: busy ? AppColors.hairline : AppColors.mutedSoft,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Baris stok. Habis ditandai dengan kata, bukan hanya warna merah.
class _StockLine extends StatelessWidget {
  final int stock;

  const _StockLine({required this.stock});

  @override
  Widget build(BuildContext context) {
    final out = stock <= 0;
    return Text(
      out ? 'Stok habis' : 'Stok $stock tersedia',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.captionSmall.copyWith(
        fontSize: 11,
        color: out ? AppColors.error : AppColors.muted,
        fontWeight: out ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final CartItem item;
  final bool busy;

  const _QuantityStepper({required this.item, required this.busy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Jumlah tidak pernah boleh mencapai nol lewat tombol kurang — menghapus
    // produk punya tombolnya sendiri, dengan konfirmasi.
    final canDecrease = !busy && item.quantity > 1;
    final canIncrease = !busy && item.quantity < item.stock;

    // Tingginya 44dp bukan karena tombolnya perlu terlihat besar, tetapi
    // karena target sentuh di bawah itu sulit dikenai — dan salah tekan di
    // sini langsung mengubah jumlah pesanan.
    return Container(
      height: 44,
      decoration: BoxDecoration(
        // Putih berpil, bukan kotak abu: kontrol yang bisa ditekan dibedakan
        // dari latar kartunya lewat permukaan dan bayangan, bukan lewat warna
        // isian yang justru membuatnya tampak nonaktif.
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppElevation.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            semanticLabel: 'Kurangi jumlah ${item.name}',
            onTap: () => _changeQuantity(context, ref, item, item.quantity - 1),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 26),
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              maxLines: 1,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            semanticLabel: 'Tambah jumlah ${item.name}',
            onTap: () => _changeQuantity(context, ref, item, item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: enabled ? onTap : null,
      pressedScale: 0.85,
      semanticLabel: semanticLabel,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : AppColors.mutedSoft,
        ),
      ),
    );
  }
}
