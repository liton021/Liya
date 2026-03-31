import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../game/screens/game_screen.dart';
import 'dart:math' as math;

/// Premium menu screen – dark wood, gold UNO Luxe logo, glassmorphism buttons
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Dark wood-textured background ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.2,
                colors: [
                  Color(0xFF2A1A0A),
                  Color(0xFF1A0F05),
                  Color(0xFF0D0802),
                ],
              ),
            ),
          ),
          // Wood grain overlay
          CustomPaint(
            size: Size.infinite,
            painter: _WoodGrainPainter(),
          ),
          // ── Particle sparkles ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: Size.infinite,
              painter: _SparkleParticlePainter(_particleCtrl.value),
            ),
          ),
          // ── Content ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildLogo(),
                const Spacer(),
                _buildButtons(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Coins
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFB8860B).withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFFD700), size: 18),
                SizedBox(width: 6),
                Text('50',
                    style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B6914), Color(0xFF5C4300)],
              ),
              border: Border.all(color: const Color(0xFFB8860B), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white70, size: 24),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // UNO text with gold preset
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFE066),
              Color(0xFFFFD700),
              Color(0xFFB8860B),
              Color(0xFFFFD700),
              Color(0xFFFFE066),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ).createShader(bounds),
          child: const Text(
            'UNO',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 6,
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2500.ms, color: Colors.white38),
        // Luxe italic
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD4A017), Color(0xFFFFD700), Color(0xFFD4A017)],
          ).createShader(bounds),
          child: const Text(
            'Luxe',
            style: TextStyle(
              fontSize: 38,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 2,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Decorative sparkles row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.star,
                size: i == 2 ? 14 : 8,
                color: const Color(0xFFFFD700).withOpacity(i == 2 ? 1.0 : 0.5),
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: -0.15, end: 0, duration: 700.ms, curve: Curves.easeOut);
  }

  Widget _buildButtons() {
    final buttons = [
      ('SINGLE PLAYER', Icons.person, () => _startSinglePlayer(context), false),
      ('MULTIPLAYER LOBBY', Icons.people, () {}, true),
      ('PLAY WITH FRIENDS', Icons.group_add, () {}, true),
      ('SHOP', Icons.storefront, () {}, true),
    ];
    return Column(
      children: buttons.asMap().entries.map((entry) {
        final i = entry.key;
        final (label, icon, cb, soon) = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
          child: _LuxeMenuButton(
            label: label,
            icon: icon,
            onTap: soon ? null : cb,
            comingSoon: soon,
          ),
        )
            .animate()
            .fadeIn(delay: (100 + i * 80).ms, duration: 450.ms)
            .slideY(begin: 0.2, end: 0, duration: 450.ms, curve: Curves.easeOut);
      }).toList(),
    );
  }

  void _startSinglePlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
class _LuxeMenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool comingSoon;
  const _LuxeMenuButton(
      {required this.label,
      required this.icon,
      this.onTap,
      this.comingSoon = false});
  @override
  State<_LuxeMenuButton> createState() => _LuxeMenuButtonState();
}

class _LuxeMenuButtonState extends State<_LuxeMenuButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.45),
            border: Border.all(
              color: const Color(0xFFB8860B).withOpacity(0.55),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF3D2B0A).withOpacity(0.7),
                const Color(0xFF1A1200).withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB8860B).withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.comingSoon
                      ? Colors.white38
                      : const Color(0xFFEDD47A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              if (widget.comingSoon) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: const Text('SOON',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rng = math.Random(7);
    for (int i = 0; i < 20; i++) {
      final y = rng.nextDouble() * size.height;
      paint.color = Colors.white.withOpacity(0.018 + rng.nextDouble() * 0.012);
      final path = Path()..moveTo(0, y);
      double cx = 0;
      while (cx < size.width) {
        cx += 20 + rng.nextDouble() * 40;
        final cy = y + (rng.nextDouble() - 0.5) * 12;
        path.lineTo(cx, cy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_WoodGrainPainter old) => false;
}

class _SparkleParticlePainter extends CustomPainter {
  final double t;
  static const _count = 18;
  static final _rng = math.Random(42);
  static final _positions = List.generate(
      _count, (_) => Offset(_rng.nextDouble(), _rng.nextDouble()));
  static final _phases = List.generate(_count, (_) => _rng.nextDouble());
  static final _sizes = List.generate(_count, (_) => 1.0 + _rng.nextDouble() * 3);

  _SparkleParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFD700);
    for (int i = 0; i < _count; i++) {
      final alpha = (math.sin((t + _phases[i]) * math.pi * 2) * 0.5 + 0.5);
      paint.color = Color.fromRGBO(255, 215, 0, alpha * 0.6);
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i] * alpha,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkleParticlePainter old) => old.t != t;
}
