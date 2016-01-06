// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../logic/card.dart' as logic_card;
import '../logic/croupier.dart' show Croupier;
import '../logic/game/game.dart' show Game, GameType, NoArgCb;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase;
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
  final bool isMini;
  final AcceptCb gameAcceptCallback;
  final List<logic_card.Card> bufferedPlay;

  HeartsGame get game => super.game;

  HeartsBoard(Croupier croupier,
      {double height,
      double width,
      double cardHeight,
      double cardWidth,
      this.isMini: false,
      this.gameAcceptCallback,
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
  Widget build(BuildContext context) {
    double offscreenDelta = config.isMini ? 5.0 : 1.5;

    Widget boardChild;
    if (config.game.phase == HeartsPhase.Play) {
      boardChild =
          config.isMini ? _buildMiniBoardLayout() : _buildBoardLayout();
    } else {
      boardChild = _buildPassLayout();
    }

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack([
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
    if (config.game.phase == HeartsPhase.Pass ||
        config.game.phase == HeartsPhase.Take) {
      passBackground = passBackgrounds[config.game.roundNumber % 4];
    }

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack([
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
          game.getTakeTarget(playerNumber) + HeartsGame.OFFSET_PASS];
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
    return new CroupierProfileComponent(
        settings: config.croupier.settingsFromPlayerNumber(pNum),
        height: config.height * sizeFactor,
        width: config.height * sizeFactor * 1.5);
  }

  Widget _playerProfile(int pNum, double sizeFactor) {
    return _rotate(_getProfile(pNum, sizeFactor), pNum);
  }

  Widget _buildPassLayoutInternal() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Column([
          new Flexible(child: _playerProfile(2, 0.2), flex: 0),
          new Flexible(child: _getPass(2), flex: 0),
          new Flexible(
              child: new Row([
                new Flexible(child: _playerProfile(1, 0.2), flex: 0),
                new Flexible(child: _getPass(1), flex: 0),
                new Flexible(child: new Block([]), flex: 1),
                new Flexible(child: _getPass(3), flex: 0),
                new Flexible(child: _playerProfile(3, 0.2), flex: 0)
              ],
                  alignItems: FlexAlignItems.center,
                  justifyContent: FlexJustifyContent.spaceAround),
              flex: 1),
          new Flexible(child: _getPass(0), flex: 0),
          new Flexible(child: _playerProfile(0, 0.2), flex: 0)
        ],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround));
  }

  Widget _buildMiniBoardLayout() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Center(
            child: new Row([
          new Flexible(
              flex: 1,
              child: new Center(
                  child: _buildAvatarSlotCombo(rotateByGamePlayerNumber(1)))),
          new Flexible(
              flex: 1,
              child: new Column([
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
        game.cardCollections[playerNumber + HeartsGame.OFFSET_PLAY];
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
              child: new CroupierProfileComponent(
                  settings:
                      config.croupier.settingsFromPlayerNumber(playerNumber),
                  height: config.cardHeight,
                  width: config.cardWidth,
                  isMini: true))));
    }

    return new Container(
        width: config.cardWidth,
        height: config.cardHeight,
        child: new Stack(items));
  }

  Widget _showTrickText(int pNum) {
    HeartsGame game = config.game;

    int numTrickCards =
        game.cardCollections[HeartsGame.OFFSET_TRICK + pNum].length;
    int numTricks = numTrickCards ~/ 4;

    String s = numTricks != 1 ? "s" : "";

    return _rotate(new Text("${numTricks} trick${s}"), pNum);
  }

  Widget _buildBoardLayout() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Column([
          new Flexible(child: _playerProfile(2, 0.2), flex: 0),
          new Flexible(child: _showTrickText(2), flex: 0),
          new Flexible(
              child: new Row([
                new Flexible(child: _playerProfile(1, 0.2), flex: 0),
                new Flexible(child: _showTrickText(1), flex: 0),
                new Flexible(child: _buildCenterCards(), flex: 1),
                new Flexible(child: _showTrickText(3), flex: 0),
                new Flexible(child: _playerProfile(3, 0.2), flex: 0)
              ],
                  alignItems: FlexAlignItems.center,
                  justifyContent: FlexJustifyContent.spaceAround),
              flex: 1),
          new Flexible(child: _showTrickText(0), flex: 0),
          new Flexible(child: _playerProfile(0, 0.2), flex: 0)
        ],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround));
  }

  Widget _buildCenterCards() {
    bool wide = (config.width >= config.height);

    if (wide) {
      return new Row([
        _buildCenterCard(1),
        new Column([_buildCenterCard(2), _buildCenterCard(0)],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround),
        _buildCenterCard(3)
      ],
          alignItems: FlexAlignItems.center,
          justifyContent: FlexJustifyContent.spaceAround);
    } else {
      return new Column([
        _buildCenterCard(2),
        new Row([_buildCenterCard(1), _buildCenterCard(3)],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround),
        _buildCenterCard(0)
      ],
          alignItems: FlexAlignItems.center,
          justifyContent: FlexJustifyContent.spaceAround);
    }
  }

  double get _centerScaleFactor {
    return math.min(config.height * 0.6 / (config.cardHeight * 3),
        config.width - config.height * 0.4 / (config.cardWidth * 3));
  }

  Widget _buildCenterCard(int playerNumber) {
    HeartsGame game = config.game;
    List<logic_card.Card> cards =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_PLAY];

    bool hasPlayed = cards.length > 0;
    bool isTurn = game.whoseTurn == playerNumber && !hasPlayed;

    return new CardCollectionComponent(
        cards, true, CardCollectionOrientation.show1,
        widthCard: config.cardWidth * this._centerScaleFactor,
        heightCard: config.cardHeight * this._centerScaleFactor,
        rotation: _rotationAngle(playerNumber),
        useKeys: true,
        backgroundColor: isTurn ? style.theme.accentColor : null);
  }

  // The off-screen cards consist of trick cards and play cards.
  // When the board is mini, the player's play cards are excluded.
  Widget _buildOffScreenCards(int playerNumber) {
    HeartsGame game = config.game;

    List<logic_card.Card> cards = new List.from(
        game.cardCollections[playerNumber + HeartsGame.OFFSET_TRICK]);

    bool isPlay = game.phase == HeartsPhase.Play;

    // Prevent over-expansion of cards until a card has been played.
    bool alreadyPlaying =
        (isPlay && (game.numPlayed > 0 || game.trickNumber > 0));

    double sizeFactor = 1.0;
    if (config.isMini) {
      if (playerNumber != game.playerNumber) {
        cards.addAll(
            game.cardCollections[playerNumber + HeartsGame.OFFSET_HAND]);
      }
    } else {
      cards.addAll(game.cardCollections[playerNumber + HeartsGame.OFFSET_HAND]);

      if (alreadyPlaying) {
        sizeFactor = this._centerScaleFactor;
      }
    }

    return new CardCollectionComponent(
        cards, isPlay, CardCollectionOrientation.show1,
        widthCard: config.cardWidth * sizeFactor,
        heightCard: config.cardHeight * sizeFactor,
        useKeys: true,
        rotation: config.isMini ? null : _rotationAngle(playerNumber),
        animationType: component_card.CardAnimationType.LONG);
  }
}
