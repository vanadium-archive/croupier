// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game_component;

class SolitaireGameComponent extends GameComponent {
  SolitaireGameComponent(Croupier croupier, SoundAssets sounds, VoidCallback cb,
      {Key key, double width, double height})
      : super(croupier, sounds, cb, key: key, width: width, height: height);

  @override
  SolitaireGameComponentState createState() =>
      new SolitaireGameComponentState();
}

class SolitaireGameComponentState
    extends GameComponentState<SolitaireGameComponent> {
  @override
  Widget build(BuildContext context) {
    SolitaireGame game = config.game as SolitaireGame;

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
    if (game.phase == SolitairePhase.play) {
      // All cards are visible.
      List<int> visibleCardCollectionIndexes =
          game.cardCollections.asMap().keys.toList();

      children.add(this.buildCardAnimationLayer(visibleCardCollectionIndexes));
    }

    return new Container(
        width: config.width,
        height: config.height,
        child: new Stack(children: children));
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

  Widget _makeDebugButtons() {
    if (config.game.debugMode == false) {
      return new Row(children: [
        new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
      ]);
    }
    return new Row(children: [
      new Flexible(flex: 1, child: new Text('P${config.game.playerNumber}')),
      new Flexible(flex: 5, child: _makeButton('Cheat', _cheatCallback)),
      new Flexible(
          flex: 5, child: _makeButton('End Round', _endRoundDebugCallback)),
      new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
    ]);
  }

  @override
  Widget _makeButton(String text, VoidCallback callback,
      {bool inactive: false}) {
    var borderColor = inactive ? Colors.grey[500] : Colors.white;
    var backgroundColor = inactive ? Colors.grey[500] : null;
    return new FlatButton(
        child: new Container(
            decoration: new BoxDecoration(
                border: new Border.all(width: 1.0, color: borderColor),
                backgroundColor: backgroundColor),
            padding: new EdgeInsets.all(10.0),
            child: new Text(text)),
        onPressed: inactive ? null : callback);
  }

  Widget buildSolitaire() {
    SolitaireGame game = config.game as SolitaireGame;

    switch (game.phase) {
      case SolitairePhase.deal:
        return showDeal();
      case SolitairePhase.play:
        return showPlay();
      case SolitairePhase.score:
        return showScore();
      default:
        assert(false);
        return null;
    }
  }

  VoidCallback _makeFlipCallback(int index) {
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
        print("You can't do that! $reason");
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
          game.cardCollections[SolitaireGame.offsetAces + i],
          true,
          CardCollectionOrientation.show1,
          widthCard: cardSize,
          heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card,
          useKeys: true);
    }).toList();
    row1.add(new Row(children: aces));

    row1.add(new Row(children: [
      new CardCollectionComponent(
          game.cardCollections[SolitaireGame.offsetDiscard],
          true,
          CardCollectionOrientation.show1,
          widthCard: cardSize,
          heightCard: cardSize,
          dragChildren: true,
          useKeys: true),
      new GestureDetector(
          child: new CardCollectionComponent(
              game.cardCollections[SolitaireGame.offsetDraw],
              false,
              CardCollectionOrientation.show1,
              widthCard: cardSize,
              heightCard: cardSize,
              useKeys: true),
          onTap: game.canDrawCard ? game.drawCardUI : null),
    ]));

    List<Widget> row2 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row2.add(new GestureDetector(
          child: new CardCollectionComponent(
              game.cardCollections[SolitaireGame.offsetDown + i],
              false,
              CardCollectionOrientation.show1,
              widthCard: cardSize,
              heightCard: cardSize,
              useKeys: true),
          onTap: game.cardCollections[SolitaireGame.offsetUp + i].length == 0
              ? _makeFlipCallback(i)
              : null));
    }
    List<Widget> row3 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row3.add(new CardCollectionComponent(
          game.cardCollections[SolitaireGame.offsetUp + i],
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

    return new Column(children: [
      new Row(
          children: row1, mainAxisAlignment: MainAxisAlignment.spaceBetween),
      new Row(
          children: row2, mainAxisAlignment: MainAxisAlignment.spaceBetween),
      new Row(
          children: row3, mainAxisAlignment: MainAxisAlignment.spaceBetween),
      _makeDebugButtons()
    ]);
  }

  Widget showScore() {
    SolitaireGame game = config.game as SolitaireGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Column(children: [
          new Text('Player ${game.playerNumber}'),
          _makeButton("Return to Lobby", _quitGameCallback),
          _makeDebugButtons()
        ]));
  }

  Widget showDeal() {
    SolitaireGame game = config.game as SolitaireGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Column(children: [
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCardsUI),
          _makeDebugButtons()
        ], mainAxisAlignment: MainAxisAlignment.spaceBetween));
  }
}
