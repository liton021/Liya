import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/card_model.dart';

/// Premium UNO card widget with glassmorphism effect
/// 
/// Features:
/// - Custom painted card design
/// - Soft shadows and inner glow
/// - Haptic feedback on interaction
/// - Smooth animations
class UnoCardWidget extends StatelessWidget {
  final UnoCard card;
  final bool isPlayable;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const UnoCardWidget({
    super.key,
    required this.card,
    this.isPlayable = true,
    this.onTap,
    this.width = 80,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPlayable && onTap != null) {
          HapticFeedback.mediumImpact();
          onTap!();
        }
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: _getCardColor().withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: CustomPaint(
          painter: UnoCardPainter(
            card: card,
            isPlayable: isPlayable,
          ),
        ),
      ),
    );
  }

  Color _getCardColor() {
    switch (card.color) {
      case UnoCardColor.red:
        return const Color(0xFFE53935);
      case UnoCardColor.blue:
        return const Color(0xFF1E88E5);
      case UnoCardColor.green:
        return const Color(0xFF43A047);
      case UnoCardColor.yellow:
        return const Color(0xFFFDD835);
      case UnoCardColor.wild:
        return Colors.black;
    }
  }
}

/// Custom painter for drawing premium UNO cards
class UnoCardPainter extends CustomPainter {
  final UnoCard card;
  final bool isPlayable;

  UnoCardPainter({
    required this.card,
    required this.isPlayable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // Draw card background
    _drawBackground(canvas, rrect);

    // Draw inner shadow
    _drawInnerShadow(canvas, rrect);

    // Draw card content
    _drawCardContent(canvas, size);

    // Draw border
    _drawBorder(canvas, rrect);

    // Apply disabled overlay if not playable
    if (!isPlayable) {
      _drawDisabledOverlay(canvas, rrect);
    }
  }

  void _drawBackground(Canvas canvas, RRect rrect) {
    final paint = Paint()
      ..color = _getBackgroundColor()
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);
  }

  void _drawInnerShadow(Canvas canvas, RRect rrect) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rrect.outerRect.deflate(2),
        const Radius.circular(10),
      ),
      shadowPaint,
    );
  }

  void _drawCardContent(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getCardText(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Draw small corner indicators
    _drawCornerIndicator(canvas, size, Alignment.topLeft);
    _drawCornerIndicator(canvas, size, Alignment.bottomRight);
  }

  void _drawCornerIndicator(Canvas canvas, Size size, Alignment alignment) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getCardText(),
        style: TextStyle(
          color: _getTextColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    Offset position;
    if (alignment == Alignment.topLeft) {
      position = const Offset(8, 8);
    } else {
      canvas.save();
      canvas.translate(size.width - 8, size.height - 8);
      canvas.rotate(3.14159); // 180 degrees
      position = const Offset(0, 0);
    }

    textPainter.paint(canvas, position);
    
    if (alignment == Alignment.bottomRight) {
      canvas.restore();
    }
  }

  void _drawBorder(Canvas canvas, RRect rrect) {
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rrect, borderPaint);
  }

  void _drawDisabledOverlay(Canvas canvas, RRect rrect) {
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, overlayPaint);
  }

  Color _getBackgroundColor() {
    switch (card.color) {
      case UnoCardColor.red:
        return const Color(0xFFE53935);
      case UnoCardColor.blue:
        return const Color(0xFF1E88E5);
      case UnoCardColor.green:
        return const Color(0xFF43A047);
      case UnoCardColor.yellow:
        return const Color(0xFFFDD835);
      case UnoCardColor.wild:
        return const Color(0xFF212121);
    }
  }

  Color _getTextColor() {
    if (card.color == UnoCardColor.yellow) {
      return Colors.black87;
    }
    return Colors.white;
  }

  String _getCardText() {
    switch (card.value) {
      case UnoCardValue.zero:
        return '0';
      case UnoCardValue.one:
        return '1';
      case UnoCardValue.two:
        return '2';
      case UnoCardValue.three:
        return '3';
      case UnoCardValue.four:
        return '4';
      case UnoCardValue.five:
        return '5';
      case UnoCardValue.six:
        return '6';
      case UnoCardValue.seven:
        return '7';
      case UnoCardValue.eight:
        return '8';
      case UnoCardValue.nine:
        return '9';
      case UnoCardValue.skip:
        return '⊘';
      case UnoCardValue.reverse:
        return '⇄';
      case UnoCardValue.drawTwo:
        return '+2';
      case UnoCardValue.wild:
        return '◆';
      case UnoCardValue.wildDrawFour:
        return '+4';
    }
  }

  @override
  bool shouldRepaint(UnoCardPainter oldDelegate) {
    return oldDelegate.card != card || oldDelegate.isPlayable != isPlayable;
  }
}
