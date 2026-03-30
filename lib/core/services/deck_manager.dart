import 'dart:math';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';

/// Manages the UNO deck generation and shuffling
/// 
/// This class is responsible for creating a standard 108-card UNO deck
/// and providing shuffling functionality using the Fisher-Yates algorithm
class DeckManager {
  static const _uuid = Uuid();
  final Random _random = Random();

  /// Generates a complete UNO deck with 108 cards
  /// 
  /// Deck composition:
  /// - 19 cards of each color (0-9, with 0 appearing once and 1-9 twice)
  /// - 2 Skip cards per color (8 total)
  /// - 2 Reverse cards per color (8 total)
  /// - 2 Draw Two cards per color (8 total)
  /// - 4 Wild cards
  /// - 4 Wild Draw Four cards
  /// 
  /// Total: 108 cards
  List<UnoCard> generateDeck() {
    final List<UnoCard> deck = [];

    // Generate colored cards (Red, Blue, Green, Yellow)
    for (final color in [
      UnoCardColor.red,
      UnoCardColor.blue,
      UnoCardColor.green,
      UnoCardColor.yellow,
    ]) {
      // Add one 0 card per color
      deck.add(UnoCard(
        color: color,
        value: UnoCardValue.zero,
        id: _uuid.v4(),
      ));

      // Add two of each number card (1-9) per color
      for (final value in [
        UnoCardValue.one,
        UnoCardValue.two,
        UnoCardValue.three,
        UnoCardValue.four,
        UnoCardValue.five,
        UnoCardValue.six,
        UnoCardValue.seven,
        UnoCardValue.eight,
        UnoCardValue.nine,
      ]) {
        for (int i = 0; i < 2; i++) {
          deck.add(UnoCard(
            color: color,
            value: value,
            id: _uuid.v4(),
          ));
        }
      }

      // Add two of each action card per color
      for (final value in [
        UnoCardValue.skip,
        UnoCardValue.reverse,
        UnoCardValue.drawTwo,
      ]) {
        for (int i = 0; i < 2; i++) {
          deck.add(UnoCard(
            color: color,
            value: value,
            id: _uuid.v4(),
          ));
        }
      }
    }

    // Add 4 Wild cards
    for (int i = 0; i < 4; i++) {
      deck.add(UnoCard(
        color: UnoCardColor.wild,
        value: UnoCardValue.wild,
        id: _uuid.v4(),
      ));
    }

    // Add 4 Wild Draw Four cards
    for (int i = 0; i < 4; i++) {
      deck.add(UnoCard(
        color: UnoCardColor.wild,
        value: UnoCardValue.wildDrawFour,
        id: _uuid.v4(),
      ));
    }

    return deck;
  }

  /// Shuffles the deck using the Fisher-Yates algorithm
  /// 
  /// This algorithm ensures a truly random distribution of cards
  /// with O(n) time complexity and O(1) space complexity
  /// 
  /// [deck] The deck to shuffle (modified in place)
  void shuffle(List<UnoCard> deck) {
    for (int i = deck.length - 1; i > 0; i--) {
      final int j = _random.nextInt(i + 1);
      final UnoCard temp = deck[i];
      deck[i] = deck[j];
      deck[j] = temp;
    }
  }

  /// Creates and returns a shuffled deck ready for play
  List<UnoCard> getShuffledDeck() {
    final deck = generateDeck();
    shuffle(deck);
    return deck;
  }
}
