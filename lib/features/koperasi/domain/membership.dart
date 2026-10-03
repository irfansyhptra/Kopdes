/// Status pendaftaran anggota pada satu Kopdes.
///
/// Cerminan `MembershipStatus` di backend. `null` pada [Membership] yang
/// dibungkusnya berarti belum pernah mendaftar — keadaan yang berbeda dari
/// [rejected], dan keduanya tidak boleh digambar dengan tombol yang sama.
enum MembershipStatus {
  pending('PENDING', 'Menunggu verifikasi'),
  active('ACTIVE', 'Anggota aktif'),
  rejected('REJECTED', 'Pendaftaran ditolak');

  final String wire;
  final String label;

  const MembershipStatus(this.wire, this.label);

  static MembershipStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

class Membership {
  final String id;
  final MembershipStatus status;

  /// Alasan yang ditulis pengurus saat menolak. Ditampilkan supaya pemohon
  /// tahu apa yang perlu diperbaiki sebelum mendaftar lagi.
  final String? reviewNote;

  const Membership({required this.id, required this.status, this.reviewNote});

  bool get isActive => status == MembershipStatus.active;
  bool get isPending => status == MembershipStatus.pending;

  /// Ditolak boleh mendaftar ulang; menunggu dan aktif tidak.
  bool get canApply => status == MembershipStatus.rejected;

  static Membership? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final status = MembershipStatus.fromWire(json['status'] as String?);
    if (status == null) return null;
    return Membership(
      id: json['id'] as String? ?? '',
      status: status,
      reviewNote: json['reviewNote'] as String?,
    );
  }
}
