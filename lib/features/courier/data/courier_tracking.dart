import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'courier_repository.dart';

/// Keadaan pengiriman posisi kurir.
class TrackingState {
  /// Tugas yang sedang disiarkan posisinya. Null = tidak menyiarkan.
  final String? deliveryId;
  final DateTime? lastSentAt;
  final Position? lastPosition;

  /// Terisi bila izin lokasi ditolak atau layanannya mati — kurir perlu
  /// tahu bahwa pembeli TIDAK sedang melihat posisinya.
  final String? problem;

  const TrackingState({
    this.deliveryId,
    this.lastSentAt,
    this.lastPosition,
    this.problem,
  });

  bool get isBroadcasting => deliveryId != null && problem == null;
}

/// Mengirim posisi kurir selama ia membawa barang.
///
/// Dijalankan hanya saat aplikasi terbuka: tidak ada layanan latar belakang
/// di proyek ini, jadi menutup aplikasi menghentikan siaran. Itu disebutkan
/// apa adanya di layar tugas, bukan disembunyikan — kurir yang mengira
/// posisinya terkirim padahal tidak akan ditelepon pembeli terus-menerus.
///
/// `distanceFilter` 25 m: titik baru hanya dikirim setelah kurir benar-benar
/// berpindah. Mengirim tiap beberapa detik saat motor berhenti di lampu
/// merah hanya menghabiskan baterai dan kuota.
class CourierTracking extends StateNotifier<TrackingState> {
  final CourierService _service;
  StreamSubscription<Position>? _sub;

  CourierTracking(this._service) : super(const TrackingState());

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 25,
  );

  Future<void> start(String deliveryId) async {
    if (state.deliveryId == deliveryId && _sub != null) return;
    await stop();

    if (!await Geolocator.isLocationServiceEnabled()) {
      state = TrackingState(
        deliveryId: deliveryId,
        problem: 'Layanan lokasi mati. Pembeli tidak bisa melihat posisi Anda.',
      );
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = TrackingState(
        deliveryId: deliveryId,
        problem: 'Izin lokasi ditolak. Pembeli tidak bisa melihat posisi Anda.',
      );
      return;
    }

    state = TrackingState(deliveryId: deliveryId);
    _sub = Geolocator.getPositionStream(locationSettings: _settings).listen((
      position,
    ) async {
      if (!mounted) return;
      try {
        await _service.pushLocation(
          deliveryId,
          position.latitude,
          position.longitude,
        );
        if (!mounted) return;
        state = TrackingState(
          deliveryId: deliveryId,
          lastSentAt: DateTime.now(),
          lastPosition: position,
        );
      } catch (_) {
        // Satu titik gagal terkirim bukan alasan menghentikan siaran:
        // titik berikutnya beberapa puluh meter lagi akan mencobanya
        // lagi, dan posisi lama tetap yang terakhir diketahui pembeli.
        if (!mounted) return;
        state = TrackingState(
          deliveryId: deliveryId,
          lastSentAt: state.lastSentAt,
          lastPosition: position,
        );
      }
    }, onError: (_) {});
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (mounted) state = const TrackingState();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final courierTrackingProvider =
    StateNotifierProvider<CourierTracking, TrackingState>(
      (ref) => CourierTracking(ref.watch(courierServiceProvider)),
    );

/// Menyalakan dan mematikan siaran mengikuti tugas yang sedang dibawa.
///
/// Satu tempat yang memutuskan, bukan setiap layar: tugas yang ditandai
/// selesai di layar mana pun akan menghentikan siarannya sendiri.
final courierTrackingSyncProvider = Provider<void>((ref) {
  final carrying = ref
      .watch(myTasksProvider)
      .maybeWhen(
        data: (tasks) =>
            tasks.where((t) => t.stage.carrying).map((t) => t.id).firstOrNull,
        orElse: () => null,
      );
  final tracking = ref.read(courierTrackingProvider.notifier);
  final current = ref.read(courierTrackingProvider).deliveryId;

  if (carrying == null) {
    if (current != null) tracking.stop();
  } else if (carrying != current) {
    tracking.start(carrying);
  }
});
