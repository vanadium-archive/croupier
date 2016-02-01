// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../logic/card.dart' as logic_card;
import '../logic/croupier.dart' show Croupier;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase;
import '../sound/sound_assets.dart';
import '../styles/common.dart' as style;
import 'card.dart' as component_card;
import 'card_collection.dart'
    show CardCollectionComponent, CardCollectionOrientation, DropType, AcceptCb;
import 'croupier_profile.dart' show CroupierProfileComponent;

const double defaultBoardHeight = 400.0;
const double defaultBoardWidth = 400.0;
const double defaultCardHeight = 40.0;
const double defaultCardWidth = 40.0;

/// A Board represents a fixed-size canvas for drawing a Game's UI.
/// While other Widgets may be drawn to accomodate space, a Board is meant to
/// consume a specific amount of space on the screen, which allows for more
/// control when positioning elements within the Board's area.
abstract class Board extends StatefulComponent {
  final Game game;
  final double _height;
  final double _width;
  final double _cardHeight;
  final double _cardWidth;

  double get height => _height ?? defaultBoardHeight;
  double get width => _width ?? defaultBoardWidth;
  double get cardHeight => _cardHeight ?? defaultCardHeight;
  double get cardWidth => _cardWidth ?? defaultCardWidth;

  Board(this.game,
      {double height, double width, double cardHeight, double cardWidth})
      : _height = height,
        _width = width,
        _cardHeight = cardHeight,
        _cardWidth = cardWidth;
}

/// The HeartsBoard represents the Hearts table view, which shows the number of
/// cards each player has, and the cards they are currently playing.
class HeartsBoard extends Board {
  final Croupier croupier;
  final SoundAssets sounds;
  final bool isMini;
  final AcceptCb gameAcceptCallback;
  final VoidCallback setGameStateCallback;
  final List<logic_card.Card> bufferedPlay;

  HeartsGame get game => super.game;

  HeartsBoard(Croupier croupier, this.sounds,
      {double height,
      double width,
      double cardHeight,
      double cardWidth,
      this.isMini: false,
      this.gameAcceptCallback,
      this.setGameStateCallback,
      this.bufferedPlay})
      : super(croupier.game,
            height: height,
            width: width,
            cardHeight: cardHeight,
            cardWidth: cardWidth),
        croupier = croupier {
    assert(this.game is HeartsGame);
  }

  HeartsBoardState createState() => new HeartsBoardState();
}

class HeartsBoardState extends State<HeartsBoard> {
  static const double PROFILE_SIZE = 0.17; // multiplier of config.height

  // Every time the counter changes, a sound will be played.
  // For example, in the pass/take phase, the counter does this:
  // 0->1->2->3->4->3->2->1->0.
  // We play 4 whooshIn sounds followed by 4 whooshOut sounds upon detecting
  // the change. Each sound only occurs during the very first build (the first
  // opportunity to detect the change).
  // In the play phase, we have this instead: 0->1->2->3->4->0
  // This 5-cycle is 4 played cards (whooshIn) and 1 take trick (whooshOut).
  int cardCounter = 0;
  bool passing = true;

  // Used to hide the cards played until it has been incremented enough.
  int localAsking = 0;

  void _handleCardCounterSounds() {
    // Ensure we have the right state while we deal and score.
    if (config.game.phase == HeartsPhase.deal ||
        config.game.phase == HeartsPhase.score) {
      cardCounter = 0;
      passing = true;
    }

    // Passing
    if (passing) {
      // If it is now someone's turn, we should no longer be passing.
      if (config.game.whoseTurn != null) {
        passing = false;

        // Special: Play a sound for the last take command of the pass phase.
        if (cardCounter > 0) {
          cardCounter = 0;
          _playSoundOut();
        }
        return;
      }

      // Passing: If somebody passed cards recently...
      if (config.game.numPassed > cardCounter) {
        cardCounter = config.game.numPassed;
        _playSoundIn();
        return;
      }

      // Passing: If somebody took cards recently...
      if (config.game.numPassed < cardCounter) {
        cardCounter = config.game.numPassed;
        _playSoundOut();
        return;
      }
      return;
    }

    // Playing: If somebody played a card...
    if (config.game.numPlayed > cardCounter) {
      cardCounter = config.game.numPlayed;
      _playSoundIn();
      return;
    }

    // Playing: If somebody took the trick...
    if (config.game.numPlayed == 0 && cardCounter != 0) {
      cardCounter = 0;
      _playSoundOut();
    }
  }

