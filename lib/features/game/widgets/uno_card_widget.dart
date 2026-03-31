import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/card_model.dart';
import 'dart:math' as math;

/// Premium UNO card widget matching reference design:
/// - Solid color background
/// - White oval/ellipse in center tilted 45°
/// - Big number/symbol in center
/// - Small corner indicators
/// - Gold glow border when playable
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
              color: Colors.black.withOpacity(0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: _cardColor().withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomPaint(
            painter: _UnoCardPainter(card: card, isPlayable: isPlayable),
          ),
        ),
      ),
    );
  }

  Color _cardColor() {
    switch (card.color) {
      case UnoCardColor.red:
        return const Color(0xFFD32F2F);
      case UnoCardColor.blue:
        return const Color(0xFF1565C0);
      case UnoCardColor.green:
        return const Color(0xFF2E7D32);
      case UnoCardColor.yellow:
        return const Color(0xFFF9A825);
      case UnoCardColor.wild:
        return Colors.black87;
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
class _UnoCardPainter extends CustomPainter {
  final UnoCard card;
  final bool isPlayable;

  _UnoCardPainter({required this.card, required this.isPlayable});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    // 1. Background
    _paintBackground(canvas, rrect, size);

    // 2. White tilted oval
    _paintOval(canvas, size);

    // 3. Center symbol
    _paintCenterSymbol(canvas, size);

    // 4. Corner labels
    _paintCornerLabel(canvas, size, topLeft: true);
    _paintCornerLabel(canvas, size, topLeft: false);

    // 5. Greyed-out overlay if not playable
    if (!isPlayable) {
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.42)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintBackground(Canvas canvas, RRect rrect, Size size) {
    // Main background color
    final bgPaint = Paint()
      ..color = _bgColor()
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, bgPaint);

    // Subtle inner gradient highlight (top lighter)
    final gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.18),
          Colors.transparent,
          Colors.black.withOpacity(0.15),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(rrect, gradPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rrect.outerRect.deflate(1.5),
        const Radius.circular(11),
      ),
      borderPaint,
    );
  }

  void _paintOval(Canvas canvas, Size size) {
    // A tilted white oval/ellipse in the background
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 6); // 30°

    final ovalPaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.7,
          height: size.height * 0.55),
      ovalPaint,
    );

    // Solid white inner oval (where the symbol sits)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: size.width * 0.55,
          height: size.height * 0.42),
      innerPaint,
    );
    canvas.restore();
  }

  void _paintCenterSymbol(Canvas canvas, Size size) {
    final text = _symbolText();
    final color = _symbolColor(); // against the white oval background

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.38,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  void _paintCornerLabel(Canvas canvas, Size size, {required bool topLeft}) {
    final text = _symbolText();

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (topLeft) {
      tp.paint(canvas, const Offset(7, 5));
    } else {
      canvas.save();
      canvas.translate(size.width - 7, size.height - 5);
      canvas.rotate(math.pi);
      tp.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  Color _bgColor() {
    switch (card.color) {
      case UnoCardColor.red:
        return const Color(0xFFD32F2F);
      case UnoCardColor.blue:
        return const Color(0xFF1565C0);
      case UnoCardColor.green:
        return const Color(0xFF2E7D32);
      case UnoCardColor.yellow:
        return const Color(0xFFF9A825);
      case UnoCardColor.wild:
        return const Color(0xFF1A1A1A);
    }
  }

  Color _symbolColor() {
    switch (card.color) {
      case UnoCardColor.red:
        return const Color(0xFFD32F2F);
      case UnoCardColor.blue:
        return const Color(0xFF1565C0);
      case UnoCardColor.green:
        return const Color(0xFF2E7D32);
      case UnoCardColor.yellow:
        return const Color(0xFFF9A825);
      case UnoCardColor.wild:
        return Colors.black87;
    }
  }

  String _symbolText() {
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
        return '✦';
      case UnoCardValue.wildDrawFour:
        return '+4';
    }
  }

  @override
  bool shouldRepaint(_UnoCardPainter old) =>
      old.card != card || old.isPlayable != isPlayable;
}
