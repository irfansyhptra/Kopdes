import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0x26FFFFFF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Card 1: KOPDES Merah Putih Banner
          Container(
            width: 150,
            height: 90,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 70,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'KOPDES MERAH PUTIH',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Anggota',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Sejak 2026',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card 2: Saldo Belanja
          _buildStatCard(
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFFD32F2F),
            title: 'Saldo Belanja',
            value: 'Rp 1.250.000',
            valueColor: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 12),
          // Card 3: Poin Koperasi
          _buildStatCard(
            icon: Icons.stars_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Poin Koperasi',
            value: '1.250 Poin',
            valueColor: const Color(0xFF1F2937),
          ),
          const SizedBox(width: 12),
          // Card 4: Status
          _buildStatCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF10B981),
            title: 'Status',
            value: 'Aktif',
            valueColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      width: 130,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildShortcutItem(
            icon: Icons.local_mall_outlined,
            label: 'Pesanan Saya',
            onTap: () => context.push('/orders/history'),
          ),
          _buildShortcutItem(
            icon: Icons.favorite_border_rounded,
            label: 'Wishlist',
            onTap: () => _showSnackBar(context, 'Fitur Wishlist segera hadir'),
          ),
          _buildShortcutItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Keranjang',
            badgeCount: 3,
            onTap: () => context.go('/cart'),
          ),
          _buildShortcutItem(
            icon: Icons.confirmation_number_outlined,
            label: 'Voucher',
            badgeCount: 6,
            onTap: () => _showSnackBar(context, 'Fitur Voucher segera hadir'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFD32F2F),
                  size: 24,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData headerIcon,
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(headerIcon, color: const Color(0xFF1F2937), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing: trailingText != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingText,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18),
                  ],
                )
              : const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 18),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFF3F4F6),
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
          backgroundColor: const Color(0xFFFFF5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Center(
                child: Text(
                  'Keluar dari Akun',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFFEF4444), size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Budi Santoso';
    final userEmail = authState.user?.email ?? 'customer@kopdes.co';
    final userPhone = authState.user?.phone ?? '0812 3456 7890';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // 1. Stack of curved red header + profile card
          SizedBox(
            height: 330,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Red background header
                Container(
                  height: 200,
                  width: double.infinity,
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
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Profil Saya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Kelola informasi & pengaturan akun Anda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildHeaderButton(
                            icon: Icons.notifications_none_rounded,
                            onTap: () => context.push('/notifications'),
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderButton(
                            icon: Icons.settings_outlined,
                            onTap: () => _showSnackBar(context, 'Pengaturan akun'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Overlapping Profile Details Card
                Positioned(
                  top: 105,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar with edit badge
                        Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/images/profile/budi_profile.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD32F2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Profile Details text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Active Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFF2E7D32),
                                      size: 12,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Anggota Aktif',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Email info
                              Row(
                                children: [
                                  const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      userEmail,
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Phone info
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 6),
                                  Text(
                                    userPhone,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Location info
                              Row(
                                children: const [
                                  Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF6B7280)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Desa Lamteh, Banda Aceh',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF9CA3AF),
                          ),
                          onPressed: () => _showSnackBar(context, 'Menuju detail profil...'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Statistics Row
          _buildStatsRow(),

          // 3. Shortcuts grid row
          _buildShortcutBar(context),
          const SizedBox(height: 8),

          // 4. Section: Akun Saya
          _buildSection(
            headerIcon: Icons.person_outline_rounded,
            title: 'Akun Saya',
            items: [
              _buildListTile(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFFF0F3),
                title: 'Detail Profil',
                subtitle: 'Lihat dan edit informasi profil Anda',
                onTap: () => _showSnackBar(context, 'Menuju detail profil...'),
              ),
              _buildListTile(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Alamat Pengiriman',
                subtitle: 'Kelola alamat pengiriman Anda',
                onTap: () => _showSnackBar(context, 'Menuju pengaturan alamat...'),
              ),
              _buildListTile(
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Metode Pembayaran',
                subtitle: 'Kelola kartu dan metode pembayaran',
                onTap: () => _showSnackBar(context, 'Menuju metode pembayaran...'),
              ),
              _buildListTile(
                icon: Icons.security_rounded,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Keamanan Akun',
                subtitle: 'Password, PIN, dan verifikasi akun',
                onTap: () => _showSnackBar(context, 'Menuju keamanan akun...'),
              ),
              _buildListTile(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Notifikasi',
                subtitle: 'Atur preferensi notifikasi Anda',
                showDivider: false,
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),

          // 5. Section: Layanan Koperasi
          _buildSection(
            headerIcon: Icons.volunteer_activism_outlined,
            title: 'Layanan Koperasi',
            items: [
              _buildListTile(
                icon: Icons.headset_mic_outlined,
                iconColor: const Color(0xFF8B5CF6),
                iconBgColor: const Color(0xFFF5F3FF),
                title: 'Hubungi CS Koperasi',
                subtitle: 'Chat langsung dengan tim kami',
                onTap: () => _showSnackBar(context, 'Menghubungi Customer Service Koperasi...'),
              ),
              _buildListTile(
                icon: Icons.receipt_long_outlined,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Riwayat Transaksi',
                subtitle: 'Lihat semua transaksi Anda',
                onTap: () => _showSnackBar(context, 'Fitur Riwayat Transaksi segera hadir'),
              ),
              _buildListTile(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Riwayat Pesanan',
                subtitle: 'Lihat pesanan dan status pengiriman',
                onTap: () => context.push('/orders/history'),
              ),
              _buildListTile(
                icon: Icons.storefront_outlined,
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFFF0F3),
                title: 'Pengajuan UMKM',
                subtitle: 'Ajukan usaha Anda menjadi mitra',
                onTap: () => _showSnackBar(context, 'Menuju halaman pendaftaran UMKM...'),
              ),
              _buildListTile(
                icon: Icons.directions_car_filled_outlined,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFECFDF5),
                title: 'Mitra Driver',
                subtitle: 'Informasi dan pendaftaran driver',
                showDivider: false,
                onTap: () => _showSnackBar(context, 'Menuju halaman pendaftaran Mitra Driver...'),
              ),
            ],
          ),

          // 6. Section: Pengaturan
          _buildSection(
            headerIcon: Icons.settings_outlined,
            title: 'Pengaturan',
            items: [
              _buildListTile(
                icon: Icons.language_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Bahasa',
                trailingText: 'Indonesia',
                onTap: () => _showSnackBar(context, 'Pengaturan bahasa...'),
              ),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Privasi',
                subtitle: 'Kebijakan privasi dan keamanan',
                onTap: () => _showSnackBar(context, 'Kebijakan privasi...'),
              ),
              _buildListTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi tentang aplikasi Kopdes',
                onTap: () => _showSnackBar(context, 'Informasi aplikasi KOPDES...'),
              ),
              _buildListTile(
                icon: Icons.smartphone_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                title: 'Versi Aplikasi',
                trailingText: 'Versi 1.0.0',
                showDivider: false,
                onTap: () {},
              ),
            ],
          ),

          // 7. Logout Button
          _buildLogoutButton(context, ref),
        ],
      ),
    );
  }
}
