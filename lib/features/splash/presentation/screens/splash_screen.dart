import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import 'splash_loading_state.dart';
import 'splash_sequence_manager.dart';

import '../../../../core/network/health_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';

const _kBackground = Color(0xFFFFFFFF);
const _kPrimaryRed = Color(0xFFE31B23);
const _kNeutralGrey = Color(0xFF9AA0A6);
const _kFlashRevealAsset = 'assets/lottie/KOMIT_logo_flash_reveal.json';

final splashFinishedProvider = StateProvider<bool>((ref) => false);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final SplashSequenceManager _sequence;
  late final AnimationController _lottieController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;
  late final Animation<Offset> _entranceOffset;
  final Completer<void> _logoAnimationDone = Completer<void>();

  bool _navigated = false;
  bool _entranceStarted = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final entranceCurve = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.68, curve: Curves.easeOut),
    );
    _entranceScale = Tween<double>(begin: 0.96, end: 1).animate(entranceCurve);
    _entranceOffset = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(entranceCurve);

    _sequence = SplashSequenceManager(
      checkHealth: () => ref.read(healthProvider.notifier).checkServerHealth(),
      loadVillageData: () => ref.read(categoriesProvider.future),
      checkSession: () => ref.read(authProvider.notifier).checkAuthStatus(),
      warmupAI: () => Future.delayed(const Duration(milliseconds: 600)),
      prepareServices: () => Future.delayed(const Duration(milliseconds: 400)),
    )..start();

    _sequence.done.then((_) => _maybeNavigate());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    } else {
      _entranceController.forward();
    }
  }

  void _playLogoAnimation(LottieComposition composition) {
    _lottieController.duration = composition.duration;
    if (MediaQuery.disableAnimationsOf(context)) {
      _lottieController.value = 1;
      _completeLogoAnimationAfterError();
      return;
    }
    _lottieController.forward(from: 0).whenComplete(() {
      if (!_logoAnimationDone.isCompleted) {
        _logoAnimationDone.complete();
      }
    });
  }

  void _completeLogoAnimationAfterError() {
    if (!_logoAnimationDone.isCompleted) {
      _logoAnimationDone.complete();
    }
  }

  Future<void> _maybeNavigate() async {
    if (_navigated || !mounted) return;
    // Durasi bootstrap minimum 3,4 detik sedikit lebih panjang daripada
    // animasi 3,2 detik. Future ini tetap menjadi pagar tambahan singkat bila
    // decode asset terlambat, tanpa membuat aplikasi tertahan saat decoder
    // tidak mengirim callback (misalnya pada test binding).
    await _logoAnimationDone.future.timeout(
      const Duration(milliseconds: 800),
      onTimeout: () {},
    );
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
    _entranceController.dispose();
    _lottieController.dispose();
    _sequence.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Center(
        child: FadeTransition(
          key: const ValueKey('kmp-splash-entrance'),
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entranceOffset,
            child: ScaleTransition(
              scale: _entranceScale,
              child: Semantics(
                label: 'Logo KMP Mitra',
                image: true,
                child: ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: AspectRatio(
                        aspectRatio: 3 / 2,
                        child: Lottie.asset(
                          _kFlashRevealAsset,
                          key: const ValueKey('kmp-flash-reveal'),
                          controller: _lottieController,
                          fit: BoxFit.contain,
                          repeat: false,
                          onLoaded: _playLogoAnimation,
                          errorBuilder: (context, error, stackTrace) {
                            _completeLogoAnimationAfterError();
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
