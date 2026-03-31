import 'dart:math';
import '../../core/models/card_model.dart';
import '../../core/services/rule_engine.dart';

/// Smart AI player for UNO game
/// 
/// Implements intelligent card selection strategy:
/// - Prioritizes action cards strategically
/// - Manages wild cards efficiently
/// - Considers card count optimization
/// - Makes defensive plays when needed
class AIPlayer {
  final Random _random = Random();
  final String playerId;
  final AIDifficulty difficulty;

  AIPlayer({
    required this.playerId,
    this.difficulty = AIDifficulty.medium,
  });

  /// Decides which card to play from hand
  /// 
  /// Returns null if no playable card (must draw)
  /// Uses strategy based on difficulty level
  UnoCard? selectCardToPlay(
    List<UnoCard> hand,
    UnoCard topCard, {
    UnoCardColor? declaredColor,
    bool hasActiveStack = false,
    UnoCardValue? stackCardType,
  }) {
    final playableCards = RuleEngine.getPlayableCards(
      hand,
      topCard,
      declaredColor: declaredColor,
      hasActiveStack: hasActiveStack,
      stackCardType: stackCardType,
    );

    if (playableCards.isEmpty) return null;

    switch (difficulty) {
      case AIDifficulty.easy:
        return _selectCardEasy(playableCards);
      case AIDifficulty.medium:
        return _selectCardMedium(playableCards, hand);
      case AIDifficulty.hard:
        return _selectCardHard(playableCards, hand, topCard);
    }
  }

  /// Easy AI: Random selection
  UnoCard _selectCardEasy(List<UnoCard> playableCards) {
    return playableCards[_random.nextInt(playableCards.length)];
  }

  /// Medium AI: Basic strategy
  /// 
  /// Priority:
  /// 1. Play action cards (Skip, Reverse, Draw Two)
  /// 2. Play number cards matching color
  /// 3. Play wild cards as last resort
  UnoCard _selectCardMedium(List<UnoCard> playableCards, List<UnoCard> hand) {
    // Prioritize action cards
    final actionCards = playableCards.where((card) => card.isActionCard).toList();
    if (actionCards.isNotEmpty) {
      return actionCards[_random.nextInt(actionCards.length)];
    }

    // Play number cards before wild cards
    final numberCards = playableCards.where((card) => !card.isWildCard).toList();
    if (numberCards.isNotEmpty) {
      return numberCards[_random.nextInt(numberCards.length)];
    }

    // Last resort: wild cards
    return playableCards[_random.nextInt(playableCards.length)];
  }

  /// Hard AI: Advanced strategy
  /// 
  /// Considers:
  /// - Card count optimization
  /// - Color distribution in hand
  /// - Strategic wild card usage
  /// - Defensive plays
  UnoCard _selectCardHard(
    List<UnoCard> playableCards,
    List<UnoCard> hand,
    UnoCard topCard,
  ) {
    // If only one card left, play it if possible
    if (hand.length == 1 && playableCards.isNotEmpty) {
      return playableCards.first;
    }

    // Calculate color distribution in hand
    final colorCounts = _calculateColorDistribution(hand);
    final dominantColor = _getDominantColor(colorCounts);

    // Strategy 1: Save wild cards for critical moments
    if (hand.length > 3) {
      final nonWildCards = playableCards.where((card) => !card.isWildCard).toList();
      if (nonWildCards.isNotEmpty) {
        // Prefer playing cards of non-dominant colors to reduce hand diversity
        final nonDominantCards = nonWildCards
            .where((card) => card.color != dominantColor)
            .toList();
        
        if (nonDominantCards.isNotEmpty) {
          // Prioritize action cards
          final actionCards = nonDominantCards.where((card) => card.isActionCard).toList();
          if (actionCards.isNotEmpty) {
            return actionCards[_random.nextInt(actionCards.length)];
          }
          return nonDominantCards[_random.nextInt(nonDominantCards.length)];
        }

        return nonWildCards[_random.nextInt(nonWildCards.length)];
      }
    }

    // Strategy 2: Use Draw Four strategically (when hand is large)
    if (hand.length > 5) {
      final drawFourCards = playableCards
          .where((card) => card.value == UnoCardValue.wildDrawFour)
          .toList();
      if (drawFourCards.isNotEmpty) {
        return drawFourCards.first;
      }
    }

    // Strategy 3: Play action cards to disrupt opponent
    final actionCards = playableCards.where((card) => card.isActionCard).toList();
    if (actionCards.isNotEmpty) {
      // Prefer Draw Two over Skip/Reverse
      final drawTwoCards = actionCards
          .where((card) => card.value == UnoCardValue.drawTwo)
          .toList();
      if (drawTwoCards.isNotEmpty) {
        return drawTwoCards.first;
      }
      return actionCards[_random.nextInt(actionCards.length)];
    }

    // Strategy 4: Play cards matching dominant color
    final dominantColorCards = playableCards
        .where((card) => card.color == dominantColor && !card.isWildCard)
        .toList();
    if (dominantColorCards.isNotEmpty) {
      return dominantColorCards[_random.nextInt(dominantColorCards.length)];
    }

    // Default: Play any available card
    return playableCards[_random.nextInt(playableCards.length)];
  }

