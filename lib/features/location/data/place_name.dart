import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';

/// Mengubah koordinat menjadi nama tempat yang bisa dibaca warga.
///
/// Tujuannya satu kalimat pendek seperti "Lamgugop, Banda Aceh" untuk kepala
/// beranda — bukan alamat lengkap. Nama desa lebih berarti bagi pengguna di
/// sini daripada nama jalan.
///
/// Mengembalikan null bila gagal, dan itu keadaan yang wajar: geocoder
/// Android menumpang layanan Google Play dan butuh jaringan, jadi di ponsel
/// tanpa keduanya ia memang tidak menjawab. Pemanggil harus punya tampilan
/// cadangan, bukan menampilkan pesan kesalahan.
Future<String?> resolvePlaceName(double latitude, double longitude) async {
  try {
    final marks = await Geocoding().placemarkFromCoordinates(
      latitude,
      longitude,
      // Hasilnya mengikuti bahasa aplikasi, bukan bahasa sistem ponsel:
      // "Banda Aceh" harus berbunyi sama bagi semua penggunanya.
      locale: const Locale('id', 'ID'),
    );
    if (marks.isEmpty) return null;
    return _format(marks.first);
  } catch (e) {
    if (kDebugMode) debugPrint('Nama tempat tidak terbaca: $e');
    return null;
  }
}

/// Dua bagian saja: yang terkecil yang dikenali, lalu kotanya.
///
/// Urutannya dipilih dari yang paling spesifik: `subLocality` biasanya berisi
/// nama desa/kelurahan, `locality` nama kecamatan atau kota. Jalan sengaja
/// dilewati — "Jl. Teuku Nyak Arief" tidak memberi tahu pengguna sedang di
/// desa mana.
String? _format(Placemark mark) {
  final detail = _firstNonEmpty([
    mark.subLocality,
    mark.locality,
    mark.subAdministrativeArea,
  ]);
  final city = _firstNonEmpty([
    mark.subAdministrativeArea,
    mark.administrativeArea,
  ]);

  if (detail == null) return city;
  if (city == null || city == detail) return detail;
  return '$detail, $city';
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    final trimmed = v?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
