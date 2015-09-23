// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of hearts;

class HeartsCommand extends GameCommand {
  final String data; // This will be parsed.

  // Usually this constructor is used when reading from a log/syncbase.
  HeartsCommand(this.data);

  // The following constructors are used for the player generating the HeartsCommand.
  HeartsCommand.deal(int playerId, List<Card> cards)
      : this.data = computeDeal(playerId, cards);

  HeartsCommand.pass(int senderId, List<Card> cards)
      : this.data = computePass(senderId, cards);

  HeartsCommand.take(int takerId) : this.data = computeTake(takerId);

  HeartsCommand.play(int playerId, Card c)
      : this.data = computePlay(playerId, c);

  HeartsCommand.ready(int playerId) : this.data = computeReady(playerId);

  static computeDeal(int playerId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("Deal:${playerId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static computePass(int senderId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("Pass:${senderId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static computeTake(int takerId) {
    return "Take:${takerId}:END";
  }

  static computePlay(int playerId, Card c) {
    return "Play:${playerId}:${c.toString()}:END";
  }

  static computeReady(int playerId) {
    return "Ready:${playerId}:END";
  }

  bool canExecute(Game g) {
    return true; // TODO(alexfandrianto): not really. Should do validation too.
  }

  void execute(Game g) {
    HeartsGame game = g as HeartsGame;

    print("HeartsCommand is executing: ${data}");
    List<String> parts = data.split(":");
    switch (parts[0]) {
      case "Deal":
        if (game.phase != HeartsPhase.Deal) {
          throw new StateError(
              "Cannot process deal commands when not in Deal phase");
        }
        // Deal appends cards to playerId's hand.
        int playerId = int.parse(parts[1]);
        List<Card> hand = game.cardCollections[playerId];
        if (hand.length + parts.length - 3 > 13) {
          throw new StateError("Cannot deal more than 13 cards to a hand");
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 2; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          this.transfer(game.deck, hand, c);
        }
        return;
      case "Pass":
        if (game.phase != HeartsPhase.Pass) {
          throw new StateError(
              "Cannot process pass commands when not in Pass phase");
        }
        // Pass moves a set of cards from senderId to receiverId.
        int senderId = int.parse(parts[1]);
        int receiverId = senderId + HeartsGame.OFFSET_PASS;
        List<Card> handS = game.cardCollections[senderId];
        List<Card> handR = game.cardCollections[receiverId];

        int numPassing = parts.length - 3;
        if (numPassing != 3) {
          throw new StateError("Must pass 3 cards, attempted ${numPassing}");
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 2; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          this.transfer(handS, handR, c);
        }
        return;
      case "Take":
        if (game.phase != HeartsPhase.Take) {
          throw new StateError(
              "Cannot process take commands when not in Take phase");
        }
        int takerId = int.parse(parts[1]);
        int senderPile = game._getTakeTarget(takerId) + HeartsGame.OFFSET_PASS;
        List<Card> handT = game.cardCollections[takerId];
        List<Card> handS = game.cardCollections[senderPile];
        handT.addAll(handS);
        handS.clear();
        return;
      case "Play":
        if (game.phase != HeartsPhase.Play) {
          throw new StateError(
              "Cannot process play commands when not in Play phase");
        }

        // Play the card from the player's hand to their play pile.
        int playerId = int.parse(parts[1]);
        int targetId = playerId + HeartsGame.OFFSET_PLAY;
        List<Card> hand = game.cardCollections[playerId];
        List<Card> discard = game.cardCollections[targetId];

        Card c = new Card.fromString(parts[2]);

        // If the card isn't valid, then we have an error.
        String reason = game.canPlay(playerId, c);
        if (reason != null) {
          throw new StateError(
              "Player ${playerId} cannot play ${c.toString()} because ${reason}");
        }
        this.transfer(hand, discard, c);
        return;
      case "Ready":
        if (game.hasGameEnded) {
          throw new StateError(
              "Game has already ended. Start a new one to play again.");
        }
        if (game.phase != HeartsPhase.Score) {
          throw new StateError(
              "Cannot process ready commands when not in Score phase");
        }
        int playerId = int.parse(parts[1]);
        game.setReady(playerId);
        return;
      default:
        print(data);
        assert(false); // How could this have happened?
    }
  }

  void transfer(List<Card> sender, List<Card> receiver, Card c) {
    if (!sender.contains(c)) {
      throw new StateError(
          "Sender ${sender.toString()} lacks Card ${c.toString()}");
    }
    sender.remove(c);
    receiver.add(c);
  }
}