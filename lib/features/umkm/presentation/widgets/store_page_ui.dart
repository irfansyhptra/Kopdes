import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/shimmer_loading.dart';

/// Lebar isi maksimal halaman Toko di tablet.
const double storePageMaxWidth = 640;

/// Permukaan putih berisi satu kelompok informasi.
class StoreSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const StoreSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(AppleRadii.tile),
      border: Border.all(color: AppColors.hairlineSoft),
      boxShadow: AppElevation.hairline,
    ),
    child: child,
  );
}

/// Judul section dengan keterangan dan satu aksi opsional.
class StoreSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const StoreSectionHeader(this.title, {super.key, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Pil status: ikon + teks, tidak pernah warna saja.
class StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color tint;

  /// Warna teks yang terbaca (≥4,5:1) — [tint] dipakai untuk ikon & latar.
  final Color text;

  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.tint,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: text),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionSmall.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Kotak ikon kecil berwarna lembut.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final double size;

  const IconTile(this.icon, {super.key, required this.tint, this.size = 40});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(AppleRadii.control),
    ),
    child: Icon(icon, size: size * 0.5, color: tint),
  );
}

/// Baris ringkasan yang bisa ditekan: ikon, judul, nilai, chevron.
class StoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  /// Nilai kosong ditulis lebih redup supaya terbaca sebagai ajakan.
  final bool placeholder;
  final VoidCallback onTap;

  const StoreRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: '$title: $value',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              const SizedBox(width: AppSpacing.base),
              IconTile(icon, tint: AppColors.muted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: placeholder
                            ? AppColors.primaryText
                            : AppColors.muted,
                        fontWeight: placeholder
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kelompok baris dengan garis pemisah tipis.
class StoreRowGroup extends StatelessWidget {
  final List<Widget> rows;

  const StoreRowGroup({super.key, required this.rows});

  @override
  Widget build(BuildContext context) => StoreSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              indent: AppSpacing.base + 40 + AppSpacing.md,
              color: AppColors.hairlineSoft,
            ),
          rows[i],
        ],
      ],
    ),
  );
}

/// Galat satu section: kalimat + Coba Lagi. Section lain tetap tampil.
class SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SectionError({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => StoreSurface(
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.muted),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 13.5,
              color: AppColors.body,
            ),
          ),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          child: const Text('Coba Lagi'),
        ),
      ],
    ),
  );
}

/// Skeleton seukuran isi section.
class SectionSkeleton extends StatelessWidget {
  final double height;
  const SectionSkeleton({super.key, required this.height});

  @override
  Widget build(BuildContext context) => ShimmerGroup(
    child: ShimmerBox(
      width: double.infinity,
      height: height,
      borderRadius: AppleRadii.tile,
    ),
  );
}

/// Kerangka halaman turunan Toko: lebar dibatasi di tablet, bisa digulir,
/// dan ruang bawah tidak tertutup gestur sistem.
class StoreSubpageBody extends StatelessWidget {
  final List<Widget> children;
  const StoreSubpageBody({super.key, required this.children});

  @override
  Widget build(BuildContext context) => ListView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: EdgeInsets.fromLTRB(
      AppSpacing.base,
      AppSpacing.md,
      AppSpacing.base,
      AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
    ),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: storePageMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ],
  );
}
