import 'package:flutter/material.dart';

class MemberCardWidget extends StatelessWidget {
  final String balance;
  final String points;
  final String statusLabel;
  final VoidCallback onTopUpTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onCouponTap;
  final VoidCallback onDetailTap;

  const MemberCardWidget({
    super.key,
    this.balance = 'Rp250.000',
    this.points = '1.250',
    this.statusLabel = 'VIP',
    required this.onTopUpTap,
    required this.onHistoryTap,
    required this.onCouponTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF150A0F).withOpacity(0.35),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFA00019).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Kartu ini menggulir bersama halaman. BackdropFilter di sini berarti
      // satu blur penuh layar dihitung ulang setiap frame gulir; yang berada
      // di belakangnya cuma gradien header, jadi gradien gelap semi-transparan
      // memberi hasil visual yang sama tanpa lapisan blur.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF280B13).withOpacity(0.85),
                const Color(0xFF14070B).withOpacity(0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: Column(
            children: [
              // Top Row: 3 Columns (Saldo, Poin, Status VIP)
              Row(
                children: [
                  // Column 1: Saldo Anggota
                  Expanded(
                    child: _buildColumnInfo(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBgGradient: const LinearGradient(
                        colors: [Color(0xFFE9162B), Color(0xFFA50018)],
                      ),
                      label: 'Saldo Anggota',
                      value: balance,
                    ),
                  ),
                  _buildVerticalDivider(),

                  // Column 2: Poin Belanja
                  Expanded(
                    child: _buildColumnInfo(
                      icon: Icons.stars_rounded,
                      iconBgGradient: const LinearGradient(
                        colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                      ),
                      label: 'Poin Belanja',
                      value: points,
                    ),
                  ),
                  _buildVerticalDivider(),

                  // Column 3: Status Anggota (VIP)
                  Expanded(
                    child: _buildColumnInfo(
                      icon: Icons.workspace_premium_rounded,
                      iconBgGradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                      ),
                      label: 'Status Anggota',
                      value: statusLabel,
                      isVip: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Bottom Row: 4 Action Chips in Dark Glass
              Row(
                children: [
                  Expanded(
                    child: _buildActionChip(
                      icon: Icons.add_rounded,
                      label: 'Top Up Saldo',
                      onTap: onTopUpTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionChip(
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat Transaksi',
                      onTap: onHistoryTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionChip(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Kupon Saya',
                      onTap: onCouponTap,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildActionChip(
                      icon: Icons.person_outline_rounded,
                      label: 'Detail Anggota',
                      onTap: onDetailTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Column Info Helper
  Widget _buildColumnInfo({
    required IconData icon,
    required Gradient iconBgGradient,
    required String label,
    required String value,
    bool isVip = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: iconBgGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!isVip)
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFE259), Color(0xFFFF8C00)],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  // Vertical Divider Helper
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withOpacity(0.12),
    );
  }

  // Dark Glass Action Chip Helper
  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.9), size: 11),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
