import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_state_provider.dart';
import '../widgets/game_table.dart';
import '../widgets/uno_card_widget.dart';
import '../widgets/uno_card_back.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player_model.dart';
import '../../../core/services/rule_engine.dart';
import '../../../core/services/audio_service.dart';

/// Main game screen – premium UNO Luxe design matching the reference
class GameScreen extends ConsumerStatefulWidget {
  final int aiCount;
  const GameScreen({super.key, this.aiCount = 1});
  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _unoGlowCtrl;
  bool _unoDeclared = false;
  
  // Power Indicator state
  bool _showPowerIndicator = false;
  String _powerSymbol = '';
  String _powerLabel = '';
  
  // Animation Keys
  final GlobalKey _drawPileKey = GlobalKey();
  final GlobalKey _discardPileKey = GlobalKey();
  final GlobalKey _playerHandKey = GlobalKey();
  final Map<String, GlobalKey> _aiHandKeys = {
    'ai1': GlobalKey(),
    'ai2': GlobalKey(),
    'ai3': GlobalKey(),
  };

  // Active flying cards
  final List<_FlyingCardData> _flyingCards = [];

  @override
  void initState() {
    super.initState();
    _unoGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final List<Player> players = [
        Player.human(id: 'player1', name: 'You'),
      ];
      for (int i = 1; i <= widget.aiCount; i++) {
        players.add(Player.ai(id: 'ai$i', name: 'AI $i'));
      }
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

    // ── AI Animation Listeners ──────────────────────────────────────────────
    ref.listen(gameStateProvider, (previous, next) {
      if (previous == null) return;
      
      // Detect Power Card Play
      final prevTop = previous.topCard;
      final nextTop = next.topCard;
      
      if (nextTop != null && (prevTop == null || nextTop != prevTop)) {
        if (nextTop.value != UnoCardValue.zero && 
            nextTop.value != UnoCardValue.one &&
            nextTop.value != UnoCardValue.two &&
            nextTop.value != UnoCardValue.three &&
            nextTop.value != UnoCardValue.four &&
            nextTop.value != UnoCardValue.five &&
            nextTop.value != UnoCardValue.six &&
            nextTop.value != UnoCardValue.seven &&
            nextTop.value != UnoCardValue.eight &&
            nextTop.value != UnoCardValue.nine) {
          
          setState(() {
            _powerSymbol = _getSymbolText(nextTop.value);
            _powerLabel = _getLabelText(nextTop.value, next.isClockwise);
            _showPowerIndicator = true;
          });
          
          Future.delayed(const Duration(milliseconds: 1600), () {
            if (mounted) setState(() => _showPowerIndicator = false);
          });
        }
      }

      // Detect AI moves for all AIs
      for (int i = 1; i <= widget.aiCount; i++) {
        final aiId = 'ai$i';
        final prevAiHand = (previous.playerHands[aiId] ?? []).length;
        final nextAiHand = (next.playerHands[aiId] ?? []).length;
        
        if (nextAiHand < prevAiHand && previous.currentPlayerId == aiId) {
          _triggerPlayAnimation(next.topCard, playerId: aiId);
        }
        
        if (nextAiHand > prevAiHand && next.currentPlayerId == aiId) {
          _triggerDrawAnimation(playerId: aiId);
        }
      }
    });

    final scale = gameState.playerIds.length > 2 ? 0.82 : 1.0;

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
                    Expanded(
                      child: Stack(
                        children: [
                          // Center table logic
                          Center(child: _buildCenterArea(gameState, size, scale)),
                          
                          // AI Players positioning
                          ..._buildAIPositions(gameState, size, scale),
                        ],
                      ),
                    ),
                    _buildPlayerHand(gameState, size, scale),
                    _buildBottomBar(gameState, size),
                  ],
                ),
                // Victory overlay
                if (gameState.status == GameStatus.finished)
                  _buildVictoryOverlay(gameState),
                
                // ── Animation Layer ──────────────────────────────────────────
                ..._flyingCards.map((data) => _buildFlyingCard(data)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top settings / coins bar ──────────────────────────────────────────────
  Widget _buildTopBar(dynamic gameState, Size size) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(height: 26),
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

  List<Widget> _buildAIPositions(dynamic gameState, Size size, double scale) {
    final List<Widget> positions = [];
    final aiIds = gameState.playerIds.where((id) => id.startsWith('ai')).toList();
    
    if (aiIds.isEmpty) return positions;

    // Determine positions based on player count
    if (aiIds.length == 1) {
      // 1 AI: Top Center
      positions.add(
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: _buildAiPlayerUI(aiIds[0], gameState, size, scale),
        )
      );
    } else if (aiIds.length == 2) {
      // 2 AIs: Top Left and Top Right
      positions.add(
        Positioned(
          top: 10,
          left: 20,
          child: _buildAiPlayerUI(aiIds[0], gameState, size, scale * 0.9, isSide: true),
        )
      );
      positions.add(
        Positioned(
          top: 10,
          right: 20,
          child: _buildAiPlayerUI(aiIds[1], gameState, size, scale * 0.9, isSide: true),
        )
      );
    } else if (aiIds.length == 3) {
      // 3 AIs: Left, Top, Right
      positions.add(
        Positioned(
          top: size.height * 0.2,
          left: 10,
          child: _buildAiPlayerUI(aiIds[0], gameState, size, scale * 0.85, isVertical: true),
        )
      );
      positions.add(
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: _buildAiPlayerUI(aiIds[1], gameState, size, scale * 0.85),
        )
      );
      positions.add(
        Positioned(
          top: size.height * 0.2,
          right: 10,
          child: _buildAiPlayerUI(aiIds[2], gameState, size, scale * 0.85, isVertical: true),
        )
      );
    }

    return positions;
  }

  Widget _buildAiPlayerUI(String aiId, dynamic gameState, Size size, double scale, {bool isSide = false, bool isVertical = false}) {
    final aiHand = gameState.playerHands[aiId] as List<UnoCard>?;
    final isActive = gameState.currentPlayerId == aiId;
    final cardCount = aiHand?.length ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPlayerAvatar(
          name: 'AI ${aiId.substring(2)}',
          cardCount: cardCount,
          isActive: isActive,
          isTop: true,
          scale: scale,
        ),
        const SizedBox(height: 8),
        _buildAiHand(cardCount, size, key: _aiHandKeys[aiId]!, scale: scale, isVertical: isVertical),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildPlayerAvatar({
    required String name,
    required int cardCount,
    required bool isActive,
    bool isTop = false,
    double scale = 1.0,
  }) {
    return Transform.scale(
      scale: scale,
      child: Column(
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
            child: isTop 
              ? const UnoCardBack(isSmall: true, width: 34, height: 50)
              : const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 4),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none)),
          Text('$cardCount cards',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 10, decoration: TextDecoration.none)),
        ],
      ),
    );
  }

  Widget _buildAiHand(int cardCount, Size size, {required Key key, double scale = 1.0, bool isVertical = false}) {
    if (cardCount == 0) return SizedBox(key: key);
    
    // Calculate overlap to fit breadth width
    final maxCardsInRow = 15;
    final displayCount = math.min(cardCount, maxCardsInRow);
    final cardW = 34.0 * scale;
    final cardH = 50.0 * scale;
    
    final widthLimit = isVertical ? 100.0 : size.width * 0.4;
    final spacing = math.min(cardW * 0.4, (widthLimit - cardW) / (displayCount - 1).clamp(1, displayCount));

    return SizedBox(
      key: key,
      height: isVertical ? (displayCount * spacing + cardH) : (cardH + 10),
      width: isVertical ? (cardW + 10) : (displayCount * spacing + cardW),
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(displayCount, (i) {
          final totalLen = (displayCount - 1) * spacing;
          
          return Positioned(
            left: isVertical ? 5 : (i * spacing),
            top: isVertical ? (i * spacing) : 2,
            child: UnoCardBack(
              width: cardW,
              height: cardH,
              isSmall: true,
              isRotated: !isVertical,
            ).animate(delay: (i * 20).ms).fadeIn().slideY(begin: -0.1, end: 0),
          );
        }),
      ),
    );
  }

  // ── Center area: draw pile + discard pile ─────────────────────────────────
  Widget _buildCenterArea(dynamic gameState, Size size, double scale) {
    final isHumanTurn = gameState.currentPlayerId == 'player1';
    final topCard = gameState.topCard as UnoCard?;
    final humanHandCount = (gameState.playerHands['player1'] as List<UnoCard>? ?? []).length;

    return Center(
      child: Transform.scale(
        scale: scale,
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
                          _triggerDrawAnimation(playerId: 'player1');
                          Future.delayed(const Duration(milliseconds: 300), () {
                            ref.read(gameStateProvider.notifier).drawCard();
                          });
                        }
                      : null,
                  child: AnimatedOpacity(
                    opacity: isHumanTurn ? 1.0 : 0.55,
                    duration: const Duration(milliseconds: 300),
                    child: _DrawPileCard(key: _drawPileKey),
                  ),
                ),
  
                const SizedBox(width: 36),
  
                // ── Discard pile Top card ───────────────────────────────
                if (topCard != null)
                  Stack(
                    key: _discardPileKey,
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
  
                      // ── DYNAMIC POWER INDICATOR ──
                      if (_showPowerIndicator)
                        Positioned(
                          left: -30,
                          right: -30,
                          top: -30,
                          bottom: -30,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.12),
                                  border: Border.all(color: Colors.white24, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _powerSymbol,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 54,
                                          fontWeight: FontWeight.w900,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                      Text(
                                        _powerLabel,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate(key: ValueKey(_powerSymbol))
                               .scale(begin: const Offset(0.5, 0.5), duration: 400.ms, curve: Curves.elasticOut)
                               .fadeIn()
                               .then()
                               .shake()
                               .then(delay: 800.ms)
                               .scale(begin: const Offset(1, 1), end: const Offset(0, 0), duration: 300.ms)
                               .fadeOut(),
                            ),
                          ),
                        ),
  
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
                                decoration: TextDecoration.none,
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
      ),
    );
  }

  Widget _buildActionButtons(dynamic gameState, int handCount, bool isHumanTurn) {
    bool showPass = false;
    
    if (isHumanTurn && gameState.hasDrawnThisTurn && !gameState.hasActiveStack) {
      final humanHand = List<UnoCard>.from(gameState.playerHands['player1'] ?? []);
      if (humanHand.isNotEmpty && gameState.topCard != null) {
        final lastDrawnCard = humanHand.last;
        // Only show PASS if the drawn card is playable (as a choice)
        showPass = RuleEngine.canPlayCard(
          lastDrawnCard, 
          gameState.topCard!,
          declaredColor: gameState.declaredColor,
          hasActiveStack: gameState.hasActiveStack,
          stackCardType: gameState.stackCardType,
          hand: humanHand,
        );
      }
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUnoBuzzer(handCount, isHumanTurn),
        const SizedBox(width: 20),
        // Fix jumping: Always maintain space for Pass button
        Visibility(
          visible: showPass,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _buildPassButton(),
        ),
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
            decoration: TextDecoration.none,
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
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          );
        },
      ),
    ).animate(target: canDeclare ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0));
  }

  // ── Player hand – fan layout ──────────────────────────────────────────────
  Widget _buildPlayerHand(dynamic gameState, Size size, double scale) {
    final humanHand =
        List<UnoCard>.from(gameState.playerHands['player1'] ?? []);
    final topCard = gameState.topCard as UnoCard?;
    final isHumanTurn = gameState.currentPlayerId == 'player1';

    final cardCount = humanHand.length;
    if (cardCount == 0 || topCard == null) return const SizedBox(height: 140);

    final cardWidth = 68.0 * scale;
    final cardHeight = 105.0 * scale;
    final cardsPerRow = 10;
    final numRows = (cardCount / cardsPerRow).ceil().clamp(1, 3);
    final rowOverlapY = 40.0;
    
    return SizedBox(
      key: _playerHandKey,
      height: cardHeight + (numRows - 1) * rowOverlapY + 20,
      width: size.width,
      child: Stack(
        children: List.generate(numRows, (r) {
          // Drawing in reverse order so Row 0 (front) is on top
          final rowIndex = (numRows - 1) - r;
          final startIdx = rowIndex * cardsPerRow;
          final endIdx = math.min(startIdx + cardsPerRow, cardCount);
          final rowCardsCount = endIdx - startIdx;
          
          if (rowCardsCount <= 0) return const SizedBox.shrink();

          // Calculate horizontal spacing for this row to fit screen
          final availableWidth = size.width - 32;
          final spacing = math.min(cardWidth * 0.45, (availableWidth - cardWidth) / (rowCardsCount - 1).clamp(1, rowCardsCount));
          final rowTotalWidth = (rowCardsCount - 1) * spacing + cardWidth;
          // r=0 is back-most, r=numRows-1 is front-most.
          // Front-most (rowIndex 0, r=numRows-1) should have bottom: 0.
          final rowBottomOffset = (numRows - 1 - r) * rowOverlapY; 

          return Positioned(
            bottom: rowBottomOffset,
            left: 0,
            right: 0,
            height: cardHeight + 10,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: List.generate(rowCardsCount, (i) {
                final globalIdx = startIdx + i;
                final card = humanHand[globalIdx];
                final xOffset = (i * spacing) - (rowTotalWidth / 2) + (cardWidth / 2);
                
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
                  left: size.width / 2 + xOffset - cardWidth / 2,
                  bottom: 5,
                  child: _InteractiveFanCard(
                    card: card,
                    isPlayable: canPlay,
                    isHumanTurn: isHumanTurn,
                    width: cardWidth,
                    height: cardHeight,
                    onTap: canPlay ? () => _playCard(card) : null,
                  ).animate(delay: (globalIdx * 15).ms).fadeIn(duration: 200.ms).slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 250.ms,
                      curve: Curves.easeOut),
                );
              }),
            ),
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
    final winnerName = isPlayerWin ? 'You' : (winnerId?.startsWith('ai') == true ? 'AI ${winnerId!.substring(2)}' : 'Opponent');
    final humanCards = (gameState.playerHands['player1'] as List<UnoCard>? ?? []).length;
    
    final List<Map<String, String>> playerScores = [];
    for (final id in gameState.playerIds) {
      final pCards = (gameState.playerHands[id] as List<UnoCard>? ?? []).length;
      final name = id == 'player1' ? 'You' : 'AI ${id.substring(2)}';
      playerScores.add({
        'name': name,
        'cards': pCards.toString(),
        'pts': (pCards * 10).toString(),
      });
    }

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
                    ...playerScores.map((s) => _scoreRow(s['name']!, s['cards']!, s['pts']!)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Play Again
              GestureDetector(
                onTap: () {
                  final List<Player> players = [
                    Player.human(id: 'player1', name: 'You'),
                  ];
                  for (int i = 1; i <= widget.aiCount; i++) {
                    players.add(Player.ai(id: 'ai$i', name: 'AI $i'));
                  }
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
      _triggerPlayAnimation(card, playerId: 'player1');
      // Wait for animation before state update
      Future.delayed(const Duration(milliseconds: 300), () {
        ref.read(gameStateProvider.notifier).playCard(card);
      });
    }
  }

  String _getSymbolText(UnoCardValue value) {
    switch (value) {
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
      default:
        return '';
    }
  }

  String _getLabelText(UnoCardValue value, bool isClockwise) {
    switch (value) {
      case UnoCardValue.skip:
        return 'BLOCKED';
      case UnoCardValue.reverse:
        return isClockwise ? 'NORMAL' : 'REVERSED';
      case UnoCardValue.drawTwo:
        return 'PICK +2';
      case UnoCardValue.wild:
        return 'CHOOSE COLOR';
      case UnoCardValue.wildDrawFour:
        return 'PICK +4';
      default:
        return '';
    }
  }

  void _triggerPlayAnimation(UnoCard? card, {required String playerId}) {
    final isAI = playerId.startsWith('ai');
    final startKey = isAI ? _aiHandKeys[playerId]! : _playerHandKey;
    final start = _getCenterOf(startKey);
    final end = _getCenterOf(_discardPileKey);
    
    // Play card/special sound
    AudioService.instance.playCardSound(card);
    _addFlyingCard(card, start, end, isBack: isAI);
  }

  void _triggerDrawAnimation({required String playerId}) {
    final isAI = playerId.startsWith('ai');
    final start = _getCenterOf(_drawPileKey);
    final endKey = isAI ? _aiHandKeys[playerId]! : _playerHandKey;
    final end = _getCenterOf(endKey);
    
    // Play draw sound
    AudioService.instance.playDrawSound();
    _addFlyingCard(null, start, end, isBack: true);
  }

  Offset _getCenterOf(GlobalKey key) {
    final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return Offset.zero;
    final pos = box.localToGlobal(Offset.zero);
    return Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
  }

  void _addFlyingCard(UnoCard? card, Offset start, Offset end, {bool isBack = false}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _flyingCards.add(_FlyingCardData(
        id: id,
        card: card,
        start: start,
        end: end,
        isBack: isBack,
      ));
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _flyingCards.removeWhere((c) => c.id == id);
        });
      }
    });
  }

  Widget _buildFlyingCard(_FlyingCardData data) {
    const cardW = 68.0;
    const cardH = 105.0;
    
    return Positioned(
      left: 0,
      top: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          final x = data.start.dx + (data.end.dx - data.start.dx) * value;
          final y = data.start.dy + (data.end.dy - data.start.dy) * value;
          final scale = 1.0 + math.sin(value * math.pi) * 0.2;
          final rotation = value * math.pi * 0.1;

          return Transform.translate(
            offset: Offset(x - cardW / 2, y - cardH / 2),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: rotation,
                child: Opacity(
                  opacity: value < 0.1 ? value * 10 : (value > 0.9 ? (1 - value) * 10 : 1.0),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: data.isBack || data.card == null
            ? const UnoCardBack(width: cardW, height: cardH)
            : _buildFancyCard(data.card!, width: cardW, height: cardH, playable: false),
      ),
    );
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

class _FlyingCardData {
  final String id;
  final UnoCard? card;
  final Offset start;
  final Offset end;
  final bool isBack;

  _FlyingCardData({
    required this.id,
    this.card,
    required this.start,
    required this.end,
    this.isBack = false,
  });
}

class _DrawPileCard extends StatelessWidget {
  const _DrawPileCard({super.key});

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
