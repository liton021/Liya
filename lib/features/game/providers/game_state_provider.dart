import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player_model.dart';
import '../../../core/services/deck_manager.dart';
import '../../../core/services/rule_engine.dart';
import '../../../core/services/ai_player.dart';

/// Provider for the game state
/// 
/// This is the central state management for the entire game
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState>((ref) {
  return GameStateNotifier();
});

/// Manages the game state and all game logic
class GameStateNotifier extends StateNotifier<GameState> {
  GameStateNotifier() : super(GameState.initial());

  final DeckManager _deckManager = DeckManager();
  final Map<String, AIPlayer> _aiPlayers = {};
  final Map<String, Player> _players = {};

  /// Initializes a new game with the specified players
  /// 
  /// [players] List of Player objects (can be human or AI)
  void initializeGame(List<Player> players) {
    if (players.length < 2 || players.length > 4) {
      throw ArgumentError('Game requires 2-4 players');
    }

    // Store players and create AI instances
    _players.clear();
    _aiPlayers.clear();
    
    for (final player in players) {
      _players[player.id] = player;
      if (player.isAI) {
        _aiPlayers[player.id] = AIPlayer(
          playerId: player.id,
          difficulty: AIDifficulty.medium,
        );
      }
    }

    final playerIds = players.map((p) => p.id).toList();

    // Generate and shuffle deck
    final deck = _deckManager.getShuffledDeck();

    // Deal 7 cards to each player
    final Map<String, List<UnoCard>> hands = {};
    int cardIndex = 0;

    for (final playerId in playerIds) {
      hands[playerId] = deck.sublist(cardIndex, cardIndex + 7);
      cardIndex += 7;
    }

    // Place first card on discard pile (ensure it's not a wild card)
    final discardPile = <UnoCard>[];
    while (cardIndex < deck.length) {
      final card = deck[cardIndex];
      if (!card.isWildCard) {
        discardPile.add(card);
        cardIndex++;
        break;
      }
      cardIndex++;
    }

    // Remaining cards go to draw pile
    final drawPile = deck.sublist(cardIndex);

    state = GameState(
      drawPile: drawPile,
      discardPile: discardPile,
      playerHands: hands,
      playerIds: playerIds,
      currentPlayerIndex: 0,
      status: GameStatus.playing,
    );

    // If first player is AI, trigger AI move
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAndTriggerAIMove();
    });
  }

  /// Plays a card from the current player's hand
  /// 
  /// [card] The card to play
  /// [declaredColor] Color to declare (required for wild cards)
  void playCard(UnoCard card, {UnoCardColor? declaredColor}) {
    final currentHand = List<UnoCard>.from(state.currentPlayerHand);
    
    if (!currentHand.contains(card)) return;
    if (state.topCard == null) return;

    // Validate move
    if (!RuleEngine.canPlayCard(card, state.topCard!, declaredColor: state.declaredColor)) {
      return;
    }

    // Remove card from hand
    currentHand.remove(card);

    // Update player's hand
    final updatedHands = Map<String, List<UnoCard>>.from(state.playerHands);
    updatedHands[state.currentPlayerId] = currentHand;

    // Add card to discard pile
    final updatedDiscard = List<UnoCard>.from(state.discardPile)..add(card);

    // Check for win
    if (currentHand.isEmpty) {
      state = state.copyWith(
        playerHands: updatedHands,
        discardPile: updatedDiscard,
        status: GameStatus.finished,
        winnerId: state.currentPlayerId,
      );
      return;
    }

    // Apply card effects
    var newState = state.copyWith(
      playerHands: updatedHands,
      discardPile: updatedDiscard,
      declaredColor: declaredColor,
      clearDeclaredColor: !card.isWildCard,
    );

    // Handle reverse
    if (RuleEngine.shouldReverseTurn(card)) {
      newState = newState.copyWith(isClockwise: !newState.isClockwise);
    }

    // Handle draw cards
    final drawCount = RuleEngine.getDrawCount(card);
    if (drawCount > 0) {
      newState = newState.copyWith(drawStackCount: drawCount);
    }

    // Move to next player
    state = _moveToNextPlayer(newState, skipNext: RuleEngine.shouldSkipTurn(card));
  }

  /// Draws a card for the current player
  void drawCard() {
    if (state.drawPile.isEmpty) {
      _reshuffleDiscardPile();
    }

    if (state.drawPile.isEmpty) return;

    final drawnCard = state.drawPile.last;
    final updatedDrawPile = List<UnoCard>.from(state.drawPile)..removeLast();
    
    final currentHand = List<UnoCard>.from(state.currentPlayerHand)..add(drawnCard);
    final updatedHands = Map<String, List<UnoCard>>.from(state.playerHands);
    updatedHands[state.currentPlayerId] = currentHand;

    state = state.copyWith(
      drawPile: updatedDrawPile,
      playerHands: updatedHands,
    );
  }

  /// Draws multiple cards (for penalties)
  void drawCards(int count) {
    for (int i = 0; i < count; i++) {
      drawCard();
    }
    state = _moveToNextPlayer(state);
  }

  /// Moves to the next player
  GameState _moveToNextPlayer(GameState currentState, {bool skipNext = false}) {
    int nextIndex = currentState.currentPlayerIndex;
    final playerCount = currentState.playerIds.length;

    if (currentState.isClockwise) {
      nextIndex = (nextIndex + 1) % playerCount;
      if (skipNext) {
        nextIndex = (nextIndex + 1) % playerCount;
      }
    } else {
      nextIndex = (nextIndex - 1 + playerCount) % playerCount;
      if (skipNext) {
        nextIndex = (nextIndex - 1 + playerCount) % playerCount;
      }
    }

    return currentState.copyWith(
      currentPlayerIndex: nextIndex,
      drawStackCount: 0,
    );
  }

  /// Reshuffles the discard pile into the draw pile
  void _reshuffleDiscardPile() {
    if (state.discardPile.length <= 1) return;

    final topCard = state.discardPile.last;
    final cardsToShuffle = state.discardPile.sublist(0, state.discardPile.length - 1);
    
    _deckManager.shuffle(cardsToShuffle);

    state = state.copyWith(
      drawPile: cardsToShuffle,
      discardPile: [topCard],
    );
  }

  /// Passes turn to next player
  void passTurn() {
    state = _moveToNextPlayer(state);
  }

  /// Checks if current player is AI and triggers their move
  Future<void> _checkAndTriggerAIMove() async {
    if (state.status != GameStatus.playing) return;
    
    final currentPlayer = _players[state.currentPlayerId];
    if (currentPlayer?.isAI != true) return;

    final aiPlayer = _aiPlayers[state.currentPlayerId];
    if (aiPlayer == null) return;

    // Add realistic delay
    await Future.delayed(Duration(milliseconds: aiPlayer.getMoveDelay()));

    // Check if game state is still valid
    if (state.status != GameStatus.playing) return;
    if (state.topCard == null) return;

    final currentHand = state.currentPlayerHand;
    
    // AI selects card to play
    final cardToPlay = aiPlayer.selectCardToPlay(
      currentHand,
      state.topCard!,
      declaredColor: state.declaredColor,
    );

    if (cardToPlay != null) {
      // AI plays the card
      UnoCardColor? declaredColor;
      if (cardToPlay.isWildCard) {
        declaredColor = aiPlayer.selectColorForWildCard(currentHand);
      }
      playCard(cardToPlay, declaredColor: declaredColor);
    } else {
      // AI must draw a card
      drawCard();
      
      // After drawing, check if AI can play the drawn card
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (state.status != GameStatus.playing) return;
      
      final updatedHand = state.currentPlayerHand;
      if (updatedHand.isNotEmpty) {
        final drawnCard = updatedHand.last;
        if (state.topCard != null &&
            RuleEngine.canPlayCard(
              drawnCard,
              state.topCard!,
              declaredColor: state.declaredColor,
            )) {
          // AI can play the drawn card
          await Future.delayed(const Duration(milliseconds: 300));
          UnoCardColor? declaredColor;
          if (drawnCard.isWildCard) {
            declaredColor = aiPlayer.selectColorForWildCard(updatedHand);
          }
          playCard(drawnCard, declaredColor: declaredColor);
          return;
        }
      }
      
      // AI cannot play, pass turn
      passTurn();
    }
  }

  /// Gets player by ID
  Player? getPlayer(String playerId) => _players[playerId];

  /// Public method to check and trigger AI turn
  Future<void> checkAITurn() async {
    await _checkAndTriggerAIMove();
  }
}
