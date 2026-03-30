import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/card_model.dart';
import '../models/game_state.dart';
import '../models/player_model.dart';

/// Firebase service for multiplayer game functionality
/// 
/// Handles:
/// - Game room creation and joining
/// - Real-time game state synchronization
/// - Player presence tracking
/// - Turn-based gameplay coordination
class FirebaseGameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new game room
  /// 
  /// Returns the room ID
  Future<String> createGameRoom({
    required Player host,
    required int maxPlayers,
  }) async {
    final roomRef = _firestore.collection('game_rooms').doc();
    
    await roomRef.set({
      'hostId': host.id,
      'hostName': host.name,
      'maxPlayers': maxPlayers,
      'currentPlayers': 1,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'players': {
        host.id: {
          'name': host.name,
          'avatarUrl': host.avatarUrl,
          'isConnected': true,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      },
    });

    return roomRef.id;
  }

  /// Joins an existing game room
  Future<bool> joinGameRoom({
    required String roomId,
    required Player player,
  }) async {
    final roomRef = _firestore.collection('game_rooms').doc(roomId);
    
    try {
      await _firestore.runTransaction((transaction) async {
        final roomDoc = await transaction.get(roomRef);
        
        if (!roomDoc.exists) {
          throw Exception('Room does not exist');
        }

        final data = roomDoc.data()!;
        final currentPlayers = data['currentPlayers'] as int;
        final maxPlayers = data['maxPlayers'] as int;
        final status = data['status'] as String;

        if (status != 'waiting') {
          throw Exception('Game already started');
        }

        if (currentPlayers >= maxPlayers) {
          throw Exception('Room is full');
        }

        transaction.update(roomRef, {
          'currentPlayers': currentPlayers + 1,
          'players.${player.id}': {
            'name': player.name,
            'avatarUrl': player.avatarUrl,
            'isConnected': true,
            'joinedAt': FieldValue.serverTimestamp(),
          },
        });
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Starts the game in a room
  Future<void> startGame({
    required String roomId,
    required GameState initialState,
  }) async {
    final roomRef = _firestore.collection('game_rooms').doc(roomId);
    
    await roomRef.update({
      'status': 'playing',
      'gameState': _serializeGameState(initialState),
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates game state in real-time
  Future<void> updateGameState({
    required String roomId,
    required GameState gameState,
  }) async {
    final roomRef = _firestore.collection('game_rooms').doc(roomId);
    
    await roomRef.update({
      'gameState': _serializeGameState(gameState),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Listens to game state changes
  Stream<GameState?> watchGameState(String roomId) {
    return _firestore
        .collection('game_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('gameState')) return null;
      
      return _deserializeGameState(data['gameState'] as Map<String, dynamic>);
    });
  }

  /// Updates player presence
  Future<void> updatePlayerPresence({
    required String roomId,
    required String playerId,
    required bool isConnected,
  }) async {
    final roomRef = _firestore.collection('game_rooms').doc(roomId);
    
    await roomRef.update({
      'players.$playerId.isConnected': isConnected,
      'players.$playerId.lastSeen': FieldValue.serverTimestamp(),
    });
  }

  /// Listens to player presence changes
  Stream<Map<String, bool>> watchPlayerPresence(String roomId) {
    return _firestore
        .collection('game_rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return {};
      
      final data = snapshot.data();
      if (data == null || !data.containsKey('players')) return {};
      
      final players = data['players'] as Map<String, dynamic>;
      final presence = <String, bool>{};
      
      players.forEach((playerId, playerData) {
        presence[playerId] = playerData['isConnected'] as bool? ?? false;
      });
      
      return presence;
    });
  }

  /// Leaves a game room
  Future<void> leaveGameRoom({
    required String roomId,
    required String playerId,
  }) async {
    await updatePlayerPresence(
      roomId: roomId,
      playerId: playerId,
      isConnected: false,
    );
  }

  /// Deletes a game room
  Future<void> deleteGameRoom(String roomId) async {
    await _firestore.collection('game_rooms').doc(roomId).delete();
  }

  /// Lists available game rooms
  Stream<List<GameRoomInfo>> watchAvailableRooms() {
    return _firestore
        .collection('game_rooms')
        .where('status', isEqualTo: 'waiting')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GameRoomInfo(
          id: doc.id,
          hostName: data['hostName'] as String,
          currentPlayers: data['currentPlayers'] as int,
          maxPlayers: data['maxPlayers'] as int,
        );
      }).toList();
    });
  }

  /// Serializes game state for Firestore
  Map<String, dynamic> _serializeGameState(GameState state) {
    return {
      'drawPileCount': state.drawPile.length,
      'discardPile': state.discardPile.map(_serializeCard).toList(),
      'playerHands': state.playerHands.map(
        (key, value) => MapEntry(key, value.map(_serializeCard).toList()),
      ),
      'playerIds': state.playerIds,
      'currentPlayerIndex': state.currentPlayerIndex,
      'isClockwise': state.isClockwise,
      'declaredColor': state.declaredColor?.name,
      'status': state.status.name,
      'winnerId': state.winnerId,
      'drawStackCount': state.drawStackCount,
    };
  }

  /// Deserializes game state from Firestore
  GameState _deserializeGameState(Map<String, dynamic> data) {
    return GameState(
      drawPile: [], // Don't sync full draw pile for security
      discardPile: (data['discardPile'] as List)
          .map((e) => _deserializeCard(e as Map<String, dynamic>))
          .toList(),
      playerHands: (data['playerHands'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List)
              .map((e) => _deserializeCard(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      playerIds: List<String>.from(data['playerIds'] as List),
      currentPlayerIndex: data['currentPlayerIndex'] as int,
      isClockwise: data['isClockwise'] as bool,
      declaredColor: data['declaredColor'] != null
          ? UnoCardColor.values.firstWhere(
              (e) => e.name == data['declaredColor'],
            )
          : null,
      status: GameStatus.values.firstWhere(
        (e) => e.name == data['status'],
      ),
      winnerId: data['winnerId'] as String?,
      drawStackCount: data['drawStackCount'] as int,
    );
  }

  /// Serializes a card
  Map<String, dynamic> _serializeCard(UnoCard card) {
    return {
      'id': card.id,
      'color': card.color.name,
      'value': card.value.name,
    };
  }

  /// Deserializes a card
  UnoCard _deserializeCard(Map<String, dynamic> data) {
    return UnoCard(
      id: data['id'] as String,
      color: UnoCardColor.values.firstWhere((e) => e.name == data['color']),
      value: UnoCardValue.values.firstWhere((e) => e.name == data['value']),
    );
  }
}

/// Information about a game room
class GameRoomInfo {
  final String id;
  final String hostName;
  final int currentPlayers;
  final int maxPlayers;

  GameRoomInfo({
    required this.id,
    required this.hostName,
    required this.currentPlayers,
    required this.maxPlayers,
  });
}
