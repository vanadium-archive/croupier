// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'card_collection.dart' show CardCollectionComponent, Orientation;
import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame;

import 'dart:math' as math;

import 'package:flutter/material.dart';

const double defaultBoardHeight = 400.0;
const double defaultBoardWidth = 400.0;
const double defaultCardHeight = 40.0;
const double defaultCardWidth = 40.0;

/// A Board represents a fixed-size canvas for drawing a Game's UI.
/// While other Widgets may be drawn to accomodate space, a Board is meant to
/// consume a specific amount of space on the screen, which allows for more
/// control when positioning elements within the Board's area.
abstract class Board extends StatelessComponent {
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
  HeartsBoard(HeartsGame game,
      {double height, double width, double cardHeight, double cardWidth})
      : super(game,
            height: height,
            width: width,
            cardHeight: cardHeight,
            cardWidth: cardWidth);

  Widget build(BuildContext context) {
    List<Widget> pile = new List<Widget>();

    _addHandsToPile(pile);
    _addProfilesToPile(pile);
    _addPlaysToPile(pile);

    return new Container(
        height: this.height, width: this.width, child: new Stack(pile));
  }

  // Show the hands of each player (facedown) around the perimeter of the board.
  void _addHandsToPile(List<Widget> pile) {
    HeartsGame game = this.game;

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards =
          game.cardCollections[i + HeartsGame.OFFSET_HAND];
      Orientation ori = i % 2 == 0 ? Orientation.horz : Orientation.vert;

      bool wide = (this.width >= this.height);
      double smallerSide = wide ? this.height : this.width;
      double sizeRatio = 0.60;
      double cccSize = sizeRatio * smallerSide;

      CardCollectionComponent ccc = new CardCollectionComponent(
          cards, false, ori,
          width: i % 2 == 0 ? cccSize : null,
          height: i % 2 != 0 ? cccSize : null,
          rotation: -math.PI / 2 * i);
      Widget w;
      switch (i) {
        case 2:
          w = new Positioned(
              top: 0.0, left: (this.width - cccSize) / 2.0, child: ccc);
          break;
        case 3:
          w = new Positioned(
              top: (this.height - cccSize) / 2.0, left: 0.0, child: ccc);
          break;
        case 0:
          w = new Positioned(
              // TODO(alexfandrianto): 1.7 is a magic number, but it just looks right somehow.
              // This could be due to the margins from each card collection.
              top: this.height - 1.7 * this.cardHeight,
              left: (this.width - cccSize) / 2.0,
              child: ccc);
          break;
        case 1:
          w = new Positioned(
              top: (this.height - cccSize) / 2.0,
              left: this.width - 1.7 * this.cardWidth,
              child: ccc);
          break;
        default:
          assert(false);
      }
      pile.add(w);
    }
  }

  // Create and add Player Profile widgets to the board.
  void _addProfilesToPile(List<Widget> pile) {
    // TODO(alexfandrianto): Show player profiles.
    // I need to access each player's CroupierSettings here.
  }

  // Add 4 play slots. If the board is wider than it is tall, we need to have
  // A flat diamond (where the center 2 cards are stacked on top of each other).
  // If the board is taller than it is wide, then we want a tall diamond. The
  // center 2 cards should be horizontally adjacent.
  // TODO(alexfandrianto): Once I get the player profile settings, I can set
  // the background color of each play slot.
  void _addPlaysToPile(List<Widget> pile) {
    HeartsGame game = this.game;

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards =
          game.cardCollections[i + HeartsGame.OFFSET_PLAY];

      double MARGIN = 10.0;
      CardCollectionComponent ccc = new CardCollectionComponent(
          cards, true, Orientation.show1,
          width: this.cardWidth,
          widthCard: this.cardWidth,
          height: this.cardHeight,
          heightCard: this.cardHeight,
          rotation: -math.PI / 2 * i);
      Widget w;

      double left02 = (this.width - this.cardWidth) / 2;
      double top13 = (this.height - this.cardHeight) / 2.0;

      double baseTop = (this.height - (this.cardHeight * 2 + MARGIN)) / 2;
      double baseLeft = (this.width - (this.cardWidth * 2 + MARGIN)) / 2;
      double dHeight = (this.cardHeight + MARGIN) / 2;
      double dWidth = (this.cardWidth + MARGIN) / 2;

      if (this.width >= this.height) {
        switch (i) {
          case 2:
            w = new Positioned(top: baseTop, left: left02, child: ccc);
            break;
          case 3:
            w = new Positioned(top: top13, left: baseLeft - dWidth, child: ccc);
            break;
          case 0:
            w = new Positioned(
                top: baseTop + dHeight * 2, left: left02, child: ccc);
            break;
          case 1:
            w = new Positioned(
                top: top13, left: baseLeft + dWidth * 3, child: ccc);
            break;
          default:
            assert(false);
        }
      } else {
        switch (i) {
          case 2:
            w = new Positioned(
                top: baseTop - dHeight, left: left02, child: ccc);
            break;
          case 3:
            w = new Positioned(top: top13, left: baseLeft, child: ccc);
            break;
          case 0:
            w = new Positioned(
                top: baseTop + dHeight * 3, left: left02, child: ccc);
            break;
          case 1:
            w = new Positioned(
                top: top13, left: baseLeft + dHeight * 2, child: ccc);
            break;
          default:
            assert(false);
        }
      }

      pile.add(w);
    }
  }
}
