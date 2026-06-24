import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import 'splash_animation_controller.dart';
import 'splash_loading_state.dart';
import 'splash_sequence_manager.dart';
import '../widgets/animated_logo_text.dart';
import '../widgets/house_path_painter.dart';

import '../../../../core/network/health_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';

const _kBackground = Color(0xFFFFFFFF);
const _kPrimaryRed = Color(0xFFFF385C);
const _kTextDark = Color(0xFF111111);
const _kNeutralGrey = Color(0xFF9AA0A6);

final splashFinishedProvider = StateProvider<bool>((ref) => false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final SplashAnimationController _anim;
  late final SplashSequenceManager _sequence;
  late final AnimationController _lottieController;

  bool _flagTriggered = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _anim = SplashAnimationController(vsync: this);
    _lottieController = AnimationController(vsync: this);

    _sequence = SplashSequenceManager(
      checkHealth: () => ref.read(healthProvider.notifier).checkServerHealth(),
      loadVillageData: () => ref.read(categoriesProvider.future),
      checkSession: () => ref.read(authProvider.notifier).checkAuthStatus(),
      warmupAI: () => Future.delayed(const Duration(milliseconds: 600)),
      prepareServices: () => Future.delayed(const Duration(milliseconds: 400)),
    )..start();

    _anim.timeline.addListener(_onTimelineTick);
    _anim.playEntrance();
    _sequence.done.then((_) => _maybeNavigate());
  }

  void _onTimelineTick() {
    if (!_flagTriggered && _anim.timeline.value >= _anim.flagRevealThreshold) {
      _flagTriggered = true;
      _lottieController.repeat(); // gentle continuous wave
    }
  }

  Future<void> _maybeNavigate() async {
    if (_navigated || !mounted) return;
    // Wait for the entrance choreography to finish so we never cut
    // the animation short even if init resolved very quickly.
    if (_anim.timeline.status != AnimationStatus.completed) {
      await _anim.timeline.forward().orCancel.catchError((_) {});
    }
    if (!mounted || _navigated) return;

    if (_sequence.state == SplashLoadingState.unreachable) {
      return;
    }

    _navigated = true;
    // Signal GoRouter that splash has successfully finished.
    ref.read(splashFinishedProvider.notifier).state = true;
  }

  @override
  void dispose() {
    _anim.timeline.removeListener(_onTimelineTick);
    _anim.dispose();
    _lottieController.dispose();
    _sequence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([_anim.timeline, _anim.breathing]),
        builder: (context, _) {
          return Opacity(
            opacity: _anim.backgroundFade.value,
            child: Center(
              child: Transform.scale(
                scale: _anim.breathing.isAnimating
                    ? _anim.breathingScale.value
                    : 1.0,
                child: _buildLogoCluster(),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 32, left: 24, right: 24),
          child: AnimatedBuilder(
            animation: _sequence,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LoadingMessage(sequence: _sequence),
                  if (_sequence.state == SplashLoadingState.unreachable) ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Restart sequence on retry
                        _sequence.start().then((_) => _maybeNavigate());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCluster() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Very soft neumorphism-style lift, kept subtle on purpose.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06 * _anim.shadowReveal.value),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9 * _anim.shadowReveal.value),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 160,
            height: 176,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // House outline, progressively drawn.
                CustomPaint(
                  size: const Size(160, 176),
                  painter: HousePathPainter(
                    roofProgress: _anim.roofDraw.value,
                    wallsProgress: _anim.wallsDraw.value,
                    poleProgress: _anim.poleGrow.value,
                  ),
                ),
                // Flag, positioned at the top of the pole. Lottie
                // handles only the cloth-wave motion; entrance
                // opacity is still driven by our own timeline so it
                // blends in instead of popping.
                Positioned(
                  top: -28,
                  child: AnimatedOpacity(
                    opacity: _flagTriggered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 280),
                    child: SizedBox(
                      width: 60,
                      height: 40,
                      child: Lottie.asset(
                        'assets/lottie/flag_wave.json',
                        controller: _lottieController,
                        fit: BoxFit.contain,
                        onLoaded: (composition) {
                          _lottieController.duration = composition.duration;
                          if (_flagTriggered) {
                            _lottieController.repeat();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedLogoText(
            text: 'KOPDES',
            progress: _anim.kopdesTextReveal.value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: _kPrimaryRed,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedLogoText(
            text: 'MERAH PUTIH',
            progress: _anim.merahPutihTextReveal.value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage({required this.sequence});

  final SplashSequenceManager sequence;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        sequence.state.message,
        key: ValueKey(sequence.state),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
          color: _kNeutralGrey,
        ),
      ),
    );
  }
}
