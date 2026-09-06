import 'package:flutter/material.dart';

class PromoBannerWidget extends StatefulWidget {
  final VoidCallback onCtaTap;

  const PromoBannerWidget({super.key, required this.onCtaTap});

  @override
  State<PromoBannerWidget> createState() => _PromoBannerWidgetState();
}

class _PromoBannerWidgetState extends State<PromoBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _bannerItems = [
    {
      'badge': 'PROMO ANGGOTA',
      'titleLine1': 'Belanja Hemat',
      'titleLine2': 'Minggu Ini',
      'desc':
          'Diskon spesial untuk anggota KMP Mitra. Keuntungan lebih, belanja lebih bijak.',
      'cta': 'Belanja Sekarang',
    },
    {
      'badge': 'DISKON SEMBAKO',
      'titleLine1': 'Beras & Minyak',
      'titleLine2': 'Super Murah',
      'desc':
          'Stok sembako berkualitas tinggi dengan harga subsidi anggota koperasi.',
      'cta': 'Lihat Promo',
    },
    {
      'badge': 'GRATIS ONGKIR',
      'titleLine1': 'Pengiriman Cepat',
      'titleLine2': 'Kurir Desa',
      'desc':
          'Pengantaran langsung ke rumah warga oleh armada resmi KMP Mitra.',
      'cta': 'Pesan Sekarang',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          // Banner Container
          Container(
            height: 168,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF660713).withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  // PageView for Banner Items
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _bannerItems.length,
                    itemBuilder: (context, index) {
                      final item = _bannerItems[index];
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF660713), // Dark burgundy red
                              Color(0xFFBA0B22), // Medium deep red
                              Color(0xFFFF3048), // Bright red accent
                            ],
                            stops: [0.0, 0.55, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Soft Overlay Texture / Circles
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),

                            // Content Row (Left Text, Right Illustration)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                14,
                                14,
                                18,
                              ),
                              child: Row(
                                children: [
                                  // Left Side Text & Button
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.18,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.3,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            item['badge']!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Title
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${item['titleLine1']!}\n',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.1,
                                                ),
                                              ),
                                              TextSpan(
                                                text: item['titleLine2']!,
                                                style: const TextStyle(
                                                  color: Color(
                                                    0xFFFFD700,
                                                  ), // Gold
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),

                                        // Description
                                        Text(
                                          item['desc']!,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.85,
                                            ),
                                            fontSize: 9.5,
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),

                                        // CTA Button
                                        GestureDetector(
                                          onTap: widget.onCtaTap,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8A0012),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.4,
                                                ),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.25),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item['cta']!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right Side Illustration (Grocery Basket + Diskon Badge)
                                  Expanded(
                                    flex: 5,
                                    child: Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        // Product Basket Mock Image / Icon Graphics
                                        Container(
                                          width: 130,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.shopping_basket_rounded,
                                              color: Colors.white,
                                              size: 68,
                                            ),
                                          ),
                                        ),

                                        // Diskon % Badge Icon Overlay
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(7),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3048),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.percent_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pagination Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_bannerItems.length, (index) {
              final bool isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isActive ? 18 : 5,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE9162B)
                      : const Color(0xFFE0E0E5),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
