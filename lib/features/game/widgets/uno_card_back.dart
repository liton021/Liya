import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Premium UNO card back widget matching the red design request.
class UnoCardBack extends StatelessWidget {
  final double width;
  final double height;
  final bool isRotated;
  final bool isSmall;

  const UnoCardBack({
    super.key,
    this.width = 80,
    this.height = 120,
    this.isRotated = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        child: CustomPaint(
          painter: _UnoCardBackPainter(isRotated: isRotated, isSmall: isSmall),
        ),
      ),
    );
  }
}

class _UnoCardBackPainter extends CustomPainter {
  final bool isRotated;
  final bool isSmall;

  _UnoCardBackPainter({required this.isRotated, required this.isSmall});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(isSmall ? 8 : 12));

    // 1. Background (Red Gradient)
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE53935),
          Color(0xFFB71C1C),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // 2. White tilted oval
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 6); // 30° tilt

    final ovalPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.8,
          height: size.height * 0.6),
      ovalPaint,
    );

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.65,
          height: size.height * 0.45),
      innerPaint,
    );
    canvas.restore();

    // 3. UNO Text
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'UNO',
        style: TextStyle(
          color: const Color(0xFFD32F2F),
          fontSize: isSmall ? size.width * 0.28 : size.width * 0.35,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          fontStyle: FontStyle.italic,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();

    // 4. Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSmall ? 1.5 : 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(isSmall ? 1 : 1.5),
        Radius.circular(isSmall ? 7 : 11),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(_UnoCardBackPainter old) => 
    old.isRotated != isRotated || old.isSmall != isSmall;
}