  /// Selects color to declare for wild cards
  /// 
  /// Chooses the color with most cards in hand
  UnoCardColor selectColorForWildCard(List<UnoCard> hand) {
    final colorCounts = _calculateColorDistribution(hand);
    return _getDominantColor(colorCounts);
  }

  /// Calculates distribution of colors in hand
  Map<UnoCardColor, int> _calculateColorDistribution(List<UnoCard> hand) {
    final counts = <UnoCardColor, int>{
      UnoCardColor.red: 0,
      UnoCardColor.blue: 0,
      UnoCardColor.green: 0,
      UnoCardColor.yellow: 0,
    };

    for (final card in hand) {
      if (card.color != UnoCardColor.wild) {
        counts[card.color] = (counts[card.color] ?? 0) + 1;
      }
    }

    return counts;
  }

  /// Gets the color with most cards
  UnoCardColor _getDominantColor(Map<UnoCardColor, int> colorCounts) {
    UnoCardColor dominantColor = UnoCardColor.red;
    int maxCount = 0;

    colorCounts.forEach((color, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantColor = color;
      }
    });

    // If no dominant color, choose randomly
    if (maxCount == 0) {
      final colors = [
        UnoCardColor.red,
        UnoCardColor.blue,
        UnoCardColor.green,
        UnoCardColor.yellow,
      ];
      return colors[_random.nextInt(colors.length)];
    }

    return dominantColor;
  }

  /// Decides whether to challenge a Wild Draw Four
  /// 
  /// Returns true if AI wants to challenge
  bool shouldChallengeWildDrawFour(List<UnoCard> hand) {
    // Hard AI challenges more strategically
    if (difficulty == AIDifficulty.hard) {
      // Challenge if hand is small (less to lose)
      return hand.length <= 3 && _random.nextDouble() > 0.5;
    }

    // Medium AI challenges occasionally
    if (difficulty == AIDifficulty.medium) {
      return _random.nextDouble() > 0.7;
    }

    // Easy AI rarely challenges
    return _random.nextDouble() > 0.9;
  }

  /// Calculates delay for AI move (for realistic timing)
  /// 
  /// Returns delay in milliseconds
  int getMoveDelay() {
    switch (difficulty) {
      case AIDifficulty.easy:
        return 1000 + _random.nextInt(1000); // 1-2 seconds
      case AIDifficulty.medium:
        return 1500 + _random.nextInt(1000); // 1.5-2.5 seconds
      case AIDifficulty.hard:
        return 2000 + _random.nextInt(1500); // 2-3.5 seconds (thinking time)
    }
  }
}

/// AI difficulty levels
enum AIDifficulty {
  easy,
  medium,
  hard,
}
