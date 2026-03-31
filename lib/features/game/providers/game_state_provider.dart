import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/card_model.dart';
import '../../../core/models/game_state.dart';
import '../../../core/models/player_model.dart';
import '../../../core/services/deck_manager.dart';
import '../../../core/services/rule_engine.dart';
import '../../../core/services/ai_player.dart';
import '../../../core/services/audio_service.dart';

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
  Timer? _unoPenaltyTimer;

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
      hasDrawnThisTurn: false,
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

    final String playerWhoPlayed = state.currentPlayerId;

    // Update player's hand
    final updatedHands = Map<String, List<UnoCard>>.from(state.playerHands);
    updatedHands[playerWhoPlayed] = currentHand;

    // Add card to discard pile
    final updatedDiscard = List<UnoCard>.from(state.discardPile)..add(card);

    // [MODIFIED] 5-second UNO penalty timer logic
    if (currentHand.length == 1) {
      final player = _players[playerWhoPlayed];
      if (player != null && !player.isAI) {
        _unoPenaltyTimer?.cancel();
        _unoPenaltyTimer = Timer(const Duration(seconds: 5), () {
          final currentUnoSet = state.unoDeclaredPlayers;
          if (!currentUnoSet.contains(playerWhoPlayed)) {
            _applyUnoPenalty(playerWhoPlayed);
          }
        });
      }
    }

    // Check for standard win
    if (currentHand.isEmpty) {
      state = state.copyWith(
        playerHands: updatedHands,
        discardPile: updatedDiscard,
        status: GameStatus.finished,
        winnerId: state.currentPlayerId,
      );
      return;
    }

    // Handle draw cards (Stacking)
    int newStackPenalty = state.stackPenalty;
    UnoCardValue? newStackCardType = state.stackCardType;

    final drawCount = RuleEngine.getDrawCount(card);
    if (drawCount > 0) {
      newStackPenalty += drawCount;
      newStackCardType = card.value;
    }

    // Apply card effects
    var newState = state.copyWith(
      playerHands: updatedHands,
      discardPile: updatedDiscard,
      declaredColor: declaredColor,
      clearDeclaredColor: !card.isWildCard,
      stackPenalty: newStackPenalty,
      stackCardType: newStackCardType,
    );

    // Handle reverse
    bool isReverse = RuleEngine.shouldReverseTurn(card);
    if (isReverse) {
      newState = newState.copyWith(isClockwise: !newState.isClockwise);
    }

    // Move to next player
    final nextState = _moveToNextPlayer(newState, 
        skipNext: RuleEngine.shouldSkipTurn(card),
        isReverse: isReverse,
    );
    state = nextState;

    // Trigger AI move if it's AI's turn
    _checkAndTriggerAIMove();
  }

  /// Draws a card for the current player
  void drawCard() {
    if (state.hasActiveStack) {
      drawCards(state.stackPenalty);
    } else if (!state.hasDrawnThisTurn) {
      _drawSingleCard();
      state = state.copyWith(hasDrawnThisTurn: true);
      
      // [NEW] Smart Pass Check: If drawn card isn't playable, auto-pass
      final player = _players[state.currentPlayerId];
      if (player != null && !player.isAI) {
        final hand = state.currentPlayerHand;
        if (hand.isNotEmpty) {
          final drawnCard = hand.last;
          final isPlayable = RuleEngine.canPlayCard(
            drawnCard, 
            state.topCard!,
            declaredColor: state.declaredColor,
            hasActiveStack: state.hasActiveStack,
            stackCardType: state.stackCardType,
            hand: hand,
          );
          
          if (!isPlayable) {
            // Auto-pass after a short delay for UX
            Future.delayed(const Duration(milliseconds: 800), () {
              if (state.hasDrawnThisTurn) passTurn();
            });
          }
        }
      }
    }
  }

  void _applyUnoPenalty(String playerId) {
    // [NEW] Play penalty sound for the 2-card draw
    AudioService.instance.playPenaltySound(2);

    // Standard rule: draw 2 cards penalty for not saying UNO
    final currentHand = List<UnoCard>.from(state.playerHands[playerId] ?? []);
    
    // Draw 2 cards manually to avoid moving turn
    for (int i = 0; i < 2; i++) {
        if (state.drawPile.isEmpty) _reshuffleDiscardPile();
        if (state.drawPile.isEmpty) break;
        
        final drawnCard = state.drawPile.last;
        state = state.copyWith(
          drawPile: List<UnoCard>.from(state.drawPile)..removeLast(),
        );
        currentHand.add(drawnCard);
    }
    
    final updatedHands = Map<String, List<UnoCard>>.from(state.playerHands);
    updatedHands[playerId] = currentHand;
    state = state.copyWith(playerHands: updatedHands);
  }

  /// Draws multiple cards (for penalties)
  void drawCards(int count) {
    // Play the penalty sound if applicable
    if (count >= 2) AudioService.instance.playPenaltySound(count);
    
    for (int i = 0; i < count; i++) {
      _drawSingleCard();
    }
    // Clear stack penalty and move to next player
    state = _moveToNextPlayer(state.copyWith(
      stackPenalty: 0,
      clearStackCardType: true,
    ));
    _checkAndTriggerAIMove();
  }

  /// Internal helper for drawing a single card without moving turn
  void _drawSingleCard() {
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

    // Clear UNO declaration if hand size is now > 1
    if (currentHand.length > 1 && state.unoDeclaredPlayers.contains(state.currentPlayerId)) {
      final updatedUno = Set<String>.from(state.unoDeclaredPlayers)..remove(state.currentPlayerId);
      state = state.copyWith(unoDeclaredPlayers: updatedUno);
    }
  }

  /// Moves to the next player
  GameState _moveToNextPlayer(GameState currentState, {bool skipNext = false, bool isReverse = false}) {
    int nextIndex = currentState.currentPlayerIndex;
    final playerCount = currentState.playerIds.length;

    // In 2-player games, Skip and Reverse both grant an extra turn to the current player
    bool shouldStayOnCurrent = (playerCount == 2 && (skipNext || isReverse));

    if (!shouldStayOnCurrent) {
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
    }

    return currentState.copyWith(
      currentPlayerIndex: nextIndex,
      hasDrawnThisTurn: false,
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
    _checkAndTriggerAIMove();
  }

  /// Declares UNO for a player
  void declareUno(String playerId) {
    if (state.unoDeclaredPlayers.contains(playerId)) return;
    
    // [NEW] Cancel penalty timer if it exists
    _unoPenaltyTimer?.cancel();
    _unoPenaltyTimer = null;
    
    final updatedUno = Set<String>.from(state.unoDeclaredPlayers)..add(playerId);
    state = state.copyWith(unoDeclaredPlayers: updatedUno);
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
      hasActiveStack: state.hasActiveStack,
      stackCardType: state.stackCardType,
    );

    if (cardToPlay != null) {
      // AI plays the card
      UnoCardColor? declaredColor;
      if (cardToPlay.isWildCard) {
        declaredColor = aiPlayer.selectColorForWildCard(currentHand);
      }
      
      // AI logic for declaring UNO
      if (currentHand.length == 2) {
        declareUno(state.currentPlayerId);
      }

      playCard(cardToPlay, declaredColor: declaredColor);
    } else {
      // AI must draw
      if (state.hasActiveStack) {
        // Cannot stack, must take the penalty
        drawCards(state.stackPenalty);
        return;
      }
      
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
              hasActiveStack: state.hasActiveStack,
              stackCardType: state.stackCardType,
              hand: updatedHand,
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
