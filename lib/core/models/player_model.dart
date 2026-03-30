/// Represents a player in the UNO game
/// 
/// Can be either a human player or AI player
class Player {
  final String id;
  final String name;
  final PlayerType type;
  final String? avatarUrl;
  final bool isConnected;

  const Player({
    required this.id,
    required this.name,
    required this.type,
    this.avatarUrl,
    this.isConnected = true,
  });

  /// Creates a human player
  factory Player.human({
    required String id,
    required String name,
    String? avatarUrl,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.human,
      avatarUrl: avatarUrl,
    );
  }

  /// Creates an AI player
  factory Player.ai({
    required String id,
    required String name,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.ai,
    );
  }

  /// Creates a remote player (for multiplayer)
  factory Player.remote({
    required String id,
    required String name,
    String? avatarUrl,
    bool isConnected = true,
  }) {
    return Player(
      id: id,
      name: name,
      type: PlayerType.remote,
      avatarUrl: avatarUrl,
      isConnected: isConnected,
    );
  }

  bool get isAI => type == PlayerType.ai;
  bool get isHuman => type == PlayerType.human;
  bool get isRemote => type == PlayerType.remote;

  Player copyWith({
    String? id,
    String? name,
    PlayerType? type,
    String? avatarUrl,
    bool? isConnected,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name, type: $type)';
}

/// Types of players
enum PlayerType {
  human,
  ai,
  remote,
}
