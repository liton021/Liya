import 'dart:math';
import 'package:flutter/material.dart';

/// Particle effect widget for card play celebrations
/// 
/// Creates a burst of particles when a card is played
/// for enhanced visual feedback
class CardParticleEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback? onComplete;

  const CardParticleEffect({
    super.key,
    required this.position,
    required this.color,
    this.onComplete,
  });

  @override
  State<CardParticleEffect> createState() => _CardParticleEffectState();
}

class _CardParticleEffectState extends State<CardParticleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particles = List.generate(20, (index) => _createParticle());

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  Particle _createParticle() {
    final angle = _random.nextDouble() * 2 * pi;
    final speed = 50 + _random.nextDouble() * 100;
    final size = 3 + _random.nextDouble() * 5;

    return Particle(
      position: widget.position,
      velocity: Offset(
        cos(angle) * speed,
        sin(angle) * speed,
      ),
      size: size,
      color: widget.color.withOpacity(0.8),
      lifetime: 0.6 + _random.nextDouble() * 0.4,
    );
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
        return CustomPaint(
          painter: ParticlePainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Represents a single particle
class Particle {
  final Offset position;
  final Offset velocity;
  final double size;
  final Color color;
  final double lifetime;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.lifetime,
  });

  Offset getPosition(double time) {
    // Apply gravity
    final gravity = 200.0;
    return Offset(
      position.dx + velocity.dx * time,
      position.dy + velocity.dy * time + 0.5 * gravity * time * time,
    );
  }

  double getOpacity(double time) {
    final normalizedTime = time / lifetime;
    return (1.0 - normalizedTime).clamp(0.0, 1.0);
  }
}

/// Custom painter for rendering particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final position = particle.getPosition(progress);
      final opacity = particle.getOpacity(progress);

      if (opacity > 0) {
        final paint = Paint()
          ..color = particle.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(position, particle.size, paint);

        // Add glow effect
        final glowPaint = Paint()
          ..color = particle.color.withOpacity(opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(position, particle.size * 1.5, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Ripple effect widget for card interactions
class RippleEffect extends StatefulWidget {
  final Offset position;
  final Color color;
  final double maxRadius;
  final VoidCallback? onComplete;

  const RippleEffect({
    super.key,
    required this.position,
    required this.color,
    this.maxRadius = 100,
    this.onComplete,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RipplePainter(
            position: widget.position,
            color: widget.color,
            progress: _controller.value,
            maxRadius: widget.maxRadius,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Offset position;
  final Color color;
  final double progress;
  final double maxRadius;

  RipplePainter({
    required this.position,
    required this.color,
    required this.progress,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = maxRadius * progress;
    final opacity = (1.0 - progress) * 0.5;

    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(position, radius, paint);

    // Inner ripple
    if (progress > 0.3) {
      final innerProgress = (progress - 0.3) / 0.7;
      final innerRadius = maxRadius * 0.7 * innerProgress;
      final innerOpacity = (1.0 - innerProgress) * 0.3;

      final innerPaint = Paint()
        ..color = color.withOpacity(innerOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(position, innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
