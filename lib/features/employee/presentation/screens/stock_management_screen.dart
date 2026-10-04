import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/employee_dashboard.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';
import '../widgets/employee_bottom_navigation.dart';

/// Manajemen Stok: daftar barang per kondisi stok, plus riwayat pergerakan.
///
/// Penyaringan "menipis"/"habis" dikirim ke server sebagai parameter, bukan
/// disaring dengan `.where()` di layar — menyaring satu halaman secara lokal
/// memberi hasil salah begitu katalog lebih panjang dari satu halaman.
class StockManagementScreen extends ConsumerStatefulWidget {
  const StockManagementScreen({super.key, this.initialFilter = 'all'});

  final String initialFilter;

  @override
  ConsumerState<StockManagementScreen> createState() =>
      _StockManagementScreenState();
}

class _StockManagementScreenState extends ConsumerState<StockManagementScreen> {
  final _scrollController = ScrollController();
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Filter awal datang dari KPI "Stok Menipis"; disetel setelah frame
    // pertama agar tidak mengubah provider selama build berlangsung.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(stockFilterProvider.notifier).state = widget.initialFilter;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      ref.read(stockListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KopdesEmployeeColors.background,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: KopdesEmployeeColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Manajemen Stok',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showHistory = !_showHistory),
            child: Text(
              _showHistory ? 'Daftar Stok' : 'Riwayat Stok',
              style: const TextStyle(
                color: KopdesEmployeeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const EmployeeBottomNavigation(
        activeItem: EmployeeNavItem.stock,
      ),
      body: KopdesContentBoundary(
        padding: EdgeInsets.zero,
        child: _showHistory ? const _HistoryList() : _stockBody(),
      ),
    );
  }

