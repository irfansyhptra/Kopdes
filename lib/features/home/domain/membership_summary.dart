/// Ringkasan keanggotaan koperasi yang tampil di beranda.
///
/// Dulu tiga angkanya dituliskan langsung di layar — Rp250.000, 1.250 poin,
/// status "VIP" — sama persis untuk setiap orang yang memasang aplikasi.
/// Angka yang tidak pernah berubah bukan informasi; ia hanya mengajari orang
/// untuk tidak mempercayai angka lain di layar yang sama.
class MembershipSummary {
  /// Saldo dompet dalam rupiah. Null = belum jadi anggota koperasi mana pun.
  final double? balance;

  /// Poin belanja. Belum ada sumbernya di backend, jadi selalu 0 untuk
  /// sekarang — bukan angka karangan yang terlihat seperti sudah berjalan.
  final int points;

  final bool isMember;

  const MembershipSummary({
    this.balance,
    this.points = 0,
    this.isMember = false,
  });

  /// Keadaan sebelum ada apa pun yang diketahui tentang penggunanya.
  static const MembershipSummary none = MembershipSummary();

  /// Jenjang keanggotaan dari poin belanja.
  ///
  /// Ambangnya SEMENTARA — belum ada aturan jenjang di backend. Ditaruh di
  /// satu tempat supaya saat aturannya ada, yang diubah hanya daftar ini.
  MemberTier? get tier {
    if (!isMember) return null;
    if (points >= 10000) return MemberTier.diamond;
    if (points >= 5000) return MemberTier.gold;
    if (points >= 1000) return MemberTier.silver;
    return MemberTier.bronze;
  }
}

enum MemberTier {
  bronze('Bronze'),
  silver('Silver'),
  gold('Gold'),
  diamond('Diamond');

  final String label;
  const MemberTier(this.label);
}
