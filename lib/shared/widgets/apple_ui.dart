import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/theme.dart';
import 'product_image_loader.dart';

// ─────────────────────────────────────────────────────────────
// Apple-inspired UI kit
//
// Aturan main (lihat apple-inspired-ui/references/visual-system.md):
// • Kedalaman visual = hierarki nyata. Kartu konten pakai hairline + bayangan
//   halus, bukan glass. Glass HANYA untuk lapisan yang mengambang di atas
//   konten yang bergerak: bottom nav & overlay control.
// • Satu warna aksen (AppColors.primary) + warna semantik. Tidak ada pelangi.
// • Radius, spasi, dan durasi selalu dari token, tidak pernah angka lepas.
// • Target sentuh minimal 44×44. Motion dimatikan saat reduce-motion aktif.
// ─────────────────────────────────────────────────────────────

/// Skala radius Apple: radius dalam = radius luar − inset.
///
/// Nilainya diturunkan dari [AppRadius], bukan ditulis ulang. Dua skala radius
/// yang hidup berdampingan sudah sempat menyimpang — kartu di aplikasi 20px
/// sementara kartu yang sama di web 24px — dan selisih itu tidak pernah
/// ketahuan dari membaca satu berkas saja.
class AppleRadii {
  static const double control = AppRadius.sm; // 12
  static const double tile = AppRadius.lg; // 20
  static const double card = AppRadius.card; // 24
  static const double group = AppRadius.card; // 24
  static const double floating = AppRadius.xxl; // 28
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

// ─────────────────────────────────────────────────────────────
// Interaksi: pressed-state halus, satu implementasi untuk semua komponen.
// ─────────────────────────────────────────────────────────────

/// Menambahkan state `pressed` (skala + peredupan) pada elemen yang bisa
/// ditekan. Menggantikan InkWell ripple Material dengan respon ala iOS.
class ApplePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  /// Status terpilih, untuk kontrol seperti tab, chip, dan segmented control.
  ///
  /// Harus lewat sini, bukan lewat `Semantics(selected: ...)` di luar: widget
  /// ini sudah membuat node semantics sendiri, jadi pembungkus di luar menjadi
  /// node terpisah dan flagnya tidak pernah ikut pada node yang dibacakan
  /// pembaca layar bersama labelnya.
  final bool? selected;

  const ApplePressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.borderRadius,
    this.semanticLabel,
    this.selected,
  });

  @override
  State<ApplePressable> createState() => _ApplePressableState();
}

class _ApplePressableState extends State<ApplePressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && widget.onTap != null) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return widget.child;

    final reduce = _reduceMotion(context);
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap!.call();
        },
        child: AnimatedScale(
          scale: _down && !reduce ? widget.pressedScale : 1.0,
          duration: reduce ? Duration.zero : AppAnimation.fast,
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _down ? 0.86 : 1.0,
            duration: reduce ? Duration.zero : AppAnimation.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Material: liquid glass (dipakai terbatas) & kartu konten (default)
// ─────────────────────────────────────────────────────────────

/// Liquid glass. Pakai hanya untuk lapisan mengambang. `BackdropFilter` mahal —
/// jangan tempel di elemen yang dirender berulang di dalam list.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final List<BoxShadow>? shadow;
  final Border? border;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = AppleRadii.floating,
    this.blur = AppGlass.blur,
    this.padding,
    this.tint,
    this.shadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final fill = tint ?? AppGlass.fill;
    final br = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadow ?? AppGlass.lift,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Fallback solid tetap terbaca kalau blur tidak dirender.
              color: fill,
              borderRadius: br,
              border: border ?? Border.all(color: AppGlass.stroke, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Kartu konten standar: permukaan solid, hairline, bayangan sangat halus.
class AppleCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool clip;

  const AppleCard({
    super.key,
    required this.child,
    this.radius = AppleRadii.card,
    this.padding,
    this.onTap,
    this.clip = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);

    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: br,
        border: Border.all(color: AppColors.hairlineSoft, width: 1),
        // `soft`, sepadan dengan `--sh-soft` pada `.kc-card` di web; `hairline`
        // membuat kartu aplikasi tampak rata sementara kartu web terangkat.
        boxShadow: AppElevation.soft,
      ),
      child: clip ? ClipRRect(borderRadius: br, child: child) : child,
    );

    return ApplePressable(onTap: onTap, borderRadius: br, child: body);
  }
}

