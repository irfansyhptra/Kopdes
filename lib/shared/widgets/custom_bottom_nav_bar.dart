import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme.dart';

// ─────────────────────────────────────────────────────────
// Premium Minimalist Navigation Bar
// Kopdes Merah Putih — Apple-quality Material 3
// ─────────────────────────────────────────────────────────

class CustomBottomNavBar extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    super.key,
    required this.navigationShell,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Beranda',
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      useSmileHouse: true,
    ),
    _NavItem(
      label: 'Marketplace',
      activeIcon: Icons.storefront_rounded,
      inactiveIcon: Icons.storefront_outlined,
    ),
    _NavItem(
      label: 'AI Assistant',
      activeIcon: Icons.auto_awesome,
      inactiveIcon: Icons.auto_awesome_outlined,
    ),
    _NavItem(
      label: 'Pesanan',
      activeIcon: Icons.near_me_rounded,
      inactiveIcon: Icons.near_me_outlined,
    ),
    _NavItem(
      label: 'Profil',
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
    ),
  ];

  void _onTabTapped(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = widget.navigationShell.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0xFFF3F4F6),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final bool isActive = index == activeIndex;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onTabTapped(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Icon container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        transform: Matrix4.translationValues(0, isActive ? -5 : 0, 0),
                        child: item.useSmileHouse
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CustomPaint(
                                  painter: SmileHousePainter(
                                    color: isActive
                                        ? AppColors.primary
                                        : const Color(0xFF9CA3AF),
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              )
                            : Icon(
                                isActive ? item.activeIcon : item.inactiveIcon,
                                color: isActive
                                    ? AppColors.primary
                                    : const Color(0xFF9CA3AF),
                                size: 22,
                              ),
                      ),
                      const SizedBox(height: 4),
                      // Animated Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: isActive
                              ? AppColors.primary
                              : const Color(0xFF9CA3AF),
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Custom Smile House Icon Painter
// Matches the custom line logo in the reference design
// ─────────────────────────────────────────────────────────

class SmileHousePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  SmileHousePainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    final path = Path();
    
    // Draw outer house contour with rounded corners
    path.moveTo(0.15 * w, 0.82 * h);
    path.lineTo(0.15 * w, 0.45 * h);
    path.quadraticBezierTo(0.15 * w, 0.38 * h, 0.22 * w, 0.33 * h);
    path.lineTo(0.44 * w, 0.15 * h);
    path.quadraticBezierTo(0.5 * w, 0.10 * h, 0.56 * w, 0.15 * h);
    path.lineTo(0.78 * w, 0.33 * h);
    path.quadraticBezierTo(0.85 * w, 0.38 * h, 0.85 * w, 0.45 * h);
    path.lineTo(0.85 * w, 0.82 * h);
    path.quadraticBezierTo(0.85 * w, 0.9 * h, 0.78 * w, 0.9 * h);
    path.lineTo(0.22 * w, 0.9 * h);
    path.quadraticBezierTo(0.15 * w, 0.9 * h, 0.15 * w, 0.82 * h);
    
    canvas.drawPath(path, paint);

    // Draw the smile: arc in the lower-middle
    final smilePath = Path();
    smilePath.moveTo(0.38 * w, 0.65 * h);
    smilePath.quadraticBezierTo(0.5 * w, 0.74 * h, 0.62 * w, 0.65 * h);
    
    canvas.drawPath(smilePath, paint);
  }

  @override
  bool shouldRepaint(covariant SmileHousePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

// ─────────────────────────────────────────────────────────
// Nav Item Data Model
// ─────────────────────────────────────────────────────────

class _NavItem {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool useSmileHouse;

  const _NavItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    this.useSmileHouse = false,
  });
}
