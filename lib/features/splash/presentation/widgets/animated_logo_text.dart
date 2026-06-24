import 'package:flutter/material.dart';

/// A single word/line that fades up with a slight scale-in, driven by
/// an external 0..1 progress value (so it stays perfectly in sync
/// with the rest of the splash timeline instead of running its own
/// independent controller).
class AnimatedLogoText extends StatelessWidget {
  const AnimatedLogoText({
    super.key,
    required this.text,
    required this.progress,
    this.style,
    this.riseDistance = 14,
  });

  final String text;
  final double progress; // 0..1, already eased by the caller
  final TextStyle? style;
  final double riseDistance;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final opacity = clamped;
    final dy = riseDistance * (1 - clamped);
    final scale = 0.94 + (0.06 * clamped);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Text(
            text,
            style:
                style ??
                const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Color(0xFF111111),
                ),
          ),
        ),
      ),
    );
  }
}
