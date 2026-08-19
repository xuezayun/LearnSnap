import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painted treasure chest — closed while quests remain, open when done.
class TreasureChestArt extends StatelessWidget {
  const TreasureChestArt({
    super.key,
    this.size = 88,
    this.open = false,
  });

  final double size;
  final bool open;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: open ? 1 : 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ChestPainter(openAmount: value),
          ),
        );
      },
    );
  }
}

class _ChestPainter extends CustomPainter {
  _ChestPainter({required this.openAmount});

  final double openAmount;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final shadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.88),
        width: w * 0.72,
        height: h * 0.12,
      ),
      shadow,
    );

    if (openAmount > 0.15) {
      final spark = Paint()..color = const Color(0xFFFFC53D).withValues(
        alpha: 0.35 + 0.5 * openAmount,
      );
      for (final p in [
        Offset(cx - w * 0.28, h * 0.18),
        Offset(cx + w * 0.3, h * 0.14),
        Offset(cx, h * 0.06),
      ]) {
        _drawStar(canvas, p, w * 0.07 * openAmount, spark);
      }
    }

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.42, w * 0.68, h * 0.42),
      Radius.circular(w * 0.08),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8A04A), Color(0xFFC4782A)],
        ).createShader(bodyRect.outerRect),
    );

    final band = Paint()..color = const Color(0xFFFFC53D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.58, w * 0.68, h * 0.1),
        Radius.circular(w * 0.02),
      ),
      band,
    );

    canvas.save();
    final hinge = Offset(cx, h * 0.42);
    canvas.translate(hinge.dx, hinge.dy);
    canvas.rotate(-0.7 * openAmount);
    canvas.translate(-hinge.dx, -hinge.dy);
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.22, w * 0.72, h * 0.24),
      Radius.circular(w * 0.12),
    );
    canvas.drawRRect(
      lidRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0B45C), Color(0xFFD48932)],
        ).createShader(lidRect.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.14, h * 0.38, w * 0.72, h * 0.07),
        Radius.circular(w * 0.02),
      ),
      band,
    );
    canvas.restore();

    final lockCenter = Offset(cx, h * 0.64);
    canvas.drawCircle(lockCenter, w * 0.09, Paint()..color = const Color(0xFFFFC53D));
    canvas.drawCircle(
      lockCenter,
      w * 0.045,
      Paint()
        ..color = const Color(0xFF8A5A18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );
    canvas.drawLine(
      lockCenter,
      lockCenter.translate(0, w * 0.05),
      Paint()
        ..color = const Color(0xFF8A5A18)
        ..strokeWidth = w * 0.018
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final p = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      final b = a + math.pi / 4;
      path.lineTo(c.dx + math.cos(b) * r * 0.35, c.dy + math.sin(b) * r * 0.35);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChestPainter oldDelegate) =>
      oldDelegate.openAmount != openAmount;
}