// ─────────────────────────────────────────────────────────────
// Section header — satu pola untuk seluruh aplikasi
// ─────────────────────────────────────────────────────────────

class AppleSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry padding;

  const AppleSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.base),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.captionSmall),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            // 44×44 target sentuh, walau labelnya kecil.
            ApplePressable(
              onTap: onAction,
              pressedScale: 1.0,
              semanticLabel: '$actionLabel $title',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kepadatan vertikal sebuah section.
///
/// [compact] dipakai ketika isinya singkat seperti grid KPI atau pintasan.
/// [regular] memberi napas lebih untuk formulir, grafik, dan isi yang perlu
/// dibaca lebih lama.
enum AppleSectionDensity { compact, regular }

/// Section adaptif yang menyatukan judul dan isi tanpa membuat kartu tambahan.
///
/// Pengelompokan dibawa oleh alignment dan jarak. Permukaan/kartu hanya dibuat
/// oleh [child] bila kontennya memang membutuhkan satu kelompok interaksi.
class AppleSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final AppleSectionDensity density;
  final EdgeInsetsGeometry headerPadding;

  const AppleSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.density = AppleSectionDensity.compact,
    this.headerPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(
          title: title,
          subtitle: subtitle,
          actionLabel: actionLabel,
          onAction: onAction,
          padding: headerPadding,
        ),
        SizedBox(
          height: density == AppleSectionDensity.compact
              ? AppSpacing.sm
              : AppSpacing.md,
        ),
        child,
      ],
    );
  }
}

typedef AppleGridExtentBuilder =
    double Function(BuildContext context, double itemWidth);

