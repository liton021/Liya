import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing card animations
/// 
/// Coordinates all card movement animations including:
/// - Card dealing from deck to player hands
/// - Card playing from hand to discard pile
/// - Card drawing from deck to hand
final animationProvider = StateNotifierProvider<AnimationNotifier, AnimationState>((ref) {
  return AnimationNotifier();
});

/// Manages animation state for card movements
class AnimationNotifier extends StateNotifier<AnimationState> {
  AnimationNotifier() : super(const AnimationState());

  /// Triggers animation for dealing cards
  /// 
  /// [cardId] Unique identifier for the card being animated
  /// [from] Starting position
  /// [to] Ending position
  /// [duration] Animation duration in milliseconds
  void animateCardDeal(
    String cardId,
    Offset from,
    Offset to, {
    int duration = 500,
  }) {
    final animations = Map<String, CardAnimation>.from(state.activeAnimations);
    animations[cardId] = CardAnimation(
      cardId: cardId,
      from: from,
      to: to,
      type: AnimationType.deal,
      startTime: DateTime.now(),
      duration: Duration(milliseconds: duration),
    );
    state = state.copyWith(activeAnimations: animations);
  }

  /// Triggers animation for playing a card
  void animateCardPlay(
    String cardId,
    Offset from,
    Offset to, {
    int duration = 400,
  }) {
    final animations = Map<String, CardAnimation>.from(state.activeAnimations);
    animations[cardId] = CardAnimation(
      cardId: cardId,
      from: from,
      to: to,
      type: AnimationType.play,
      startTime: DateTime.now(),
      duration: Duration(milliseconds: duration),
    );
    state = state.copyWith(activeAnimations: animations);
  }

  /// Triggers animation for drawing a card
  void animateCardDraw(
    String cardId,
    Offset from,
    Offset to, {
    int duration = 450,
  }) {
    final animations = Map<String, CardAnimation>.from(state.activeAnimations);
    animations[cardId] = CardAnimation(
      cardId: cardId,
      from: from,
      to: to,
      type: AnimationType.draw,
      startTime: DateTime.now(),
      duration: Duration(milliseconds: duration),
    );
    state = state.copyWith(activeAnimations: animations);
  }

  /// Removes completed animation
  void removeAnimation(String cardId) {
    final animations = Map<String, CardAnimation>.from(state.activeAnimations);
    animations.remove(cardId);
    state = state.copyWith(activeAnimations: animations);
  }

  /// Clears all animations
  void clearAnimations() {
    state = const AnimationState();
  }
}

/// State holding all active animations
class AnimationState {
  final Map<String, CardAnimation> activeAnimations;

  const AnimationState({
    this.activeAnimations = const {},
  });

  AnimationState copyWith({
    Map<String, CardAnimation>? activeAnimations,
  }) {
    return AnimationState(
      activeAnimations: activeAnimations ?? this.activeAnimations,
    );
  }
}

/// Represents a single card animation
class CardAnimation {
  final String cardId;
  final Offset from;
  final Offset to;
  final AnimationType type;
  final DateTime startTime;
  final Duration duration;

  const CardAnimation({
    required this.cardId,
    required this.from,
    required this.to,
    required this.type,
    required this.startTime,
    required this.duration,
  });

  /// Calculates current position based on elapsed time
  /// Uses cubic bezier curve for smooth animation
  Offset getCurrentPosition() {
    final elapsed = DateTime.now().difference(startTime);
    final progress = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    
    // Cubic bezier easing for smooth animation
    final easedProgress = _cubicBezier(progress);
    
    return Offset(
      from.dx + (to.dx - from.dx) * easedProgress,
      from.dy + (to.dy - from.dy) * easedProgress,
    );
  }

  /// Cubic bezier easing function for smooth animations
  double _cubicBezier(double t) {
    // Control points for smooth ease-in-out
    const double p0 = 0.0;
    const double p1 = 0.42;
    const double p2 = 0.58;
    const double p3 = 1.0;

    final double oneMinusT = 1.0 - t;
    return oneMinusT * oneMinusT * oneMinusT * p0 +
        3.0 * oneMinusT * oneMinusT * t * p1 +
        3.0 * oneMinusT * t * t * p2 +
        t * t * t * p3;
  }

  bool get isComplete {
    final elapsed = DateTime.now().difference(startTime);
    return elapsed >= duration;
  }
}

/// Types of card animations
enum AnimationType {
  deal,
  play,
  draw,
}
