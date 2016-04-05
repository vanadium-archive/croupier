// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class Card {
  final String deck;
  final String identifier;

  Card(this.deck, this.identifier);
  Card.fromString(String cardData)
      : deck = cardData.split(" ")[0],
        identifier = cardData.split(" ")[1];

  @override
  bool operator ==(Object other) {
    if (other is! Card) return false;
    Card o = other as Card;
    return deck == o.deck && identifier == o.identifier;
  }

  @override
  int get hashCode => 37 * (deck.hashCode + 41 * identifier.hashCode);

  // TODO(alexfandrianto): https://github.com/dart-lang/sdk/issues/26184
  // Put the UnmodifiableListView<Card> back when dartanalyzer no longer warns.
  static final List<Card> all = <Card>[
    new Card("classic", "c1"),
    new Card("classic", "c2"),
    new Card("classic", "c3"),
    new Card("classic", "c4"),
    new Card("classic", "c5"),
    new Card("classic", "c6"),
    new Card("classic", "c7"),
    new Card("classic", "c8"),
    new Card("classic", "c9"),
    new Card("classic", "c10"),
    new Card("classic", "cj"),
    new Card("classic", "cq"),
    new Card("classic", "ck"),
    new Card("classic", "d1"),
    new Card("classic", "d2"),
    new Card("classic", "d3"),
    new Card("classic", "d4"),
    new Card("classic", "d5"),
    new Card("classic", "d6"),
    new Card("classic", "d7"),
    new Card("classic", "d8"),
    new Card("classic", "d9"),
    new Card("classic", "d10"),
    new Card("classic", "dj"),
    new Card("classic", "dq"),
    new Card("classic", "dk"),
    new Card("classic", "h1"),
    new Card("classic", "h2"),
    new Card("classic", "h3"),
    new Card("classic", "h4"),
    new Card("classic", "h5"),
    new Card("classic", "h6"),
    new Card("classic", "h7"),
    new Card("classic", "h8"),
    new Card("classic", "h9"),
    new Card("classic", "h10"),
    new Card("classic", "hj"),
    new Card("classic", "hq"),
    new Card("classic", "hk"),
    new Card("classic", "s1"),
    new Card("classic", "s2"),
    new Card("classic", "s3"),
    new Card("classic", "s4"),
    new Card("classic", "s5"),
    new Card("classic", "s6"),
    new Card("classic", "s7"),
    new Card("classic", "s8"),
    new Card("classic", "s9"),
    new Card("classic", "s10"),
    new Card("classic", "sj"),
    new Card("classic", "sq"),
    new Card("classic", "sk"),
  ];

  toString() => "${deck} ${identifier}";

  get string => toString();
}
