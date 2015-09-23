// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import 'card.dart' as component_card;
import 'draggable.dart' show Draggable;
import 'util.dart' as util;

import 'dart:math' as math;
import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Orientation { vert, horz, fan, show1, suit }
enum DropType {
  none,
  card,
  card_collection
  // I can see that both would be nice, but I'm not sure how to do that yet.
}

const double DEFAULT_WIDTH = 200.0;
const double DEFAULT_CARD_HEIGHT = 60.0;
const double DEFAULT_CARD_WIDTH = 60.0;

const double CARD_MARGIN = 3.0; // transparent
const double WHITE_LINE_HEIGHT = 2.0; // white
const double WHITE_LINE_MARGIN = 4.0; // each side

class CardCollectionComponent extends StatefulComponent {
  List<logic_card.Card> cards;
  Orientation orientation;
  bool faceUp;
  Function parentCallback;
  bool dragChildren;
  DropType acceptType;
  Function comparator;
  double width;
  double widthCard;
  double heightCard;
  var backgroundColor;
  var altColor;

  String status = 'bar';

  CardCollectionComponent(
      this.cards, this.faceUp, this.orientation, this.parentCallback,
      {this.dragChildren: false, this.acceptType: DropType.none, this.comparator: null,
      this.width: DEFAULT_WIDTH, this.widthCard: DEFAULT_CARD_WIDTH, this.heightCard: DEFAULT_CARD_HEIGHT,
      this.backgroundColor, this.altColor}) {

    if (this.backgroundColor == null) {
      backgroundColor = colors.Grey[500];
    }
    if (this.altColor == null) {
      altColor = colors.Grey[600];
    }
  }

  void syncConstructorArguments(CardCollectionComponent other) {
    cards = other.cards;
    orientation = other.orientation;
    faceUp = other.faceUp;
    parentCallback = other.parentCallback;
    dragChildren = other.dragChildren;
    acceptType = other.acceptType;
    comparator = other.comparator;
    width = other.width;
    widthCard = other.widthCard;
    heightCard = other.heightCard;
    backgroundColor = other.backgroundColor;
    altColor = other.altColor;
  }

  bool _handleWillAccept(dynamic data) {
    print('will accept?');
    print(data);
    return true;
  }

  void _handleAccept(component_card.Card data) {
    print('accept');
    setState(() {
      status = 'ACCEPT ${data.card.toString()}';
      parentCallback(data.card, this.cards);
    });
  }

  void _handleAcceptMultiple(CardCollectionComponent data) {
    print('acceptMulti');
    setState(() {
      status = 'ACCEPT multi: ${data.cards.toString()}';
      parentCallback(data.cards, this.cards);
    });
  }

  List<logic_card.Card> get _sortedCards {
    assert(this.comparator != null);
    List<logic_card.Card> cs = new List<logic_card.Card>();
    cs.addAll(this.cards);
    cs.sort(comparator);
    return cs;
  }

  // returns null if it's up to the container (like a Flex) to figure this out.
  double get desiredHeight {
    switch (this.orientation) {
      case Orientation.vert:
        return null;
      case Orientation.horz:
      case Orientation.fan:
      case Orientation.show1:
        return _produceRowHeight;
      case Orientation.suit:
        return _produceRowHeight * 4 + _whiteLineHeight * 3;
      default:
        assert(false);
        return null;
    }
  }

  // returns null if it's up to the container (like a Flex) to figure this out.
  double get desiredWidth {
    switch (this.orientation) {
      case Orientation.vert:
      case Orientation.show1:
        return widthCard;
      case Orientation.horz:
      case Orientation.fan:
      case Orientation.suit:
        return this.width;
      default:
        assert(false);
        return null;
    }
  }

  double get _produceRowHeight => heightCard + CARD_MARGIN * 2;
  Widget _produceRow(List<Widget> cardWidgets, {emptyBackgroundImage: ""}) {
    if (cardWidgets.length == 0) {
      // Just return a centered background image.
      return new Container(
        decoration: new BoxDecoration(backgroundColor: this.backgroundColor),
        height: _produceRowHeight,
        width: this.width,
        child: new Center(child: new Opacity(
          opacity: 0.45,
          child: new Container(
            height: heightCard,
            child: emptyBackgroundImage == "" ? null : new NetworkImage(src: emptyBackgroundImage)
          )
        ))
      );
    }

    // Let's do a stack of positioned cards!
    List<Widget> kids = new List<Widget>();

    double w =  this.width ?? widthCard * 5;
    double spacing = math.min(widthCard + CARD_MARGIN * 2, (w - widthCard - 2 * CARD_MARGIN) / (cardWidgets.length - 1));

    for (int i = 0; i < cardWidgets.length; i++) {
      kids.add(new Positioned(
        top: CARD_MARGIN,
        left: CARD_MARGIN + spacing * i,
        child: cardWidgets[i]
      ));
    }
    return new Container(
      decoration: new BoxDecoration(backgroundColor: this.backgroundColor),
      height: _produceRowHeight,
      width: this.width,
      child: new Stack(kids)
    );
  }

