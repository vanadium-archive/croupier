// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of proto;

class ProtoCommand extends GameCommand {
  final String data; // This will be parsed.

  // Usually this constructor is used when reading from a log/syncbase.
  ProtoCommand(this.data);

  // The following constructors are used for the player generating the ProtoCommand.
  ProtoCommand.deal(int playerId, List<Card> cards)
      : this.data = computeDeal(playerId, cards);

  // TODO: receiverId is actually implied by the game round. So it may end up being removable.
  ProtoCommand.pass(int senderId, int receiverId, List<Card> cards)
      : this.data = computePass(senderId, receiverId, cards);

  ProtoCommand.play(int playerId, Card c)
      : this.data = computePlay(playerId, c);

  static computeDeal(int playerId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("Deal:${playerId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static computePass(int senderId, int receiverId, List<Card> cards) {
    StringBuffer buff = new StringBuffer();
    buff.write("Pass:${senderId}:${receiverId}:");
    cards.forEach((card) => buff.write("${card.toString()}:"));
    buff.write("END");
    return buff.toString();
  }

  static computePlay(int playerId, Card c) {
    return "Play:${playerId}:${c.toString()}:END";
  }

  bool canExecute(Game game) {
    return true;
  }

  void execute(Game game) {
    print("ProtoCommand is executing: ${data}");
    List<String> parts = data.split(":");
    switch (parts[0]) {
      case "Deal":
        // Deal appends cards to playerId's hand.
        int playerId = int.parse(parts[1]);
        List<Card> hand = game.cardCollections[playerId];

        // The last part is 'END', but the rest are cards.
        for (int i = 2; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          this.transfer(game.deck, hand, c);
        }
        return;
      case "Pass":
        // Pass moves a set of cards from senderId to receiverId.
        int senderId = int.parse(parts[1]);
        int receiverId = int.parse(parts[2]);
        List<Card> handS = game.cardCollections[senderId];
        List<Card> handR = game.cardCollections[receiverId];

        // The last part is 'END', but the rest are cards.
        for (int i = 3; i < parts.length - 1; i++) {
          Card c = new Card.fromString(parts[i]);
          this.transfer(handS, handR, c);
        }
        return;
      case "Play":
        // In this case, move it to the designated discard pile.
        // For now, the discard pile is pile #4. This may change.
        int playerId = int.parse(parts[1]);
        List<Card> hand = game.cardCollections[playerId];

        Card c = new Card.fromString(parts[2]);
        this.transfer(hand, game.cardCollections[4], c);
        return;
      default:
        print(data);
        assert(false); // How could this have happened?
    }
  }

  void transfer(List<Card> sender, List<Card> receiver, Card c) {
    assert(sender.contains(c));
    sender.remove(c);
    receiver.add(c);
  }
}