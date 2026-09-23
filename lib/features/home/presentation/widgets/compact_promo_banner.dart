import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/product_image_loader.dart';

/// Satu slide banner promosi.
class PromoBannerItem {
  final String badge;
  final String title;
  final String highlight;
  final String description;
  final String cta;
  final IconData icon;

  /// Gambar iklan dari `Banner.imageUrl`. Null atau gagal dimuat berarti
  /// artwork gambar sendiri yang tampil — banner tetap terbaca meski
  /// gambarnya belum diunggah admin atau jaringannya putus.
  final String? imageUrl;

  const PromoBannerItem({
    required this.badge,
    required this.title,
    required this.highlight,
    required this.description,
    required this.cta,
    required this.icon,
    this.imageUrl,
  });
}

/// Banner promosi ringkas setinggi ±100px.
///
/// Menggantikan banner 168px sebelumnya. Ketiga slide-nya dipertahankan —
/// hanya tingginya yang dipadatkan supaya lebih banyak bagian beranda muat
/// dalam satu viewport.
class CompactPromoBanner extends StatefulWidget {
  final List<PromoBannerItem> items;
  final ValueChanged<PromoBannerItem> onCtaTap;

  /// Tinggi kartu. Beranda memakai bawaan 100 karena banner di sana hanyalah
  /// satu section di antara banyak; Marketplace mengirim nilai adaptif yang
  /// lebih tinggi karena di sana banner adalah iklan utama halaman.
  final double height;

  /// Pergeseran otomatis. Mati secara bawaan supaya perilaku beranda tidak
  /// ikut berubah hanya karena Marketplace membutuhkannya.
  final bool autoPlay;

  const CompactPromoBanner({
    super.key,
    required this.items,
    required this.onCtaTap,
    this.height = 100,
    this.autoPlay = false,
  });

  /// Isi bawaan, dipakai selama banner belum datang dari API.
  static const List<PromoBannerItem> defaultItems = [
    PromoBannerItem(
      badge: 'GRATIS ONGKIR',
      title: 'Pengiriman Cepat',
      highlight: 'Kurir Desa',
      description:
          'Pengantaran langsung ke rumah warga oleh armada resmi KMP Mitra.',
      cta: 'Pesan Sekarang',
      icon: Icons.local_shipping_rounded,
    ),
    PromoBannerItem(
      badge: 'PROMO ANGGOTA',
      title: 'Belanja Hemat',
      highlight: 'Minggu Ini',
      description: 'Diskon spesial untuk anggota KMP Mitra.',
      cta: 'Belanja Sekarang',
      icon: Icons.local_offer_rounded,
    ),
    PromoBannerItem(
      badge: 'DISKON SEMBAKO',
      title: 'Beras & Minyak',
      highlight: 'Super Murah',
      description: 'Sembako berkualitas dengan harga subsidi anggota.',
      cta: 'Lihat Promo',
      icon: Icons.shopping_basket_rounded,
    ),
  ];

  @override
  State<CompactPromoBanner> createState() => _CompactPromoBannerState();
}

class _CompactPromoBannerState extends State<CompactPromoBanner> {
  final PageController _controller = PageController();

