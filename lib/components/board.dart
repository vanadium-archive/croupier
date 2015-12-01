// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/card.dart' as logic_card;
import '../logic/croupier.dart' show Croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' show Game, GameType, NoArgCb;
import '../logic/hearts/hearts.dart' show HeartsGame;
import 'card.dart' as component_card;
import 'card_collection.dart'
    show CardCollectionComponent, CardCollectionOrientation;
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
  final NoArgCb trueSetState;

  HeartsBoard(Croupier croupier, this.trueSetState,
      {double height, double width, double cardHeight, double cardWidth})
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
  bool trickTaking = false;
  List<List<logic_card.Card>> playedCards = new List<List<logic_card.Card>>(4);

  static const int SHOW_TRICK_DURATION = 750; // ms

  @override
  void initState() {
    super.initState();

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

  Widget build(BuildContext context) {
    if (!trickTaking) {
      if (_detectTrick()) {
        trickTaking = true;
        _fillMissingPlayedCard();
        // Unfortunately, ZCards are drawn on the game layer,
        // so instead of setState, we must use trueSetState.
        new Future.delayed(const Duration(milliseconds: SHOW_TRICK_DURATION),
            () {
          trickTaking = false;
          config.trueSetState();
        });
      } else {
        _fillPlayedCards();
      }
    }

    return new Container(
        height: config.height,
        width: config.width,
        child: new Stack([
          new Positioned(top: 0.0, left: 0.0, child: _buildBoardLayout()),
          new Positioned(
              top: config.height * 1.5,
              left: (config.width - config.cardWidth) / 2,
              child: _buildTrick(0)), // bottom
          new Positioned(
              top: (config.height - config.cardHeight) / 2,
              left: config.width * -0.5,
              child: _buildTrick(1)), // left
          new Positioned(
              top: config.height * -0.5,
              left: (config.width - config.cardWidth) / 2,
              child: _buildTrick(2)), // top
          new Positioned(
              top: (config.height - config.cardHeight) / 2,
              left: config.width * 1.5,
              child: _buildTrick(3)) // right
        ]));
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
    int userID = config.croupier.userIDFromPlayerNumber(playerNumber);

    bool isMini = isWide && config.cardHeight * 2 > config.height * 0.25;

    CroupierSettings cs; // If cs is null, a placeholder is used instead.
    if (userID != null) {
      cs = config.croupier.settings_everyone[userID];
    }
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
    return new CardCollectionComponent(
        game.cardCollections[
            game.getTakeTarget(playerNumber) + HeartsGame.OFFSET_PASS],
        false,
        CardCollectionOrientation.horz,
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
    if (trickTaking) {
      cards = playedCards[playerNumber];
    }

    return new CardCollectionComponent(
        cards, true, CardCollectionOrientation.show1,
        widthCard: config.cardWidth * 1.25,
        heightCard: config.cardHeight * 1.25,
        backgroundColor:
            game.whoseTurn == playerNumber ? Colors.blue[500] : null,
        useKeys: true);
  }

  Widget _buildTrick(int playerNumber) {
    HeartsGame game = config.game;
    List<logic_card.Card> cards =
        game.cardCollections[playerNumber + HeartsGame.OFFSET_TRICK];
    // If took trick, exclude the last 4 cards for the trick taking animation.
    if (trickTaking && playerNumber == game.lastTrickTaker) {
      cards = new List.from(cards.sublist(0, cards.length - 4));
    }

    return new CardCollectionComponent(
        cards, true, CardCollectionOrientation.show1,
        widthCard: config.cardWidth,
        heightCard: config.cardHeight,
        useKeys: true,
        animationType: component_card.CardAnimationType.LONG);
  }
}
