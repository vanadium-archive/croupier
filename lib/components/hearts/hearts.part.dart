// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game_component;

class HeartsGameComponent extends GameComponent {
  HeartsGameComponent(Croupier croupier, NoArgCb cb,
      {Key key, double width, double height})
      : super(croupier, cb, key: key, width: width, height: height);

  HeartsGameComponentState createState() => new HeartsGameComponentState();
}

class HeartsGameComponentState extends GameComponentState<HeartsGameComponent> {
  List<logic_card.Card> passingCards1 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards2 = new List<logic_card.Card>();
  List<logic_card.Card> passingCards3 = new List<logic_card.Card>();

  HeartsType _lastViewType;
  bool _showSplitView = false;
  bool trickTaking = false;
  List<List<logic_card.Card>> playedCards = new List<List<logic_card.Card>>(4);

  static const int SHOW_TRICK_DURATION = 2000; // ms

  @override
  void initState() {
    super.initState();

    // If someone sat at the table, they would have the value 4.
    // If nobody sat at the table, then we should show the split view.
    if (!config.croupier.players_found.values.contains(4)) {
      _showSplitView = true;
    }
    _reset();

    _fillPlayedCards();
  }

  // Make copies of the played cards.
  void _fillPlayedCards() {
    for (int i = 0; i < 4; i++) {
      playedCards[i] = new List<logic_card.Card>.from(
          config.game.cardCollections[i + HeartsGame.OFFSET_PLAY]);
    }
  }

  // If there were 3 played cards before and now there are 0...
  bool _detectTrick() {
    HeartsGame game = config.game;
    int lastNumPlayed = playedCards.where((List<logic_card.Card> list) {
      return list.length > 0;
    }).length;
    return lastNumPlayed == 3 && game.numPlayed == 0;
  }

  // Make a copy of the missing played card.
  void _fillMissingPlayedCard() {
    HeartsGame game = config.game;
    List<logic_card.Card> trickPile =
        game.cardCollections[game.lastTrickTaker + HeartsGame.OFFSET_TRICK];

    // Find the index of the missing play card.
    int missing;
    for (int j = 0; j < 4; j++) {
      if (playedCards[j].length == 0) {
        missing = j;
        break;
      }
    }

    // Use the trickPile to get this card.
    playedCards[missing] = <logic_card.Card>[
      trickPile[trickPile.length - 4 + missing]
    ];
  }

  @override
  void _reset() {
    super._reset();
    HeartsGame game = config.game as HeartsGame;
    _lastViewType = game.viewType;
  }

