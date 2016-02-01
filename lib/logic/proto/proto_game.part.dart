// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of proto;

class ProtoGame extends Game {
  @override
  String get gameTypeName => "Proto";

  static final GameArrangeData _arrangeData =
      new GameArrangeData(false, new Set());
  GameArrangeData get gameArrangeData => _arrangeData;

  ProtoGame({int gameID, bool isCreator})
      : super.create(GameType.proto, new ProtoLog(), 6,
            gameID: gameID, isCreator: isCreator) {
    // playerNumber would be used in a real game, but I have to ignore it for debugging.
    // It would determine faceUp/faceDown status.faceDown

    // We do some arbitrary things here... Just for setup.
    // The first 4 of our 6 piles will get some random cards.
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

  @override
  void startGameSignal() {}
}
