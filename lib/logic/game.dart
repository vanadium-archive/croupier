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
  final GameLog gamelog = new GameLog();
  int playerNumber;
  Function updateCallback;
  String debugString = 'hello?';

  Game.hearts(this.playerNumber) : gameType = GameType.Hearts {
    gamelog.setGame(this);

    // playerNumber would be used in a real game, but I have to ignore it for debugging.
    // It would determine faceUp/faceDown status.

    deck.shuffle();
    cardCollections.add(new List<Card>()); // Player A
    cardCollections.add(new List<Card>()); // Player B
    cardCollections.add(new List<Card>()); // Player C
    cardCollections.add(new List<Card>()); // Player D
    cardCollections.add(new List<Card>()); // an empty pile
    cardCollections.add(new List<Card>()); // a hidden pile!

    /*deal(0, 8);
    deal(1, 5);
    deal(2, 4);
    deal(3, 1);*/
  }

  List<Card> deckPeek(int numCards) {
    assert(deck.length >= numCards);
    List<Card> cards = new List<Card>.from(deck.take(numCards));
    return cards;
  }

  void deal(int playerId, int numCards) {
    gamelog.add(new HeartsCommand.deal(playerId, this.deckPeek(numCards)));
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
    int destId = cardCollections.indexOf(dest);

    gamelog.add(new HeartsCommand.pass(i, destId, <Card>[card]));

    /*cardCollections[i].remove(card);
    dest.add(card);*/
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
