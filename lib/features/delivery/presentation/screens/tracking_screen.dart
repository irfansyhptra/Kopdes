import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../localization/app_localizations.dart';

class TrackingScreen extends StatelessWidget {
  final String deliveryId;

  const TrackingScreen({super.key, required this.deliveryId});

  Widget _buildHeaderButton({
    required Widget child,
    Color backgroundColor = const Color(0x26FFFFFF),
    Color borderColor = const Color(0x1AFFFFFF),
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCustomHeader(BuildContext context, AppLocalizations? localizations) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localizations?.translate('orderTracking') ?? 'Lacak Pesanan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _buildCustomHeader(context, localizations),
          // ─── Map Placeholder ───
          Container(
            height: 200,
            margin: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapPainter())),
                // Origin
                Positioned(
                  left: 50,
                  top: 45,
                  child: _MapMarker(
                    icon: Icons.storefront_rounded,
                    label: 'UMKM',
                    color: AppColors.primary,
                  ),
                ),
                // Destination
                Positioned(
                  right: 60,
                  bottom: 35,
                  child: _MapMarker(
                    icon: Icons.home_rounded,
                    label: 'Tujuan',
                    color: AppColors.ink,
                  ),
                ),
                // Courier
                Positioned(
                  left: 150,
                  top: 80,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: AppColors.onPrimary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Courier Info ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'B',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budi Santoso',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Honda Supra X • AB 1234 CD',
                          style: AppTypography.captionSmall,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '4.9',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── Timeline ───
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _TimelineStep(
                  title: 'Paket Sedang Diantar',
                  description: 'Kurir menuju lokasi Anda. Estimasi: 15 menit.',
                  time: '14:20',
                  isActive: true,
                ),
                _TimelineStep(
                  title: 'Pesanan Diambil Kurir',
                  description: 'Paket diserahkan oleh Toko UMKM Mandiri.',
                  time: '13:55',
                ),
                _TimelineStep(
                  title: 'Pembayaran Terverifikasi',
                  description: 'Dana berhasil diverifikasi via QRIS.',
                  time: '13:40',
                ),
                _TimelineStep(
                  title: 'Pesanan Dibuat',
                  description: 'Pesanan terdaftar di sistem KOPDES.',
                  time: '13:30',
                  isLast: true,
                ),
              ],
            ),
          ),

          // ─── Confirm Button ───
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Pesanan selesai dikonfirmasi'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    );
                    context.go('/home');
                  },
                  child: Text(
                    'Konfirmasi Paket Diterima',
                    style: AppTypography.buttonMd.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ───

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MapMarker({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String description;
  final String time;
  final bool isActive;
  final bool isLast;

  const _TimelineStep({
    required this.title,
    required this.description,
    required this.time,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isActive ? AppColors.primary : AppColors.hairline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        SizedBox(
          width: 46,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              time,
              style: AppTypography.captionSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.mutedSoft,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
        // Dot + line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 1.5, height: 48, color: AppColors.hairlineSoft),
          ],
        ),
        const SizedBox(width: AppSpacing.base),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.ink : AppColors.mutedSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: AppTypography.captionSmall.copyWith(
                  color: isActive ? AppColors.muted : AppColors.mutedSoft,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.hairlineSoft.withOpacity(0.5)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Grid
    for (double i = 0; i < size.width; i += 24) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 24) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Route path
    final routePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(70, 65)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.2, 160, 100)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.75,
        size.width - 80,
        size.height - 50,
      );

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
