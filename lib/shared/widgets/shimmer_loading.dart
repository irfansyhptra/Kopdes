import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// Shimmer — satu controller untuk satu grup placeholder
//
// Versi sebelumnya membuat satu AnimationController di dalam SETIAP ShimmerBox.
// Satu grid skeleton 4 kartu × 4 kotak berarti 16 controller dengan 16 Ticker
// terdaftar di SchedulerBinding, semuanya repeat() bersamaan, hanya untuk
// menganimasikan gradien yang fasenya sama persis.
//
// Sekarang satu [ShimmerGroup] memiliki satu controller dan membagikannya ke
// seluruh subtree. Tampilannya identik — fase animasinya memang selalu sama.
// ─────────────────────────────────────────────────────────

const List<Color> _kShimmerColors = [
  Color(0xFFEEEEEE),
  Color(0xFFF5F5F5),
  Color(0xFFEEEEEE),
];

/// Menyediakan satu detak animasi shimmer untuk semua [ShimmerBox] di bawahnya.
///
/// Bungkus keseluruhan layar/blok placeholder dengan ini, bukan tiap kotaknya.
class ShimmerGroup extends StatefulWidget {
  final Widget child;

  const ShimmerGroup({super.key, required this.child});

  @override
  State<ShimmerGroup> createState() => _ShimmerGroupState();
}

class _ShimmerGroupState extends State<ShimmerGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(animation: _controller, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  final Animation<double> animation;

  const _ShimmerScope({required this.animation, required super.child});

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      animation != oldWidget.animation;
}

/// Kotak placeholder. Harus berada di dalam [ShimmerGroup].
///
/// Tanpa grup, kotak tetap digambar tetapi diam — lebih baik placeholder statis
/// daripada diam-diam menghidupkan controller kedua per kotak.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final animation = _ShimmerScope.maybeOf(context);

    assert(
      animation != null,
      'ShimmerBox harus berada di dalam ShimmerGroup. '
      'Bungkus blok placeholder-nya dengan ShimmerGroup(child: ...).',
    );

    if (animation == null) {
      return _box(const LinearGradient(colors: _kShimmerColors));
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        return _box(
          LinearGradient(
            begin: Alignment(-1.0 + 2.0 * t, 0),
            end: Alignment(-1.0 + 2.0 * t + 1.0, 0),
            colors: _kShimmerColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        );
      },
    );
  }

  Widget _box(Gradient gradient) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: gradient,
    ),
  );
}

/// Menyapukan kilau shimmer di atas widget nyata (bukan kotak placeholder).
///
/// ShaderMask memicu saveLayer, jadi pakai ini hanya untuk satu blok — bukan
/// per elemen. Untuk placeholder, [ShimmerBox] lebih murah.
class ShimmerContainer extends StatelessWidget {
  final Widget child;

  const ShimmerContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final animation = _ShimmerScope.maybeOf(context);
    if (animation == null) return child;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) {
        final t = animation.value;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.0 + 2.0 * t, 0),
            end: Alignment(-1.0 + 2.0 * t + 1.0, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFF8F8F8),
              Color(0xFFEEEEEE),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: inner,
        );
      },
      // child dibangun sekali, bukan tiap frame.
      child: child,
    );
  }
}
