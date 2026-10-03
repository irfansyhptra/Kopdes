import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/network/error_message.dart';
import '../../core/theme/theme.dart';
import 'apple_ui.dart';

/// Umpan balik untuk tindakan yang menunggu jaringan.
///
/// Satu overlay dipakai dari awal sampai akhir: berputar selama menunggu, lalu
/// berubah jadi centang atau silang di tempat yang sama. Dua dialog terpisah —
/// satu untuk memuat, satu untuk hasil — membuat layar berkedip di antaranya,
/// dan pada alur yang langsung berpindah halaman (daftar, masuk) dialog kedua
/// sering kalah cepat dari perpindahannya lalu tidak pernah terlihat.
///
/// Ini untuk tindakan yang memang memblokir: menekan tombol lalu menunggu
/// jawaban. Isi halaman yang sedang dimuat tetap memakai skeleton
/// (`skeleton_loaders.dart`) — lihat aturan di CLAUDE.md.

// ─────────────────────────────────────────────────────────────
// Indikator
// ─────────────────────────────────────────────────────────────

/// Indikator ala iOS: jeruji yang memudar berputar, bukan busur Material.
///
/// Dibuat sendiri, bukan `CupertinoActivityIndicator`, supaya warnanya ikut
/// token aplikasi dan ukurannya bebas.
class AppleActivityIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const AppleActivityIndicator({super.key, this.size = 24, this.color});

  @override
  State<AppleActivityIndicator> createState() => _AppleActivityIndicatorState();
}