/// Grid Apple-style yang memilih jumlah kolom dari lebar yang benar-benar ada.
///
/// [minimumItemWidth] menjaga tile tidak menyempit sampai teks dan target sentuh
/// bertabrakan. [maxColumns] membatasi density di layar lebar. Tinggi tile bisa
/// mengikuti Dynamic Type lewat [itemExtentBuilder], sehingga desain menjadi
/// lebih rapat pada teks normal tetapi tetap tumbuh saat teks diperbesar.
class AppleResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minimumItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;
  final AppleGridExtentBuilder? itemExtentBuilder;

  const AppleResponsiveGrid({
    super.key,
    required this.children,
    this.minimumItemWidth = 136,
    this.maxColumns = 4,
    this.spacing = AppSpacing.md,
    this.runSpacing = AppSpacing.md,
    this.childAspectRatio = 1,
    this.itemExtentBuilder,
  }) : assert(minimumItemWidth > 0),
       assert(maxColumns > 0);

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minimumItemWidth;
        final fittingColumns =
            ((availableWidth + spacing) / (minimumItemWidth + spacing)).floor();
        final columns = fittingColumns.clamp(1, maxColumns);
        final itemWidth = (availableWidth - spacing * (columns - 1)) / columns;
        final itemExtent = itemExtentBuilder?.call(context, itemWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            mainAxisExtent: itemExtent,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Batas lebar dan gutter adaptif yang sama untuk customer, UMKM, dan Kopdes.
class AppleContentBoundary extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const AppleContentBoundary({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 1024
            ? AppSpacing.xl
            : constraints.maxWidth >= 600
            ? AppSpacing.lg
            : constraints.maxWidth < 360
            ? AppSpacing.md
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

// ─────────────────────────────────────────────────────────────
// Card menu — tile kategori/menu bergaya iOS (squircle tonal)
// ─────────────────────────────────────────────────────────────

class AppleMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Warna isian squircle ikon — pola ikon iOS Settings. Biarkan null untuk
  /// tile netral. Pakai palet tenang & terbatas, jangan pelangi penuh.
  final Color? tint;
  final bool selected;
  final VoidCallback? onTap;
  final double size;

  /// Lebar tile. Default mengikuti ukuran ikonnya — pas untuk rail mendatar.
  /// Grid mengisinya dengan lebar selnya supaya label punya ruang penuh.
  final double? width;

  const AppleMenuTile({
    super.key,
    required this.icon,
    required this.label,
    this.tint,
    this.selected = false,
    this.onTap,
    this.size = 58,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);
    final filled = tint != null;

    final bg = filled ? tint! : AppColors.surfaceSoft;
    final fg = filled ? AppColors.onPrimary : AppColors.body;

    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        // Lebar mengikuti ukuran ikon supaya tile bisa dipadatkan dari
        // pemanggilnya tanpa label jadi berdesakan.
        width: width ?? size + 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: reduce ? Duration.zero : AppAnimation.fast,
              curve: Curves.easeOut,
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppleRadii.tile),
                // Terpilih ditandai cincin aksen di luar squircle.
                border: Border.all(
                  color: selected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  // Radius dalam = radius luar − inset padding.
                  borderRadius: BorderRadius.circular(AppleRadii.tile - 3),
                  border: filled
                      ? null
                      : Border.all(color: AppColors.hairlineSoft, width: 1),
                ),
                child: Icon(icon, color: fg, size: 24),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 11.5,
                height: 1.2,
                // Status terpilih lewat warna DAN bobot, tidak warna saja.
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Palet tint tile menu — desaturasi, tenang, cukup untuk membedakan kategori
/// tanpa melawan warna aksen produk.
class AppleTints {
  static const List<Color> palette = [
    Color(0xFFB4693C), // terracotta
    Color(0xFF3A7CA5), // biru laut
    Color(0xFFC08A2E), // amber tua
    Color(0xFF7A5EA8), // ungu
    Color(0xFFB05070), // mawar
    Color(0xFF3F8A6E), // hijau
  ];

  static Color at(int i) => palette[i % palette.length];
}

// ─────────────────────────────────────────────────────────────
// Chip filter — segmented-style, bukan Material ChoiceChip
// ─────────────────────────────────────────────────────────────

class AppleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const AppleChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion(context);

    // Pil tetap terlihat 36, area sentuhnya 44 — batas Apple HIG. Yang boleh
    // ringkas tampilannya, bukan sasaran jarinya. Wadah chip di layar juga
    // dinaikkan ke 44; sebelumnya `SizedBox(height: 34)` bahkan memotong
    // pil 36-nya sendiri.
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.96,
      semanticLabel: label,
      child: SizedBox(
        height: 44,
        child: Center(
          child: AnimatedContainer(
            duration: reduce ? Duration.zero : AppAnimation.fast,
            curve: Curves.easeOut,
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.hairline,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTypography.buttonSm.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.onPrimary : AppColors.body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Kontrol kecil di atas media — inilah pemakaian glass yang kedua
// ─────────────────────────────────────────────────────────────

/// Tombol bulat translusen di atas gambar produk (favorit, dsb).
///
/// Sengaja TIDAK memakai BackdropFilter: tombol ini muncul sekali per kartu,
/// jadi di grid 20 produk berarti 20 lapisan blur yang harus dirender ulang
/// setiap frame saat menggulir. Isian putih pekat memberi keterbacaan yang
/// sama di atas foto apa pun dengan biaya nol.
class AppleGlassIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;

  const AppleGlassIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.iconColor,
    this.onTap,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.90,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppGlass.fillSolidSoft,
          shape: BoxShape.circle,
          boxShadow: AppElevation.hairline,
        ),
        child: Icon(icon, size: size * 0.5, color: iconColor ?? AppColors.body),
      ),
    );
  }
}

/// Tombol aksi utama pada kartu (tambah ke keranjang). Solid, bukan glass:
/// ini aksi primer, harus punya kontras penuh.
class AppleAddButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final IconData icon;
  final String semanticLabel;

  const AppleAddButton({
    super.key,
    this.onTap,
    this.size = 32,
    this.icon = Icons.add_rounded,
    this.semanticLabel = 'Tambah ke keranjang',
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.88,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.hairline,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.onPrimary : AppColors.mutedSoft,
          size: size * 0.56,
        ),
      ),
    );
  }
}

