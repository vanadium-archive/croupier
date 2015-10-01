// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase;
//import 'board.dart' show Board;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, Orientation;

import 'package:sky/widgets_next.dart';
import 'package:sky/material.dart' as material;

typedef void NoArgCb();

abstract class GameComponent extends StatefulComponent {
  final NavigatorState navigator;
  final Game game;
  final NoArgCb gameEndCallback;
  final double width;
  final double height;

  GameComponent(this.navigator, this.game, this.gameEndCallback, {this.width, this.height});
}

abstract class GameComponentState<T extends GameComponent> extends State<T> {
  void initState(_) {
    super.initState(_);

    config.game.updateCallback = update;
  }

  // This callback is used to force the UI to draw when state changes occur
  // outside of the UIs control (e.g., synced data).
  void update() {
    setState(() {});
  }

  // A helper that most subclasses use in order to quit their respective games.
  void _quitGameCallback() {
    setState(() {
      config.gameEndCallback();
    });
  }

  // A helper that subclasses might override to create buttons.
  Widget _makeButton(String text, NoArgCb callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  @override
  Widget build(BuildContext context); // still UNIMPLEMENTED
}

GameComponent createGameComponent(NavigatorState navigator, Game game, NoArgCb gameEndCallback,
    {double width, double height}) {
  switch (game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(navigator, game, gameEndCallback,
          width: width, height: height);
    case GameType.Hearts:
      return new HeartsGameComponent(navigator, game, gameEndCallback,
          width: width, height: height);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}

class ProtoGameComponent extends GameComponent {
  ProtoGameComponent(NavigatorState navigator, Game game, NoArgCb cb, {double width, double height})
      : super(navigator, game, cb, width: width, height: height);

  ProtoGameComponentState createState() => new ProtoGameComponentState();
}

class ProtoGameComponentState extends GameComponentState<ProtoGameComponent> {
  @override
  Widget build(BuildContext context) {
    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(config.game.debugString));

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards = config.game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(config.navigator, cards,
          config.game.playerNumber == i, Orientation.horz,
          dragChildren: true, acceptType: DropType.card, acceptCallback: _makeGameMoveCallback, width: config.width);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
        decoration: new BoxDecoration(
            backgroundColor: material.Colors.green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(config.navigator, config.game.cardCollections[4], true,
            Orientation.show1,
            dragChildren: true, acceptType: DropType.card, acceptCallback: _makeGameMoveCallback, width: config.width)));

    cardCollections.add(_makeDebugButtons());

    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.pink[500]),
        child: new Flex(cardCollections, direction: FlexDirection.vertical));
  }

  void _makeGameMoveCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      try {
        config.game.move(card, dest);
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        config.game.debugString = e.toString();
      }
    });
  }

  Widget _makeDebugButtons() => new Flex([
        new Text('P${config.game.playerNumber}'),
        _makeButton('Switch View', _switchPlayersCallback),
        _makeButton('Quit', _quitGameCallback)
      ]);

  void _switchPlayersCallback() {
    setState(() {
      config.game.playerNumber = (config.game.playerNumber + 1) % 4;
    });
  }
}

class HeartsGameComponent extends GameComponent {
  HeartsGameComponent(NavigatorState navigator, Game game, NoArgCb cb, {double width, double height})
      : super(navigator, game, cb, width: width, height: height);

  HeartsGameComponentState createState() => new HeartsGameComponentState();
}

class HeartsGameComponentState extends GameComponentState<HeartsGameComponent> {
  List<logic_card.Card> passingCards1 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards2 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards3 = new List<logic_card.Card>();

