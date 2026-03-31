import '../models/card_model.dart';

/// Manages all UNO game rules and logic
/// 
/// This class encapsulates the game rules making it easy to modify
/// or extend game mechanics in the future
class RuleEngine {
  /// Validates if a card can be played on the current top card
  /// 
  /// [cardToPlay] The card the player wants to play
  /// [topCard] The current card on top of the discard pile
  /// [declaredColor] The color declared for wild cards (if applicable)
  /// [hasActiveStack] Whether there is an active +2 or +4 stack
  /// [stackCardType] The type of card generating the stack (+2 or +4)
  /// [hand] The player's hand (used to check +4 legality)
  /// 
  /// Returns true if the move is valid
  static bool canPlayCard(
    UnoCard cardToPlay,
    UnoCard topCard, {
    UnoCardColor? declaredColor,
    bool hasActiveStack = false,
    UnoCardValue? stackCardType,
    List<UnoCard>? hand,
  }) {
    // 1. Handle Active Stacks
    if (hasActiveStack && stackCardType != null) {
      if (stackCardType == UnoCardValue.drawTwo) {
        // Can stack +2 on +2, or +4 on +2
        return cardToPlay.value == UnoCardValue.drawTwo || 
               cardToPlay.value == UnoCardValue.wildDrawFour;
      } else if (stackCardType == UnoCardValue.wildDrawFour) {
        // Can only stack +4 on +4
        return cardToPlay.value == UnoCardValue.wildDrawFour;
      }
      return false;
    }

    // 3. Normal Play
    // Wild cards can always be played
    if (cardToPlay.isWildCard) return true;

    // If top card is wild, check against declared color
    if (topCard.isWildCard && declaredColor != null) {
      return cardToPlay.color == declaredColor;
    }

    // Standard rule: match color or value
    return cardToPlay.canPlayOn(topCard);
  }

  /// Calculates how many cards to draw based on the played card
  /// 
  /// Returns the number of cards to draw (0 if no draw action)
  static int getDrawCount(UnoCard card) {
    if (card.value == UnoCardValue.drawTwo) return 2;
    if (card.value == UnoCardValue.wildDrawFour) return 4;
    return 0;
  }

  /// Determines if the turn should be skipped
  static bool shouldSkipTurn(UnoCard card) {
    return card.value == UnoCardValue.skip;
  }

  /// Determines if the turn order should be reversed
  static bool shouldReverseTurn(UnoCard card) {
    return card.value == UnoCardValue.reverse;
  }

  /// Checks if a player needs to declare a color (for wild cards)
  static bool needsColorDeclaration(UnoCard card) {
    return card.isWildCard;
  }

  /// Validates if a player can declare UNO (when they have 1 card left)
  /// 
  /// [remainingCards] Number of cards in player's hand
  static bool canDeclareUno(int remainingCards) {
    return remainingCards == 1;
  }

  /// Checks if a player has won the game
  static bool hasPlayerWon(int remainingCards) {
    return remainingCards == 0;
  }

  /// Calculates penalty for not declaring UNO
  /// 
  /// Returns the number of cards to draw as penalty
  static int getUnoPenalty() {
    return 1;
  }

  /// Checks if a player has any playable cards
  /// 
  /// [hand] Player's current hand
  /// [topCard] Current top card on discard pile
  /// [declaredColor] Color declared for wild cards
  static bool hasPlayableCard(
    List<UnoCard> hand,
    UnoCard topCard, {
    UnoCardColor? declaredColor,
    bool hasActiveStack = false,
    UnoCardValue? stackCardType,
  }) {
    return hand.any((card) => canPlayCard(
      card, topCard, 
      declaredColor: declaredColor, 
      hasActiveStack: hasActiveStack, 
      stackCardType: stackCardType,
      hand: hand,
    ));
  }

  /// Gets all playable cards from a hand
  static List<UnoCard> getPlayableCards(
    List<UnoCard> hand,
    UnoCard topCard, {
    UnoCardColor? declaredColor,
    bool hasActiveStack = false,
    UnoCardValue? stackCardType,
  }) {
    return hand
        .where((card) => canPlayCard(
          card, topCard, 
          declaredColor: declaredColor,
          hasActiveStack: hasActiveStack,
          stackCardType: stackCardType,
          hand: hand,
        ))
        .toList();
  }

  /// Calculates points for a card (used in scoring)
  static int getCardPoints(UnoCard card) {
    switch (card.value) {
      case UnoCardValue.zero:
        return 0;
      case UnoCardValue.one:
        return 1;
      case UnoCardValue.two:
        return 2;
      case UnoCardValue.three:
        return 3;
      case UnoCardValue.four:
        return 4;
      case UnoCardValue.five:
        return 5;
      case UnoCardValue.six:
        return 6;
      case UnoCardValue.seven:
        return 7;
      case UnoCardValue.eight:
        return 8;
      case UnoCardValue.nine:
        return 9;
      case UnoCardValue.skip:
      case UnoCardValue.reverse:
      case UnoCardValue.drawTwo:
        return 20;
      case UnoCardValue.wild:
      case UnoCardValue.wildDrawFour:
        return 50;
    }
  }

  /// Calculates total points in a hand
  static int calculateHandPoints(List<UnoCard> hand) {
    return hand.fold(0, (sum, card) => sum + getCardPoints(card));
  }
}
