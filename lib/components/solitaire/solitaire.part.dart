// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game_component;

class SolitaireGameComponent extends GameComponent {
  SolitaireGameComponent(NavigatorState navigator, Game game, NoArgCb cb,
      {double width, double height})
      : super(navigator, game, cb, width: width, height: height);

  SolitaireGameComponentState createState() => new SolitaireGameComponentState();
}

class SolitaireGameComponentState extends GameComponentState<SolitaireGameComponent> {
  @override
  Widget build(BuildContext context) {
    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.grey[300]),
        child: buildSolitaire());
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
    row1.add(new Row([
      new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_ACES + 0], true, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card),
      new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_ACES + 1], true, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card),
      new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_ACES + 2], true, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card),
      new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_ACES + 3], true, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card),
    ]));

    row1.add(new Row([
      new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_DISCARD], true, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize,
          dragChildren: true),
      new InkWell(
        child: new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_DRAW], false, Orientation.show1,
        widthCard: cardSize, heightCard: cardSize),
        onTap: game.canDrawCard ? game.drawCardUI : null
      ),
    ]));

    List<Widget> row2 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row2.add(
        new InkWell(
          child: new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_DOWN + i], false, Orientation.show1, widthCard: cardSize, heightCard: cardSize),
          onTap: game.cardCollections[SolitaireGame.OFFSET_UP + i].length == 0 ? _makeFlipCallback(i) : null
        )
      );
    }
    List<Widget> row3 = new List<Widget>();
    for (int i = 0; i < 7; i++) {
      row3.add(
        new CardCollectionComponent(config.navigator, game.cardCollections[SolitaireGame.OFFSET_UP + i], true, Orientation.vert,
          widthCard: cardSize, heightCard: cardSize, height: config.height * 0.6,
          acceptCallback: _moveCallback,
          dragChildren: true,
          acceptType: DropType.card)
      );
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
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton("Return to Lobby", _quitGameCallback),
          _makeDebugButtons()
        ], direction: FlexDirection.vertical));
  }

  Widget showDeal() {
    SolitaireGame game = config.game as SolitaireGame;

    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: material.Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          _makeButton('Deal', game.dealCardsUI),
          _makeDebugButtons()
        ],
            direction: FlexDirection.vertical,
            justifyContent: FlexJustifyContent.spaceBetween));
  }
}