  @override
  Widget build(BuildContext context) {
    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.grey[300]),
        child: buildHearts());
  }

  // Passing between the temporary pass list and the player's hand.
  // Does not actually move anything in game logic terms.
  void _uiPassCardCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      if (passingCards1.contains(card)) {
        passingCards1.remove(card);
      }
      if (passingCards2.contains(card)) {
        passingCards2.remove(card);
      }
      if (passingCards3.contains(card)) {
        passingCards3.remove(card);
      }

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
    HeartsGame game = config.game as HeartsGame;
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
      config.game.playerNumber = (config.game.playerNumber + 1) % 4;
      _clearPassing(); // Just for sanity.
    });
  }

  void _makeGamePassCallback() {
    setState(() {
      try {
        HeartsGame game = config.game as HeartsGame;
        game.passCards(_combinePassing());
        _clearPassing();
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        config.game.debugString = e.toString();
      }
    });
  }

  void _makeGameTakeCallback() {
    setState(() {
      try {
        HeartsGame game = config.game as HeartsGame;
        game.takeCards();
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        config.game.debugString = e.toString();
      }
    });
  }

  void _makeGameMoveCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      HeartsGame game = config.game;
      String reason = game.canPlay(game.playerNumber, card);
      if (reason == null) {
        game.move(card, dest);
      } else {
        print("You can't do that! ${reason}");
        game.debugString = reason;

      }
    });
  }

  void _endRoundDebugCallback() {
    setState(() {
      HeartsGame game = config.game as HeartsGame;
      game.jumpToScorePhaseDebug();
    });
  }

  Widget _makeDebugButtons() => new Container(
      width: config.width,
      child: new Flex([
        new Flexible(flex: 1, child: new Text('P${config.game.playerNumber}')),
        new Flexible(
            flex: 5, child: _makeButton('Switch View', _switchPlayersCallback)),
        new Flexible(
            flex: 5,
            child: _makeButton('Dump Log', () => print(config.game.gamelog))),
        new Flexible(
            flex: 5, child: _makeButton('End Round', _endRoundDebugCallback)),
        new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
      ]));

  @override
  Widget _makeButton(String text, NoArgCb callback, {bool inactive: false}) {
    var borderColor =
        inactive ? material.Colors.grey[500] : material.Colors.white;
    var backgroundColor = inactive ? material.Colors.grey[500] : null;
    return new FlatButton(
        child: new Container(
            decoration: new BoxDecoration(
                border: new Border.all(width: 1.0, color: borderColor),
                backgroundColor: backgroundColor),
            padding: new EdgeDims.all(10.0),
            child: new Text(text)),
        enabled: !inactive,
        onPressed: inactive ? null : callback);
  }

  Widget buildHearts() {
    HeartsGame game = config.game as HeartsGame;

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
    HeartsGame game = config.game as HeartsGame;

    List<Widget> cardCollections = new List<Widget>();

    List<Widget> plays = new List<Widget>();
    for (int i = 0; i < 4; i++) {
      plays.add(new CardCollectionComponent(
          config.navigator,
          game.cardCollections[i + HeartsGame.OFFSET_PLAY],
          true,
          Orientation.show1,
          width: config.width));
    }
    cardCollections.add(new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.teal[600]),
        width: config.width,
        child:
            new Flex(plays, justifyContent: FlexJustifyContent.spaceAround)));

    int p = game.playerNumber;

    Widget playArea = new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.teal[500]),
        width: config.width,
        child: new Center(
            child: new CardCollectionComponent(
                config.navigator,
                game.cardCollections[p + HeartsGame.OFFSET_PLAY],
                true,
                Orientation.show1,
                acceptCallback: _makeGameMoveCallback,
                acceptType: p == game.whoseTurn ? DropType.card : DropType.none,
                width: config.width,
                backgroundColor: p == game.whoseTurn
                    ? material.Colors.white
                    : material.Colors.grey[500],
                altColor: p == game.whoseTurn
                    ? material.Colors.grey[200]
                    : material.Colors.grey[600])));
    cardCollections.add(playArea);

    List<logic_card.Card> cards = game.cardCollections[p];
    CardCollectionComponent c = new CardCollectionComponent(
        config.navigator,
        cards, game.playerNumber == p, Orientation.suit,
        dragChildren: game.whoseTurn == p,
        comparator: _compareCards,
        width: config.width);
    cardCollections.add(c); // flex

    cardCollections.add(new Text("Player ${game.whoseTurn}'s turn"));
    cardCollections.add(new Text(game.debugString));
    cardCollections.add(_makeDebugButtons());

    return new Column(cardCollections,
        justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showScore() {
    HeartsGame game = config.game as HeartsGame;

    Widget w;
    if (game.hasGameEnded) {
      w = new Text("Game Over!");
    } else if (game.ready[game.playerNumber]) {
      w = new Text("Waiting for other players...");
    } else {
      w = _makeButton('Ready?', game.setReadyUI);
    }

    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.pink[500]),
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
    HeartsGame game = config.game as HeartsGame;

    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCards),
          _makeDebugButtons()
        ],
            direction: FlexDirection.vertical,
            justifyContent: FlexJustifyContent.spaceBetween));
  }

  // the pass phase screen consists of 2 parts:
  // The cards being passed + Pass button.
  // The cards in your hand.
  Widget showPass() {
    HeartsGame game = config.game as HeartsGame;

    List<logic_card.Card> passCards =
        game.cardCollections[game.playerNumber + HeartsGame.OFFSET_PASS];

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> remainingCards = new List<logic_card.Card>();
    playerCards.forEach((logic_card.Card c) {
      if (!passingCards1.contains(c) &&
          !passingCards2.contains(c) &&
          !passingCards3.contains(c)) {
        remainingCards.add(c);
      }
    });

    bool hasPassed = passCards.length != 0;
    // TODO(alexfandrianto): You can pass as many times as you want... which is silly.
    // Luckily, later passes shouldn't do anything.

    List<Widget> passingCardWidgets = <Widget>[
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              passingCards1, true, Orientation.show1,
              acceptCallback: _uiPassCardCallback,
              dragChildren: !hasPassed,
              acceptType: DropType.card,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200])),
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              passingCards2, true, Orientation.show1,
              acceptCallback: _uiPassCardCallback,
              dragChildren: !hasPassed,
              acceptType: DropType.card,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200])),
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              passingCards3, true, Orientation.show1,
              acceptCallback: _uiPassCardCallback,
              dragChildren: !hasPassed,
              acceptType: DropType.card,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200]))
    ];
    Widget passArea;
    if (hasPassed) {
      passArea = new Container(
          decoration:
              new BoxDecoration(backgroundColor: material.Colors.teal[600]),
          width: config.width,
          child: new Flex(
              passingCardWidgets
                ..add(_makeButton("Pass", null, inactive: true)),
              justifyContent: FlexJustifyContent.spaceBetween));
    } else {
      passArea = new Container(
          decoration:
              new BoxDecoration(backgroundColor: material.Colors.teal[500]),
          width: config.width,
          child: new Flex(
              passingCardWidgets
                ..add(_makeButton("Pass", _makeGamePassCallback)),
              justifyContent: FlexJustifyContent.spaceBetween));
    }

    // Return the pass cards and the player's remaining hand.
    // (Also includes debug info)
    return new Column(<Widget>[
      passArea,
      new CardCollectionComponent(
              config.navigator,
          remainingCards, true, Orientation.suit,
          acceptCallback: _uiPassCardCallback,
          dragChildren: !hasPassed,
          acceptType: DropType.card,
          comparator: _compareCards,
          width: config.width,
          backgroundColor: material.Colors.grey[500],
          altColor: material.Colors.grey[700]),
      new Text(game.debugString),
      _makeDebugButtons()
    ], justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showTake() {
    HeartsGame game = config.game as HeartsGame;

    List<logic_card.Card> playerCards = game.cardCollections[game.playerNumber];
    List<logic_card.Card> takeCards =
        game.cardCollections[game.takeTarget + HeartsGame.OFFSET_PASS];

    bool hasTaken = takeCards.length == 0;

    List<logic_card.Card> take1 =
        takeCards.length != 0 ? takeCards.sublist(0, 1) : [];
    List<logic_card.Card> take2 =
        takeCards.length != 0 ? takeCards.sublist(1, 2) : [];
    List<logic_card.Card> take3 =
        takeCards.length != 0 ? takeCards.sublist(2, 3) : [];

    List<Widget> takeCardWidgets = <Widget>[
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              take1, true, Orientation.show1,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200])),
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              take2, true, Orientation.show1,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200])),
      new Container(
          margin: new EdgeDims.all(10.0),
          child: new CardCollectionComponent(
              config.navigator,
              take3, true, Orientation.show1,
              backgroundColor: material.Colors.white,
              altColor: material.Colors.grey[200]))
    ];
    Widget takeArea;
    if (hasTaken) {
      takeArea = new Container(
          decoration:
              new BoxDecoration(backgroundColor: material.Colors.teal[600]),
          width: config.width,
          child: new Flex(
              takeCardWidgets..add(_makeButton("Take", null, inactive: true)),
              justifyContent: FlexJustifyContent.spaceBetween));
    } else {
      takeArea = new Container(
          decoration:
              new BoxDecoration(backgroundColor: material.Colors.teal[500]),
          width: config.width,
          child: new Flex(
              takeCardWidgets..add(_makeButton("Take", _makeGameTakeCallback)),
              justifyContent: FlexJustifyContent.spaceBetween));
    }

    // Return the passsed cards and the player's hand.
    // (Also includes debug info)
    return new Column(<Widget>[
      takeArea,
      new CardCollectionComponent(
              config.navigator, playerCards, true, Orientation.suit,
          comparator: _compareCards,
          width: config.width,
          backgroundColor: material.Colors.grey[500],
          altColor: material.Colors.grey[700]),
      new Text(game.debugString),
      _makeDebugButtons()
    ], justifyContent: FlexJustifyContent.spaceBetween);
  }
}
