import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft wash background with organic blobs — used across main screens.
class AppScaffoldBackground extends StatelessWidget {
  const AppScaffoldBackground({
    super.key,
    required this.child,
    this.includeSafeArea = false,
  });

  final Widget child;
  final bool includeSafeArea;

  @override
  Widget build(BuildContext context) {
    final content = includeSafeArea ? SafeArea(child: child) : child;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.washTop,
                AppColors.washMid,
                AppColors.washBottom,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        const Positioned(
          top: -80,
          right: -60,
          child: _Blob(
            size: 220,
            color: Color(0x332EC4B6),
          ),
        ),
        const Positioned(
          top: 160,
          left: -90,
          child: _Blob(
            size: 180,
            color: Color(0x22F0A060),
          ),
        ),
        const Positioned(
          bottom: -40,
          right: -20,
          child: _Blob(
            size: 160,
            color: Color(0x1A5CBF7A),
          ),
        ),
        content,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _BlobPainter(color),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.9, h * 0.05, w, h * 0.35, w * 0.85, h * 0.55);
    path.cubicTo(w * 0.95, h * 0.85, w * 0.55, h, w * 0.35, h * 0.85);
    path.cubicTo(w * 0.05, h * 0.9, 0, h * 0.45, w * 0.2, h * 0.25);
    path.cubicTo(w * 0.15, h * 0.08, w * 0.3, 0, w * 0.5, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) =>
      oldDelegate.color != color;
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 88,
    this.strokeWidth = 8,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final bg = Paint()
      ..color = AppColors.brand.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = AppColors.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}
