// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase;
import '../src/syncbase/syncbase_echo_impl.dart' show SyncbaseEchoImpl;
//import 'board.dart' show Board;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, Orientation;

import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

abstract class GameComponent extends StatefulComponent {
  Game game;
  Function gameEndCallback;
  double width;
  double height;

  GameComponent(this.game, this.gameEndCallback, {this.width, this.height}) {
    game.updateCallback = update;
  }

  void update() {
    setState(() {});
  }

  void syncConstructorArguments(GameComponent other) {
    this.game = other.game;
  }

  // A helper that most subclasses use in order to quit their respective games.
  void _quitGameCallback() {
    setState(() {
      this.gameEndCallback();
    });
  }

  Widget _makeButton(String text, Function callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  Widget build();
}

GameComponent createGameComponent(Game game, Function gameEndCallback, {double width, double height}) {
  switch (game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(game, gameEndCallback, width: width, height: height);
    case GameType.Hearts:
      return new HeartsGameComponent(game, gameEndCallback, width: width, height: height);
    case GameType.SyncbaseEcho:
      return new SyncbaseEchoGameComponent(game, gameEndCallback);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}

class ProtoGameComponent extends GameComponent {
  ProtoGameComponent(Game game, Function cb, {double width, double height}) : super(game, cb, width: width, height: height);

  Widget build() {
    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(cards,
          game.playerNumber == i, Orientation.horz, _makeGameMoveCallback,
          dragChildren: true, acceptType: DropType.card, width: width);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
        decoration: new BoxDecoration(
            backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true,
            Orientation.show1, _makeGameMoveCallback,
            dragChildren: true, acceptType: DropType.card, width: width)));

    cardCollections.add(_makeDebugButtons());

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

  Widget _makeDebugButtons() => new Flex([
        new Text('P${game.playerNumber}'),
        _makeButton('Switch View', _switchPlayersCallback),
        _makeButton('Quit', _quitGameCallback)
      ]);

  void _switchPlayersCallback() {
    setState(() {
      game.playerNumber = (game.playerNumber + 1) % 4;
    });
  }
}

class SyncbaseEchoGameComponent extends GameComponent {
  SyncbaseEchoImpl s;

  SyncbaseEchoGameComponent(Game game, Function cb) : super(game, cb);

  Widget build() {
    if (s == null) {
      s = new SyncbaseEchoImpl(game);
    }
    return buildSyncbaseEcho();
  }

  Widget buildSyncbaseEcho() {
    return new Container(
        decoration:
            const BoxDecoration(backgroundColor: const Color(0xFF00ACC1)),
        child: new Flex([
          new RaisedButton(child: new Text('doPutGet'), onPressed: s.doPutGet),
          new Text('putStr: ${s.putStr}'),
          new Text('getStr: ${s.getStr}'),
          _makeButton('Quit', _quitGameCallback)
        ], direction: FlexDirection.vertical));
  }
}

class HeartsGameComponent extends GameComponent {
  List<logic_card.Card> passingCards1 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards2 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards3 = new List<logic_card.Card>();

  HeartsGameComponent(Game game, Function cb, {double width, double height}) : super(game, cb, width: width, height: height);
  Widget build() {
    return new Container(
      decoration: new BoxDecoration(
        backgroundColor: colors.Grey[300]
      ),
      child: buildHearts()
    );
  }

  // Passing between the temporary pass list and the player's hand.
  // Does not actually move anything in game logic terms.
  void _uiPassCardCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      if (passingCards1.contains(card)) { passingCards1.remove(card); }
      if (passingCards2.contains(card)) { passingCards2.remove(card); }
      if (passingCards3.contains(card)) { passingCards3.remove(card); }

