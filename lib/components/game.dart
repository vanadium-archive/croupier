import '../logic/card.dart' as logic_card;
import '../logic/game.dart'
    show Game, GameType, Viewer, HeartsGame, HeartsPhase;
import '../src/syncbase/syncbase_echo_impl.dart' show SyncbaseEchoImpl;
//import 'board.dart' show Board;
import 'card_collection.dart' show CardCollectionComponent, DropType, Orientation;
import 'draggable.dart' show Draggable;

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

abstract class GameComponent extends StatefulComponent {
  Game game;

  GameComponent(this.game) {
    game.updateCallback = update;
  }

  void update() {
    setState(() {});
  }

  void syncConstructorArguments(GameComponent other) {
    this.game = other.game;
  }

  Widget _makeButton(String text, Function callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  Widget build();
}

GameComponent createGameComponent(Game game) {
  switch(game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(game);
    case GameType.Hearts:
      return new HeartsGameComponent(game);
    case GameType.SyncbaseEcho:
      return new SyncbaseEchoGameComponent(game);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}


class ProtoGameComponent extends GameComponent {
  ProtoGameComponent(Game game) : super(game);

  Widget build() {
    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(
          cards, game.playerNumber == i, Orientation.horz, _makeGameMoveCallback, dragChildren: true, acceptType: DropType.card);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
        decoration: new BoxDecoration(
            backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true,
            Orientation.show1, _makeGameMoveCallback, dragChildren: true, acceptType: DropType.card)));

    cardCollections.add(_makeSwitchViewButton());

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex(cardCollections, direction: FlexDirection.vertical));
  }

  void _makeGameMoveCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      try {
        game.move(card, dest);
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  Widget _makeSwitchViewButton() =>
      _makeButton('Switch View', _switchPlayersCallback);

  void _switchPlayersCallback() {
    setState(() {
      game.playerNumber = (game.playerNumber + 1) % 4;
    });
  }
}

class SyncbaseEchoGameComponent extends GameComponent {
  SyncbaseEchoImpl s;

  SyncbaseEchoGameComponent(Game game) : super(game);

  Widget build() {
    if (s == null) {
      s = new SyncbaseEchoImpl(game);
    }
    return buildSyncbaseEcho();
  }

  Widget buildSyncbaseEcho() {
    return new Container(
        decoration: const BoxDecoration(
            backgroundColor: const Color(0xFF00ACC1)),
        child: new Flex([
      new RaisedButton(child: new Text('doEcho'), onPressed: s.doEcho),
      new Text('sendMsg: ${s.sendMsg}'),
      new Text('recvMsg: ${s.recvMsg}'),
      new RaisedButton(child: new Text('doPutGet'), onPressed: s.doPutGet),
      new Text('putStr: ${s.putStr}'),
      new Text('getStr: ${s.getStr}')
    ], direction: FlexDirection.vertical));
  }
}

class HeartsGameComponent extends GameComponent {
  List<logic_card.Card> passingCards = new List<logic_card.Card>();

  HeartsGameComponent(Game game) : super(game);
  Widget build() {
    return buildHearts();
    // Does NOT work in checked mode since it has a Stack of Positioned Stack with Positioned Widgets.
    // Issue and possible workaround? https://github.com/domokit/sky_engine/issues/732
    // return new Board(1, [2, 3, 4], [1, 2, 3, 4]);
    // For GameType.Board
  }

