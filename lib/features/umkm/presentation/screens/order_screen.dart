import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/components/order_card.dart';
import '../../../../shared/components/error_state_widget.dart';
import '../../../../shared/components/empty_state_widget.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_feedback.dart';
import '../controllers/order_controller.dart';
import '../widgets/seller_page_ui.dart';
import '../../data/models/order_model.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key});

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _openingChats = {};

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

  Future<void> _handleUpdateStatus(OrderModel order, String status) async {
    final pickup = order.fulfillment.toUpperCase() == 'PICKUP';
    // Penjual mitra tidak memerintah kurir. "Siap diantar" hanya menitipkan
    // pesanan ke kolam tugas kurir Kopdes, dan kabar suksesnya harus
    // mengatakan itu — bukan "kurir sudah ditugaskan".
    final sukses = status == 'READY_FOR_DELIVERY'
        ? (pickup
              ? 'Pembeli bisa mengambil pesanannya sekarang.'
              : 'Pesanan masuk daftar tugas kurir Kopdes. Kurir yang '
                    'mengambilnya akan menghubungi Anda.')
        : 'Siapkan barangnya, lalu tandai siap bila sudah selesai.';

    await runWithFeedback(
      context,
      waiting: 'Memperbarui status pesanan…',
      action: () => ref
          .read(orderControllerProvider.notifier)
          .updateOrderStatus(order.id, status),
      successTitle: status == 'READY_FOR_DELIVERY'
          ? (pickup ? 'Siap diambil' : 'Pengantaran diajukan')
          : 'Pesanan diproses',
      successMessage: sukses,
      failureTitle: 'Status pesanan belum berubah',
      failureMessage: 'Periksa koneksi, lalu coba lagi.',
    );
  }

  Future<void> _openOrderChat(OrderModel order, ChatChannel channel) async {
    final key = '${order.id}:${channel.apiValue}';
    if (_openingChats.contains(key)) return;
    setState(() => _openingChats.add(key));

    try {
      final conversation = await ref
          .read(chatServiceProvider)
          .startOrderConversation(order.id, channel: channel);
      ref.invalidate(conversationsProvider);
      ref.invalidate(channelConversationsProvider);
      if (!mounted) return;
      final title = channel == ChatChannel.delivery
          ? order.courier?.name ?? 'Kurir'
          : order.customer.name;
      context.push(
        channel.detailPath(conversation.id),
        extra: ChatDetailArguments(title: title, channel: channel),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              channel == ChatChannel.delivery
                  ? 'Chat kurir belum dapat dibuka.'
                  : 'Chat pembeli belum dapat dibuka.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingChats.remove(key));
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, int tabIndex) {
    switch (tabIndex) {
      case 0: // Pesanan Baru
        return orders
            .where(
              (o) =>
                  o.status.toUpperCase() == 'PENDING' ||
                  o.status.toUpperCase() == 'PAID',
            )
            .toList();
      case 1: // Diproses
        return orders
            .where((o) => o.status.toUpperCase() == 'PROCESSING')
            .toList();
      case 2: // Siap Kirim
        return orders
            .where((o) => o.status.toUpperCase() == 'READY_FOR_DELIVERY')
            .toList();
      case 3: // Selesai / Batal
        return orders
            .where(
              (o) =>
                  o.status.toUpperCase() == 'DELIVERED' ||
                  o.status.toUpperCase() == 'COMPLETED' ||
                  o.status.toUpperCase() == 'CANCELLED',
            )
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
          backgroundColor: AppColors.surfaceSoft,
          body: SellerPageChrome(
            title: 'Pesanan',
            subtitle: 'Pantau pesanan dari masuk hingga selesai',
            actions: [
              GlassIconButton(
                icon: Icons.refresh_rounded,
                label: 'Perbarui pesanan',
                onDark: true,
                onTap: () => ref.invalidate(sellerOrdersProvider),
              ),
            ],
            headerChild: Container(
              height: 42,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: const Color(0x29FFFFFF)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppElevation.subtle,
                ),
                labelColor: AppColors.primaryText,
                unselectedLabelColor: AppColors.onPrimary,
                labelStyle: AppTypography.captionSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppTypography.captionSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Baru'),
                  Tab(text: 'Diproses'),
                  Tab(text: 'Butuh Kurir'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            body: ordersState.when(
              loading: () =>
                  const Center(child: AppleActivityIndicator(size: 28)),
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
                      onRefresh: () async =>
                          ref.invalidate(sellerOrdersProvider),
                      color: AppColors.primary,
                      child: SellerContentBoundary(
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(
                            0,
                            AppSpacing.base,
                            0,
                            112,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final order = filtered[idx];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: OrderCard(
                                order: order,
                                onChatBuyer: () => _openOrderChat(
                                  order,
                                  ChatChannel.marketplace,
                                ),
                                onChatCourier: order.courier == null
                                    ? null
                                    : () => _openOrderChat(
                                        order,
                                        ChatChannel.delivery,
                                      ),
                                onUpdateStatus: (newStatus) =>
                                    _handleUpdateStatus(order, newStatus),
                                onTap: () => _showOrderDetailsSheet(order),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
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
        title = 'Belum Ada Permintaan Pengantaran';
        desc = 'Pesanan yang diajukan akan terlihat oleh kurir KOPDES.';
        icon = Icons.local_shipping_outlined;
        break;
      case 3:
        title = 'Riwayat Kosong';
        desc = 'Belum ada transaksi selesai atau dibatalkan di toko Anda.';
        icon = Icons.history_rounded;
        break;
    }

    return EmptyStateWidget(icon: icon, title: title, description: desc);
  }

  void _showOrderDetailsSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 640,
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: AppElevation.modal,
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: AppSpacing.lg),

                      _buildInfoRow('Nama Pembeli', order.customer.name),
                      _buildInfoRow('Email', order.customer.email),
                      _buildInfoRow('Nomor HP', order.customer.phone),
                      const Divider(height: AppSpacing.lg),

                      Text(
                        'Alamat Pengiriman',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${order.deliveryAddress.recipientName} (${order.deliveryAddress.phone})',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.deliveryAddress.street}, ${order.deliveryAddress.city}, ${order.deliveryAddress.state} - ${order.deliveryAddress.postalCode}',
                        style: AppTypography.caption,
                      ),
                      const Divider(height: AppSpacing.lg),

                      _buildInfoRow(
                        'Metode Pembayaran',
                        order.paymentMethod.toUpperCase(),
                      ),
                      _buildInfoRow(
                        'Status Pembayaran',
                        order.paymentStatus.toUpperCase(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                          ),
                          child: const Text('Tutup'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final shouldStack = constraints.maxWidth < 360 || textScale > 1.25;
          final labelWidget = Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
          );
          final valueWidget = Text(
            value,
            textAlign: shouldStack ? TextAlign.left : TextAlign.right,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          );

          if (shouldStack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 2), valueWidget],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: labelWidget),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: valueWidget),
            ],
          );
        },
      ),
    );
  }
}
