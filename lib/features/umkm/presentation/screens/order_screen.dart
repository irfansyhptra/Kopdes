import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/order_card.dart';
import '../../../../shared/components/loading_widget.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/components/empty_state_widget.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateStatus(String orderId, String status) async {
    setState(() {
      _isUpdating = true;
    });

    final success = await ref
        .read(orderControllerProvider.notifier)
        .updateOrderStatus(orderId, status);

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan berhasil diperbarui ke: $status'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui status pesanan'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, int tabIndex) {
    switch (tabIndex) {
      case 0: // Pesanan Baru
        return orders
            .where((o) => o.status.toUpperCase() == 'PENDING' || o.status.toUpperCase() == 'PAID')
            .toList();
      case 1: // Diproses
        return orders.where((o) => o.status.toUpperCase() == 'PROCESSING').toList();
      case 2: // Siap Kirim
        return orders.where((o) => o.status.toUpperCase() == 'READY_FOR_DELIVERY').toList();
      case 3: // Selesai / Batal
        return orders
            .where((o) =>
                o.status.toUpperCase() == 'DELIVERED' ||
                o.status.toUpperCase() == 'COMPLETED' ||
                o.status.toUpperCase() == 'CANCELLED')
            .toList();
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(sellerOrdersProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: AppBar(
            title: const Text('Kelola Pesanan'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.muted,
              tabs: const [
                Tab(text: 'Baru'),
                Tab(text: 'Diproses'),
                Tab(text: 'Siap Kirim'),
                Tab(text: 'Riwayat'),
              ],
            ),
          ),
          body: ordersState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (error, stack) => ErrorStateWidget(
              errorMessage: error.toString(),
              onRetry: () => ref.invalidate(sellerOrdersProvider),
            ),
            data: (orders) {
              return TabBarView(
                controller: _tabController,
                children: List.generate(4, (index) {
                  final filtered = _filterOrders(orders, index);

                  if (filtered.isEmpty) {
                    return _buildEmptyStateForTab(index);
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(sellerOrdersProvider),
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.base,
                        AppSpacing.section,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final order = filtered[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: OrderCard(
                            order: order,
                            onUpdateStatus: (newStatus) => _handleUpdateStatus(order.id, newStatus),
                            onTap: () {
                              // We can navigate to details or show a modal sheet
                              _showOrderDetailsSheet(order);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }),
              );
            },
          ),
        ),
        if (_isUpdating)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: LoadingWidget(message: 'Memperbarui status pesanan...'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStateForTab(int index) {
    String title = '';
    String desc = '';
    IconData icon = Icons.receipt_long_outlined;

    switch (index) {
      case 0:
        title = 'Tidak Ada Pesanan Baru';
        desc = 'Belum ada pesanan masuk dari pembeli saat ini.';
        icon = Icons.notifications_none_rounded;
        break;
      case 1:
        title = 'Tidak Ada Pesanan Diproses';
        desc = 'Semua pesanan Anda sudah disiapkan atau dikirim.';
        icon = Icons.outdoor_grill_outlined;
        break;
      case 2:
        title = 'Tidak Ada Pesanan Siap Kirim';
        desc = 'Belum ada pesanan yang siap dipickup oleh kurir.';
        icon = Icons.local_shipping_outlined;
        break;
      case 3:
        title = 'Riwayat Kosong';
        desc = 'Belum ada transaksi selesai atau dibatalkan di toko Anda.';
        icon = Icons.history_rounded;
        break;
    }

    return EmptyStateWidget(
      icon: icon,
      title: title,
      description: desc,
    );
  }

  void _showOrderDetailsSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Rincian Pesanan Lengkap',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const Divider(height: AppSpacing.lg),
                
                // Info Customer
                _buildInfoRow('Nama Pembeli', order.customer.name),
                _buildInfoRow('Email', order.customer.email),
                _buildInfoRow('Nomor HP', order.customer.phone),
                const Divider(height: AppSpacing.lg),

                // Alamat Pengiriman
                Text(
                  'Alamat Pengiriman',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${order.deliveryAddress.recipientName} (${order.deliveryAddress.phone})',
                  style: AppTypography.bodyMedium,
                ),
                Text(
                  '${order.deliveryAddress.street}, ${order.deliveryAddress.city}, ${order.deliveryAddress.state} - ${order.deliveryAddress.postalCode}',
                  style: AppTypography.caption,
                ),
                const Divider(height: AppSpacing.lg),

                // Metode pembayaran
                _buildInfoRow('Metode Pembayaran', order.paymentMethod.toUpperCase()),
                _buildInfoRow('Status Pembayaran', order.paymentStatus.toUpperCase()),
                const SizedBox(height: AppSpacing.xl),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.muted)),
          Text(value, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
