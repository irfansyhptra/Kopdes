import 'package:flutter/material.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String userName;
  final String userLocation;
  final int notificationCount;
  final int cartCount;
  final int chatCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onCartTap;
  final VoidCallback onChatTap;
  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  const HomeHeaderWidget({
    super.key,
    required this.userName,
    required this.userLocation,
    this.notificationCount = 5,
    this.cartCount = 3,
    this.chatCount = 2,
    required this.onNotificationTap,
    required this.onCartTap,
    required this.onChatTap,
    required this.onSearchTap,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF090A0D), // Near black
            Color(0xFF3A0710), // Dark burgundy
            Color(0xFF8F071B), // Deep red
            Color(0xFFE9162B), // Bright primary red
          ],
          stops: [0.0, 0.28, 0.58, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background Radial Glow 1 (Top-Right)
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF3048).withOpacity(0.50),
                    const Color(0xFFFF3048).withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.70],
                ),
              ),
            ),
          ),

          // Background Radial Glow 2 (Center Left)
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFA50018).withOpacity(0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Header Content Column
          Padding(
            padding: EdgeInsets.fromLTRB(18, topPadding + 14, 18, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Info & Header Action Buttons Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // KMP MITRA Logo (Circular Glass Badge)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8A0818),
                        border: Border.all(color: Colors.white, width: 2.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF3048).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white70,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.home_work_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              Text(
                                'KMP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  height: 0.9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'MITRA',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.w800,
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Greeting & User Name Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Datang Kembali,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD700),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF4A0610),
                                  size: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFFFF4D6D),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                userLocation,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3 Header Glass Action Buttons (Notification, Cart, Chat)
                    _buildGlassIconButton(
                      icon: Icons.notifications_outlined,
                      badgeCount: notificationCount,
                      onTap: onNotificationTap,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassIconButton(
                      icon: Icons.shopping_cart_outlined,
                      badgeCount: cartCount,
                      onTap: onCartTap,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassIconButton(
                      icon: Icons.chat_outlined,
                      badgeCount: chatCount,
                      onTap: onChatTap,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Neon Red Glow Curve Line Accent
                Container(
                  height: 1.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFFFF3048).withOpacity(0.8),
                        Colors.white.withOpacity(0.9),
                        const Color(0xFFFF3048).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Search Bar & Filter Button Row
                Row(
                  children: [
                    // Search Bar Input Container
                    Expanded(
                      child: GestureDetector(
                        onTap: onSearchTap,
                        // Tanpa BackdropFilter: widget ini ikut menggulir, dan
                        // blur di dalam area yang menggulir dirender ulang tiap
                        // frame. Yang ada di belakangnya hanya gradien statis
                        // milik header sendiri, jadi isian translusen terlihat
                        // sama persis dengan biaya nol.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.85),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cari produk kebutuhanmu...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.72),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filter Button (White Pill with Red Icon & Text)
                    GestureDetector(
                      onTap: onFilterTap,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: const Color(0xFFFF3048).withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFE9162B),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Filter',
                              style: TextStyle(
                                color: Color(0xFF15171C),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header Glass Button Helper
  Widget _buildGlassIconButton({
    required IconData icon,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.28),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3048),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3048).withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      height: 1,
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
