import 'card.dart' show Card;
import 'dart:math' show Random;

// Note: Proto and Board are "fake" games intended to demonstrate what we can do.
// Proto is just a drag cards around "game".
// Board is meant to show how one _could_ layout a game of Hearts. This one is not hooked up very well yet.
enum GameType {
  Proto, Hearts, Poker, Solitaire, Board
}

/// A game consists of multiple decks and tracks a single deck of cards.
/// It also handles events; when cards are dragged to and from decks.
class Game {
  final GameType gameType;
  final List<List<Card>> cardCollections = new List<List<Card>>();
  final List<Card> deck = new List<Card>.from(Card.All);

  final Random random = new Random();
  final GameLog gamelog = new GameLog();
  int playerNumber;
  String debugString = 'hello?';

  Function updateCallback; // Used to inform components of when a change has occurred. This is especially important when something non-UI related changes what should be drawn.

  factory Game(GameType gt, int pn) {
    switch (gt) {
      case GameType.Proto:
        return new ProtoGame(pn);
      case GameType.Hearts:
        return new HeartsGame(pn);
      default:
        assert(false);
        return null;
    }
  }

  // A super constructor, don't call this unless you're a subclass.
  Game._create(this.gameType, this.playerNumber, int numCollections) {
    gamelog.setGame(this);
    for (int i = 0; i < numCollections; i++) {
      cardCollections.add(new List<Card>());
    }
  }

  List<Card> deckPeek(int numCards) {
    assert(deck.length >= numCards);
    List<Card> cards = new List<Card>.from(deck.take(numCards));
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

  // UNIMPLEMENTED: Let subclasses override this?
  // Or is it improper to do so?
  void move(Card card, List<Card> dest) {}
}

class ProtoGame extends Game {
  ProtoGame(int playerNumber) : super._create(GameType.Proto, playerNumber, 6) {
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
    gamelog.add(new HeartsCommand.deal(playerId, this.deckPeek(numCards)));
  }

  // Overrides Game's move method with the "move" logic for the card dragging prototype.
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

    gamelog.add(new HeartsCommand.pass(i, destId, <Card>[card]));

    debugString = 'Move ${i} ${card.toString()}';
    print(debugString);
  }
}

class HeartsGame extends Game {
  HeartsGame(int playerNumber) : super._create(GameType.Hearts, playerNumber, 6) {
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
    gamelog.add(new HeartsCommand.deal(playerId, this.deckPeek(numCards)));
  }

  // Overrides Game's move method with the "move" logic for Hearts.
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

    gamelog.add(new HeartsCommand.pass(i, destId, <Card>[card]));

    debugString = 'Move ${i} ${card.toString()}';
    print(debugString);
  }
}


class GameLog {
  Game game;
  List<GameCommand> log = new List<GameCommand>();
  int position = 0;

  void setGame(Game g) {
    this.game = g;
  }

  // This adds and executes the GameCommand.
  void add(GameCommand gc) {
    log.add(gc);

    while (position < log.length) {
      log[position].execute(game);
      if (game.updateCallback != null) {
        game.updateCallback();
      }
      position++;
    }
  }
}

abstract class GameCommand {
  void execute(Game game);
}


class HeartsCommand extends GameCommand {
  final String data; // This will be parsed.

  // Usually this constructor is used when reading from a log/syncbase.
  HeartsCommand(this.data);

  // The following constructors are used for the player generating the HeartsCommand.
  HeartsCommand.deal(int playerId, List<Card> cards) :
    this.data = computeDeal(playerId, cards);

  // TODO: receiverId is actually implied by the game round. So it may end up being removable.
  HeartsCommand.pass(int senderId, int receiverId, List<Card> cards) :
    this.data = computePass(senderId, receiverId, cards);

  HeartsCommand.play(int playerId, Card c) :
    this.data = computePlay(playerId, c);

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

  void execute(Game game) {
    print("HeartsCommand is executing: ${data}");
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
