// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of proto;

class ProtoGame extends Game {
  ProtoGame(int playerNumber)
      : super.create(GameType.Proto, new ProtoLog(), playerNumber, 6) {
    // playerNumber would be used in a real game, but I have to ignore it for debugging.
    // It would determine faceUp/faceDown status.faceDown

    // TODO: Set the number of piles created to either 9 (1x per player, 1 discard, 4 play piles) or 12 (2x per player, 4 play piles)
    // But for now, we will deal with 6. 1x per player, 1 discard, and 1 undrawn pile.

    // We do some arbitrary things here... Just for setup.
    deck.shuffle();
    deal(0, 8);
    deal(1, 5);
    deal(2, 4);
    deal(3, 1);
  }

  void deal(int playerId, int numCards) {
    gamelog.add(new ProtoCommand.deal(playerId, this.deckPeek(numCards)));
  }

  // Overrides Game's move method with the "move" logic for the card dragging prototype.
  @override
  void move(Card card, List<Card> dest) {
    // The first step is to find the card. Where is it?
    // then we can remove it and add to the dest.
    debugString = 'Moving... ${card.toString()}';
    int i = findCard(card);
    if (i == -1) {
      debugString = 'NO... ${card.toString()}';
      return;
    }
    int destId = cardCollections.indexOf(dest);

    gamelog.add(new ProtoCommand.pass(i, destId, <Card>[card]));

    debugString = 'Move ${i} ${card.toString()}';
    print(debugString);
  }

  @override
  void triggerEvents() {}
}
