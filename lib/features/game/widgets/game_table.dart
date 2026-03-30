import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Premium game table widget with realistic texture
/// 
/// Creates a dark matte or wooden texture background
/// for the game playing surface
class GameTable extends StatelessWidget {
  final Widget child;
  final TableStyle style;

  const GameTable({
    super.key,
    required this.child,
    this.style = TableStyle.darkMatte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getTableGradient(),
      ),
      child: CustomPaint(
        painter: TableTexturePainter(style: style),
        child: child,
      ),
    );
  }

  LinearGradient _getTableGradient() {
    switch (style) {
      case TableStyle.darkMatte:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
        );
      case TableStyle.woodTexture:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3E2723),
            const Color(0xFF4E342E),
            const Color(0xFF5D4037),
          ],
        );
      case TableStyle.greenFelt:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20),
            const Color(0xFF2E7D32),
            const Color(0xFF388E3C),
          ],
        );
    }
  }
}

/// Enum for different table styles
enum TableStyle {
  darkMatte,
  woodTexture,
  greenFelt,
}

/// Custom painter for table texture effects
class TableTexturePainter extends CustomPainter {
  final TableStyle style;

  TableTexturePainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case TableStyle.darkMatte:
        _paintMatteTexture(canvas, size);
        break;
      case TableStyle.woodTexture:
        _paintWoodTexture(canvas, size);
        break;
      case TableStyle.greenFelt:
        _paintFeltTexture(canvas, size);
        break;
    }

    // Add subtle vignette effect
    _paintVignette(canvas, size);
  }

  void _paintMatteTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Fixed seed for consistency

    // Add noise texture
    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintWoodTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw wood grain lines
    for (int i = 0; i < 30; i++) {
      final y = (size.height / 30) * i;
      final path = Path();
      path.moveTo(0, y);

      // Create wavy line for wood grain
      for (double x = 0; x < size.width; x += 10) {
        final offset = math.sin(x * 0.05 + i) * 3;
        path.lineTo(x, y + offset);
      }

      paint.color = Colors.black.withOpacity(0.1);
      canvas.drawPath(path, paint);
    }

    // Add wood knots
    final random = math.Random(42);
    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      _drawWoodKnot(canvas, Offset(x, y));
    }
  }

  void _drawWoodKnot(Canvas canvas, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final radius = 10.0 + i * 5;
      paint.color = Colors.black.withOpacity(0.15 - i * 0.02);
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintFeltTexture(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);

    // Add felt fiber texture
    for (int i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final length = random.nextDouble() * 3 + 1;
      final angle = random.nextDouble() * math.pi * 2;

      final path = Path();
      path.moveTo(x, y);
      path.lineTo(
        x + math.cos(angle) * length,
        y + math.sin(angle) * length,
      );

      canvas.drawPath(path, paint..strokeWidth = 0.5);
    }
  }

  void _paintVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.3),
      ],
      stops: const [0.5, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(TableTexturePainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

/// Decorative table edge widget
class TableEdge extends StatelessWidget {
  final double height;

  const TableEdge({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C2C54).withOpacity(0.8),
            const Color(0xFF1A1A2E).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: EdgeDetailPainter(),
      ),
    );
  }
}

/// Painter for decorative edge details
class EdgeDetailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw decorative lines
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.3),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(EdgeDetailPainter oldDelegate) => false;
}
