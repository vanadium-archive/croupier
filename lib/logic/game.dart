import 'card.dart' show Card;
import 'dart:math' show Random;

enum GameType {
  Hearts
}

/// A game consists of multiple decks and tracks a single deck of cards.
/// It also handles events; when cards are dragged to and from decks.
class Game {
  final GameType gameType;
  final List<List<Card>> cardCollections = new List<List<Card>>();
  final List<Card> deck = <Card>[
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
  ];

  final Random random = new Random();

  Game.hearts(int playerNumber) : gameType = GameType.Hearts {
    // playerNumber would be used in a real game, but I have to ignore it for debugging.
    // It would determine faceUp/faceDown status.

    deck.shuffle();
    cardCollections.add(this.deal(10));
    cardCollections.add(this.deal(5));
    cardCollections.add(this.deal(1));
    cardCollections.add(this.deal(1));
    cardCollections.add(new List<Card>()); // an empty pile TODO(alexfandrianto): Why can't I just have an empty stack?
    cardCollections.add(new List<Card>()); // a hidden pile!
  }

  List<Card> deal(int numCards) {
    assert(deck.length >= numCards);
    List<Card> cards = new List<Card>.from(deck.take(numCards));
    deck.removeRange(0, numCards);
    return cards;
  }

  void move(Card card, List<Card> dest) {
    // The first step is to find the card. Where is it?
    // then we can remove it and add to the dest.
    int i = findCard(card);
    assert(i != -1);
    cardCollections[i].remove(card);
    dest.add(card);
  }

  // Which card collection has the card?
  int findCard(Card card) {
    for (var i = 0; i < cardCollections; i++) {
      if (cardCollections[i].contains(card)) {
        return i;
      }
    }
    return -1;
  }
}