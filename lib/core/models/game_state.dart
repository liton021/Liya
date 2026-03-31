import '../models/card_model.dart';

/// Represents the current state of the UNO game
class GameState {
  final List<UnoCard> drawPile;
  final List<UnoCard> discardPile;
  final Map<String, List<UnoCard>> playerHands;
  final List<String> playerIds;
  final int currentPlayerIndex;
  final bool isClockwise;
  final UnoCardColor? declaredColor;
  final GameStatus status;
  final String? winnerId;
  final int drawStackCount;

  // ── Stacking support ───────────────────────────────────────────────────────
  /// Cumulative penalty cards from stacked +2 / +4 cards.
  /// 0 means no active stack.
  final int stackPenalty;

  /// The type of card currently being stacked (drawTwo or wildDrawFour).
  /// null when no stack is active.
  final UnoCardValue? stackCardType;

  // ── Settings ───────────────────────────────────────────────────────────────
  /// Whether stacking (+2 on +2, +4 on +4) is enabled.
  final bool stackingEnabled;

  /// Whether the current player has already drawn a card this turn.
  final bool hasDrawnThisTurn;

  /// Set of players who have declared UNO.
  final Set<String> unoDeclaredPlayers;

  const GameState({
    required this.drawPile,
    required this.discardPile,
    required this.playerHands,
    required this.playerIds,
    required this.currentPlayerIndex,
    this.isClockwise = true,
    this.declaredColor,
    this.status = GameStatus.waiting,
    this.winnerId,
    this.drawStackCount = 0,
    this.stackPenalty = 0,
    this.stackCardType,
    this.stackingEnabled = true, // ON by default (Bangladesh preference)
    this.hasDrawnThisTurn = false,
    this.unoDeclaredPlayers = const {},
  });

  factory GameState.initial() {
    return const GameState(
      drawPile: [],
      discardPile: [],
      playerHands: {},
      playerIds: [],
      currentPlayerIndex: 0,
    );
  }

  /// Gets the current top card on the discard pile
  UnoCard? get topCard => discardPile.isEmpty ? null : discardPile.last;

  /// Gets the current player's ID
  String get currentPlayerId => playerIds[currentPlayerIndex];

  /// Gets the current player's hand
  List<UnoCard> get currentPlayerHand => playerHands[currentPlayerId] ?? [];

  /// Whether there is an active draw stack that must be resolved
  bool get hasActiveStack => stackPenalty > 0;

  /// Number of players
  int get playerCount => playerIds.length;

  /// Creates a copy with modified fields
  GameState copyWith({
    List<UnoCard>? drawPile,
    List<UnoCard>? discardPile,
    Map<String, List<UnoCard>>? playerHands,
    List<String>? playerIds,
    int? currentPlayerIndex,
    bool? isClockwise,
    UnoCardColor? declaredColor,
    bool clearDeclaredColor = false,
    GameStatus? status,
    String? winnerId,
    int? drawStackCount,
    int? stackPenalty,
    UnoCardValue? stackCardType,
    bool clearStackCardType = false,
    bool? stackingEnabled,
    bool? hasDrawnThisTurn,
    Set<String>? unoDeclaredPlayers,
  }) {
    return GameState(
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      playerHands: playerHands ?? this.playerHands,
      playerIds: playerIds ?? this.playerIds,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      isClockwise: isClockwise ?? this.isClockwise,
      declaredColor:
          clearDeclaredColor ? null : (declaredColor ?? this.declaredColor),
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      drawStackCount: drawStackCount ?? this.drawStackCount,
      stackPenalty: stackPenalty ?? this.stackPenalty,
      stackCardType: clearStackCardType
          ? null
          : (stackCardType ?? this.stackCardType),
      stackingEnabled: stackingEnabled ?? this.stackingEnabled,
      hasDrawnThisTurn: hasDrawnThisTurn ?? this.hasDrawnThisTurn,
      unoDeclaredPlayers: unoDeclaredPlayers ?? this.unoDeclaredPlayers,
    );
  }
}

/// Enum representing the current status of the game
enum GameStatus {
  waiting,
  playing,
  finished,
  paused,
}
