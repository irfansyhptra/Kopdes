import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/inventory_card.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/components/empty_state_widget.dart';
import '../controllers/inventory_controller.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isUpdating = false;

  Future<void> _handleUpdateStock(String productId, int newStock) async {
    setState(() {
      _isUpdating = true;
    });

    final success = await ref
        .read(inventoryControllerProvider.notifier)
        .updateStock(productId, newStock);

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok produk berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui stok produk'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(sellerInventoryProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: const Text('Kelola Stok & Inventaris'),
            centerTitle: true,
          ),
          body: inventoryState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stack) => ErrorStateWidget(
              errorMessage: error.toString(),
              onRetry: () => ref.invalidate(sellerInventoryProvider),
            ),
            data: (inventoryList) {
              if (inventoryList.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.inventory_outlined,
                  title: 'Inventaris Kosong',
                  description: 'Belum ada produk yang tercatat dalam inventaris toko Anda.',
                );
              }

              // Sort: low stock first
              final sortedList = List.of(inventoryList)
                ..sort((a, b) => a.stock.compareTo(b.stock));

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(sellerInventoryProvider),
                color: AppColors.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.base,
                    AppSpacing.section,
                  ),
                  itemCount: sortedList.length,
                  itemBuilder: (context, idx) {
                    final item = sortedList[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: InventoryCard(
                        inventory: item,
                        onUpdateStock: (newStock) => _handleUpdateStock(item.productId, newStock),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: LoadingWidget(message: 'Memperbarui stok...'),
            ),
          ),
      ],
    );
  }
}
