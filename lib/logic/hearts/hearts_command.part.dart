// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of hearts;

class HeartsCommand extends GameCommand {
  // Usually this constructor is used when reading from a log/syncbase.
  HeartsCommand(String phase, String data)
      : super(phase, data, simultaneity: computeSimul(phase));

  HeartsCommand.fromCommand(String cmd)
      : super(cmd.split("|")[0], cmd.split("|")[1],
            simultaneity: computeSimul(cmd.split("|")[0]));

  // The following constructors are used for the player generating the HeartsCommand.
  HeartsCommand.deal(int playerId, List<Card> cards)
      : super("Deal", computeDeal(playerId, cards),
            simultaneity: SimulLevel.INDEPENDENT);

  HeartsCommand.pass(int senderId, List<Card> cards)
      : super("Pass", computePass(senderId, cards),
            simultaneity: SimulLevel.INDEPENDENT);

  HeartsCommand.take(int takerId)
      : super("Take", computeTake(takerId),
            simultaneity: SimulLevel.INDEPENDENT);

  HeartsCommand.play(int playerId, Card c)
      : super("Play", computePlay(playerId, c),
            simultaneity: SimulLevel.TURN_BASED);

  HeartsCommand.takeTrick()
      : super("TakeTrick", computeTakeTrick(),
            simultaneity: SimulLevel.TURN_BASED);

  HeartsCommand.ready(int playerId)
      : super("Ready", computeReady(playerId),
            simultaneity: SimulLevel.INDEPENDENT);

  static SimulLevel computeSimul(String phase) {
    switch (phase) {
      case "Deal":
        return SimulLevel.INDEPENDENT;
      case "Pass":
        return SimulLevel.INDEPENDENT;
      case "Take":
        return SimulLevel.INDEPENDENT;
      case "Play":
        return SimulLevel.TURN_BASED;
      case "TakeTrick":
        return SimulLevel.TURN_BASED;
      case "Ready":
        return SimulLevel.INDEPENDENT;
      default:
        print(phase);
        assert(false); // How could this have happened?
        return null;
    }
  }

