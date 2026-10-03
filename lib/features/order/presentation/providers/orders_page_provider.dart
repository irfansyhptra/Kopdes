import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/seller_ref.dart';
import '../../domain/order_status_view.dart';
import 'cart_provider.dart';
import 'order_provider.dart';

// ─────────────────────────────────────────────────────────────
// Navigasi antar subhalaman
// ─────────────────────────────────────────────────────────────

/// Tab aktif. Disimpan di provider, bukan di state layar, supaya kembali dari
/// detail pesanan tidak melemparkan pengguna ke tab Keranjang lagi.
final ordersTabProvider = StateProvider<OrdersTab>((_) => OrdersTab.cart);

/// Filter kecil di tab Selesai.
final doneFilterProvider = StateProvider<DoneFilter>((_) => DoneFilter.all);

/// Grup penjual yang sedang dilipat. Menyimpan yang dilipat (bukan yang
/// terbuka) berarti grup baru dari server selalu muncul terbuka.
final collapsedSellerGroupsProvider = StateProvider<Set<String>>(
  (_) => const {},
);

/// Ringkasan Belanja terbuka atau terlipat. Milik pengguna, jadi tidak
/// direset tiap kali keranjang dimuat ulang.
final summaryExpandedProvider = StateProvider<bool>((_) => true);

// ─────────────────────────────────────────────────────────────
// Pilihan produk
// ─────────────────────────────────────────────────────────────

/// Id item keranjang yang tercentang.
///
/// Pilihan adalah keadaan lokal: mencentang atau melepas centang tidak pernah
/// memanggil API. Yang dikirim ke server hanyalah daftar id saat checkout.
class SelectedCartItemsNotifier extends StateNotifier<Set<String>> {
  SelectedCartItemsNotifier() : super(const {});

  /// Id yang pernah terlihat di keranjang. Tanpa ini, item yang sengaja
  /// dilepas centangnya akan tercentang lagi setiap kali `/cart` menjawab.
  final Set<String> _known = {};

  /// Menyelaraskan pilihan dengan isi keranjang terbaru: item yang baru masuk
  /// langsung tercentang — pengguna baru saja menambahkannya — dan item yang
  /// sudah tidak ada dibuang, supaya totalnya tidak menghitung barang hantu.
  void syncWithCart(Set<String> ids) {
    final next = state.where(ids.contains).toSet();
    for (final id in ids) {
      if (!_known.contains(id)) next.add(id);
    }
    _known
      ..clear()
      ..addAll(ids);
    if (!setEquals(next, state)) state = next;
  }

  void toggleItem(String itemId) {
    state = state.contains(itemId)
        ? (Set<String>.from(state)..remove(itemId))
        : (Set<String>.from(state)..add(itemId));
  }

  void selectSeller(Iterable<String> itemIds) {
    state = Set<String>.from(state)..addAll(itemIds);
  }

  void unselectSeller(Iterable<String> itemIds) {
    state = Set<String>.from(state)..removeAll(itemIds);
  }

  void selectAll(Iterable<String> allItemIds) {
    state = allItemIds.toSet();
  }

  void clearSelection() {
    state = const {};
  }
}

final selectedCartItemsProvider =
    StateNotifierProvider<SelectedCartItemsNotifier, Set<String>>((ref) {
      final notifier = SelectedCartItemsNotifier();
      ref.listen<AsyncValue<Cart>>(cartProvider, (_, next) {
        final cart = next.valueOrNull;
        if (cart != null) {
          notifier.syncWithCart(cart.items.map((i) => i.id).toSet());
        }
      }, fireImmediately: true);
      return notifier;
    });

/// True bila satu item tercentang. Baris produk mengamati provider ini saja,
/// jadi mencentang satu produk tidak membangun ulang seluruh daftar.
final isCartItemSelectedProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(selectedCartItemsProvider.select((s) => s.contains(id)));
});

/// Item yang permintaannya ke server sedang berjalan (ubah jumlah atau hapus).
/// Dipakai untuk mematikan tombol sehingga ketukan ganda tidak mengirim dua
/// permintaan untuk baris yang sama.
final mutatingCartItemsProvider = StateProvider<Set<String>>((_) => const {});

final isCartItemBusyProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(mutatingCartItemsProvider.select((s) => s.contains(id)));
});

// ─────────────────────────────────────────────────────────────
// Pengelompokan keranjang per penjual
// ─────────────────────────────────────────────────────────────

class CartSellerGroup {
  final SellerRef seller;
  final List<CartItem> items;

  const CartSellerGroup({required this.seller, required this.items});

  String get key => seller.groupKey;

  List<String> get itemIds => [for (final i in items) i.id];
}

/// Status centang tiga keadaan. Diperlukan karena satu produk yang dilepas
/// centangnya membuat tokonya "sebagian", bukan "tidak dipilih".
enum CheckState { none, some, all }

