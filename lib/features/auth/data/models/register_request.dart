/// Pendaftaran mandiri di aplikasi hanya membuat akun pembeli.
///
/// Tidak ada `role` di sini dengan sengaja. Backend menolak peran selain
/// CUSTOMER pada endpoint ini (`SELF_REGISTER_ROLES`), dan mengirim field yang
/// pasti ditolak hanya membuat form gagal dengan alasan yang membingungkan.
/// Mitra UMKM mengajukan diri lewat Kopdes desanya; akun kurir dan pegawai
/// dibuat pengurus Kopdes.
class RegisterRequest {
  final String name;
  final String email;
  final String phone;
  final String password;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'phone': phone, 'password': password};
  }
}
