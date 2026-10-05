import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';

/// Satu titik yang digambar di peta.
class MapPoint {
  final double latitude;
  final double longitude;
  final IconData icon;
  final Color tint;

  /// Dibacakan pembaca layar — peta itu sendiri tidak terbaca olehnya.
  final String label;

  const MapPoint({
    required this.latitude,
    required this.longitude,
    required this.icon,
    required this.tint,
    required this.label,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Peta pengantaran.
///
/// Ubin dari OpenStreetMap: tanpa kunci API dan tanpa akun penagihan, jadi
/// peta tetap hidup walau tidak ada yang memperpanjang langganan. Navigasi
/// belok-per-belok sengaja tidak dibuat sendiri — [openDirections]
/// menyerahkannya ke aplikasi peta di ponsel kurir, yang sudah punya suara,
/// data lalu lintas, dan peta luring.
///
/// Tanpa satu titik pun yang diketahui, peta tidak digambar sama sekali:
/// peta kosong di tengah samudra lebih membingungkan daripada tidak ada peta.
class DeliveryMap extends StatefulWidget {
  final List<MapPoint> points;

  /// Garis lurus antar titik — jarak pandang, bukan rute jalan. Rute jalan
  /// yang sebenarnya butuh layanan routing tersendiri.
  final bool connect;
  final double height;

  const DeliveryMap({
    super.key,
    required this.points,
    this.connect = true,
    this.height = 220,
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fit() {
    final pts = widget.points;
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      _controller.move(pts.first.latLng, 16);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts.map((p) => p.latLng).toList()),
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = widget.points;
    if (pts.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: pts.first.latLng,
                initialZoom: 15,
                initialCameraFit: pts.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(
                          pts.map((p) => p.latLng).toList(),
                        ),
                        padding: const EdgeInsets.all(48),
                      )
                    : null,
                interactionOptions: const InteractionOptions(
                  // Rotasi dimatikan: peta yang tidak lagi menghadap utara
                  // membuat orang salah membaca arah, dan tidak ada tombol
                  // "kembalikan ke utara" yang mudah ditemukan.
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kopdes.smart.kopdes',
                  maxNativeZoom: 19,
                ),
                if (widget.connect && pts.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: pts.map((p) => p.latLng).toList(),
                        strokeWidth: 3,
                        color: AppColors.primary.withValues(alpha: 0.75),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final p in pts)
                      Marker(
                        point: p.latLng,
                        width: 40,
                        height: 40,
                        child: Semantics(
                          label: p.label,
                          child: _Pin(icon: p.icon, tint: p.tint),
                        ),
                      ),
                  ],
                ),
                const _Attribution(),
              ],
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Material(
                color: AppColors.canvas,
                shape: const CircleBorder(),
                elevation: 2,
                child: IconButton(
                  // 44×44: ikonnya kecil, bidang sentuhnya tidak.
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  tooltip: 'Pusatkan peta',
                  onPressed: _fit,
                  icon: const Icon(
                    Icons.center_focus_strong_rounded,
                    size: 20,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final IconData icon;
  final Color tint;
  const _Pin({required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tint,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.canvas, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 20, color: AppColors.onPrimary),
    );
  }
}

/// Atribusi OpenStreetMap — syarat pemakaian ubinnya, bukan hiasan.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.canvas.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              '© OpenStreetMap',
              style: AppTypography.captionSmall.copyWith(
                fontSize: 9.5,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jarak garis lurus dalam kalimat yang bisa dipakai: "1,4 km".
///
/// Garis lurus, bukan jarak tempuh — disebut "garis lurus" di layar supaya
/// kurir tidak menganggapnya jarak berkendara lalu salah menghitung waktu.
String straightLineDistance(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  final m = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
  if (m < 1000) return '${m.round()} m';
  return '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Menyerahkan navigasi ke aplikasi peta di ponsel.
///
/// Dicoba `google.navigation:` lebih dulu — itu yang langsung membuka mode
/// mengemudi. Bila Google Maps tidak terpasang, jatuh ke tautan web yang
/// bisa dibuka peramban mana pun.
Future<bool> openDirections(double lat, double lng) async {
  final nav = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  if (await canLaunchUrl(nav)) {
    return launchUrl(nav, mode: LaunchMode.externalApplication);
  }
  final web = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
  );
  return launchUrl(web, mode: LaunchMode.externalApplication);
}