  Widget _stockBody() {
    final filter = ref.watch(stockFilterProvider);
    final state = ref.watch(stockListProvider);

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: KopdesSpacing.md,
              vertical: KopdesSpacing.sm,
            ),
            children: [
              for (final option in const [
                ('all', 'Produk Aktif'),
                ('low', 'Stok Menipis'),
                ('out', 'Stok Habis'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: KopdesSpacing.sm),
                  child: _FilterChip(
                    label: option.$2,
                    selected: filter == option.$1,
                    onTap: () => ref.read(stockFilterProvider.notifier).state =
                        option.$1,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const _StockSkeletonList(),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(KopdesSpacing.base),
                child: KopdesSectionError(
                  message: 'Daftar stok belum berhasil dimuat',
                  onRetry: () => ref
                      .read(stockListProvider.notifier)
                      .load(forceRefresh: true),
                ),
              ),
            ),
            data: (data) {
              if (data.items.isEmpty) {
                return Center(
                  child: Text(
                    filter == 'all'
                        ? 'Belum ada barang di katalog Kopdes'
                        : 'Semua stok dalam kondisi aman',
                    style: const TextStyle(
                      color: KopdesEmployeeColors.textSecondary,
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                color: KopdesEmployeeColors.primary,
                onRefresh: () => ref
                    .read(stockListProvider.notifier)
                    .load(forceRefresh: true),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    KopdesSpacing.md,
                    0,
                    KopdesSpacing.md,
                    120,
                  ),
                  itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: KopdesSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index >= data.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(KopdesSpacing.base),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return _StockRow(item: data.items[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KopdesRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? KopdesEmployeeColors.primary
              : KopdesEmployeeColors.surface,
          borderRadius: BorderRadius.circular(KopdesRadii.pill),
          border: Border.all(color: KopdesEmployeeColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : KopdesEmployeeColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StockRow extends ConsumerWidget {
  const _StockRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdjust = ref.watch(
      hasPermissionProvider(Permissions.inventoryAdjust),
    );
    final color = item.isOut
        ? KopdesEmployeeColors.primary
        : item.isLow
        ? KopdesEmployeeColors.warning
        : KopdesEmployeeColors.success;

    return KopdesSurface(
      padding: const EdgeInsets.all(KopdesSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: KopdesEmployeeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.price.formatted} • SKU ${item.sku ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: KopdesEmployeeColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  // Status ditulis, bukan hanya diberi warna: pengguna dengan
                  // buta warna tidak bisa membedakan kuning dari merah.
                  item.isOut
                      ? 'Stok habis'
                      : item.isLow
                      ? 'Stok menipis — sisa ${item.stock} ${item.unit} '
                            '(min ${item.minStock})'
                      : 'Stok ${item.stock} ${item.unit}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (canAdjust)
            IconButton(
              tooltip: 'Sesuaikan stok',
              icon: const Icon(Icons.tune_rounded, size: 20),
              color: KopdesEmployeeColors.primary,
              onPressed: () => _openAdjustSheet(context, ref, item),
            ),
        ],
      ),
    );
  }
}

Future<void> _openAdjustSheet(
  BuildContext context,
  WidgetRef ref,
  StockItem item,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: KopdesEmployeeColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AdjustStockSheet(item: item),
  );
}

/// Form penyesuaian stok: masuk, keluar, atau hasil hitung fisik (opname).
class _AdjustStockSheet extends ConsumerStatefulWidget {
  const _AdjustStockSheet({required this.item});

  final StockItem item;

  @override
  ConsumerState<_AdjustStockSheet> createState() => _AdjustStockSheetState();
}

class _AdjustStockSheetState extends ConsumerState<_AdjustStockSheet> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  String _mode = 'IN';
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isOpname => _mode == 'OPNAME';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: KopdesSpacing.base,
        right: KopdesSpacing.base,
        top: KopdesSpacing.base,
        bottom: MediaQuery.viewInsetsOf(context).bottom + KopdesSpacing.base,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Stok sistem: ${widget.item.stock} ${widget.item.unit}',
              style: const TextStyle(
                fontSize: 12.5,
                color: KopdesEmployeeColors.textSecondary,
              ),
            ),
            const SizedBox(height: KopdesSpacing.base),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'IN', label: Text('Masuk')),
                ButtonSegment(value: 'OUT', label: Text('Keluar')),
                ButtonSegment(value: 'OPNAME', label: Text('Opname')),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() => _mode = v.first),
            ),
            const SizedBox(height: KopdesSpacing.base),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isOpname
                    ? 'Hasil hitung fisik'
                    : 'Jumlah (${widget.item.unit})',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null) return 'Isi angka';
                // Opname boleh nol (barang benar-benar habis); penyesuaian
                // masuk/keluar sebesar nol tidak mengubah apa pun.
                if (_isOpname ? n < 0 : n < 1) {
                  return _isOpname ? 'Tidak boleh negatif' : 'Minimal 1';
                }
                return null;
              },
            ),
            const SizedBox(height: KopdesSpacing.md),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: _isOpname ? 'Catatan (opsional)' : 'Alasan',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (_isOpname) return null;
                return (value?.trim().isEmpty ?? true)
                    ? 'Alasan wajib diisi untuk jejak audit'
                    : null;
              },
            ),
            const SizedBox(height: KopdesSpacing.base),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: KopdesEmployeeColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(_submitting ? 'Menyimpan…' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final actions = ref.read(employeeActionsProvider);
    final quantity = int.parse(_quantityController.text.trim());
    final error = _isOpname
        ? await actions.stockOpname(
            productId: widget.item.id,
            countedStock: quantity,
            note: _reasonController.text.trim(),
          )
        : await actions.adjustStock(
            productId: widget.item.id,
            type: _mode,
            quantity: quantity,
            reason: _reasonController.text.trim(),
          );

    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop();
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(stockHistoryProvider);

    return history.when(
      loading: () => const _StockSkeletonList(),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(KopdesSpacing.base),
          child: KopdesSectionError(
            message: 'Riwayat stok belum berhasil dimuat',
            onRetry: () => ref.invalidate(stockHistoryProvider),
          ),
        ),
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada pergerakan stok',
              style: TextStyle(color: KopdesEmployeeColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            KopdesSpacing.md,
            KopdesSpacing.md,
            KopdesSpacing.md,
            120,
          ),
          itemCount: page.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: KopdesSpacing.sm),
          itemBuilder: (context, index) {
            final move = page.items[index];
            final positive = move.type == 'IN';
            return KopdesSurface(
              padding: const EdgeInsets.all(KopdesSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          move.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${move.typeLabel} • ${move.actorName}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: KopdesEmployeeColors.textSecondary,
                          ),
                        ),
                        if (move.reason.isNotEmpty)
                          Text(
                            move.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: KopdesEmployeeColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${positive ? '+' : '−'}${move.quantity}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: positive
                              ? KopdesEmployeeColors.success
                              : KopdesEmployeeColors.primary,
                        ),
                      ),
                      Text(
                        'sisa ${move.stockAfter}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: KopdesEmployeeColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StockSkeletonList extends StatelessWidget {
  const _StockSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(KopdesSpacing.md),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: KopdesSpacing.sm),
      itemBuilder: (_, _) => const KopdesSurface(
        padding: EdgeInsets.all(KopdesSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KopdesSkeleton(height: 14, width: 170),
            SizedBox(height: 8),
            KopdesSkeleton(height: 12, width: 120),
            SizedBox(height: 8),
            KopdesSkeleton(height: 12, width: 90),
          ],
        ),
      ),
    );
  }
}
