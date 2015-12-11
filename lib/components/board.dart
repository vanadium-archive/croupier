// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/card.dart' as logic_card;
import '../logic/croupier.dart' show Croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' show Game, GameType, NoArgCb;
import '../logic/hearts/hearts.dart' show HeartsGame;
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
  final bool trickTaking;
  final List<List<logic_card.Card>> playedCards;

  HeartsBoard(Croupier croupier,
      {double height,
      double width,
      double cardHeight,
      double cardWidth,
      this.isMini: false,
      this.gameAcceptCallback,
      this.trickTaking,
      this.playedCards})
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
    double offscreenDelta = config.isMini ? 5.0 : 2.0;

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack([
          new Positioned(
              top: 0.0,
              left: 0.0,
              child: config.isMini
                  ? _buildMiniBoardLayout()
                  : _buildBoardLayout()),
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
    HeartsGame game = config.game as HeartsGame;
    int p = game.playerNumber;

    List<Widget> items = new List<Widget>();
    bool isMe = playerNumber == p;
    bool isPlayerTurn = playerNumber == game.whoseTurn && !config.trickTaking;

    List<logic_card.Card> showCard =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_PLAY];

    if (config.trickTaking) {
      showCard = config.playedCards[playerNumber];
    }

    items.add(new Positioned(
        top: 0.0,
        left: 0.0,
        child: new CardCollectionComponent(
            showCard, true, CardCollectionOrientation.show1,
            useKeys: true,
            acceptCallback: config.gameAcceptCallback,
            acceptType: isMe && isPlayerTurn ? DropType.card : DropType.none,
            widthCard: config.cardWidth - 6.0,
            heightCard: config.cardHeight - 6.0,
            backgroundColor:
                isPlayerTurn ? style.theme.accentColor : Colors.grey[500],
            altColor: isPlayerTurn ? Colors.grey[200] : Colors.grey[600])));

    bool hasPlayed =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_PLAY].length > 0;
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

  Widget _buildBoardLayout() {
    return new Container(
        height: config.height,
        width: config.width,
        child: new Column([
          new Flexible(child: _buildPlayer(2), flex: 5),
          new Flexible(
              child: new Row([
                new Flexible(child: _buildPlayer(1), flex: 3),
                new Flexible(child: _buildCenterCards(), flex: 4),
                new Flexible(child: _buildPlayer(3), flex: 3)
              ],
                  alignItems: FlexAlignItems.center,
                  justifyContent: FlexJustifyContent.spaceAround),
              flex: 9),
          new Flexible(child: _buildPlayer(0), flex: 5)
        ],
            alignItems: FlexAlignItems.center,
            justifyContent: FlexJustifyContent.spaceAround));
  }

  Widget _buildPlayer(int playerNumber) {
    bool wide = (config.width >= config.height);

    List<Widget> widgets = [
      _getProfile(playerNumber, wide),
      _getHand(playerNumber),
      _getPass(playerNumber)
    ];

    if (playerNumber % 2 == 0) {
      return new Row(widgets,
          alignItems: FlexAlignItems.center,
          justifyContent: FlexJustifyContent.center);
    } else {
      return new Column(widgets,
          alignItems: FlexAlignItems.center,
          justifyContent: FlexJustifyContent.center);
    }
  }

  Widget _getProfile(int playerNumber, bool isWide) {
    bool isMini = isWide && config.cardHeight * 2 > config.height * 0.25;

    // If cs is null, a placeholder is used instead.
    CroupierSettings cs =
        config.croupier.settingsFromPlayerNumber(playerNumber);
    return new CroupierProfileComponent(
        settings: cs, height: config.height * 0.15, isMini: isMini);
  }

  Widget _getHand(int playerNumber) {
    double sizeRatio = 0.30;
    double cccSize = sizeRatio * config.width;

    return new CardCollectionComponent(
        config.game.cardCollections[playerNumber + HeartsGame.OFFSET_HAND],
        false,
        CardCollectionOrientation.horz,
        width: cccSize,
        widthCard: config.cardWidth,
        heightCard: config.cardHeight,
        useKeys: true);
  }

  Widget _getPass(int playerNumber) {
    double sizeRatio = 0.10;
    double cccSize = sizeRatio * config.width;

    HeartsGame game = config.game;
    List<logic_card.Card> cardsToTake = [];
    int takeTarget = game.getTakeTarget(playerNumber);
    if (takeTarget != null) {
      cardsToTake = game.cardCollections[
          game.getTakeTarget(playerNumber) + HeartsGame.OFFSET_PASS];
    }
    return new CardCollectionComponent(
        cardsToTake, false, CardCollectionOrientation.horz,
        backgroundColor: Colors.grey[300],
        width: cccSize,
        widthCard: config.cardWidth / 2,
        heightCard: config.cardHeight / 2,
        useKeys: true);
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

  Widget _buildCenterCard(int playerNumber) {
    HeartsGame game = config.game;
    List<logic_card.Card> cards =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_PLAY];
    if (config.trickTaking) {
      cards = config.playedCards[playerNumber];
    }

    return new Container(
        decoration: game.whoseTurn == playerNumber ? style.Box.liveNow : null,
        child: new CardCollectionComponent(
            cards, true, CardCollectionOrientation.show1,
            widthCard: config.cardWidth * 2,
            heightCard: config.cardHeight * 2,
            useKeys: true));
  }

  Widget _buildOffScreenCards(int playerNumber) {
    HeartsGame game = config.game;

    List<logic_card.Card> cards =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_TRICK];
    // If took trick, exclude the last 4 cards for the trick taking animation.
    if (config.trickTaking && playerNumber == game.lastTrickTaker) {
      cards = new List.from(cards.sublist(0, cards.length - 4));
    } else {
      cards = new List.from(cards);
    }

    double sizeFactor = 2.0;
    if (config.isMini) {
      sizeFactor = 1.0;
      if (playerNumber != game.playerNumber) {
        cards.addAll(
            game.cardCollections[playerNumber + HeartsGame.OFFSET_HAND]);
      }
    }

    return new CardCollectionComponent(
        cards, true, CardCollectionOrientation.show1,
        widthCard: config.cardWidth * sizeFactor,
        heightCard: config.cardHeight * sizeFactor,
        useKeys: true,
        animationType: component_card.CardAnimationType.LONG);
  }
}