  @override
  Widget build(BuildContext context) {
    HeartsGame game = config.game as HeartsGame;

    // check if we need to swap out our 's map.
    if (_lastViewType != game.viewType) {
      _reset();
    }

    // Set the trickTaking flag on each build.
    if (!trickTaking) {
      if (_detectTrick()) {
        trickTaking = true;
        _fillMissingPlayedCard();
        // Unfortunately, ZCards are drawn on the game layer,
        // so instead of setState, we must use trueSetState.
        new Future.delayed(const Duration(milliseconds: SHOW_TRICK_DURATION),
            () {
          setState(() {
            trickTaking = false;
          });
        });
      } else {
        _fillPlayedCards();
      }
    }

    // Hearts Widget
    Widget heartsWidget = new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.grey[300]),
        child: buildHearts());

    List<Widget> children = new List<Widget>();
    children.add(new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.grey[300]),
        width: config.width,
        height: config.height,
        child: heartsWidget));
    List<int> visibleCardCollectionIndexes = new List<int>();
    if (game.phase != HeartsPhase.StartGame &&
        game.phase != HeartsPhase.Deal &&
        game.phase != HeartsPhase.Score) {
      int playerNum = game.playerNumber;
      if (game.viewType == HeartsType.Player) {
        switch (game.phase) {
          case HeartsPhase.Pass:
            visibleCardCollectionIndexes
                .add(HeartsGame.OFFSET_PASS + playerNum);
            visibleCardCollectionIndexes
                .add(HeartsGame.OFFSET_HAND + playerNum);
            break;
          case HeartsPhase.Take:
            visibleCardCollectionIndexes
                .add(HeartsGame.OFFSET_PASS + game.takeTarget);
            visibleCardCollectionIndexes
                .add(HeartsGame.OFFSET_HAND + playerNum);
            break;
          case HeartsPhase.Play:
            if (_showSplitView) {
              for (int i = 0; i < 4; i++) {
                visibleCardCollectionIndexes.add(HeartsGame.OFFSET_HAND + i);
                visibleCardCollectionIndexes.add(HeartsGame.OFFSET_TRICK + i);
                visibleCardCollectionIndexes.add(HeartsGame.OFFSET_PLAY + i);
              }
            } else {
              visibleCardCollectionIndexes
                  .add(HeartsGame.OFFSET_PLAY + playerNum);
              visibleCardCollectionIndexes
                  .add(HeartsGame.OFFSET_HAND + playerNum);
            }

            break;
          default:
            break;
        }
      } else {
        // A board will need to see these things.
        for (int i = 0; i < 4; i++) {
          visibleCardCollectionIndexes.add(HeartsGame.OFFSET_PLAY + i);
          visibleCardCollectionIndexes.add(HeartsGame.OFFSET_PASS + i);
          visibleCardCollectionIndexes.add(HeartsGame.OFFSET_HAND + i);
          visibleCardCollectionIndexes.add(HeartsGame.OFFSET_TRICK + i);
        }
      }
    }
    children.add(this.buildCardAnimationLayer(visibleCardCollectionIndexes));

    return new Container(
        width: config.width, height: config.height, child: new Stack(children));
  }

  void _switchViewCallback() {
    HeartsGame game = config.game;
    setState(() {
      if (game.viewType == HeartsType.Player) {
        game.viewType = HeartsType.Board;
      } else {
        game.viewType = HeartsType.Player;
        if (!game.isPlayer) {
          game.playerNumber = 0; // avoid accidental red screen
        }
      }
    });
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

      if (dest == passingCards1) {
        passingCards1.clear();
        passingCards1.add(card);
      } else if (dest == passingCards2) {
        passingCards2.clear();
        passingCards2.add(card);
      } else if (dest == passingCards3) {
        passingCards3.clear();
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
        game.debugString = null;
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        config.game.debugString = "You must pass 3 cards";
      }
    });
  }

  void _makeGameTakeCallback() {
    setState(() {
      try {
        // TODO(alexfandrianto): Another way to clear these passing cards is to
        // do so upon the transition from the pass phase to the take phase.
        // However, since they are never seen outside of the Pass phase, it is
        // also valid to clear them upon taking any cards.
        _clearPassing();
        HeartsGame game = config.game as HeartsGame;
        game.takeCards();
        game.debugString = null;
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
        game.debugString = null;
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
      game.debugString = null;
    });
  }

  Widget _makeDebugButtons() {
    if (config.game.debugMode == false) {
      return new Flex([]);
    }
    return new Container(
        width: config.width,
        child: new Flex([
          new Flexible(
              flex: 1, child: new Text('P${config.game.playerNumber}')),
          new Flexible(
              flex: 5,
              child: _makeButton('Switch Player', _switchPlayersCallback)),
          new Flexible(
              flex: 5, child: _makeButton('Switch View', _switchViewCallback)),
          new Flexible(
              flex: 5, child: _makeButton('End Round', _endRoundDebugCallback)),
          new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
        ]));
  }

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

  Widget buildHearts() {
    HeartsGame game = config.game as HeartsGame;

    if (game.viewType == HeartsType.Board) {
      return buildHeartsBoard();
    }

    switch (game.phase) {
      case HeartsPhase.StartGame:
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

  Widget buildHeartsBoard() {
    HeartsGame game = config.game as HeartsGame;
    List<Widget> kids = new List<Widget>();
    switch (game.phase) {
      case HeartsPhase.StartGame:
      case HeartsPhase.Deal:
        kids.add(new Text("Waiting for Deal..."));
        break;
      case HeartsPhase.Pass:
      case HeartsPhase.Take:
      case HeartsPhase.Play:
        kids.add(showBoard());
        break;
      case HeartsPhase.Score:
        return showScore();
      default:
        assert(false);
        return null;
    }
    kids.add(_makeDebugButtons());
    return new Column(kids, justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showBoard() {
    return new HeartsBoard(config.croupier,
        width: config.width,
        height: 0.80 * config.height,
        trickTaking: trickTaking,
        playedCards: playedCards);
  }

  String _getName(int playerNumber) {
    return config.croupier.settingsFromPlayerNumber(playerNumber)?.name;
  }

  String _getStatus() {
    HeartsGame game = config.game;

    String status;
    switch (game.phase) {
      case HeartsPhase.Play:
        // Who's turn is it?
        String name = _getName(game.whoseTurn) ?? "Player ${game.whoseTurn}";
        status = game.whoseTurn == game.playerNumber
            ? "Your turn"
            : "${name}'s turn";

        // Override if someone is taking a trick.
        if (this.trickTaking) {
          String trickTaker =
              _getName(game.lastTrickTaker) ?? "Player ${game.lastTrickTaker}";
          status = game.lastTrickTaker == game.playerNumber
              ? "Your trick"
              : "${trickTaker}'s trick";
        }
        break;
      case HeartsPhase.Pass:
        if (game.hasPassed(game.playerNumber)) {
          status = "Waiting for cards...";
        } else {
          String name =
              _getName(game.passTarget) ?? "Player ${game.passTarget}";
          status = "Pass to ${name}";
        }
        break;
      case HeartsPhase.Take:
        if (game.hasTaken(game.playerNumber)) {
          status = "Waiting for other players...";
        } else {
          String name =
              _getName(game.takeTarget) ?? "Player ${game.takeTarget}";
          status = "Take from ${name}";
        }
        break;
      default:
        break;
    }

    // Override if there is a debug string.
    if (config.game.debugString != null) {
      status = config.game.debugString;
    }

    return status;
  }

  Widget _buildStatusBar() {
    HeartsGame game = config.game;

    List<Widget> statusWidgets = new List<Widget>();
    statusWidgets.add(new Text(_getStatus(), style: style.Text.largeStyle));

    switch (game.phase) {
      case HeartsPhase.Play:
        statusWidgets
            .add(new IconButton(icon: "action/swap_vert", onPressed: () {
          setState(() {
            _showSplitView = !_showSplitView;
          });
        }));
        break;
      case HeartsPhase.Pass:
      case HeartsPhase.Take:
        // TODO(alexfandrianto): Icons for arrow_upward and arrow_downward were
        // just added to the material icon list. However, they are not available
        // through Flutter yet.
        double rotationAngle = 0.0; // right
        switch (game.roundNumber % 4) {
          case 1:
            rotationAngle = math.PI; // left
            break;
          case 2:
            rotationAngle = -math.PI / 2; // up
            break;
        }
        if (game.phase == HeartsPhase.Take) {
          rotationAngle = rotationAngle + math.PI; // opposite
        }
        statusWidgets.add(new Transform(
            transform:
                new vector_math.Matrix4.identity().rotateZ(rotationAngle),
            alignment: new FractionalOffset(0.5, 0.5),
            child: new Icon(icon: "navigation/arrow_forward")));
        break;
      default:
        break;
    }

    return new Container(
        padding: new EdgeDims.all(10.0),
        decoration:
            new BoxDecoration(backgroundColor: style.theme.primaryColor),
        child: new Row(statusWidgets,
            justifyContent: FlexJustifyContent.spaceBetween));
  }

  Widget _buildFullMiniBoard() {
    return new Container(
        width: config.width * 0.5,
        height: config.height * 0.25,
        child: new HeartsBoard(config.croupier,
            width: config.width * 0.5,
            height: config.height * 0.25,
            cardWidth: config.height * 0.1,
            cardHeight: config.height * 0.1,
            isMini: true,
            gameAcceptCallback: _makeGameMoveCallback,
            trickTaking: trickTaking,
            playedCards: playedCards));
  }

  Widget showPlay() {
    HeartsGame game = config.game as HeartsGame;
    int p = game.playerNumber;

    List<Widget> cardCollections = new List<Widget>();

    if (_showSplitView) {
      cardCollections.add(new Container(
          decoration:
              new BoxDecoration(backgroundColor: style.theme.primaryColor),
          child: new Column([_buildFullMiniBoard(), _buildStatusBar()])));
    } else {
      Widget playArea = new Container(
          decoration: new BoxDecoration(backgroundColor: Colors.teal[500]),
          width: config.width,
          child: new Center(
              child: new CardCollectionComponent(
                  game.cardCollections[p + HeartsGame.OFFSET_PLAY],
                  true,
                  CardCollectionOrientation.show1,
                  useKeys: true,
                  acceptCallback: _makeGameMoveCallback,
                  acceptType:
                      p == game.whoseTurn ? DropType.card : DropType.none,
                  backgroundColor:
                      p == game.whoseTurn ? Colors.white : Colors.grey[500],
                  altColor: p == game.whoseTurn
                      ? Colors.grey[200]
                      : Colors.grey[600])));

      cardCollections.add(new Container(
          decoration:
              new BoxDecoration(backgroundColor: style.theme.primaryColor),
          child: new BlockBody([_buildStatusBar(), playArea])));
    }

    List<logic_card.Card> cards = game.cardCollections[p];
    CardCollectionComponent c = new CardCollectionComponent(
        cards, game.playerNumber == p, CardCollectionOrientation.suit,
        dragChildren: true, // Can drag, but may not have anywhere to drop
        comparator: _compareCards,
        width: config.width,
        useKeys: true);
    cardCollections.add(new BlockBody([c, _makeDebugButtons()]));

    return new Column(cardCollections,
        justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget showScore() {
    HeartsGame game = config.game as HeartsGame;

    Widget w;
    if (game.hasGameEnded) {
      w = new Text("Game Over!");
    } else if (!game.isPlayer || game.ready[game.playerNumber]) {
      w = new Text("Waiting for other players...");
    } else {
      w = _makeButton('New Round', game.setReadyUI);
    }

    bool isTall = MediaQuery.of(context).orientation == Orientation.portrait;
    FlexDirection crossDirection =
        isTall ? FlexDirection.horizontal : FlexDirection.vertical;
    FlexDirection mainDirection =
        isTall ? FlexDirection.vertical : FlexDirection.horizontal;
    TextStyle bigStyle = isTall ? style.Text.hugeStyle : style.Text.largeStyle;
    TextStyle bigRedStyle =
        isTall ? style.Text.hugeRedStyle : style.Text.largeRedStyle;

    List<Widget> scores = new List<Widget>();
    scores.add(new Flexible(
        child: new Flex([
          new Flexible(
              child: new Center(child: new Text("Score:", style: bigStyle)),
              flex: 1),
          new Flexible(
              child: new Center(child: new Text("Round", style: bigStyle)),
              flex: 1),
          new Flexible(
              child: new Center(child: new Text("Total", style: bigStyle)),
              flex: 1)
        ], direction: crossDirection),
        flex: 1));
    for (int i = 0; i < 4; i++) {
      bool isMaxForRound =
          game.deltaScores.reduce(math.max) == game.deltaScores[i];
      bool isMaxOverall = game.scores.reduce(math.max) == game.scores[i];

      TextStyle deltaStyle = isMaxForRound ? bigRedStyle : bigStyle;
      TextStyle scoreStyle = isMaxOverall ? bigRedStyle : bigStyle;

      scores.add(new Flexible(
          child: new Flex([
            new Flexible(
                child: new CroupierProfileComponent(
                    settings: config.croupier.settingsFromPlayerNumber(i)),
                flex: 1),
            new Flexible(
                child: new Center(
                    child:
                        new Text("${game.deltaScores[i]}", style: deltaStyle)),
                flex: 1),
            new Flexible(
                child: new Center(
                    child: new Text("${game.scores[i]}", style: scoreStyle)),
                flex: 1)
          ], direction: crossDirection),
          flex: 2));
    }
    return new Column([
      new Flexible(child: new Flex(scores, direction: mainDirection), flex: 5),
      new Flexible(
          child: new Row([w, _makeButton("Return to Lobby", _quitGameCallback)],
              justifyContent: FlexJustifyContent.spaceAround),
          flex: 1),
      new Flexible(child: new Row([_makeDebugButtons()]), flex: 1)
    ]);
  }

  Widget showDeal() {
    HeartsGame game = config.game as HeartsGame;

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Flex([
          new Text('Player ${game.playerNumber}'),
          new Text('Waiting for Deal...'),
          _makeDebugButtons()
        ],
            direction: FlexDirection.vertical,
            justifyContent: FlexJustifyContent.spaceBetween));
  }

  Widget _helpPassTake(
      String name,
      List<logic_card.Card> c1,
      List<logic_card.Card> c2,
      List<logic_card.Card> c3,
      List<logic_card.Card> hand,
      AcceptCb cb,
      NoArgCb buttoncb) {
    bool draggable = (cb != null);
    bool completed = (buttoncb == null);

    List<Widget> topCardWidgets = new List<Widget>();
    topCardWidgets.add(_topCardWidget(c1, cb));
    topCardWidgets.add(_topCardWidget(c2, cb));
    topCardWidgets.add(_topCardWidget(c3, cb));
    topCardWidgets.add(_makeButton(name, buttoncb, inactive: completed));

    Color bgColor = completed ? Colors.teal[600] : Colors.teal[500];

    Widget statusBar = _buildStatusBar();

    Widget topArea = new Container(
        decoration: new BoxDecoration(backgroundColor: bgColor),
        padding: new EdgeDims.all(10.0),
        width: config.width,
        child: new Flex(topCardWidgets,
            justifyContent: FlexJustifyContent.spaceBetween));
    Widget combinedTopArea = new BlockBody([statusBar, topArea]);

    Widget handArea = new CardCollectionComponent(
        hand, true, CardCollectionOrientation.suit,
        dragChildren: draggable,
        comparator: _compareCards,
        width: config.width,
        acceptCallback: cb,
        acceptType: cb != null ? DropType.card : null,
        backgroundColor: Colors.grey[500],
        altColor: Colors.grey[700],
        useKeys: true);

    Widget combinedBottomArea = new BlockBody([handArea, _makeDebugButtons()]);

    return new Column(<Widget>[combinedTopArea, combinedBottomArea],
        justifyContent: FlexJustifyContent.spaceBetween);
  }

  Widget _topCardWidget(List<logic_card.Card> cards, AcceptCb cb) {
    Widget ccc = new CardCollectionComponent(
        cards, true, CardCollectionOrientation.show1,
        dragChildren: cb != null,
        acceptCallback: cb,
        acceptType: cb != null ? DropType.card : null,
        backgroundColor: Colors.white,
        altColor: Colors.grey[200],
        useKeys: true);

    if (cb == null) {
      ccc = new Container(child: ccc);
    }

    return ccc;
  }

  // Pass Phase Screen: Show the cards being passed and the player's remaining cards.
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

    return _helpPassTake(
        "Pass",
        passingCards1,
        passingCards2,
        passingCards3,
        remainingCards,
        _uiPassCardCallback,
        hasPassed ? null : _makeGamePassCallback);
  }

  // Take Phase Screen: Show the cards the player has received and the player's hand.
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

    return _helpPassTake("Take", take1, take2, take3, playerCards, null,
        hasTaken ? null : _makeGameTakeCallback);
  }
}

class HeartsArrangeComponent extends GameArrangeComponent {
  HeartsArrangeComponent(Croupier croupier, {double width, double height})
      : super(croupier, width: width, height: height);

  bool get hasSat => croupier.game.playerNumber != null;

  Widget build(BuildContext context) {
    int numAtTable = croupier.players_found.values
        .where((int playerNumber) => playerNumber == 4)
        .length;

    return new Container(
        decoration: style.Box.liveNow,
        height: height,
        width: width,
        child: new Column([
          new Flexible(
              flex: 1,
              child: new Row(
                  [_buildEmptySlot(), _buildSlot("Player", 2), _buildEmptySlot()],
                  justifyContent: FlexJustifyContent.spaceAround,
                  alignItems: FlexAlignItems.stretch)),
          new Flexible(
              flex: 1,
              child: new Row([
                _buildSlot("Player", 1),
                _buildSlot("Table: ${numAtTable}", 4),
                _buildSlot("Player", 3)
              ],
                  justifyContent: FlexJustifyContent.spaceAround,
                  alignItems: FlexAlignItems.stretch)),
          new Flexible(
              flex: 1,
              child: new Row(
                  [_buildEmptySlot(), _buildSlot("Player", 0), _buildEmptySlot()],
                  justifyContent: FlexJustifyContent.spaceAround,
                  alignItems: FlexAlignItems.stretch))
        ],
            justifyContent: FlexJustifyContent.spaceAround,
            alignItems: FlexAlignItems.stretch));
  }

  Widget _buildEmptySlot() {
    return new Flexible(flex: 1, child: new Text(""));
  }

  Widget _buildSlot(String name, int index) {
    NoArgCb onTap = () {
      croupier.settings_manager.setPlayerNumber(croupier.game.gameID, index);
      HeartsGame game = croupier.game;
      game.playerNumber = index;
      game.setReadyUI();
    };
    Widget slotWidget = new Text(name, style: style.Text.hugeStyle);

    bool seatTaken =
        index >= 0 && index < 4 && croupier.players_found.containsValue(index);
    if (seatTaken) {
      onTap = null;
      slotWidget = new CroupierProfileComponent(
          settings: croupier.settingsFromPlayerNumber(index));
    } else if (hasSat) {
      onTap = null;
    }

    return new Flexible(
        flex: 1,
        child: new GestureDetector(
            child: new Card(
                color: croupier.game.playerNumber == index
                    ? style.theme.accentColor
                    : null,
                child: slotWidget),
            onTap: onTap));
  }
}