/// Keranjang dikelompokkan per toko, mempertahankan urutan datangnya item
/// dari server sehingga daftar tidak melompat-lompat setiap kali dimuat.
final cartSellerGroupsProvider = Provider<List<CartSellerGroup>>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null) return const [];

  final order = <String>[];
  final buckets = <String, List<CartItem>>{};
  final sellers = <String, SellerRef>{};

  for (final item in cart.items) {
    final key = item.seller.groupKey;
    if (!buckets.containsKey(key)) {
      order.add(key);
      buckets[key] = [];
      sellers[key] = item.seller;
    }
    buckets[key]!.add(item);
  }

  return [
    for (final key in order)
      CartSellerGroup(seller: sellers[key]!, items: buckets[key]!),
  ];
});

final sellerGroupCheckStateProvider = Provider.family<CheckState, String>((
  ref,
  groupKey,
) {
  final groups = ref.watch(cartSellerGroupsProvider);
  CartSellerGroup? group;
  for (final candidate in groups) {
    if (candidate.key == groupKey) {
      group = candidate;
      break;
    }
  }
  if (group == null || group.items.isEmpty) return CheckState.none;

  final selected = ref.watch(selectedCartItemsProvider);
  final count = group.items.where((i) => selected.contains(i.id)).length;
  if (count == 0) return CheckState.none;
  return count == group.items.length ? CheckState.all : CheckState.some;
});

final allItemsCheckStateProvider = Provider<CheckState>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null || cart.items.isEmpty) return CheckState.none;

  final selected = ref.watch(selectedCartItemsProvider);
  final count = cart.items.where((i) => selected.contains(i.id)).length;
  if (count == 0) return CheckState.none;
  return count == cart.items.length ? CheckState.all : CheckState.some;
});

// ─────────────────────────────────────────────────────────────
// Ringkasan Belanja
// ─────────────────────────────────────────────────────────────

class CartSummary {
  /// Semua nominal disimpan sebagai rupiah bulat. Menjumlahkan `double`
  /// antar baris menumpuk galat pembulatan yang akhirnya terlihat di total.
  final int subtotal;
  final int shipping;
  final int discount;

  /// Jumlah baris produk yang tercentang — angka di "Subtotal (n produk)".
  final int selectedLines;

  /// Jumlah satuan barang yang tercentang.
  final int selectedUnits;

  final int totalLines;

  const CartSummary({
    this.subtotal = 0,
    this.shipping = 0,
    this.discount = 0,
    this.selectedLines = 0,
    this.selectedUnits = 0,
    this.totalLines = 0,
  });

  int get total => subtotal + shipping - discount;

  bool get canCheckout => selectedLines > 0;
}

/// Total dihitung dari data keranjang dan pilihan pengguna — tidak pernah
/// dari angka tetap.
///
/// Ongkir dan diskon bernilai nol karena backend belum punya tarif ongkir
/// maupun voucher untuk keranjang; keduanya sudah menjadi bagian rumus di
/// sini supaya nilainya cukup diisi begitu endpoint-nya ada.
final cartSummaryProvider = Provider<CartSummary>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null) return const CartSummary();

  final selected = ref.watch(selectedCartItemsProvider);

  var subtotal = 0;
  var lines = 0;
  var units = 0;
  for (final item in cart.items) {
    if (!selected.contains(item.id)) continue;
    subtotal += item.lineTotal;
    lines += 1;
    units += item.quantity;
  }

  return CartSummary(
    subtotal: subtotal,
    selectedLines: lines,
    selectedUnits: units,
    totalLines: cart.items.length,
  );
});

// ─────────────────────────────────────────────────────────────
// Pesanan diproses & selesai
// ─────────────────────────────────────────────────────────────

/// Riwayat dipecah di sisi klien: `/orders/history` tidak menerima parameter
/// status, jadi memisahkannya di sini lebih murah daripada dua permintaan
/// berhalaman untuk data yang sama. Yang dipecah adalah halaman yang sudah
/// terkumpul, sehingga "muat lebih banyak" menambah keduanya sekaligus.
final activeOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  return ref
      .watch(orderHistoryListProvider)
      .whenData(
        (orders) => orders.where((o) => o.statusView.isActive).toList(),
      );
});

final doneOrdersProvider = Provider<AsyncValue<List<Order>>>((ref) {
  final filter = ref.watch(doneFilterProvider);
  return ref.watch(orderHistoryListProvider).whenData((orders) {
    final finished = orders.where((o) => !o.statusView.isActive);
    return switch (filter) {
      DoneFilter.all => finished.toList(),
      DoneFilter.completed =>
        finished.where((o) => !o.statusView.isCancelled).toList(),
      DoneFilter.cancelled =>
        finished.where((o) => o.statusView.isCancelled).toList(),
    };
  });
});

/// Badge pada tab. Nol berarti badge tidak digambar sama sekali, bukan
/// lingkaran berisi "0".
final activeOrderCountProvider = Provider<int>((ref) {
  return ref.watch(activeOrdersProvider).valueOrNull?.length ?? 0;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).valueOrNull?.items.length ?? 0;
});