      if (dest == passingCards1 && passingCards1.length == 0) {
        passingCards1.add(card);
      } else if (dest == passingCards2 && passingCards2.length == 0) {
        passingCards2.add(card);
      } else if (dest == passingCards3 && passingCards3.length == 0) {
        passingCards3.add(card);
      }
    });
  }

  int _compareCards(logic_card.Card a, logic_card.Card b) {
    if (a == b) return 0;
    assert(a.deck == "classic" && b.deck == "classic");
    HeartsGame game = this.game as HeartsGame;
    int r = game.getCardSuit(a).compareTo(game.getCardSuit(b));
    if (r != 0) return r;
    return game.getCardValue(a) < game.getCardValue(b) ? -1 : 1;
  }

  void _clearPassing() {
    passingCards1.clear();
    passingCards2.clear();
    passingCards3.clear();
  }
  List<logic_card.Card> _combinePassing() {
    List<logic_card.Card> ls = new List<logic_card.Card>();
    ls.addAll(passingCards1);
    ls.addAll(passingCards2);
    ls.addAll(passingCards3);
    return ls;
  }

  // This shouldn't always be here, but for now, we have little choice.
  void _switchPlayersCallback() {
    setState(() {
      game.playerNumber = (game.playerNumber + 1) % 4;
      _clearPassing(); // Just for sanity.
    });
  }

  void _makeGamePassCallback() {
    setState(() {
      try {
        HeartsGame game = this.game as HeartsGame;
        game.passCards(_combinePassing());
        _clearPassing();
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  void _makeGameTakeCallback() {
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

  void _endRoundDebugCallback() {
    setState(() {
      HeartsGame game = this.game as HeartsGame;
      game.jumpToScorePhaseDebug();
    });
  }

  Widget _makeDebugButtons() => new Container(
    width: this.width,
    child: new Flex([
        new Flexible(flex: 1, child: new Text('P${game.playerNumber}')),
        new Flexible(
            flex: 5, child: _makeButton('Switch View', _switchPlayersCallback)),
        new Flexible(
            flex: 5,
            child: _makeButton('Dump Log', () => print(this.game.gamelog))),
        new Flexible(
            flex: 5, child: _makeButton('End Round', _endRoundDebugCallback)),
        new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
      ])
  );

  Widget _makeButton(String text, Function callback, {bool inactive: false}) {
    var borderColor = inactive ? colors.Grey[500] : colors.white;
    var backgroundColor = inactive ? colors.Grey[500] : null;
    return new FlatButton(
      child: new Container(
        decoration: new BoxDecoration(
          border: new Border.all(width: 1.0, color: borderColor),
          backgroundColor: backgroundColor
        ),
        padding: new EdgeDims.all(10.0),
        child: new Text(text)
      ),
      enabled: !inactive,
      onPressed: inactive ? null : callback
    );
  }

  Widget buildHearts() {
    HeartsGame game = this.game as HeartsGame;

    switch (game.phase) {
      case HeartsPhase.Deal:
        return showDeal();
      case HeartsPhase.Pass:
        return showPass();
      case HeartsPhase.Take:
        return showTake();
      case HeartsPhase.Play:
        return showPlay();
      case HeartsPhase.Score:
        return showScore();
      default:
        assert(false);
        return null;
    }
  }

  Widget showPlay() {
    HeartsGame game = this.game as HeartsGame;

    List<Widget> cardCollections = new List<Widget>();

    List<Widget> plays = new List<Widget>();
    for (int i = 0; i < 4; i++) {
      plays.add(new CardCollectionComponent(
        game.cardCollections[i + HeartsGame.OFFSET_PLAY],
        true,
        Orientation.show1,
        _makeGameMoveCallback,
        width: width
      ));
    }
    cardCollections.add(new Container(
      decoration: new BoxDecoration(
        backgroundColor: colors.Teal[600]
      ),
      width: this.width,
      child: new Flex(plays, justifyContent: FlexJustifyContent.spaceAround)
    ));


    int p = game.playerNumber;

    Widget playArea = new Container(
      decoration: new BoxDecoration(
        backgroundColor: colors.Teal[500]
      ),
      width: this.width,
      child: new Center(
        child: new CardCollectionComponent(
          game.cardCollections[p + HeartsGame.OFFSET_PLAY],
          true,
          Orientation.show1,
          _makeGameMoveCallback,
          acceptType: p == game.whoseTurn ? DropType.card : DropType.none,
          width: width,
          backgroundColor: p == game.whoseTurn ? colors.white : colors.Grey[500],
          altColor: p == game.whoseTurn ? colors.Grey[200] : colors.Grey[600]
        )
      )
    );
    cardCollections.add(playArea);

    List<logic_card.Card> cards = game.cardCollections[p];
    CardCollectionComponent c = new CardCollectionComponent(cards,
        game.playerNumber == p, Orientation.suit, _makeGameMoveCallback,
        dragChildren: game.whoseTurn == p, comparator: _compareCards, width: width);
    cardCollections.add(c); // flex

    cardCollections.add(new Text("Player ${game.whoseTurn}'s turn"));
    cardCollections.add(new Text(game.debugString));
    cardCollections.add(_makeDebugButtons());

    return new Column(cardCollections, justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showScore() {
    HeartsGame game = this.game as HeartsGame;

    Widget w;
    if (game.hasGameEnded) {
      w = new Text("Game Over!");
    } else if (game.ready[game.playerNumber]) {
      w = new Text("Waiting for other players...");
    } else {
      w = _makeButton('Ready?', game.setReadyUI);
    }

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          // TODO(alexfandrianto): we want to show round by round, deltas too, don't we?
          new Text('${game.scores}'),
          w,
          _makeButton("Return to Lobby", _quitGameCallback),
          _makeDebugButtons()
        ], direction: FlexDirection.vertical));
  }

  Widget showDeal() {
    HeartsGame game = this.game as HeartsGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCards),
          _makeDebugButtons()
        ], direction: FlexDirection.vertical, justifyContent: FlexJustifyContent.spaceBetween));
  }

  // the pass phase screen consists of 2 parts:
  // The cards being passed + Pass button.
  // The cards in your hand.
  Widget showPass() {
    HeartsGame game = this.game as HeartsGame;

    List<logic_card.Card> passCards =
        game.cardCollections[game.playerNumber + HeartsGame.OFFSET_PASS];

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> remainingCards = new List<logic_card.Card>();
    playerCards.forEach((logic_card.Card c) {
      if (!passingCards1.contains(c) && !passingCards2.contains(c) &&
        !passingCards3.contains(c)) {

        remainingCards.add(c);
      }
    });

    bool hasPassed = passCards.length != 0;
    // TODO(alexfandrianto): You can pass as many times as you want... which is silly.
    // Luckily, later passes shouldn't do anything.

    List<Widget> passingCardWidgets = <Widget>[
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          passingCards1, true, Orientation.show1, _uiPassCardCallback,
          dragChildren: !hasPassed, acceptType: DropType.card,
          backgroundColor: colors.white, altColor: colors.Grey[200])),
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          passingCards2, true, Orientation.show1, _uiPassCardCallback,
          dragChildren: !hasPassed, acceptType: DropType.card,
          backgroundColor: colors.white, altColor: colors.Grey[200])),
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          passingCards3, true, Orientation.show1, _uiPassCardCallback,
          dragChildren: !hasPassed, acceptType: DropType.card,
          backgroundColor: colors.white, altColor: colors.Grey[200]))
    ];
    Widget passArea;
    if (hasPassed) {
      passArea = new Container(
        decoration: new BoxDecoration(
          backgroundColor: colors.Teal[600]
        ),
        width: this.width,
        child: new Flex(
          passingCardWidgets..add(_makeButton("Pass", null, inactive: true)),
          justifyContent: FlexJustifyContent.spaceBetween
        )
      );
    } else {
      passArea = new Container(
        decoration: new BoxDecoration(
          backgroundColor: colors.Teal[500]
        ),
        width: this.width,
        child: new Flex(
          passingCardWidgets..add(_makeButton("Pass", _makeGamePassCallback)),
          justifyContent: FlexJustifyContent.spaceBetween
        )
      );
    }

    // Return the pass cards and the player's remaining hand.
    // (Also includes debug info)
    return new Column(<Widget>[
      passArea,
      new CardCollectionComponent(
          remainingCards, true, Orientation.suit, _uiPassCardCallback,
          dragChildren: !hasPassed, acceptType: DropType.card, comparator: _compareCards, width: width,
          backgroundColor: colors.Grey[500], altColor: colors.Grey[700]),
      new Text(game.debugString),
      _makeDebugButtons()
    ], justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showTake() {
    HeartsGame game = this.game as HeartsGame;

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> takeCards =
        game.cardCollections[game.takeTarget + HeartsGame.OFFSET_PASS];

    bool hasTaken = takeCards.length == 0;

    List<logic_card.Card> take1 = takeCards.length != 0 ? takeCards.sublist(0, 1) : [];
    List<logic_card.Card> take2 = takeCards.length != 0 ? takeCards.sublist(1, 2) : [];
    List<logic_card.Card> take3 = takeCards.length != 0 ? takeCards.sublist(2, 3) : [];

    List<Widget> takeCardWidgets = <Widget>[
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          take1, true, Orientation.show1, null,
          backgroundColor: colors.white, altColor: colors.Grey[200])),
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          take2, true, Orientation.show1, null,
          backgroundColor: colors.white, altColor: colors.Grey[200])),
      new Container(margin: new EdgeDims.all(10.0), child: new CardCollectionComponent(
          take3, true, Orientation.show1, null,
          backgroundColor: colors.white, altColor: colors.Grey[200]))
    ];
    Widget takeArea;
    if (hasTaken) {
      takeArea = new Container(
        decoration: new BoxDecoration(
          backgroundColor: colors.Teal[600]
        ),
        width: this.width,
        child: new Flex(
          takeCardWidgets..add(_makeButton("Take", null, inactive: true)),
          justifyContent: FlexJustifyContent.spaceBetween
        )
      );
    } else {
      takeArea = new Container(
        decoration: new BoxDecoration(
          backgroundColor: colors.Teal[500]
        ),
        width: this.width,
        child: new Flex(
          takeCardWidgets..add(_makeButton("Take", _makeGameTakeCallback)),
          justifyContent: FlexJustifyContent.spaceBetween
        )
      );
    }

    // Return the passsed cards and the player's hand.
    // (Also includes debug info)
    return new Column(<Widget>[
      takeArea,
      new CardCollectionComponent(
          playerCards, true, Orientation.suit, null,
          comparator: _compareCards, width: width,
          backgroundColor: colors.Grey[500], altColor: colors.Grey[700]),
      new Text(game.debugString),
      _makeDebugButtons()
    ], justifyContent: FlexJustifyContent.spaceBetween);
  }
}
