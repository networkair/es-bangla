import 'package:flutter/material.dart';

/// A lightweight, GPU-accelerated animated shimmer loading effect.
/// Replaces generic circular progress indicators with modern skeleton waves.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
  });

  /// Factory helper for a generic rounded rectangle shimmer box
  static Widget box({
    double? width,
    double? height,
    double borderRadius = 8,
    Color baseColor = const Color(0xFFE2E8F0),
    Color highlightColor = const Color(0xFFF8FAFC),
  }) {
    return AppShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Factory helper for circular shimmer placeholders (e.g. avatars, icon containers)
  static Widget circle({
    required double size,
    Color baseColor = const Color(0xFFE2E8F0),
    Color highlightColor = const Color(0xFFF8FAFC),
  }) {
    return AppShimmer(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// Factory helper for 16:9 banner placeholders
  static Widget banner16x9({
    double borderRadius = 4,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AppShimmer(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Stack(
            children: [
              // Subtle badge placeholder in top-left
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 90,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Subtle icon in center
              Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 38,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
