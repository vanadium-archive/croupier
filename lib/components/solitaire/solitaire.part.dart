// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game_component;

class SolitaireGameComponent extends GameComponent {
  SolitaireGameComponent(Game game, NoArgCb cb, {double width, double height})
      : super(game, cb, width: width, height: height);

  SolitaireGameComponentState createState() =>
      new SolitaireGameComponentState();
}

class SolitaireGameComponentState
    extends GameComponentState<SolitaireGameComponent> {
  @override
  Widget build(BuildContext context) {
    SolitaireGame game = config.game as SolitaireGame;

    print("Building Solitaire!");

    // Build Solitaire and have it fill up the card level map.
    // Unfortunately, this is required so that we can know which card components
    // to collect.
    Widget solitaireWidget = buildSolitaire();

    List<Widget> children = new List<Widget>();
    children.add(new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.grey[300]),
        width: config.width,
        height: config.height,
        child: solitaireWidget));
    if (game.phase == SolitairePhase.Play) {
      // All cards are visible.
      List<int> visibleCardCollections =
          game.cardCollections.asMap().keys.toList();

      children.add(this.buildCardAnimationLayer(visibleCardCollections));
    }

    return new Container(
        width: config.width, height: config.height, child: new Stack(children));
  }

  void _cheatCallback() {
    setState(() {
      SolitaireGame game = config.game as SolitaireGame;
      game.cheatUI();
    });
  }

  void _endRoundDebugCallback() {
    setState(() {
      SolitaireGame game = config.game as SolitaireGame;
      game.jumpToScorePhaseDebug();
    });
  }

  Widget _makeDebugButtons() => new Container(
      width: config.width,
      child: new Flex([
        new Flexible(flex: 1, child: new Text('P${config.game.playerNumber}')),
        new Flexible(flex: 5, child: _makeButton('Cheat', _cheatCallback)),
        new Flexible(
            flex: 5, child: _makeButton('End Round', _endRoundDebugCallback)),
        new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
      ]));

  @override
  Widget _makeButton(String text, NoArgCb callback, {bool inactive: false}) {
    var borderColor = inactive ? Colors.grey[500] : Colors.white;
    var backgroundColor = inactive ? Colors.grey[500] : null;
    return new FlatButton(
        child: new Container(
            decoration: new BoxDecoration(
                border: new Border.all(width: 1.0, color: borderColor),
                backgroundColor: backgroundColor),
            padding: new EdgeDims.all(10.0),
            child: new Text(text)),
        onPressed: inactive ? null : callback);
  }

  Widget buildSolitaire() {
    SolitaireGame game = config.game as SolitaireGame;

    switch (game.phase) {
      case SolitairePhase.Deal:
        return showDeal();
      case SolitairePhase.Play:
        return showPlay();
      case SolitairePhase.Score:
        return showScore();
      default:
        assert(false);
        return null;
    }
  }

  NoArgCb _makeFlipCallback(int index) {
    SolitaireGame game = config.game as SolitaireGame;
    return () {
      game.flipCardUI(index);
    };
  }

  void _moveCallback(logic_card.Card card, List<logic_card.Card> collection) {
    setState(() {
      SolitaireGame game = config.game;
      String reason = game.canPlay(card, collection);
      if (reason == null) {
        game.move(card, collection);
      } else {
        print("You can't do that! ${reason}");
        game.debugString = reason;
      }
    });
  }

  Widget showPlay() {
    SolitaireGame game = config.game as SolitaireGame;

    double cardSize = config.width / 8.0;

    List<Widget> row1 = new List<Widget>();
    List<CardCollectionComponent> aces = [0, 1, 2, 3].map((int i) {
      return new CardCollectionComponent(
          game.cardCollections[SolitaireGame.OFFSET_ACES + i],
          true,
          CardCollectionOrientation.show1,
          widthCard: cardSize,
          heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card,
          useKeys: true);
    }).toList();
    row1.add(new Row(aces));

    row1.add(new Row([
      new CardCollectionComponent(
          game.cardCollections[SolitaireGame.OFFSET_DISCARD],
          true,
          CardCollectionOrientation.show1,
          widthCard: cardSize,
          heightCard: cardSize,
          dragChildren: true,
          useKeys: true),
      new InkWell(
          child: new CardCollectionComponent(
              game.cardCollections[SolitaireGame.OFFSET_DRAW],
              false,
              CardCollectionOrientation.show1,
              widthCard: cardSize,
              heightCard: cardSize,
              useKeys: true),
          onTap: game.canDrawCard ? game.drawCardUI : null),
    ]));

    List<Widget> row2 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row2.add(new InkWell(
          child: new CardCollectionComponent(
              game.cardCollections[SolitaireGame.OFFSET_DOWN + i],
              false,
              CardCollectionOrientation.show1,
              widthCard: cardSize,
              heightCard: cardSize,
              useKeys: true),
          onTap: game.cardCollections[SolitaireGame.OFFSET_UP + i].length == 0
              ? _makeFlipCallback(i)
              : null));
    }
    List<Widget> row3 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row3.add(new CardCollectionComponent(
          game.cardCollections[SolitaireGame.OFFSET_UP + i],
          true,
          CardCollectionOrientation.vert,
          widthCard: cardSize,
          heightCard: cardSize,
          height: config.height * 0.6,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card,
          useKeys: true));
    }

    return new Column([
      new Row(row1, justifyContent: FlexJustifyContent.spaceBetween),
      new Row(row2, justifyContent: FlexJustifyContent.spaceBetween),
      new Row(row3, justifyContent: FlexJustifyContent.spaceBetween),
      _makeDebugButtons()
    ]);
  }

  Widget showScore() {
    SolitaireGame game = config.game as SolitaireGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton("Return to Lobby", _quitGameCallback),
          _makeDebugButtons()
        ], direction: FlexDirection.vertical));
  }

  Widget showDeal() {
    SolitaireGame game = config.game as SolitaireGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCardsUI),
          _makeDebugButtons()
        ],
            direction: FlexDirection.vertical,
            justifyContent: FlexJustifyContent.spaceBetween));
  }
}
