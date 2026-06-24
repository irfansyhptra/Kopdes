import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'responsive_layout.dart';
import 'custom_bottom_nav_bar.dart';
import '../../core/theme/theme.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _MobileShell(
        navigationShell: navigationShell,
        onTap: (index) => _onTap(context, index),
      ),
      desktop: _DesktopShell(
        navigationShell: navigationShell,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _MobileShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: CustomBottomNavBar(
        navigationShell: navigationShell,
        onTap: onTap,
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const _DesktopShell({required this.navigationShell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(
                right: BorderSide(color: AppColors.hairlineSoft, width: 1),
              ),
            ),
            child: NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: onTap,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              indicatorColor: AppColors.primaryTint,
              selectedLabelTextStyle: AppTypography.captionSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelTextStyle: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
              ),
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(
                    Icons.home_rounded,
                    color: AppColors.primary,
                  ),
                  label: Text('Beranda'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                  label: Text('Marketplace'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                  ),
                  label: Text('AI Assistant'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                  ),
                  label: Text('Pesanan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                  ),
                  label: Text('Profil'),
                ),
              ],
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
