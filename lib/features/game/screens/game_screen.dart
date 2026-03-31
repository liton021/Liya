import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../widgets/game_table.dart';
import '../widgets/uno_card_widget.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player_model.dart';
import '../../../core/services/rule_engine.dart';

/// Main game screen – premium UNO Luxe design matching the reference
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _unoGlowCtrl;
  bool _unoDeclared = false;

  @override
  void initState() {
    super.initState();
    _unoGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final players = [
        Player.human(id: 'player1', name: 'You'),
        Player.ai(id: 'ai1', name: 'AI Opponent'),
      ];
      ref.read(gameStateProvider.notifier).initializeGame(players);
    });
  }

  @override
  void dispose() {
    _unoGlowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GameTable(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(gameState, size),
                    _buildOpponentArea(gameState, size),
                    Expanded(child: _buildCenterArea(gameState, size)),
                    _buildPlayerHand(gameState, size),
                    _buildBottomBar(gameState, size),
                  ],
                ),
                // Victory overlay
                if (gameState.status == GameStatus.finished)
                  _buildVictoryOverlay(gameState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top settings / coins bar ──────────────────────────────────────────────
  Widget _buildTopBar(dynamic gameState, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: AnimatedBuilder(
          animation: _unoGlowCtrl,
          builder: (_, __) => Icon(
            gameState.isClockwise
                ? Icons.rotate_right
                : Icons.rotate_left,
            color:
                Colors.white.withOpacity(0.4 + _unoGlowCtrl.value * 0.3),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _iconCircleButton(IconData icon, VoidCallback onTap,
      {Color color = Colors.white70}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // ── Opponent area (top) ───────────────────────────────────────────────────
  Widget _buildOpponentArea(dynamic gameState, Size size) {
    final opponentId =
        gameState.playerIds.length > 1 ? gameState.playerIds[1] : null;
    final opponentHand =
        opponentId != null ? gameState.playerHands[opponentId] as List<UnoCard>? : null;
    final isAiTurn = gameState.currentPlayerId == 'ai1';
    final opponent = opponentId != null
        ? ref.read(gameStateProvider.notifier).getPlayer(opponentId)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Column(
        children: [
          // Avatar + name + card count
          _buildPlayerAvatar(
            name: opponent?.name ?? 'AI',
            cardCount: opponentHand?.length ?? 0,
            isActive: isAiTurn,
            isTop: true,
          ),
          const SizedBox(height: 6),
          // AI thinking indicator
          if (isAiTurn)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Color(0xFFFFD700)),
                  ),
                  SizedBox(width: 8),
                  Text('Thinking...',
                      style: TextStyle(
                          color: Color(0xFFEDD47A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white24),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildPlayerAvatar({
    required String name,
    required int cardCount,
    required bool isActive,
    bool isTop = false,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
            ),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFFFD700)
                  : Colors.white.withOpacity(0.25),
              width: isActive ? 3 : 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        Text('$cardCount cards',
            style: TextStyle(
                color: Colors.white.withOpacity(0.55), fontSize: 10)),
      ],
    );
  }

  // ── Center area: draw pile + discard pile ─────────────────────────────────
  Widget _buildCenterArea(dynamic gameState, Size size) {
    final isHumanTurn = gameState.currentPlayerId == 'player1';
    final topCard = gameState.topCard as UnoCard?;
    final humanHandCount = (gameState.playerHands['player1'] as List<UnoCard>? ?? []).length;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Draw pile ──────────────────────────────────────────
              GestureDetector(
                onTap: isHumanTurn
                    ? () {
                        HapticFeedback.mediumImpact();
                        ref.read(gameStateProvider.notifier).drawCard();
                      }
                    : null,
                child: AnimatedOpacity(
                  opacity: isHumanTurn ? 1.0 : 0.55,
                  duration: const Duration(milliseconds: 300),
                  child: _DrawPileCard(),
                ),
              ),

              const SizedBox(width: 36),

              // ── Discard pile Top card ───────────────────────────────
              if (topCard != null)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _cardGlowColor(topCard).withOpacity(0.65),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: _buildFancyCard(topCard, width: 90, height: 135,
                          playable: false),
                    )
                        .animate()
                        .scale(begin: const Offset(0.85, 0.85), duration: 300.ms, curve: Curves.easeOut)
                        .fadeIn(duration: 200.ms),

                    // Active stack badge indicator    
                    if (gameState.hasActiveStack)
                      Positioned(
                        top: -12,
                        right: -18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE53935), Color(0xFFC62828)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFFD700), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.red.withOpacity(0.7), blurRadius: 16)
                            ],
                          ),
                          child: Text(
                            '+${gameState.stackPenalty}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1.1, 1.1), duration: 500.ms),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 30),
          // ── UNO Buzzer & Pass Button ──────────────────────────
          _buildActionButtons(gameState, humanHandCount, isHumanTurn),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic gameState, int handCount, bool isHumanTurn) {
    final showPass = isHumanTurn && gameState.hasDrawnThisTurn && !gameState.hasActiveStack;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUnoBuzzer(handCount, isHumanTurn),
        if (showPass) ...[
          const SizedBox(width: 20),
          _buildPassButton(),
        ],
      ],
    );
  }

  Widget _buildPassButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(gameStateProvider.notifier).passTurn();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Text(
          'PASS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    ).animate().fadeIn().scale();
  }

  Widget _buildUnoBuzzer(int handCount, bool isHumanTurn) {
    final unoDeclared = (ref.read(gameStateProvider).unoDeclaredPlayers).contains('player1');
    final canDeclare = handCount == 1 && isHumanTurn && !unoDeclared;
    
    return GestureDetector(
      onTap: canDeclare
          ? () {
              HapticFeedback.heavyImpact();
              ref.read(gameStateProvider.notifier).declareUno('player1');
            }
          : null,
      child: AnimatedBuilder(
        animation: _unoGlowCtrl,
        builder: (_, __) {
          final glowFactor = canDeclare ? _unoGlowCtrl.value : 0.0;
          return Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: canDeclare 
                  ? [const Color(0xFFFFD700), const Color(0xFFD4A017), const Color(0xFFB8860B)]
                  : [Colors.grey[800]!, Colors.grey[900]!],
              ),
              border: Border.all(
                color: canDeclare ? Colors.white : Colors.white12,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (canDeclare ? const Color(0xFFFFD700) : Colors.black)
                      .withOpacity(0.3 + glowFactor * 0.4),
                  blurRadius: 10 + glowFactor * 15,
                  spreadRadius: 1 + glowFactor * 3,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'UNO',
                style: TextStyle(
                  color: canDeclare ? Colors.black87 : Colors.white24,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    ).animate(target: canDeclare ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }

  // ── Player hand – fan layout ──────────────────────────────────────────────
  Widget _buildPlayerHand(dynamic gameState, Size size) {
    final humanHand =
        List<UnoCard>.from(gameState.playerHands['player1'] ?? []);
    final topCard = gameState.topCard as UnoCard?;
    final isHumanTurn = gameState.currentPlayerId == 'player1';

    if (humanHand.isEmpty || topCard == null) return const SizedBox(height: 140);

    final cardCount = humanHand.length;
    final maxAngle = math.min(0.04 * cardCount, 0.55); // fan spread radians
    final cardWidth = 68.0;
    final cardHeight = 105.0;
    final overlap = math.min(0.55, 22.0 / cardWidth); // how much cards overlap

    return SizedBox(
      height: 155,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: List.generate(cardCount, (i) {
          final t = cardCount == 1 ? 0.5 : i / (cardCount - 1);
          final angle = (t - 0.5) * 2 * maxAngle;
          // vertical offset: cards further to edge dip down
          final yOffset = (t - 0.5).abs() * (t - 0.5).abs() * 24;
          // horizontal offset
          final spacing = math.min(cardWidth * (1 - overlap), 40.0);
          final totalW = spacing * (cardCount - 1);
          final xCenter = (size.width / 2) - (totalW / 2) + i * spacing;

          final card = humanHand[i];
          final canPlay = isHumanTurn &&
              RuleEngine.canPlayCard(
                card, 
                topCard,
                declaredColor: gameState.declaredColor,
                hasActiveStack: gameState.hasActiveStack,
                stackCardType: gameState.stackCardType,
                hand: humanHand,
              );

          return Positioned(
            left: xCenter - cardWidth / 2,
            bottom: 8 - yOffset,
            child: Transform.rotate(
              angle: angle,
              child: _InteractiveFanCard(
                card: card,
                isPlayable: canPlay,
                isHumanTurn: isHumanTurn,
                width: cardWidth,
                height: cardHeight,
                onTap: canPlay ? () => _playCard(card) : null,
              ),
            ).animate(delay: (i * 40).ms).fadeIn(duration: 250.ms).slideY(
                begin: 0.4,
                end: 0,
                duration: 350.ms,
                curve: Curves.easeOutCubic),
          );
        }),
      ),
    );
  }

  // ── Bottom: your avatar + UNO button ─────────────────────────────────────
  Widget _buildBottomBar(dynamic gameState, Size size) {
    return const SizedBox(height: 20);
  }

  // ── Victory overlay ───────────────────────────────────────────────────────
  Widget _buildVictoryOverlay(dynamic gameState) {
    final winnerId = gameState.winnerId as String?;
    final isPlayerWin = winnerId == 'player1';
    final winnerName = isPlayerWin ? 'You' : 'AI Opponent';
    final humanCards = (gameState.playerHands['player1'] as List<UnoCard>? ?? []).length;
    final aiCards = (gameState.playerHands['ai1'] as List<UnoCard>? ?? []).length;

    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A).withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFB8860B).withOpacity(0.7),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti particles
              SizedBox(
                height: 30,
                child: CustomPaint(
                  size: const Size(double.infinity, 30),
                  painter: _ConfettiPainter(),
                ),
              ),
              // VICTORY text
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFE066), Color(0xFFFFD700), Color(0xFFB8860B)],
                ).createShader(b),
                child: Text(
                  isPlayerWin ? 'VICTORY!' : 'DEFEAT',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              )
                  .animate()
                  .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              // Winner avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9E9E9E), Color(0xFF616161)],
                  ),
                  border: Border.all(
                      color: const Color(0xFFFFD700), width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.5),
                        blurRadius: 20)
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 6),
              Text(
                winnerName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              // Scoreboard
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _scoreRow('Players', 'Cards', 'Pts', isHeader: true),
                    _scoreRow('You', humanCards.toString(),
                        (humanCards * 4).toString()),
                    _scoreRow('AI Opponent', aiCards.toString(),
                        (aiCards * 4).toString()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Play Again
              GestureDetector(
                onTap: () {
                  final players = [
                    Player.human(id: 'player1', name: 'You'),
                    Player.ai(id: 'ai1', name: 'AI Opponent'),
                  ];
                  ref.read(gameStateProvider.notifier).initializeGame(players);
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4A017), Color(0xFFFFD700), Color(0xFFB8860B)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('PLAY AGAIN',
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Text('BACK TO MENU',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms);
  }

  Widget _scoreRow(String player, String cards, String pts,
      {bool isHeader = false}) {
    final style = TextStyle(
      color: isHeader
          ? Colors.white54
          : Colors.white,
      fontSize: isHeader ? 11 : 14,
      fontWeight: isHeader ? FontWeight.w500 : FontWeight.w600,
      letterSpacing: isHeader ? 1.2 : 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!isHeader)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.person_outline, color: Colors.white38, size: 18),
            ),
          Expanded(child: Text(player, style: style)),
          SizedBox(
              width: 50,
              child: Text(cards,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                      color: isHeader ? Colors.white38 : Colors.white70))),
          SizedBox(
              width: 40,
              child: Text(pts,
                  textAlign: TextAlign.end,
                  style: style.copyWith(
                      color: isHeader
                          ? Colors.white38
                          : const Color(0xFFFFD700)))),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _playCard(UnoCard card) {
    if (card.isWildCard) {
      _showColorPicker(card);
    } else {
      HapticFeedback.mediumImpact();
      ref.read(gameStateProvider.notifier).playCard(card);
    }
  }

  void _showColorPicker(UnoCard card) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Choose Color',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _colorDot(UnoCardColor.red, card, const Color(0xFFE53935)),
            _colorDot(UnoCardColor.blue, card, const Color(0xFF1E88E5)),
            _colorDot(UnoCardColor.green, card, const Color(0xFF43A047)),
            _colorDot(UnoCardColor.yellow, card, const Color(0xFFFDD835)),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(UnoCardColor color, UnoCard card, Color display) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        HapticFeedback.mediumImpact();
        ref
            .read(gameStateProvider.notifier)
            .playCard(card, declaredColor: color);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: display,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: display.withOpacity(0.55),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
      ),
    );
  }

  Color _cardGlowColor(UnoCard card) {
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
        return Colors.purple;
    }
  }

  Widget _buildFancyCard(UnoCard card,
      {double width = 80, double height = 120, bool playable = true}) {
    return UnoCardWidget(
      card: card,
      width: width,
      height: height,
      isPlayable: playable,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
/// Draw pile card (face-down stack with stacked shadow illusion)
class _DrawPileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 135,
      child: Stack(
        children: [
          // Shadow cards behind
          for (int i = 3; i >= 1; i--)
            Positioned(
              left: i * 1.5,
              top: i * 1.0,
              child: Container(
                width: 90,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D2910),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          // Top card (face-down)
          _buildFaceDown(),
        ],
      ),
    );
  }

  Widget _buildFaceDown() {
    return Container(
      width: 90,
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A3A1E),
            Color(0xFF0F2212),
          ],
        ),
        border: Border.all(color: Colors.white24, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFF1B4020),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: const Center(
            child: Text(
              'UNO',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
/// Fan card with lift-on-tap behaviour
class _InteractiveFanCard extends StatefulWidget {
  final UnoCard card;
  final bool isPlayable;
  final bool isHumanTurn;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const _InteractiveFanCard({
    required this.card,
    required this.isPlayable,
    required this.isHumanTurn,
    this.onTap,
    this.width = 68,
    this.height = 105,
  });

  @override
  State<_InteractiveFanCard> createState() => _InteractiveFanCardState();
}

class _InteractiveFanCardState extends State<_InteractiveFanCard> {
  bool _lifted = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.isPlayable) setState(() => _lifted = true);
      },
      onTapUp: (_) {
        setState(() => _lifted = false);
        if (widget.isPlayable) {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        }
      },
      onTapCancel: () => setState(() => _lifted = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.translationValues(
          0,
          _lifted ? -22 : (widget.isPlayable ? -6 : 0),
          0,
        ),
        child: Stack(
          children: [
            UnoCardWidget(
              card: widget.card,
              isPlayable: widget.isPlayable,
              width: widget.width,
              height: widget.height,
            ),
            // Playable highlight overlay
            if (widget.isPlayable)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
/// Simple confetti painter for victory screen
class _ConfettiPainter extends CustomPainter {
  static final _rng = math.Random(99);
  static final _colors = [
    Colors.yellow,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange
  ];
  static final _confetti = List.generate(
    40,
    (i) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < _confetti.length; i++) {
      paint.color = _colors[i % _colors.length].withOpacity(0.8);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(
              _confetti[i].dx * size.width, _confetti[i].dy * size.height),
          width: 6,
          height: 6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
