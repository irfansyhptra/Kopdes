import 'package:flutter/material.dart';

/// Owns every `Animation<double>` the splash screen needs and exposes
/// them as plain 0..1 values via [Listenable]s, so widgets stay dumb
/// (no AnimationController plumbing inside the widget tree itself).
///
/// Two controllers are used on purpose:
/// - [timeline] plays ONCE, drives the choreography (fade-in,
///   house draw, pole grow, text reveal).
/// - [breathing] loops forever (reverse-repeat) once the timeline
///   finishes, driving the micro scale "breathing" effect on the
///   finished logo. Keeping it separate means it never has to fight
///   with the one-shot timeline's curve math.
class SplashAnimationController {
  SplashAnimationController({required TickerProvider vsync})
    : timeline = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 3000),
      ),
      breathing = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 1800),
      ) {
    backgroundFade = _interval(0.0, 0.12);
    roofDraw = _interval(0.10, 0.34);
    wallsDraw = _interval(0.30, 0.50);
    poleGrow = _interval(0.46, 0.58);
    // Flag (Lottie) is triggered as a discrete event once poleGrow
    // crosses this threshold -- see SplashScreen._onTimelineTick.
    flagRevealThreshold = 0.56;
    kopdesTextReveal = _interval(0.60, 0.74);
    merahPutihTextReveal = _interval(0.70, 0.86);
    shadowReveal = _interval(0.78, 0.95);

    breathingScale = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: breathing, curve: Curves.easeInOut));
  }

  final AnimationController timeline;
  final AnimationController breathing;

  late final Animation<double> backgroundFade;
  late final Animation<double> roofDraw;
  late final Animation<double> wallsDraw;
  late final Animation<double> poleGrow;
  late final double flagRevealThreshold;
  late final Animation<double> kopdesTextReveal;
  late final Animation<double> merahPutihTextReveal;
  late final Animation<double> shadowReveal;
  late final Animation<double> breathingScale;

  Animation<double> _interval(
    double start,
    double end, {
    Curve curve = Curves.easeOutCubic,
  }) {
    return CurvedAnimation(
      parent: timeline,
      curve: Interval(start, end, curve: curve),
    );
  }

  /// Plays the one-shot timeline, then starts the infinite breathing
  /// loop. Returns a Future that resolves once the entry choreography
  /// has fully played out (useful to gate "ready to navigate").
  Future<void> playEntrance() async {
    await timeline.forward();
    breathing.repeat(reverse: true);
  }

  void dispose() {
    timeline.dispose();
    breathing.dispose();
  }
}