  /// Indikator halaman memakai ValueNotifier, bukan setState: menggeser banner
  /// hanya perlu membangun ulang deretan titik, bukan seluruh banner.
  final ValueNotifier<int> _page = ValueNotifier<int>(0);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAuto();
  }

  @override
  void didUpdateWidget(covariant CompactPromoBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.items.length != widget.items.length) {
      _startAuto();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _page.dispose();
    super.dispose();
  }

  /// Selalu membatalkan timer lama lebih dulu: [didUpdateWidget] bisa terpanggil
  /// berkali-kali, dan dua timer berjalan bersamaan membuat banner melewati
  /// satu slide setiap putaran.
  void _startAuto() {
    _timer?.cancel();
    _timer = null;
    if (!widget.autoPlay || widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
  }

  /// Sentuhan pengguna menghentikan putaran otomatis untuk seterusnya. Banner
  /// yang bergeser sendiri tepat saat sedang dibaca lebih mengganggu daripada
  /// membantu, dan pengguna yang sudah menggeser manual jelas ingin memilih
  /// sendiri.
  void _stopAuto() {
    _timer?.cancel();
    _timer = null;
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    final next = (_page.value + 1) % widget.items.length;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.jumpToPage(next);
    } else {
      _controller.animateToPage(
        next,
        duration: AppAnimation.slow,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (_) => _stopAuto(),
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (i) => _page.value = i,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base,
                ),
                child: _BannerCard(
                  item: widget.items[index],
                  tall: widget.height >= 118,
                  onCtaTap: () => widget.onCtaTap(widget.items[index]),
                ),
              ),
            ),
          ),
        ),
        if (widget.items.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          ValueListenableBuilder<int>(
            valueListenable: _page,
            builder: (context, current, _) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (i) {
                final active = i == current;
                return AnimatedContainer(
                  duration: AppAnimation.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.hairline,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final PromoBannerItem item;
  final VoidCallback onCtaTap;

  /// Varian tinggi dipakai Marketplace: judul boleh dua baris, tombol turun ke
  /// bawah teks, dan artwork keranjang belanja muncul di kanan.
  final bool tall;

  const _BannerCard({
    required this.item,
    required this.onCtaTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkRed, AppColors.brightRed],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(
          tall ? AppleRadii.group : AppleRadii.card,
        ),
        boxShadow: AppElevation.hairline,
      ),
      padding: tall
          ? const EdgeInsets.all(AppSpacing.base - 2)
          : const EdgeInsets.fromLTRB(
              AppSpacing.md + 2,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
            ),
      child: tall ? _tallLayout() : _compactLayout(),
    );
  }

  /// Tata letak beranda: teks di kiri, ikon dan tombol di kanan.
  Widget _compactLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x38FFFFFF),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Judul + sorotan digabung dalam satu paragraf supaya
              // pembaca layar membacanya sebagai satu kalimat.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${item.title} '),
                    TextSpan(
                      text: item.highlight,
                      style: const TextStyle(color: AppColors.yellowAccent),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xD9FFFFFF),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: const Color(0xE6FFFFFF), size: 22),
            const SizedBox(height: 6),
            ApplePressable(
              onTap: onCtaTap,
              pressedScale: 0.94,
              semanticLabel: item.cta,
              child: Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  item.cta,
                  maxLines: 1,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tata letak Marketplace: teks dan tombol di kiri, artwork keranjang di
  /// kanan. Artwork dilepas pada lebar sempit supaya teks tidak terhimpit —
  /// kalau keduanya tidak muat berdampingan, teks yang menang.
  Widget _tallLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _badge(),
                  const SizedBox(height: AppSpacing.xs + 1),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${item.title} '),
                          TextSpan(
                            text: item.highlight,
                            style: const TextStyle(
                              color: AppColors.yellowAccent,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xD9FFFFFF),
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 1),
                  _ctaButton(),
                ],
              ),
            ),
            if (constraints.maxWidth >= 300) ...[
              const SizedBox(width: AppSpacing.md),
              _BannerArtwork(icon: item.icon, imageUrl: item.imageUrl),
            ],
          ],
        );
      },
    );
  }

  Widget _badge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0x38FFFFFF),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      item.badge,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: AppColors.yellowAccent,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        height: 1.2,
      ),
    ),
  );

  Widget _ctaButton() => ApplePressable(
    onTap: onCtaTap,
    pressedScale: 0.96,
    semanticLabel: item.cta,
    child: Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        item.cta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    ),
  );
}

/// Artwork banner: keranjang belanja dengan isi khas Kopdes.
///
/// Digambar dari ikon Material, bukan aset gambar — banner ini datang dari API
/// dan bisa berganti kapan saja, jadi ilustrasinya harus ikut ganti tanpa perlu
/// aset baru per kampanye.
class _BannerArtwork extends StatelessWidget {
  final IconData icon;
  final String? imageUrl;

  const _BannerArtwork({required this.icon, this.imageUrl});

  /// Beras, minyak, kopi, dan makanan ringan — isi keranjang khas warga desa.
  static const _goods = <IconData>[
    Icons.rice_bowl_rounded,
    Icons.water_drop_rounded,
    Icons.coffee_rounded,
    Icons.cookie_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // Dekoratif murni: pembaca layar sudah mendapat judul, deskripsi, dan
    // tombol dari kolom teks di sebelahnya.
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ExcludeSemantics(
        child: SizedBox(
          width: 96,
          child: ProductImageLoader(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholderIconSize: 26,
          ),
        ),
      );
    }

    return ExcludeSemantics(
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0x2EFFFFFF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: AppColors.yellowAccent),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final good in _goods)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Icon(good, size: 11, color: const Color(0xCCFFFFFF)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
