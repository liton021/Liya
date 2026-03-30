import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../providers/game_state_provider.dart';
import '../widgets/uno_card_widget.dart';
import '../../../core/models/card_model.dart';
import '../../../core/services/rule_engine.dart';

/// Main game screen with premium Apple-inspired design
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize game with 2 players for now
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).initializeGame(['player1', 'player2']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16213E),
              const Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top player area
              _buildOpponentArea(gameState),

              // Center play area
              Expanded(
                child: _buildPlayArea(gameState),
              ),

              // Current player's hand
              _buildPlayerHand(gameState),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the opponent's card area with glassmorphism
  Widget _buildOpponentArea(gameState) {
    final opponentId = gameState.playerIds.length > 1 ? gameState.playerIds[1] : null;
    final opponentHand = opponentId != null ? gameState.playerHands[opponentId] : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, color: Colors.white70, size: 32),
            const SizedBox(width: 12),
            Text(
              'Opponent: ${opponentHand?.length ?? 0} cards',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the center play area with discard pile and draw pile
  Widget _buildPlayArea(gameState) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Draw pile
          GestureDetector(
            onTap: () {
              ref.read(gameStateProvider.notifier).drawCard();
            },
            child: Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C54),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.style,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          ),

          const SizedBox(width: 40),

          // Discard pile (top card)
          if (gameState.topCard != null)
            UnoCardWidget(
              card: gameState.topCard!,
              width: 100,
              height: 150,
              isPlayable: false,
            ),
        ],
      ),
    );
  }

  /// Builds the current player's hand at the bottom
  Widget _buildPlayerHand(gameState) {
    final currentHand = gameState.currentPlayerHand;
    final topCard = gameState.topCard;

    if (currentHand.isEmpty || topCard == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: currentHand.length,
        itemBuilder: (context, index) {
          final card = currentHand[index];
          final isPlayable = RuleEngine.canPlayCard(
            card,
            topCard,
            declaredColor: gameState.declaredColor,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: UnoCardWidget(
              card: card,
              isPlayable: isPlayable,
              onTap: isPlayable
                  ? () => _playCard(card)
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// Handles playing a card
  void _playCard(UnoCard card) {
    if (card.isWildCard) {
      _showColorPicker(card);
    } else {
      ref.read(gameStateProvider.notifier).playCard(card);
    }
  }

  /// Shows color picker dialog for wild cards
  void _showColorPicker(UnoCard card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Choose a color',
          style: TextStyle(color: Colors.white),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColorButton(UnoCardColor.red, card),
            _buildColorButton(UnoCardColor.blue, card),
            _buildColorButton(UnoCardColor.green, card),
            _buildColorButton(UnoCardColor.yellow, card),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(UnoCardColor color, UnoCard card) {
    Color displayColor;
    switch (color) {
      case UnoCardColor.red:
        displayColor = const Color(0xFFE53935);
        break;
      case UnoCardColor.blue:
        displayColor = const Color(0xFF1E88E5);
        break;
      case UnoCardColor.green:
        displayColor = const Color(0xFF43A047);
        break;
      case UnoCardColor.yellow:
        displayColor = const Color(0xFFFDD835);
        break;
      default:
        displayColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        ref.read(gameStateProvider.notifier).playCard(card, declaredColor: color);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}
