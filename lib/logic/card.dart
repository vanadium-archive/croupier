class Card {
  final String deck;
  final String identifier;

  const Card(this.deck, this.identifier);

  toString() => "${deck} ${identifier}";

  get string => toString();
}
