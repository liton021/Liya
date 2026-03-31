import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Premium dark-green felt game table  matching the reference design
class GameTable extends StatelessWidget {
  final Widget child;
  final TableStyle style;

  const GameTable({
    super.key,
    required this.child,
    this.style = TableStyle.greenFelt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, 0.1),
          radius: 1.0,
          colors: [
            Color(0xFF1E5622), // bright felt center
            Color(0xFF153B18), // mid felt
            Color(0xFF0C2610), // dark edges
          ],
        ),
      ),
      child: CustomPaint(
        painter: _FeltTablePainter(),
        child: child,
      ),
    );
  }
}

enum TableStyle { darkMatte, woodTexture, greenFelt }

// ────────────────────────────────────────────────────────────────────────────
class _FeltTablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(13);

    // Felt fiber texture
    final fiberPaint = Paint()
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 900; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final angle = rng.nextDouble() * math.pi * 2;
      final len = 2.0 + rng.nextDouble() * 4;
      fiberPaint.color =
          Colors.black.withOpacity(0.04 + rng.nextDouble() * 0.04);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(angle) * len, y + math.sin(angle) * len),
        fiberPaint,
      );
    }

    // Decorative oval border ring (like a real card table)
    final ovalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = const Color(0xFF1A4D1F).withOpacity(0.7);

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width * 0.78,
      height: size.height * 0.42,
    );
    canvas.drawOval(ovalRect, ovalPaint);

    // Inner oval – lighter highlight
    final innerOvalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.06);
    canvas.drawOval(
      ovalRect.deflate(8),
      innerOvalPaint,
    );

    // Subtle vignette
    final vigPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.45),
        ],
        stops: const [0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vigPaint);
  }

  @override
  bool shouldRepaint(_FeltTablePainter old) => false;
}

// Keep legacy aliases so other widgets still compile
class TableTexturePainter extends CustomPainter {
  final TableStyle style;
  const TableTexturePainter({required this.style});
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(TableTexturePainter old) => false;
}

class TableEdge extends StatelessWidget {
  final double height;
  const TableEdge({super.key, this.height = 40});
  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

class EdgeDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(EdgeDetailPainter old) => false;
}
