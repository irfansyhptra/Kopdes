import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/employee_responsive.dart';
import '../employee_theme.dart';
import '../providers/employee_providers.dart';
import '../widgets/ai_insight_banner.dart';
import '../widgets/dashboard_insight_panels.dart';
import '../widgets/employee_bottom_navigation.dart';
import '../widgets/employee_header.dart';
import '../widgets/employee_kpi_section.dart';
import '../widgets/quick_access_section.dart';
import '../widgets/today_orders_section.dart';

/// Beranda Pegawai Kopdes.
///
/// `CustomScrollView` + sliver, dan setiap bagian mengelola loading/error-nya
/// sendiri: satu endpoint yang lambat tidak boleh menahan seluruh halaman,
/// dan satu yang gagal tidak boleh mengosongkannya.
class KopdesEmployeeDashboardPage extends ConsumerWidget {
  const KopdesEmployeeDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = KopdesResponsiveSpec.fromWidth(constraints.maxWidth);

        final dashboard = RefreshIndicator(
          color: KopdesEmployeeColors.primary,
          onRefresh: () async {
            ref.invalidate(employeeSummaryProvider);
            ref.invalidate(todayOrdersProvider);
            ref.invalidate(stockSummaryProvider);
            ref.invalidate(financeSummaryProvider);
            ref.invalidate(storeStatusProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: KopdesEmployeeHeader()),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: spec.pagePadding),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: KopdesSpacing.base),
                    EmployeeKpiSection(columns: spec.kpiColumns),
                    const SizedBox(height: KopdesSpacing.base),
                    QuickAccessSection(columns: spec.quickActionColumns),
                    const SizedBox(height: KopdesSpacing.base),
                    TodayOrdersSection(compact: spec.isCompact),
                    const SizedBox(height: KopdesSpacing.base),
                    DashboardInsightPanels(spec: spec),
                    const SizedBox(height: KopdesSpacing.base),
                    const KopdesAiInsightBanner(),
                    // Ruang untuk bottom navigation: tanpa ini banner AI
                    // tertutup bar dan tidak pernah bisa ditekan.
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          backgroundColor: KopdesEmployeeColors.background,
          // Bilahnya mengambang, jadi isi boleh lewat di belakangnya — ruang
          // amannya sudah disediakan `SizedBox` di kaki daftar.
          extendBody: true,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: spec.maxContentWidth),
              child: dashboard,
            ),
          ),
          bottomNavigationBar: const EmployeeBottomNavigation(
            activeItem: EmployeeNavItem.home,
          ),
        );
      },
    );
  }
}
