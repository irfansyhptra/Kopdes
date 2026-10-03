import '../data/chat_models.dart';

class ChatChannelLogic {
  static const _sellerRoles = {'UMKM', 'ADMIN_KOPDES', 'PEGAWAI_KOPDES'};

  static bool isSellerRole(String? role) => _sellerRoles.contains(role);

  static List<ChatChannel> channelsForRole(String? role) {
    if (role == 'CUSTOMER') return const [ChatChannel.marketplace];
    if (role == 'COURIER') return const [ChatChannel.delivery];
    if (isSellerRole(role)) {
      return const [ChatChannel.marketplace, ChatChannel.delivery];
    }
    return const [ChatChannel.general];
  }

  static String title(ChatChannel channel, String? role) {
    return switch (channel) {
      ChatChannel.marketplace =>
        isSellerRole(role) ? 'Chat Pembeli' : 'Chat Penjual',
      ChatChannel.delivery => role == 'COURIER' ? 'Chat Penjual' : 'Chat Kurir',
      ChatChannel.general => 'Semua Percakapan',
    };
  }

  static String description(ChatChannel channel, String? role) {
    return switch (channel) {
      ChatChannel.marketplace =>
        isSellerRole(role)
            ? 'Jawab pertanyaan produk dan pesanan dari pembeli.'
            : 'Tanyakan produk dan perkembangan pesanan kepada penjual.',
      ChatChannel.delivery =>
        role == 'COURIER'
            ? 'Koordinasikan pengambilan paket dengan penjual.'
            : 'Atur penjemputan dan serah terima paket dengan kurir.',
      ChatChannel.general => 'Lihat seluruh percakapan yang dapat Anda akses.',
    };
  }

  static String emptyMessage(ChatChannel channel, String? role) {
    return switch (channel) {
      ChatChannel.marketplace =>
        isSellerRole(role)
            ? 'Belum ada pembeli yang menghubungi toko.'
            : 'Belum ada percakapan dengan penjual.',
      ChatChannel.delivery =>
        role == 'COURIER'
            ? 'Belum ada percakapan dengan penjual.'
            : 'Belum ada percakapan dengan kurir.',
      ChatChannel.general => 'Belum ada percakapan.',
    };
  }

  static List<String> quickReplies(ChatChannel channel, String? role) {
    return switch (channel) {
      ChatChannel.marketplace =>
        isSellerRole(role)
            ? const [
                'Produk tersedia, Kak.',
                'Pesanan sedang kami siapkan.',
                'Terima kasih sudah berbelanja.',
              ]
            : const [
                'Apakah produknya masih tersedia?',
                'Bagaimana status pesanan saya?',
                'Terima kasih.',
              ],
      ChatChannel.delivery =>
        role == 'COURIER'
            ? const [
                'Saya menuju lokasi penjemputan.',
                'Saya sudah tiba di lokasi.',
                'Paket sudah saya terima.',
              ]
            : const [
                'Paket siap diambil.',
                'Mohon konfirmasi waktu penjemputan.',
                'Terima kasih, paket sudah diserahkan.',
              ],
      ChatChannel.general => const [],
    };
  }

  static String roleLabel(String role) => switch (role) {
    'CUSTOMER' => 'Pembeli',
    'COURIER' => 'Kurir',
    'UMKM' => 'Penjual UMKM',
    'ADMIN_KOPDES' => 'Admin Kopdes',
    'PEGAWAI_KOPDES' => 'Pegawai Kopdes',
    'SUPER_ADMIN' => 'Super Admin',
    _ => 'Pengguna',
  };

  static String landingPath(String? role) => switch (role) {
    'UMKM' => '/umkm',
    'COURIER' => '/courier',
    'ADMIN_KOPDES' => '/admin',
    'PEGAWAI_KOPDES' => '/pegawai',
    'SUPER_ADMIN' => '/super-admin',
    _ => '/home',
  };
}