  void _playSoundIn() {
    if (!config.isMini) {
      config.sounds.play("whooshIn");
    }
  }

  void _playSoundOut() {
    if (!config.isMini) {
      config.sounds.play("whooshOut");
    }
  }

  Widget build(BuildContext context) {
    double offscreenDelta = config.isMini ? 5.0 : 1.5;

    _handleCardCounterSounds();
    _handleLocalAskingReset();

    Widget boardChild;
    if (config.game.phase == HeartsPhase.play) {
      boardChild =
          config.isMini ? _buildMiniBoardLayout() : _buildBoardLayout();
    } else {
      boardChild = _buildPassLayout();
    }

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack(children: [
          new Positioned(top: 0.0, left: 0.0, child: boardChild),
          new Positioned(
              top: config.height * (offscreenDelta + 0.5),
              left: (config.width - config.cardWidth) / 2,
              child: _buildOffScreenCards(
                  config.isMini ? rotateByGamePlayerNumber(0) : 0)), // bottom
          new Positioned(
              top: (config.height - config.cardHeight) / 2,
              left: config.width * (-offscreenDelta + 0.5),
              child: _buildOffScreenCards(
                  config.isMini ? rotateByGamePlayerNumber(1) : 1)), // left
          new Positioned(
              top: config.height * (-offscreenDelta + 0.5),
              left: (config.width - config.cardWidth) / 2,
              child: _buildOffScreenCards(
                  config.isMini ? rotateByGamePlayerNumber(2) : 2)), // top
          new Positioned(
              top: (config.height - config.cardHeight) / 2,
              left: config.width * (offscreenDelta + 0.5),
              child: _buildOffScreenCards(
                  config.isMini ? rotateByGamePlayerNumber(3) : 3)) // right
        ]));
  }

  int rotateByGamePlayerNumber(int i) {
    return (i + config.game.playerNumber) % 4;
  }

  static Map<int, String> passBackgrounds = const <int, String>{
    0: "images/games/hearts/pass_right.png",
    1: "images/games/hearts/pass_left.png",
    2: "images/games/hearts/pass_across.png",
    3: "",
  };

  Widget _buildPassLayout() {
    String passBackground = ""; // It's possible to have no background.
    if (config.game.phase == HeartsPhase.pass ||
        config.game.phase == HeartsPhase.take) {
      passBackground = passBackgrounds[config.game.roundNumber % 4];
    }

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack(children: [
          new Positioned(
              top: 0.0,
              left: 0.0,
              child: new AssetImage(
                  name: passBackground,
                  height: config.height,
                  width: config.width)),
          new Positioned(top: 0.0, left: 0.0, child: _buildPassLayoutInternal())
        ]));
  }

  double _rotationAngle(int pNum) {
    return pNum * math.PI / 2;
  }

  Widget _rotate(Widget w, int pNum) {
    return new Transform(
        child: w,
        transform:
            new vector_math.Matrix4.identity().rotateZ(_rotationAngle(pNum)),
        alignment: new FractionalOffset(0.5, 0.5));
  }

  Widget _getPass(int playerNumber) {
    double sizeRatio = 0.10;
    double cccSize = math.min(sizeRatio * config.width, config.cardWidth * 3.5);

    HeartsGame game = config.game;
    List<logic_card.Card> cardsToTake = [];
    int takeTarget = game.getTakeTarget(playerNumber);
    if (takeTarget != null) {
      cardsToTake = game.cardCollections[
          game.getTakeTarget(playerNumber) + HeartsGame.offsetPass];
    }

    bool isHorz = playerNumber % 2 == 0;
    CardCollectionOrientation ori = isHorz
        ? CardCollectionOrientation.horz
        : CardCollectionOrientation.vert;
    return new CardCollectionComponent(cardsToTake, false, ori,
        backgroundColor: style.transparentColor,
        width: isHorz ? cccSize : null,
        height: isHorz ? null : cccSize,
        widthCard: config.cardWidth,
        heightCard: config.cardHeight,
        rotation: playerNumber * math.PI / 2,
        useKeys: true);
  }

  Widget _getProfile(int pNum, double sizeFactor) {
    return new CroupierProfileComponent.horizontal(
        settings: config.croupier.settingsFromPlayerNumber(pNum));
  }

  Widget _playerProfile(int pNum, double sizeFactor) {
    return _rotate(_getProfile(pNum, sizeFactor), pNum);
  }

  Widget _buildPassLayoutInternal() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Column(
            children: [
          new Flexible(child: _playerProfile(2, PROFILE_SIZE), flex: 0),
          new Flexible(child: _getPass(2), flex: 0),
          new Flexible(
              child: new Row(
                  children: [
                new Flexible(child: _playerProfile(1, PROFILE_SIZE), flex: 0),
                new Flexible(child: _getPass(1), flex: 0),
                new Flexible(child: new Block(children: []), flex: 1),
                new Flexible(child: _getPass(3), flex: 0),
                new Flexible(child: _playerProfile(3, PROFILE_SIZE), flex: 0)
              ],
                  alignItems: FlexAlignItems.center,
                  justifyContent: FlexJustifyContent.spaceAround),
              flex: 1),
          new Flexible(child: _getPass(0), flex: 0),
          new Flexible(child: _playerProfile(0, PROFILE_SIZE), flex: 0)
        ],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround));
  }

  Widget _buildMiniBoardLayout() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Center(
            child: new Row(children: [
          new Flexible(
              flex: 1,
              child: new Center(
                  child: _buildAvatarSlotCombo(rotateByGamePlayerNumber(1)))),
          new Flexible(
              flex: 1,
              child: new Column(children: [
                new Flexible(
                    flex: 1,
                    child: _buildAvatarSlotCombo(rotateByGamePlayerNumber(2))),
                new Flexible(
                    flex: 1,
                    child: _buildAvatarSlotCombo(rotateByGamePlayerNumber(0)))
              ])),
          new Flexible(
              flex: 1,
              child: new Center(
                  child: _buildAvatarSlotCombo(rotateByGamePlayerNumber(3))))
        ])));
  }

  Widget _buildAvatarSlotCombo(int playerNumber) {
    HeartsGame game = config.game;
    int p = game.playerNumber;

    List<Widget> items = new List<Widget>();
    bool isMe = playerNumber == p;

    List<logic_card.Card> showCard =
        game.cardCollections[playerNumber + HeartsGame.offsetPlay];
    bool hasPlayed = showCard.length > 0;
    bool isTurn = playerNumber == game.whoseTurn && !hasPlayed;
    if (isMe && config.bufferedPlay != null) {
      showCard = config.bufferedPlay;
    }

    items.add(new Positioned(
        top: 0.0,
        left: 0.0,
        child: new CardCollectionComponent(
            showCard, true, CardCollectionOrientation.show1,
            useKeys: true,
            acceptCallback: config.gameAcceptCallback,
            acceptType: isMe && !hasPlayed ? DropType.card : DropType.none,
            widthCard: config.cardWidth - 6.0,
            heightCard: config.cardHeight - 6.0,
            backgroundColor:
                isTurn ? style.theme.accentColor : Colors.grey[500],
            altColor: isTurn ? Colors.grey[200] : Colors.grey[600])));

    if (!hasPlayed) {
      items.add(new Positioned(
          top: 0.0,
          left: 0.0,
          child: new IgnorePointer(
              child: new CroupierProfileComponent.mini(
                  settings:
                      config.croupier.settingsFromPlayerNumber(playerNumber),
                  height: config.cardHeight,
                  width: config.cardWidth))));
    }

    return new Container(
        width: config.cardWidth,
        height: config.cardHeight,
        child: new Stack(children: items));
  }

  Widget _showTrickText(int pNum) {
    HeartsGame game = config.game;

    int numTrickCards =
        game.cardCollections[HeartsGame.offsetTrick + pNum].length;
    int numTricks = numTrickCards ~/ 4;

    String s = numTricks != 1 ? "s" : "";

    return _rotate(new Text("${numTricks} trick${s}"), pNum);
  }

  void _handleLocalAskingReset() {
    // If the trick was taken, we can reset localAsking.
    if (config.game.numPlayed == 0) {
      localAsking = 0;
    }
  }

  bool _incrementLocalAsking() {
    if (localAsking < config.game.numPlayed) {
      setState(() {
        localAsking++;
        if (config.setGameStateCallback != null) {
          config.setGameStateCallback(); // Required for ZCards to redraw.
        }
      });
      return true;
    }
    return false;
  }

  void _boardLayoutTapCb() {
    // You can tap anywhere on the board to fake "Ask" or "Take Trick".
    if (localAsking < 4) {
      // Try to increment. If it fails, be lenient! Give 0.5 seconds to check
      // this condition again.
      if (!_incrementLocalAsking()) {
        new Future.delayed(const Duration(milliseconds: 500), () {
          _incrementLocalAsking(); // give it one more shot
        });
      }
    } else {
      config.game.takeTrickUI();
    }
  }

  Widget _buildBoardLayout() {
    int activePlayer = config.game.allPlayed
        ? config.game.determineTrickWinner()
        : config.game.whoseTurn;

    return new GestureDetector(
        onTap: _boardLayoutTapCb,
        child: new Container(
            height: config.height,
            width: config.width,
            decoration: new BoxDecoration(
                border: new Border(
                    top: new BorderSide(
                        color: activePlayer == 2
                            ? style.theme.accentColor
                            : style.transparentColor,
                        width: 5.0),
                    right: new BorderSide(
                        color: activePlayer == 3
                            ? style.theme.accentColor
                            : style.transparentColor,
                        width: 5.0),
                    left: new BorderSide(
                        color: activePlayer == 1
                            ? style.theme.accentColor
                            : style.transparentColor,
                        width: 5.0),
                    bottom: new BorderSide(
                        color: activePlayer == 0
                            ? style.theme.accentColor
                            : style.transparentColor,
                        width: 5.0))),
            child: new Column(
                children: [
              new Flexible(child: _playerProfile(2, PROFILE_SIZE), flex: 0),
              new Flexible(child: _showTrickText(2), flex: 0),
              new Flexible(
                  child: new Row(
                      children: [
                    new Flexible(
                        child: _playerProfile(1, PROFILE_SIZE), flex: 0),
                    new Flexible(child: _showTrickText(1), flex: 0),
                    new Flexible(
                        child: new Center(child: _buildCenterCards()), flex: 1),
                    new Flexible(child: _showTrickText(3), flex: 0),
                    new Flexible(
                        child: _playerProfile(3, PROFILE_SIZE), flex: 0)
                  ],
                      alignItems: FlexAlignItems.center,
                      justifyContent: FlexJustifyContent.spaceAround),
                  flex: 1),
              new Flexible(child: _showTrickText(0), flex: 0),
              new Flexible(child: _playerProfile(0, PROFILE_SIZE), flex: 0)
            ],
                alignItems: FlexAlignItems.center,
                justifyContent: FlexJustifyContent.spaceAround)));
  }

  Widget _buildCenterCards() {
    double height = config.cardHeight * this._centerScaleFactor;
    double width = config.cardWidth * this._centerScaleFactor;
    Widget centerPiece = new Container(
        height: height, width: width, child: new Block(children: []));
    if (localAsking == 4) {
      // If all cards played are revealed, show Take Trick button.
      int rotateNum = config.game.determineTrickWinner();
      double smaller = math.min(height, width);

      // TODO(alexfandrianto): The Text looks great within the square
      // container, but this is supposed to be pressable like a button.
      // The reason why I did it this way is that the button's disappearance
      // prevents the board's onTap handler from firing.
      // https://github.com/flutter/flutter/issues/1497
      centerPiece = _rotate(
          new Container(
              height: smaller,
              width: smaller,
              decoration: style.Box.liveBackground,
              child: new Center(
                  child: new Text("Take", style: style.Text.largeStyle))),
          rotateNum);
    }

    return new Column(
        children: [
      new Flexible(
          child: new Row(
              children: [
        new Flexible(child: new Block(children: [])),
        new Flexible(child: new Center(child: _buildCenterCard(2))),
        new Flexible(child: new Block(children: [])),
      ],
              alignItems: FlexAlignItems.center,
              justifyContent: FlexJustifyContent.center)),
      new Flexible(
          child: new Row(
              children: [
        new Flexible(child: new Center(child: _buildCenterCard(1))),
        new Flexible(
            child: new Row(
                children: [centerPiece],
                alignItems: FlexAlignItems.center,
                justifyContent: FlexJustifyContent.center)),
        new Flexible(child: new Center(child: _buildCenterCard(3))),
      ],
              alignItems: FlexAlignItems.center,
              justifyContent: FlexJustifyContent.center)),
      new Flexible(
          child: new Row(
              children: [
        new Flexible(child: new Block(children: [])),
        new Flexible(child: new Center(child: _buildCenterCard(0))),
        new Flexible(child: new Block(children: [])),
      ],
              alignItems: FlexAlignItems.center,
              justifyContent: FlexJustifyContent.center))
    ],
        alignItems: FlexAlignItems.center,
        justifyContent: FlexJustifyContent.center);
  }

  double get _centerScaleFactor {
    bool wide = (config.width >= config.height);
    double heightUsed = 2 * PROFILE_SIZE;

    if (wide) {
      return config.height * (1 - heightUsed) / (config.cardHeight * 4);
    } else {
      return (config.width - (1.5 * config.height * heightUsed)) /
          (config.cardWidth * 4);
    }
  }

  Widget _buildCenterCard(int playerNumber) {
    HeartsGame game = config.game;
    List<logic_card.Card> cards =
        game.cardCollections[playerNumber + HeartsGame.offsetPlay];

    // TODO(alexfandrianto): Clean up soon.
    // https://github.com/vanadium/issues/issues/1098
    //bool hasPlayed = cards.length > 0;
    //bool isTurn = game.whoseTurn == playerNumber && !hasPlayed;

    double height = config.cardHeight * this._centerScaleFactor;
    double width = config.cardWidth * this._centerScaleFactor;

    bool canShow =
        (playerNumber - config.game.lastTrickTaker) % 4 < localAsking;

    List<Widget> stackWidgets = <Widget>[
      new Positioned(
          top: 0.0,
          left: 0.0,
          child: new CardCollectionComponent(
              cards, canShow, CardCollectionOrientation.show1,
              widthCard: width - 6,
              heightCard: height - 6,
              rotation: _rotationAngle(playerNumber),
              useKeys: true))
    ];

    // TODO(alexfandrianto): Clean up soon.
    // https://github.com/vanadium/issues/issues/1098
    /*if (isTurn) {
      stackWidgets.add(new Positioned(
          top: 0.0,
          left: 0.0,
          child: _rotate(
              new Container(
                  height: height,
                  width: width,
                  child: new RaisedButton(
                      child: new Text("Play", style: style.Text.largeStyle),
                      onPressed: config.game.asking ? null : config.game.askUI,
                      color: style.theme.accentColor)),
              playerNumber)));
    }*/

    return new Container(
        height: height, width: width, child: new Stack(children: stackWidgets));
  }

  // The off-screen cards consist of trick cards and play cards.
  // When the board is mini, the player's play cards are excluded.
  Widget _buildOffScreenCards(int playerNumber) {
    HeartsGame game = config.game;

    List<logic_card.Card> cards = new List.from(
        game.cardCollections[playerNumber + HeartsGame.offsetTrick]);

    bool isPlay = game.phase == HeartsPhase.play;

    // Prevent over-expansion of cards until a card has been played.
    bool alreadyPlaying =
        (isPlay && (game.numPlayed > 0 || game.trickNumber > 0));

    double sizeFactor = 1.0;
    if (config.isMini) {
      if (playerNumber != game.playerNumber) {
        cards
            .addAll(game.cardCollections[playerNumber + HeartsGame.offsetHand]);
      }
    } else {
      cards.addAll(game.cardCollections[playerNumber + HeartsGame.offsetHand]);

      if (alreadyPlaying) {
        sizeFactor = this._centerScaleFactor;
      }
    }

    return new CardCollectionComponent(
        cards, alreadyPlaying, CardCollectionOrientation.show1,
        widthCard: config.cardWidth * sizeFactor,
        heightCard: config.cardHeight * sizeFactor,
        useKeys: true,
        rotation: config.isMini ? null : _rotationAngle(playerNumber),
        animationType: component_card.CardAnimationType.long);
  }
}
