import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/error_message.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/chat_models.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/screens/conversation_list_screen.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../umkm/presentation/widgets/seller_dashboard_sections.dart';
import '../../../umkm/presentation/widgets/seller_header.dart';
import '../../../umkm/presentation/widgets/store_page_ui.dart';
import '../../data/courier_repository.dart';
import '../../data/courier_tracking.dart';
import '../widgets/courier_ui.dart';
import 'courier_account_screen.dart';
import 'courier_history_screen.dart';
import 'courier_tasks_screen.dart';

/// Konsol kurir — kerangka yang sama dengan konsol UMKM dan Kopdes.
///
/// Dasbor, Tugas, Riwayat, Pesan, Akun.
class CourierDashboardScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const CourierDashboardScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CourierDashboardScreen> createState() =>
      _CourierDashboardScreenState();
}

class _CourierDashboardScreenState
    extends ConsumerState<CourierDashboardScreen> {
  late int _currentIndex = widget.initialIndex;

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    // Siaran posisi mengikuti tugas yang sedang dibawa, dipasang satu kali
    // di akar konsol supaya tetap hidup saat kurir berpindah tab.
    ref.watch(courierTrackingSyncProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _CourierOverviewTab(onNavigateTab: _onTabSelected),
          const CourierTasksScreen(),
          const CourierHistoryScreen(),
          const ConversationListScreen(channel: ChatChannel.delivery),
          const CourierAccountScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: AppGlassNavBar(
        items: const [
          GlassNavItem(
            label: 'Dasbor',
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
          ),
          GlassNavItem(
            label: 'Tugas',
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
          ),
          GlassNavItem(
            label: 'Riwayat',
            icon: Icons.history_outlined,
            activeIcon: Icons.history_rounded,
          ),
          GlassNavItem(
            label: 'Pesan',
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
          ),
          GlassNavItem(
            label: 'Akun',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
        activeIndex: _currentIndex,
        onSelect: _onTabSelected,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// TAB 0: DASBOR
// ─────────────────────────────────────────────────────────
class _CourierOverviewTab extends ConsumerWidget {
  final ValueChanged<int> onNavigateTab;

  const _CourierOverviewTab({required this.onNavigateTab});

  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(courierSummaryProvider);
    final mine = ref.watch(myTasksProvider);
    final tracking = ref.watch(courierTrackingProvider);
    final chatCount = ref
        .watch(conversationsProvider)
        .maybeWhen(
          data: (items) => items.fold<int>(0, (t, c) => t + c.unreadCount),
          orElse: () => 0,
        );

    final carrying = mine.valueOrNull
        ?.where((t) => t.stage.carrying)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: Column(
        children: [
          SellerHeader(
            storeName: user?.name ?? 'Kurir',
            statusLabel: switch (carrying) {
              null => 'Siap menerima tugas',
              _ => 'Sedang mengantar #${carrying.shortCode}',
            },
            isVerified: tracking.isBroadcasting,
            newOrderCount: summary.valueOrNull?.availableTasks ?? 0,
            chatCount: chatCount,
            notificationCount: ref.watch(unreadNotificationCountProvider),
            onOrdersTap: () => onNavigateTab(1),
            onChatTap: () => onNavigateTab(3),
            onNotificationTap: () => context.push('/notifications'),
            onSearchTap: () => onNavigateTab(1),
            onAddProductTap: () => onNavigateTab(1),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                refreshCourier(ref);
                try {
                  await ref.read(courierSummaryProvider.future);
                } catch (_) {}
              },
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = c.maxWidth > _maxContentWidth
                      ? (c.maxWidth - _maxContentWidth) / 2
                      : 0.0;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.base + side,
                      AppSpacing.md,
                      AppSpacing.base + side,
                      112,
                    ),
                    children: [
                      summary.when(
                        skipLoadingOnRefresh: true,
                        loading: () => const SectionSkeleton(height: 108),
                        error: (e, _) => SectionError(
                          message:
                              'Angka hari ini belum termuat. '
                              '${networkErrorMessage(e)}',
                          onRetry: () => ref.invalidate(courierSummaryProvider),
                        ),
                        data: (s) => CourierSummaryCard(summary: s),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Tugas yang sedang dibawa naik ke paling atas: itu
                      // satu-satunya hal yang sedang dikerjakan kurir.
                      if (carrying != null) ...[
                        const StoreSectionHeader('Sedang diantar'),
                        CourierTaskCard(
                          task: carrying,
                          onTap: () =>
                              context.push(CourierRoutes.task(carrying.id)),
                          action: TaskActionButton(
                            icon: Icons.navigation_rounded,
                            label: 'Lanjutkan Pengantaran',
                            onPressed: () =>
                                context.push(CourierRoutes.task(carrying.id)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      QuickActionsRow(
                        actions: [
                          SellerQuickAction(
                            icon: Icons.pan_tool_alt_outlined,
                            label: 'Ambil Tugas',
                            onTap: () => onNavigateTab(1),
                          ),
                          SellerQuickAction(
                            icon: Icons.local_shipping_outlined,
                            label: 'Tugas Saya',
                            onTap: () => onNavigateTab(1),
                          ),
                          SellerQuickAction(
                            icon: Icons.history_rounded,
                            label: 'Riwayat',
                            onTap: () => onNavigateTab(2),
                          ),
                          SellerQuickAction(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Pesan',
                            onTap: () => onNavigateTab(3),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      ...summary.maybeWhen(
                        skipLoadingOnRefresh: true,
                        data: (s) => [
                          AttentionSection(
                            onSeeAll: () => onNavigateTab(1),
                            items: [
                              AttentionItem(
                                icon: Icons.inbox_rounded,
                                tint: AppColors.primary,
                                title: 'Tugas tersedia',
                                urgentMessage: 'Menunggu diambil kurir',
                                calmMessage: 'Tidak ada tugas yang menunggu',
                                count: s.availableTasks,
                                onTap: () => onNavigateTab(1),
                              ),
                              AttentionItem(
                                icon: Icons.local_shipping_outlined,
                                tint: const Color(0xFF2F6FDB),
                                title: 'Tugas Anda',
                                urgentMessage: 'Sedang Anda bawa',
                                calmMessage: 'Tidak ada tugas berjalan',
                                count: s.activeTasks,
                                onTap: () => onNavigateTab(1),
                              ),
                            ],
                          ),
                        ],
                        orElse: () => const [],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
