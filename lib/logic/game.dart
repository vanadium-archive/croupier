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
  final List<Card> deck = new List<Card>.from(Card.All);

  final Random random = new Random();
  String debugString = 'hello?';

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
    debugString = 'Moving... ${card.toString()}';
    int i = findCard(card);
    if (i == -1) {
      debugString = 'NO... ${card.toString()}';
      return;
    }
    cardCollections[i].remove(card);
    dest.add(card);
    debugString = 'Move ${i} ${card.toString()}';
    print(debugString);
  }

  // Which card collection has the card?
  int findCard(Card card) {
    for (int i = 0; i < cardCollections.length; i++) {
      if (cardCollections[i].contains(card)) {
        return i;
      }
    }
    return -1;
  }
}
