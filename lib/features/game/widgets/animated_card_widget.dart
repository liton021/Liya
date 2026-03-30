import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/card_model.dart';
import 'uno_card_widget.dart';

/// Animated card widget that follows a Bezier curve path
/// 
/// This widget animates cards moving from one position to another
/// using a smooth Bezier curve trajectory for premium feel
class AnimatedCardWidget extends StatefulWidget {
  final UnoCard card;
  final Offset startPosition;
  final Offset endPosition;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool isPlayable;

  const AnimatedCardWidget({
    super.key,
    required this.card,
    required this.startPosition,
    required this.endPosition,
    this.duration = const Duration(milliseconds: 500),
    this.onComplete,
    this.isPlayable = true,
  });

  @override
  State<AnimatedCardWidget> createState() => _AnimatedCardWidgetState();
}

class _AnimatedCardWidgetState extends State<AnimatedCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Cubic bezier curve for smooth easing
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final position = _calculateBezierPosition(_animation.value);
        final scale = _calculateScale(_animation.value);
        final rotation = _calculateRotation(_animation.value);

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotation,
              child: UnoCardWidget(
                card: widget.card,
                isPlayable: widget.isPlayable,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Calculates position along Bezier curve
  /// 
  /// Uses quadratic Bezier curve with control point above the midpoint
  /// for a natural arc trajectory
  Offset _calculateBezierPosition(double t) {
    final start = widget.startPosition;
    final end = widget.endPosition;

    // Calculate control point (creates arc above the straight line)
    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;
    final controlPoint = Offset(midX, midY - 100); // Arc height

    // Quadratic Bezier formula: B(t) = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
    final oneMinusT = 1.0 - t;
    final x = oneMinusT * oneMinusT * start.dx +
        2 * oneMinusT * t * controlPoint.dx +
        t * t * end.dx;
    final y = oneMinusT * oneMinusT * start.dy +
        2 * oneMinusT * t * controlPoint.dy +
        t * t * end.dy;

    return Offset(x, y);
  }

  /// Calculates scale during animation
  /// 
  /// Card slightly grows at the peak of the arc for emphasis
  double _calculateScale(double t) {
    // Scale up to 1.1 at midpoint, then back to 1.0
    if (t < 0.5) {
      return 1.0 + (t * 0.2);
    } else {
      return 1.1 - ((t - 0.5) * 0.2);
    }
  }

  /// Calculates rotation during animation
  /// 
  /// Slight rotation for natural card flip effect
  double _calculateRotation(double t) {
    // Rotate slightly during flight
    return (t - 0.5) * 0.2; // Max ±0.1 radians
  }
}

/// Enhanced card widget with hover and press effects
class InteractiveCardWidget extends StatefulWidget {
  final UnoCard card;
  final bool isPlayable;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const InteractiveCardWidget({
    super.key,
    required this.card,
    this.isPlayable = true,
    this.onTap,
    this.width = 80,
    this.height = 120,
  });

  @override
  State<InteractiveCardWidget> createState() => _InteractiveCardWidgetState();
}

class _InteractiveCardWidgetState extends State<InteractiveCardWidget> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.isPlayable) {
          setState(() => _isPressed = true);
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.isPlayable && widget.onTap != null) {
          HapticFeedback.mediumImpact();
          widget.onTap!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..translate(0.0, _isPressed ? 4.0 : (_isHovered ? -8.0 : 0.0))
            ..scale(_isPressed ? 0.95 : 1.0),
          child: UnoCardWidget(
            card: widget.card,
            isPlayable: widget.isPlayable,
            width: widget.width,
            height: widget.height,
          ),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .shimmer(
            duration: 2000.ms,
            color: widget.isPlayable
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
          ),
    );
  }
}

/// Card flip animation widget
class FlipCardWidget extends StatefulWidget {
  final UnoCard card;
  final bool showFront;
  final Duration duration;

  const FlipCardWidget({
    super.key,
    required this.card,
    this.showFront = true,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    if (widget.showFront) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FlipCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showFront != widget.showFront) {
      if (widget.showFront) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * 3.14159; // π radians
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: angle < 1.5708 // π/2
              ? _buildCardBack()
              : Transform(
                  transform: Matrix4.identity()..rotateY(3.14159),
                  alignment: Alignment.center,
                  child: UnoCardWidget(card: widget.card),
                ),
        );
      },
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C54),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.style,
          color: Colors.white.withOpacity(0.3),
          size: 48,
        ),
      ),
    );
  }
}