  double get _whiteLineHeight => WHITE_LINE_HEIGHT;

  Widget wrapCards(List<Widget> cardWidgets) {
    switch (this.orientation) {
      case Orientation.vert:
        return new Flex(util.flexChildren(cardWidgets),
            direction: FlexDirection.vertical);
      case Orientation.horz:
        return _produceRow(cardWidgets);
      case Orientation.fan:
      // unimplemented, so we'll fall through to show1, for now.
      // Probably a Stack + Positioned
      case Orientation.show1:
        return new Stack(cardWidgets);
      case Orientation.suit:
        List<Widget> cs = new List<Widget>();
        List<Widget> ds = new List<Widget>();
        List<Widget> hs = new List<Widget>();
        List<Widget> ss = new List<Widget>();

        List<logic_card.Card> theCards =
          this.comparator != null ? this._sortedCards : this.cards;
        for (int i = 0; i < theCards.length; i++) {
          // Group by suit. Then sort.
          logic_card.Card c = theCards[i];
          switch(c.identifier[0]) {
            case 'c':
              cs.add(cardWidgets[i]);
              break;
            case 'd':
              ds.add(cardWidgets[i]);
              break;
            case 'h':
              hs.add(cardWidgets[i]);
              break;
            case 's':
              ss.add(cardWidgets[i]);
              break;
            default:
              assert(false);
          }
        }
        return new Container(
          decoration: new BoxDecoration(backgroundColor: colors.white),
          child: new Stack(<Widget>[
            new Positioned(
              top: 0.0,
              child: _produceRow(ss, emptyBackgroundImage: "images/suits/Spade.png")
            ),
            new Positioned(
              top: _produceRowHeight + _whiteLineHeight,
              child: _produceRow(hs, emptyBackgroundImage: "images/suits/Heart.png")
            ),
            new Positioned(
              top: 2 * _produceRowHeight + 2 * _whiteLineHeight,
              child: _produceRow(cs, emptyBackgroundImage: "images/suits/Club.png")
            ),
            new Positioned(
              top: 3 * _produceRowHeight + 3 * _whiteLineHeight,
              child: _produceRow(ds, emptyBackgroundImage: "images/suits/Diamond.png")
            )
          ])
        );
      default:
        assert(false);
        return null;
    }
  }

  Widget build() {
    return _buildCollection();
  }

  Widget _buildCollection() {
    List<Widget> cardComponents = new List<Widget>();
    List<logic_card.Card> cs = this.comparator != null ? this._sortedCards : this.cards;

    for (int i = 0; i < cs.length; i++) {
      component_card.Card c = new component_card.Card(cs[i], faceUp, width: widthCard, height: heightCard);

      if (dragChildren) {
        cardComponents.add(new Draggable<component_card.Card>(c));
      } else {
        cardComponents.add(c);
      }
    }

    // Let's draw a stack of cards with DragTargets.
    // TODO(alexfandrianto): In many cases, card collections shouldn't have draggable cards.
    // Additionally, it may be worthwhile to restrict it to 1 at a time.
    switch (this.acceptType) {
      case DropType.none:
        return new Container(
            decoration: new BoxDecoration(
                backgroundColor: this.backgroundColor),
            height: this.desiredHeight,
            width: this.desiredWidth,
            child: wrapCards(cardComponents));
      case DropType.card:
        return new DragTarget<component_card.Card>(
            onWillAccept: _handleWillAccept, onAccept: _handleAccept,
            builder: (List<component_card.Card> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  backgroundColor:
                      data.isEmpty ? this.backgroundColor : this.altColor),
              height: this.desiredHeight,
              width: this.desiredWidth,
              child: wrapCards(cardComponents));
        });
      case DropType.card_collection:
        return new DragTarget<CardCollectionComponent>(
            onWillAccept: _handleWillAccept, onAccept: _handleAcceptMultiple,
            builder: (List<CardCollectionComponent> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  backgroundColor:
                      data.isEmpty ? this.backgroundColor : this.altColor),
              height: this.desiredHeight,
              width: this.desiredWidth,
              child: wrapCards(cardComponents));
        });
    }
  }
}
