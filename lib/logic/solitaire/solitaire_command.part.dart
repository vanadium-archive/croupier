// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of solitaire;

class SolitaireCommand extends GameCommand {
  // Usually this constructor is used when reading from a log/syncbase.
  SolitaireCommand(String phase, String data)
      : super(phase, data, simultaneity: SimulLevel.TURN_BASED);

  SolitaireCommand.fromCommand(String cmd)
      : super(cmd.split("|")[0], cmd.split("|")[1],
            simultaneity: SimulLevel.TURN_BASED);

  // The following constructors are used for the player generating the SolitaireCommand.
  SolitaireCommand.deal(List<Card> allCards)
      : super("Deal", computeDeal(allCards),
            simultaneity: SimulLevel.TURN_BASED);

  SolitaireCommand.move(Card target, int targetPile)
  : super("Move", computeMove(target, targetPile), simultaneity: SimulLevel.TURN_BASED);

  SolitaireCommand.draw()
  : super("Draw", computeDraw(), simultaneity: SimulLevel.TURN_BASED);

  SolitaireCommand.flip(int targetPile)
  : super("Flip", computeFlip(targetPile), simultaneity: SimulLevel.TURN_BASED);

  static String computeDeal(List<Card> allCards) {
    StringBuffer buff = new StringBuffer();
    allCards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  // Note: Depending on the target's position w.r.t. the targetPile, this may
  // actually move a group of cards instead.
  static String computeMove(Card target, int targetPile) {
    return "${target.toString()}:${targetPile}:END";
  }

  // Note: If there are no cards to draw, this will reset the draw pile.
  static String computeDraw() {
    return "END";
  }

  static String computeFlip(int targetPile) {
    return "${targetPile}:END";
  }

  @override
  bool canExecute(Game g) {
    // TODO(alexfandrianto): This is very similar to execute, but without the
    // mutations. It's possible to use a shared function to simplify/combine the
    // logic.
    SolitaireGame game = g as SolitaireGame;

    print("SolitaireCommand is checking: ${command}");
    List<String> parts = data.split(":");
    switch (phase) {
      case "Deal":
        return game.phase == SolitairePhase.Deal && parts.length - 1 == 52;
      case "Move":
        if (game.phase != SolitairePhase.Play) {
          return false;
        }

        // Move the card to the pile.
        Card c = new Card.fromString(parts[0]);
        int targetId = int.parse(parts[1]);
        int sourceId = game.findCard(c);
        if (sourceId == -1) {
          return false;
        }
        if (targetId < 0 || targetId >= game.cardCollections.length) {
          return false;
        }
        List<Card> source = game.cardCollections[sourceId];
        List<Card> dest = game.cardCollections[targetId];

        // If the card isn't valid, then we have an error.
        String reason = game.canPlay(c, dest);
        if (reason != null) {
          return false;
        }
        bool canTransfer = this.transferCheck(source, dest, c);
        return canTransfer;
      case "Draw":
        if (game.phase != SolitairePhase.Play) {
          return false;
        }

        List<Card> drawPile = game.cardCollections[SolitaireGame.OFFSET_DRAW];
        List<Card> discardPile = game.cardCollections[SolitaireGame.OFFSET_DISCARD];

        return drawPile.length > 0 || discardPile.length > 0;
      case "Flip":
        if (game.phase != SolitairePhase.Play) {
          return false;
        }

        int flipId = int.parse(parts[0]);
        if (flipId < 0 || flipId >= 7) {
          return false;
        }

        List<Card> flipSource = game.cardCollections[SolitaireGame.OFFSET_DOWN + flipId];
        List<Card> flipDest = game.cardCollections[SolitaireGame.OFFSET_UP + flipId];

        return flipDest.length == 0 && flipSource.length > 0;
      default:
        print(data);
        assert(false); // How could this have happened?
        return false;
    }
  }

  @override
  void execute(Game g) {
    SolitaireGame game = g as SolitaireGame;

    print("SolitaireCommand is executing: ${command}");
    List<String> parts = data.split(":");
    switch (phase) {
      case "Deal":
        if (game.phase != SolitairePhase.Deal) {
          throw new StateError(
              "Cannot process deal commands when not in Deal phase");
        }
        if (parts.length - 1 != 52) {
          throw new StateError(
            "Not enough cards dealt. Need 52, got ${parts.length - 1}");
        }

        // Deal fills out each of the down cards with one of each up card.
        int index = 0;
        for (int i = 0; i < 7; i++) {
          for (int j = 0; j < i; j++) {
            this.transfer(game.deck, game.cardCollections[SolitaireGame.OFFSET_DOWN + i], new Card.fromString(parts[index]));
            index++;
          }
          this.transfer(game.deck, game.cardCollections[SolitaireGame.OFFSET_UP + i], new Card.fromString(parts[index]));
          index++;
        }

        // The remaining cards are for the draw pile.
        for (; index < 52; index++) {
          this.transfer(game.deck, game.cardCollections[SolitaireGame.OFFSET_DRAW], new Card.fromString(parts[index]));
        }
        return;
      case "Move":
        if (game.phase != SolitairePhase.Play) {
          throw new StateError(
              "Cannot process move commands when not in Play phase");
        }

        // Move the card to the pile.
        Card c = new Card.fromString(parts[0]);
        int targetId = int.parse(parts[1]);
        int sourceId = game.findCard(c);
        if (sourceId == -1) {
          throw new StateError(
            "Cannot move unknown card ${c.toString()}");
        }
        if (targetId < 0 || targetId >= game.cardCollections.length) {
          throw new StateError(
            "Cannot move to unknown pile ${targetId}");
        }
        List<Card> source = game.cardCollections[sourceId];
        List<Card> dest = game.cardCollections[targetId];

        // If the card isn't valid, then we have an error.
        String reason = game.canPlay(c, dest);
        if (reason != null) {
          throw new StateError(
              "Cannot move ${c.toString()} to Pile ${targetId} because ${reason}");
        }
        this.transferGroup(source, dest, c);
        return;
      case "Draw":
        if (game.phase != SolitairePhase.Play) {
          throw new StateError(
              "Cannot process draw commands when not in Play phase");
        }

        List<Card> drawPile = game.cardCollections[SolitaireGame.OFFSET_DRAW];
        List<Card> discardPile = game.cardCollections[SolitaireGame.OFFSET_DISCARD];

        if (drawPile.length != 0) {
          this.transfer(drawPile, discardPile, drawPile[0]);
        } else if (discardPile.length != 0) {
          this.transferGroup(discardPile, drawPile, discardPile[0]);
        } else {
          throw new StateError("No cards left to draw");
        }
        return;
      case "Flip":
        if (game.phase != SolitairePhase.Play) {
          throw new StateError(
              "Cannot process flip commands when not in Play phase");
        }

        int flipId = int.parse(parts[0]);
        if (flipId < 0 || flipId >= 7) {
          throw new StateError(
            "Cannot process flip command for index ${flipId}");
        }

        List<Card> flipSource = game.cardCollections[SolitaireGame.OFFSET_DOWN + flipId];
        List<Card> flipDest = game.cardCollections[SolitaireGame.OFFSET_UP + flipId];

        if (flipDest.length != 0) {
          throw new StateError(
            "Cannot flip ${flipId} because destination has cards");
        }
        if (flipSource.length == 0) {
          throw new StateError(
            "Cannot flip ${flipId} because source has no cards");
        }
        this.transfer(flipSource, flipDest, flipSource[flipSource.length - 1]);
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

  // Transfers every card from a certain cutoff card onwards.
  void transferGroup(List<Card> sender, List<Card> receiver, Card c) {
    int index = sender.indexOf(c);
    if (index == -1) {
      throw new StateError(
          "Sender ${sender.toString()} lacks Card ${c.toString()}");
    }
    List<Card> lost = new List<Card>.from(sender.getRange(index, sender.length));
    sender.removeRange(index, sender.length);
    receiver.addAll(lost);
  }

  bool transferCheck(List<Card> sender, List<Card> receiver, Card c) {
    return sender.contains(c);
  }
}
