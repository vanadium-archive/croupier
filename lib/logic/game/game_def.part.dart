// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game;

// Note: Proto and Board are "fake" games intended to demonstrate what we can do.
// Proto is just a drag cards around "game".
// Board is meant to show how one _could_ layout a game of Hearts. This one is not hooked up very well yet.
enum GameType { Proto, Hearts, Poker, Solitaire, Board }

/// A game consists of multiple decks and tracks a single deck of cards.
/// It also handles events; when cards are dragged to and from decks.
class Game {
  final GameType gameType;
  final List<List<Card>> cardCollections = new List<List<Card>>();
  final List<Card> deck = new List<Card>.from(Card.All);

  final math.Random random = new math.Random();
  final GameLog gamelog;
  int playerNumber;
  String debugString = 'hello?';

  Function updateCallback; // Used to inform components of when a change has occurred. This is especially important when something non-UI related changes what should be drawn.

  // A public super constructor that doesn't really do anything.
  // Don't call this unless you're a subclass.
  Game.dummy(this.gameType, this.gamelog) {}

  // A super constructor, don't call this unless you're a subclass.
  Game.create(
      this.gameType, this.gamelog, this.playerNumber, int numCollections) {
    gamelog.setGame(this);
    for (int i = 0; i < numCollections; i++) {
      cardCollections.add(new List<Card>());
    }
  }

  List<Card> deckPeek(int numCards, [int start = 0]) {
    assert(deck.length >= numCards);

    List<Card> cards =
        new List<Card>.from(deck.getRange(start, start + numCards));
    return cards;
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

  void resetCards() {
    for (int i = 0; i < cardCollections.length; i++) {
      cardCollections[i].clear();
    }
    deck.clear();
    deck.addAll(Card.All);
  }

  // UNIMPLEMENTED: Let subclasses override this?
  // Or is it improper to do so?
  void move(Card card, List<Card> dest) {}

  // UNIMPLEMENTED: Override this to implement game-specific logic after each event.
  void triggerEvents() {}
}