  // Passing between the temporary pass list and the player's hand.
  // Does not actually move anything in game logic terms.
  void _uiPassCardCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      if (dest == passingCards && !passingCards.contains(card) && passingCards.length < 3) {
        passingCards.add(card);
      } else if (dest != passingCards && passingCards.contains(card)) {
        passingCards.remove(card);
      }
    });
  }

  // This shouldn't always be here, but for now, we have little choice.
  void _switchPlayersCallback() {
    setState(() {
      game.playerNumber = (game.playerNumber + 1) % 4;
      passingCards.clear(); // Just for sanity.
    });
  }

  void _makeGamePassCallback(List<logic_card.Card> cards, List<logic_card.Card> dest) {
    setState(() {
      try {
        HeartsGame game = this.game as HeartsGame;
        game.passCards(cards);
        passingCards.clear();
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  void _makeGameTakeCallback(List<logic_card.Card> cards, List<logic_card.Card> dest) {
    setState(() {
      try {
        HeartsGame game = this.game as HeartsGame;
        game.takeCards();
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  void _makeGameMoveCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      try {
        game.move(card, dest);
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  Widget _makeSwitchViewButton() =>
      _makeButton('Switch View', _switchPlayersCallback);

  Widget _makeButton(String text, Function callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  Widget buildHearts() {
    HeartsGame game = this.game as HeartsGame;

    switch (game.phase) {
      case HeartsPhase.Deal:
        return new Container(
            decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
            child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCards),
          _makeSwitchViewButton()
        ], direction: FlexDirection.vertical));
      case HeartsPhase.Pass:
        return showPass();
      case HeartsPhase.Take:
        return showTake();
      case HeartsPhase.Play:
      case HeartsPhase.Score:
        return showBoard();
      default:
        assert(false);
        return null;
    }
  }

  Widget showBoard() {
    HeartsGame game = this.game as HeartsGame;

    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(
          cards, game.playerNumber == i, Orientation.horz, _makeGameMoveCallback);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
        decoration: new BoxDecoration(
            backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true,
            Orientation.show1, _makeGameMoveCallback)));

    cardCollections.add(new FlatButton(
        child: new Text('Switch View'), onPressed: _switchPlayersCallback));

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex(cardCollections, direction: FlexDirection.vertical));
  }

  Widget showPass() {
    HeartsGame game = this.game as HeartsGame;

    List<logic_card.Card> passCards = game.cardCollections[game.playerNumber + HeartsGame.OFFSET_PASS];

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> remainingCards = new List<logic_card.Card>();
    playerCards.forEach((logic_card.Card c) {
      if (!passingCards.contains(c)){
        remainingCards.add(c);
      }
    });

    bool hasPassed = passCards.length != 0;
    // TODO(alexfandrianto): You can pass as many times as you want... which is silly.
    // Luckily, later passes shouldn't do anything.

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex(<Widget>[
          new Text(game.debugString),
          new CardCollectionComponent(passCards, true,
                Orientation.horz, _makeGamePassCallback, acceptType: DropType.card_collection),
          new Draggable<CardCollectionComponent>(new CardCollectionComponent(passingCards, true,
                Orientation.horz, _uiPassCardCallback, dragChildren: !hasPassed, acceptType: DropType.card)),
          new CardCollectionComponent(remainingCards, true,
                Orientation.horz, _uiPassCardCallback, dragChildren: !hasPassed, acceptType: DropType.card),
          new FlatButton(
            child: new Text('Switch View'),
            onPressed: _switchPlayersCallback)
        ], direction: FlexDirection.vertical));
  }

  Widget showTake() {
    HeartsGame game = this.game as HeartsGame;

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> takeCards = game.cardCollections[game.takeTarget + HeartsGame.OFFSET_PASS];

    bool hasTaken = takeCards.length == 0;

    Widget take = new CardCollectionComponent(takeCards, true,
                Orientation.horz, _makeGameTakeCallback);
    if (!hasTaken) {
      take = new Draggable<CardCollectionComponent>(take);
    }

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex(<Widget>[
          new Text(game.debugString),
          take,
          new CardCollectionComponent(playerCards, true,
                Orientation.horz, _makeGameTakeCallback, dragChildren: true, acceptType: DropType.card_collection),
          new FlatButton(
            child: new Text('Switch View'),
            onPressed: _switchPlayersCallback)
        ], direction: FlexDirection.vertical));
  }
}
