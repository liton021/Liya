/// Represents a single UNO card with its properties
/// 
/// This model defines the core structure of an UNO card including
/// its color, value, and type (number, action, or wild)
class UnoCard {
  final UnoCardColor color;
  final UnoCardValue value;
  final String id;

  const UnoCard({
    required this.color,
    required this.value,
    required this.id,
  });

  /// Checks if this card can be played on top of another card
  /// 
  /// Rules:
  /// - Wild cards can be played on any card
  /// - Cards must match either color or value
  bool canPlayOn(UnoCard otherCard) {
    if (color == UnoCardColor.wild) return true;
    if (otherCard.color == UnoCardColor.wild) return true;
    return color == otherCard.color || value == otherCard.value;
  }

  /// Returns true if this is an action card (Skip, Reverse, Draw Two)
  bool get isActionCard {
    return value == UnoCardValue.skip ||
        value == UnoCardValue.reverse ||
        value == UnoCardValue.drawTwo;
  }

  /// Returns true if this is a wild card (Wild or Wild Draw Four)
  bool get isWildCard => color == UnoCardColor.wild;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnoCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UnoCard(color: $color, value: $value, id: $id)';
}

/// Enum representing the four colors in UNO plus wild
enum UnoCardColor {
  red,
  blue,
  green,
  yellow,
  wild,
}

/// Enum representing all possible card values in UNO
enum UnoCardValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour,
}
