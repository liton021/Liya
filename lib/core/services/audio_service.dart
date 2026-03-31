import 'package:audioplayers/audioplayers.dart';
import '../models/card_model.dart';

/// Service to handle sound effects for the UNO game.
class AudioService {
  static final AudioService instance = AudioService._internal();
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  // File paths (relative to assets/sounds/)
  static const String cardPlayStr = 'card_play.mp3';
  static const String cardDrawStr = 'card_draw.mp3';
  static const String specialSkipStr = 'special_skip.mp3';
  static const String specialReverseStr = 'special_reverse.mp3';
  static const String specialDraw2Str = 'special_draw2.mp3';
  static const String specialDraw4Str = 'special_draw4.mp3';

  /// Plays the sound effect for playing a card
  Future<void> playCardSound(UnoCard? card) async {
    // All cards play the same sound now
    await _playSound(cardPlayStr);
  }

  /// Plays sound for drawing card (single)
  Future<void> playDrawSound() async {
    await _playSound(cardDrawStr);
  }

  /// Plays the penalty sounds specifically when someone draws 2 or 4 cards
  Future<void> playPenaltySound(int count) async {
    if (count == 2) {
      await _playSound(specialDraw2Str);
    } else if (count >= 4) {
      await _playSound(specialDraw4Str);
    }
  }

  Future<void> _playSound(String fileName) async {
    try {
      // Source is within assets/sounds/ as defined in pubspec.yaml
      await _player.stop(); // Stop current sound before playing new one
      await _player.play(AssetSource('sounds/$fileName'), volume: 0.8);
      
      // [MODIFIED] Limit special_draw4.mp3 to 1 second
      if (fileName == specialDraw4Str) {
        Future.delayed(const Duration(seconds: 1), () async {
          if (_player.source != null) {
            await _player.stop();
          }
        });
      }
    } catch (e) {
      // Audio failed, likely file missing - silently ignore for UX
      print('Audio play failed: $e');
    }
  }

  /// Preload sounds for better response time
  Future<void> preload() async {
    // Optional: Preload logic if needed by the player package
  }
}