/// Badge kecil (diskon, "Baru"). Tonal, bukan gradien menyala.
class AppleBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const AppleBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(
          color: AppColors.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card item — kartu produk untuk grid & carousel
// ─────────────────────────────────────────────────────────────

/// Rasio lebar:tinggi kartu produk.
///
/// Dipakai bersama oleh grid dan carousel supaya kartu yang sama tidak punya
/// dua tinggi tergantung siapa yang menggambarnya.
///
/// Angkanya ikut skala teks: pada teks besar kartu perlu lebih tinggi, kalau
/// tidak isinya meluber. Batas bawah 0,30 menahan kartu agar tidak jadi tiang
/// sempit pada skala teks ekstrem.
double productCardAspectRatio(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  // 0,565 — dinaikkan dari 0,53 setelah baris keterangan diringkas dan
  // isinya dirapatkan ke atas. Rasio yang lebih besar berarti kartu lebih
  // pendek pada lebar yang sama; sisa ruang yang dulu menganga antara
  // keterangan dan harga sekarang tidak ada lagi.
  return (0.565 / textScale.clamp(1.0, 1.8)).clamp(0.30, 0.565);
}

/// Rasio untuk [AppleProductTile], yang isinya lebih pendek.
///
/// Kartu Marketplace punya baris rating dan jarak serta kemungkinan baris
/// harga coret; [AppleProductTile] tidak. Memakai satu rasio untuk keduanya
/// menyisakan lubang kosong di tengah kartu yang lebih pendek — jadi keduanya
/// punya anggaran tingginya sendiri, dan keduanya tetap ikut skala teks.
double compactProductCardAspectRatio(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  // 0,62 diukur, bukan ditebak: 0,66 meluber 6px pada kartu 196dp, dan 0,64
  // masih meluber 4,3px pada kartu 172dp — nama panjang membungkus lebih
  // banyak baris justru ketika kartunya paling sempit.
  return (0.62 / textScale.clamp(1.0, 1.8)).clamp(0.34, 0.62);
}

/// Lebar satu kartu pada carousel mendatar.
///
/// [availableWidth] adalah lebar yang benar-benar diberikan kepada daftarnya —
/// dari `LayoutBuilder`, bukan dari `MediaQuery.sizeOf`. Kartu di dalam panel
/// selebar 400dp pada tablet 1024dp harus mengikuti panelnya, bukan layarnya.
///
/// Sekitar 1,75 kartu terlihat sekaligus, sehingga potongan kartu berikutnya
/// di tepi menandakan daftarnya bisa digeser. Dijepit 172–200dp supaya pada
/// 320dp kartunya tidak menyempit sampai namanya tinggal satu kata per baris,
/// dan pada 430dp tidak melebar sampai hanya satu kartu yang muat.
double productCardWidth(double availableWidth) {
  final usable = availableWidth - AppSpacing.base * 2;
  return (usable / 1.75).clamp(172.0, 200.0);
}

class AppleProductTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String price;
  final String? originalPrice;
  final String? badge;
  final Color? badgeColor;
  final String? meta;
  final bool? isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final double imageHeight;
  final BoxFit imageFit;

  const AppleProductTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.subtitle,
    this.originalPrice,
    this.badge,
    this.badgeColor,
    this.meta,
    this.isFavorite,
    this.onFavoriteTap,
    this.onTap,
    this.onAdd,
    this.imageHeight = 132,
    this.imageFit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return AppleCard(
      onTap: onTap,
      radius: AppleRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media plate: warna netral, gambar jadi satu-satunya warna kuat.
          Stack(
            children: [
              Container(
                height: imageHeight,
                width: double.infinity,
                color: AppColors.surfaceSoft,
                child: ProductImageLoader(imageUrl: imageUrl, fit: imageFit),
              ),
              if (badge != null)
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: AppleBadge(label: badge!, color: badgeColor),
                ),
              if (isFavorite != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: AppleGlassIconButton(
                    icon: isFavorite!
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor: isFavorite!
                        ? AppColors.primary
                        : AppColors.muted,
                    semanticLabel: isFavorite!
                        ? 'Hapus dari favorit'
                        : 'Simpan ke favorit',
                    onTap: onFavoriteTap,
                  ),
                ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: AppColors.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    price,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                if (originalPrice != null) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    originalPrice!,
                                    style: AppTypography.captionSmall.copyWith(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (meta != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                meta!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onAdd != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppleAddButton(onTap: onAdd),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Item list — inset grouped list ala iOS Settings
// ─────────────────────────────────────────────────────────────

/// Membungkus baris-baris menjadi satu grup dengan separator hairline.
/// Menggantikan tumpukan kartu mengambang: pengelompokan tanpa noise.
class AppleListGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final double indent;

  const AppleListGroup({
    super.key,
    required this.children,
    this.margin,
    this.indent = 84,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: indent,
            color: AppColors.hairlineSoft,
          ),
        );
      }
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppleRadii.group),
        border: Border.all(color: AppColors.hairlineSoft, width: 1),
        // `soft`, sepadan dengan `--sh-soft` pada `.kc-card` di web; `hairline`
        // membuat kartu aplikasi tampak rata sementara kartu web terangkat.
        boxShadow: AppElevation.soft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleRadii.group),
        child: Column(children: rows),
      ),
    );
  }
}

