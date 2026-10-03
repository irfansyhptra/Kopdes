import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/app_glass_chrome.dart';
import '../../../../shared/widgets/apple_ui.dart';

/// Batas baca dan ritme horizontal bersama untuk seluruh portal penjual.
///
/// Di ponsel konten memakai gutter 16 dp seperti beranda pelanggan. Di layar
/// lebar konten tidak dibiarkan merentang dari tepi ke tepi; hal ini menjaga
/// angka, form, dan kartu tetap mudah dipindai.
class SellerContentBoundary extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final Alignment alignment;

  const SellerContentBoundary({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 920,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 840
            ? AppSpacing.xl
            : AppSpacing.base;
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: horizontal),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Kerangka halaman utama pada tab penjual.
///
/// Header merah adalah satu-satunya bidang ekspresif. Konten di bawahnya
/// memakai permukaan solid supaya hierarki dan performa tetap baik.
class SellerPageChrome extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? headerChild;
  final Widget body;

  const SellerPageChrome({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.actions = const [],
    this.headerChild,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surfaceSoft,
      child: Column(
        children: [
          GlassPageHeader(
            title: title,
            subtitle: subtitle,
            actions: actions,
            child: headerChild,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Header untuk halaman turunan (form dan detail) dengan tombol kembali yang
/// tetap memiliki target sentuh 44 dp.
class SellerSubpageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final List<Widget> actions;

  const SellerSubpageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkRed, AppColors.brightRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxxl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.base,
            AppSpacing.sm,
            AppSpacing.base,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              GlassIconButton(
                icon: Icons.arrow_back_rounded,
                label: 'Kembali',
                onDark: true,
                onTap: onBack,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xE6FFFFFF),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (final action in actions) ...[
                const SizedBox(width: AppSpacing.sm),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge tonal untuk status operasional. Ikon dan teks membuat status tetap
/// dapat dibedakan tanpa mengandalkan warna saja.
class SellerStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const SellerStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kelompok bidang/form dengan judul yang konsisten dan permukaan solid.
class SellerSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SellerSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.padding = const EdgeInsets.all(AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: AppTypography.captionSmall.copyWith(height: 1.4),
              ),
            ],
            const SizedBox(height: AppSpacing.base),
          ],
          child,
        ],
      ),
    );
  }
}

/// Scrim pemrosesan bersama; state tetap terlihat di belakang dan fokus
/// visual tertahan pada indikator progres.
class SellerLoadingScrim extends StatelessWidget {
  final Widget child;

  const SellerLoadingScrim({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.32),
        child: Center(child: child),
      ),
    );
  }
}