class _AppleActivityIndicatorState extends State<AppleActivityIndicator>
    with SingleTickerProviderStateMixin {
  static const int _spokes = 12;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    // Hormati "kurangi animasi": tanpa ini indikator tetap berputar terus dan
    // justru itu yang dihindari orang yang menyalakan setelan tersebut.
    if (!(WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations)) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.muted;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SpokePainter(
              progress: _controller.value,
              color: color,
              spokes: _spokes,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpokePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int spokes;

  _SpokePainter({
    required this.progress,
    required this.color,
    required this.spokes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, size.width * 0.09);

    canvas.translate(radius, radius);
    for (var i = 0; i < spokes; i++) {
      // Jeruji yang baru saja dilewati paling pekat, lalu memudar memutar.
      final t = ((i / spokes) - progress) % 1.0;
      paint.color = color.withValues(alpha: 0.15 + 0.85 * t);
      canvas.save();
      canvas.rotate(2 * math.pi * i / spokes);
      canvas.drawLine(
        Offset(0, -radius * 0.52),
        Offset(0, -radius * 0.92),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SpokePainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Ikon hasil
// ─────────────────────────────────────────────────────────────

/// Centang atau silang yang digambar, bukan muncul begitu saja.
///
/// Goresannya ikut maju bersama lingkarannya supaya terbaca sebagai "selesai",
/// bukan sebagai ikon statis yang kebetulan ada di sana.
class AppleStatusIcon extends StatefulWidget {
  final bool success;
  final double size;

  const AppleStatusIcon({super.key, required this.success, this.size = 64});

  @override
  State<AppleStatusIcon> createState() => _AppleStatusIconState();
}

class _AppleStatusIconState extends State<AppleStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.success ? AppColors.success : AppColors.error;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pop = Curves.easeOutBack.transform(
          _controller.value.clamp(0.0, 0.55) / 0.55,
        );
        final stroke = _controller.value <= 0.35
            ? 0.0
            : Curves.easeOut.transform((_controller.value - 0.35) / 0.65);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.scale(
            scale: pop,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.12),
              ),
              child: CustomPaint(
                painter: _MarkPainter(
                  progress: stroke,
                  color: tint,
                  success: widget.success,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool success;

  _MarkPainter({
    required this.progress,
    required this.color,
    required this.success,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.085;

    final w = size.width;
    final path = Path();
    if (success) {
      path
        ..moveTo(w * 0.28, w * 0.52)
        ..lineTo(w * 0.44, w * 0.67)
        ..lineTo(w * 0.73, w * 0.36);
    } else {
      path
        ..moveTo(w * 0.34, w * 0.34)
        ..lineTo(w * 0.66, w * 0.66)
        ..moveTo(w * 0.66, w * 0.34)
        ..lineTo(w * 0.34, w * 0.66);
    }

    // Goresannya digambar sepanjang `progress`, bukan di-fade: memudarkan
    // seluruh bentuk terbaca sebagai gambar yang muncul, bukan garis ditarik.
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.progress != progress || old.success != success;
}

// ─────────────────────────────────────────────────────────────
// Overlay
// ─────────────────────────────────────────────────────────────

enum _Phase { loading, success, failure }

abstract class _FeedbackCardApi {
  Future<void> settle(_Phase phase, String title, String? body);
  Future<void> waitForClose();
}

/// Pegangan ke overlay yang sedang tampil.
///
/// Dibuat lewat [AppleFeedback.show]. Pemanggil wajib menutupnya lewat
/// [success], [failure], atau [dismiss] — kalau tidak, layarnya terkunci.
class AppleFeedback {
  final _FeedbackCardApi _state;
  final NavigatorState _navigator;
  bool _closed = false;

  AppleFeedback._(this._state, this._navigator);

  /// Menampilkan overlay pemuatan dan mengembalikan pegangannya.
  ///
  /// `useRootNavigator` disengaja: alur masuk dan daftar berpindah halaman
  /// begitu sesi terbentuk, dan overlay yang menempel pada halaman lama akan
  /// ikut hilang bersamanya sebelum hasilnya sempat terbaca.
  static AppleFeedback show(BuildContext context, String message) {
    final key = GlobalKey<_AppleFeedbackCardState>();
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: const Color(0x591D1D1F),
      builder: (_) => _AppleFeedbackCard(key: key, message: message),
    );

    return AppleFeedback._(key.currentState ?? _pending(key), navigator);
  }

  /// `showDialog` belum membangun kartunya saat [show] kembali, jadi
  /// pegangannya menunggu frame pertama lewat penunda di bawah.
  static _FeedbackCardApi _pending(GlobalKey<_AppleFeedbackCardState> key) =>
      _DeferredState(key);

  /// Berubah jadi centang, tahan sebentar, lalu tutup sendiri.
  Future<void> success(String title, [String? body]) =>
      _finish(_Phase.success, title, body, const Duration(milliseconds: 1400));

  /// Berubah jadi silang dan menunggu ditutup pengguna: pesan gagal yang
  /// hilang sendiri sebelum sempat dibaca sama saja dengan tidak ada.
  Future<void> failure(String title, [String? body]) =>
      _finish(_Phase.failure, title, body, null);

  /// Menutup tanpa menampilkan hasil.
  void dismiss() {
    if (_closed) return;
    _closed = true;
    if (_navigator.canPop()) _navigator.pop();
  }

  Future<void> _finish(
    _Phase phase,
    String title,
    String? body,
    Duration? hold,
  ) async {
    if (_closed) return;
    await _state.settle(phase, title, body);
    if (hold != null) {
      await Future<void>.delayed(hold);
      dismiss();
    } else {
      await _state.waitForClose();
      dismiss();
    }
  }
}

/// Penunda: menahan panggilan sampai kartunya benar-benar terpasang.
class _DeferredState implements _FeedbackCardApi {
  final GlobalKey<_AppleFeedbackCardState> _key;

  _DeferredState(this._key);

  Future<_FeedbackCardApi> get _real async {
    // Kartunya terpasang pada frame berikutnya setelah `showDialog`.
    while (_key.currentState == null) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    return _key.currentState!;
  }

  @override
  Future<void> settle(_Phase phase, String title, String? body) async =>
      (await _real).settle(phase, title, body);

  @override
  Future<void> waitForClose() async => (await _real).waitForClose();
}

class _AppleFeedbackCard extends StatefulWidget {
  final String message;

  const _AppleFeedbackCard({super.key, required this.message});

  @override
  State<_AppleFeedbackCard> createState() => _AppleFeedbackCardState();
}

class _AppleFeedbackCardState extends State<_AppleFeedbackCard>
    implements _FeedbackCardApi {
  _Phase _phase = _Phase.loading;
  late String _title = widget.message;
  String? _body;
  final _closeRequested = <void Function()>[];

  @override
  Future<void> settle(_Phase phase, String title, String? body) async {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      _title = title;
      _body = body;
    });
    // Satu frame supaya animasi ikonnya mulai sebelum penahanannya dihitung.
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }

  @override
  Future<void> waitForClose() {
    final done = Completer<void>();
    _closeRequested.add(done.complete);
    return done.future;
  }

  void _close() {
    for (final f in _closeRequested) {
      f();
    }
    _closeRequested.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: AppAnimation.normal,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.modal),
            boxShadow: AppElevation.modal,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSize(
                duration: AppAnimation.normal,
                curve: Curves.easeOut,
                child: _phase == _Phase.loading
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: AppleActivityIndicator(size: 44),
                      )
                    : AppleStatusIcon(success: _phase == _Phase.success),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (_body != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _body!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 13.5,
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
              if (_phase == _Phase.failure) ...[
                const SizedBox(height: AppSpacing.lg),
                ApplePressable(
                  onTap: _close,
                  semanticLabel: 'Tutup',
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      'Tutup',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pembungkus aksi
// ─────────────────────────────────────────────────────────────

/// Menjalankan satu aksi yang menunggu jaringan di balik modal tunggu, lalu
/// melaporkan hasilnya di modal yang sama.
///
/// Inilah pola bakunya: pengguna menekan sesuatu, overlay berputar muncul
/// seketika, dan apa pun yang terjadi — berhasil, ditolak server, jaringan
/// mati — selalu ada jawabannya di layar. Tanpa pembungkus ini tiap layar
/// menuliskan urutan show/await/success/failure-nya sendiri, dan yang lupa
/// satu langkah meninggalkan tombol yang ditekan tanpa tanda apa pun.
///
/// [action] mengembalikan `true` bila berhasil, `false` bila gagal dengan
/// cara yang sudah ditangani, atau melempar — lemparannya diterjemahkan
/// lewat [networkErrorMessage].
///
/// Dengan [successTitle] kosong, modalnya ditutup tanpa kabar sukses: dipakai
/// saat pemanggil ingin menampilkan dialog pilihannya sendiri lewat
/// [onSuccess], mis. "Lihat Keranjang / Lanjut Belanja".
Future<bool> runWithFeedback(
  BuildContext context, {
  required String waiting,
  required Future<bool> Function() action,
  String? successTitle,
  String? successMessage,
  String failureTitle = 'Gagal',
  String? failureMessage,
  Future<void> Function()? onSuccess,
}) async {
  final feedback = AppleFeedback.show(context, waiting);

  bool ok;
  String? error;
  try {
    ok = await action();
  } catch (e) {
    ok = false;
    error = networkErrorMessage(e);
  }

  if (!ok) {
    await feedback.failure(
      failureTitle,
      error ?? failureMessage ?? 'Coba lagi sebentar lagi.',
    );
    return false;
  }

  if (successTitle != null) {
    await feedback.success(successTitle, successMessage);
  } else {
    feedback.dismiss();
  }

  if (onSuccess != null) await onSuccess();
  return true;
}

// ─────────────────────────────────────────────────────────────
// Modal hasil tindakan
// ─────────────────────────────────────────────────────────────

/// Modal hasil untuk tindakan yang selesai seketika.
///
/// Bedanya dengan [AppleFeedback]: yang itu menemani penantian lalu menutup
/// sendiri, yang ini berhenti dan menawarkan langkah berikutnya. Dipakai saat
/// hasilnya membuka pilihan — "sudah masuk keranjang, mau lihat atau lanjut
/// belanja?" — bukan sekadar kabar yang lewat.
///
/// Kabar yang tidak menawarkan apa pun sebaiknya tetap jadi SnackBar: modal
/// memaksa orang menutupnya, dan memakainya untuk setiap konfirmasi kecil
/// mengubah alur belanja jadi rentetan ketukan "OK".
Future<T?> showAppleActionDialog<T>(
  BuildContext context, {
  required String title,
  String? message,
  bool success = true,
  Widget? icon,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0x591D1D1F),
    builder: (_) => _AppleActionDialog(
      title: title,
      message: message,
      success: success,
      icon: icon,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    ),
  );
}

class _AppleActionDialog extends StatelessWidget {
  final String title;
  final String? message;
  final bool success;
  final Widget? icon;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _AppleActionDialog({
    required this.title,
    required this.message,
    required this.success,
    required this.icon,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: AppAnimation.normal,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.modal),
            boxShadow: AppElevation.modal,
          ),
          // Bisa digulir: pada layar pendek — ponsel mendarat, atau skala
          // teks besar — isi modal melebihi tingginya, dan Column telanjang
          // menjawabnya dengan garis kuning-hitam alih-alih membiarkan orang
          // menggulir ke tombolnya.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon ?? AppleStatusIcon(success: success),
                const SizedBox(height: AppSpacing.base),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 13.5,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _DialogButton(
                  label: primaryLabel,
                  onTap: onPrimary,
                  filled: true,
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _DialogButton(
                    label: secondaryLabel!,
                    onTap: onSecondary!,
                    filled: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    return ApplePressable(
      onTap: onTap,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        width: double.infinity,
        // 48, bukan 44: tombol modal adalah aksi utama layar saat ia terbuka.
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: filled
              ? null
              : Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Text(
          label,
          style: AppTypography.buttonSm.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: filled ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