/// Baris produk untuk [AppleListGroup].
class AppleProductRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String price;
  final String? meta;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const AppleProductRow({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    this.subtitle,
    this.meta,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      pressedScale: 0.99,
      semanticLabel: title,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              // Radius dalam = radius grup − inset.
              borderRadius: BorderRadius.circular(
                AppleRadii.group - AppSpacing.md,
              ),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.surfaceSoft,
                child: ProductImageLoader(imageUrl: imageUrl),
              ),
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
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Text(
                        price,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: AppColors.ink,
                        ),
                      ),
                      if (meta != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (onAdd != null)
              AppleAddButton(onTap: onAdd, size: 34)
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedSoft,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

/// Format rupiah standar aplikasi — sebelumnya diduplikasi di 5 layar.
///
/// Pola dikompilasi sekali di tingkat pustaka. Versi lama membangun ulang
/// RegExp pada setiap panggilan, dan fungsi ini dipanggil sekali per kartu
/// per frame saat menggulir.
final RegExp _thousands = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

String formatRupiah(num value) => 'Rp${formatThousands(value)}';

/// Nama bulan ditulis sendiri, bukan lewat `DateFormat(..., 'id_ID')`.
///
/// Locale itu menuntut `initializeDateFormatting()` dipanggil saat aplikasi
/// mulai, dan aplikasi ini tidak memanggilnya — memakainya membuat baris
/// tanggal melempar `LocaleDataException` alih-alih menampilkan tanggal.
const _monthsId = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "4 Okt 2026".
String shortDateId(DateTime d) =>
    '${d.day} ${_monthsId[d.month - 1]} ${d.year}';

/// "4 Okt 2026, 16.20".
String dateTimeId(DateTime d) =>
    '${shortDateId(d)}, ${d.hour.toString().padLeft(2, '0')}.'
    '${d.minute.toString().padLeft(2, '0')}';

/// Angka dengan pemisah ribuan, tanpa "Rp" — untuk poin, jumlah, dan sejenisnya.
String formatThousands(num value) =>
    value.toStringAsFixed(0).replaceAllMapped(_thousands, (m) => '${m[1]}.');

/// Tinggi tile angka pada dasbor (KPI 2 kolom).
///
/// `mainAxisExtent`, bukan `childAspectRatio`: isinya — ikon, label, dan
/// satu angka — tingginya tidak bergantung pada lebar kartu, jadi mengikatnya
/// lewat `childAspectRatio` hanya membuat tile meluber di layar sempit dan
/// berlubang di tablet.
double dashboardTileHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return 104.0 + 52.0 * (textScale.clamp(1.0, 2.0) - 1);
}

/// Tinggi tile pintasan fitur, yang punya subjudul dua baris.
double featureTileHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
  return 112.0 + 72.0 * (textScale.clamp(1.0, 2.0) - 1);
}
