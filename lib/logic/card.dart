class Card {
  final String deck;
  final String identifier;

  Card(this.deck, this.identifier);
  Card.fromString(String cardData) : deck = cardData.split(" ")[0], identifier = cardData.split(" ")[1];

  bool operator ==(Object other) {
    if (other is! Card) return false;
    Card o = other as Card;
    return deck == o.deck && identifier == o.identifier;
  }
  int get hashCode => 37 * (deck.hashCode + 41 * identifier.hashCode);

  toString() => "${deck} ${identifier}";

  get string => toString();
}
