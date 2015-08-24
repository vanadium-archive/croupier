import 'dart:collection';

class Card {
  final String deck;
  final String identifier;

  static final List<Card> All = new UnmodifiableListView<Card>([
    const Card("classic", "c1"),
    const Card("classic", "c2"),
    const Card("classic", "c3"),
    const Card("classic", "c4"),
    const Card("classic", "c5"),
    const Card("classic", "c6"),
    const Card("classic", "c7"),
    const Card("classic", "c8"),
    const Card("classic", "c9"),
    const Card("classic", "c10"),
    const Card("classic", "cj"),
    const Card("classic", "cq"),
    const Card("classic", "ck"),
    const Card("classic", "d1"),
    const Card("classic", "d2"),
    const Card("classic", "d3"),
    const Card("classic", "d4"),
    const Card("classic", "d5"),
    const Card("classic", "d6"),
    const Card("classic", "d7"),
    const Card("classic", "d8"),
    const Card("classic", "d9"),
    const Card("classic", "d10"),
    const Card("classic", "dj"),
    const Card("classic", "dq"),
    const Card("classic", "dk"),
    const Card("classic", "h1"),
    const Card("classic", "h2"),
    const Card("classic", "h3"),
    const Card("classic", "h4"),
    const Card("classic", "h5"),
    const Card("classic", "h6"),
    const Card("classic", "h7"),
    const Card("classic", "h8"),
    const Card("classic", "h9"),
    const Card("classic", "h10"),
    const Card("classic", "hj"),
    const Card("classic", "hq"),
    const Card("classic", "hk"),
    const Card("classic", "s1"),
    const Card("classic", "s2"),
    const Card("classic", "s3"),
    const Card("classic", "s4"),
    const Card("classic", "s5"),
    const Card("classic", "s6"),
    const Card("classic", "s7"),
    const Card("classic", "s8"),
    const Card("classic", "s9"),
    const Card("classic", "s10"),
    const Card("classic", "sj"),
    const Card("classic", "sq"),
    const Card("classic", "sk"),
  ]);


  const Card(this.deck, this.identifier);

  toString() => "${deck} ${identifier}";

  get string => toString();
}
