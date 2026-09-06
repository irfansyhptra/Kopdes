import 'package:url_launcher/url_launcher.dart';

/// Membuka petunjuk arah di aplikasi peta perangkat.
///
/// Memakai skema `geo:` lebih dulu agar Android menampilkan pemilih aplikasi —
/// pengguna bebas memakai Google Maps, Waze, atau lainnya. Bila tidak ada yang
/// menangani (umumnya iOS), jatuh ke URL web Google Maps.
///
/// Mengembalikan false bila tidak ada aplikasi yang bisa membukanya, sehingga
/// pemanggil dapat menampilkan pesan alih-alih gagal diam-diam.
Future<bool> openDirections({
  required double latitude,
  required double longitude,
  String? label,
}) async {
  final encodedLabel = Uri.encodeComponent(label ?? '');
  final geo = Uri.parse(
    'geo:$latitude,$longitude?q=$latitude,$longitude'
    '${label != null ? '($encodedLabel)' : ''}',
  );

  if (await canLaunchUrl(geo)) {
    return launchUrl(geo, mode: LaunchMode.externalApplication);
  }

  final web = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
  );
  if (await canLaunchUrl(web)) {
    return launchUrl(web, mode: LaunchMode.externalApplication);
  }
  return false;
}