  static String computeDeal(int playerId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("${playerId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static String computePass(int senderId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("${senderId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static String computeTake(int takerId) {
    return "${takerId}:END";
  }

  static String computePlay(int playerId, Card c) {
    return "${playerId}:${c.toString()}:END";
  }

  static String computeTakeTrick() {
    return "END";
  }

  static String computeReady(int playerId) {
    return "${playerId}:END";
  }

  @override
  bool canExecute(Game g) {
    // TODO(alexfandrianto): This is very similar to execute, but without the
    // mutations. It's possible to use a shared function to simplify/combine the
    // logic.
    HeartsGame game = g as HeartsGame;

    print("HeartsCommand is checking: ${data}");
    List<String> parts = data.split(":");
    switch (phase) {
      case "Deal":
        if (game.phase != HeartsPhase.Deal) {
          return false;
        }
        // Deal appends cards to playerId's hand.
        int playerId = int.parse(parts[0]);
        List<Card> hand = game.cardCollections[playerId];
        if (hand.length + parts.length - 3 > 13) {
          return false;
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 1; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          bool canTransfer = this.transferCheck(game.deck, hand, c);
          if (!canTransfer) {
            return false;
          }
        }
        return true;
      case "Pass":
        if (game.phase != HeartsPhase.Pass) {
          return false;
        }
        // Pass moves a set of cards from senderId to receiverId.
        int senderId = int.parse(parts[0]);
        int receiverId = senderId + HeartsGame.OFFSET_PASS;
        List<Card> handS = game.cardCollections[senderId];
        List<Card> handR = game.cardCollections[receiverId];

        int numPassing = parts.length - 2; // not senderId and not end
        if (numPassing != 3) {
          return false;
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 1; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          bool canTransfer = this.transferCheck(handS, handR, c);
          if (!canTransfer) {
            return false;
          }
        }
        return true;
      case "Take":
        if (game.phase != HeartsPhase.Take) {
          return false;
        }
        return true;
      case "Play":
        if (game.phase != HeartsPhase.Play) {
          return false;
        }

        // Play the card from the player's hand to their play pile.
        int playerId = int.parse(parts[0]);
        int targetId = playerId + HeartsGame.OFFSET_PLAY;
        List<Card> hand = game.cardCollections[playerId];
        List<Card> discard = game.cardCollections[targetId];

        Card c = new Card.fromString(parts[1]);

        // If the card isn't valid, then we have an error.
        String reason = game.canPlay(playerId, c);
        if (reason != null) {
          return false;
        }
        bool canTransfer = this.transferCheck(hand, discard, c);
        return canTransfer;
      case "TakeTrick":
        if (game.phase != HeartsPhase.Play) {
          return false;
        }

        // There must be 4 cards played.
        return game.allPlayed;
      case "Ready":
        if (game.hasGameEnded) {
          return false;
        }
        if (game.phase != HeartsPhase.Score) {
          return false;
        }
        return true;
      default:
        print(data);
        assert(false); // How could this have happened?
        return false;
    }
  }

  @override
  void execute(Game g) {
    HeartsGame game = g as HeartsGame;

    print("HeartsCommand is executing: ${data}");
    List<String> parts = data.split(":");
    switch (phase) {
      case "Deal":
        if (game.phase != HeartsPhase.Deal) {
          throw new StateError(
              "Cannot process deal commands when not in Deal phase");
        }
        // Deal appends cards to playerId's hand.
        int playerId = int.parse(parts[0]);
        List<Card> hand = game.cardCollections[playerId];
        if (hand.length + parts.length - 3 > 13) {
          throw new StateError("Cannot deal more than 13 cards to a hand");
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 1; i < parts.length - 1; i++) {
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
        int senderId = int.parse(parts[0]);
        int receiverId = senderId + HeartsGame.OFFSET_PASS;
        List<Card> handS = game.cardCollections[senderId];
        List<Card> handR = game.cardCollections[receiverId];

        int numPassing = parts.length - 2; // not senderId and not end
        if (numPassing != 3) {
          throw new StateError("Must pass 3 cards, attempted ${numPassing}");
        }

        // The last part is 'END', but the rest are cards.
        for (int i = 1; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          this.transfer(handS, handR, c);
        }
        return;
      case "Take":
        if (game.phase != HeartsPhase.Take) {
          throw new StateError(
              "Cannot process take commands when not in Take phase");
        }
        int takerId = int.parse(parts[0]);
        int senderPile = game.getTakeTarget(takerId) + HeartsGame.OFFSET_PASS;
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
        int playerId = int.parse(parts[0]);
        int targetId = playerId + HeartsGame.OFFSET_PLAY;
        List<Card> hand = game.cardCollections[playerId];
        List<Card> discard = game.cardCollections[targetId];

        Card c = new Card.fromString(parts[1]);

        // If the card isn't valid, then we have an error.
        String reason = game.canPlay(playerId, c);
        if (reason != null) {
          throw new StateError(
              "Player ${playerId} cannot play ${c.toString()} because ${reason}");
        }
        this.transfer(hand, discard, c);
        return;
      case "TakeTrick":
        if (game.phase != HeartsPhase.Play) {
          throw new StateError(
              "Cannot process take trick commands when not in Play phase");
        }
        if (!game.allPlayed) {
          throw new StateError(
              "Cannot take trick when some players have not played");
        }

        // Determine who won this trick.
        int winner = game.determineTrickWinner();

        // Move the cards to their trick list. Also check if hearts was broken.
        // Note: While some variants of Hearts allow the QUEEN_OF_SPADES to
        // break hearts, this version does NOT implement that rule.
        for (int i = 0; i < 4; i++) {
          List<Card> play = game.cardCollections[i + HeartsGame.OFFSET_PLAY];
          if (!game.heartsBroken && game.isHeartsCard(play[0])) {
            game.heartsBroken = true;
          }
          game.cardCollections[winner + HeartsGame.OFFSET_TRICK]
              .addAll(play); // or add(play[0])
          play.clear();
        }

        // Set them as the next person to go.
        game.lastTrickTaker = winner;
        game.trickNumber++;

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
        int playerId = int.parse(parts[0]);
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

  bool transferCheck(List<Card> sender, List<Card> receiver, Card c) {
    return sender.contains(c);
  }
}
