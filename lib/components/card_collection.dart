// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import 'card.dart' as component_card;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;

enum CardCollectionOrientation { vert, horz, fan, show1, suit }
enum DropType {
  none,
  card,
  card_collection
  // I can see that both would be nice, but I'm not sure how to do that yet.
}

typedef void AcceptCb(dynamic data, List<logic_card.Card> cards);

const double DEFAULT_WIDTH = 200.0;
const double DEFAULT_HEIGHT = 200.0;
const double DEFAULT_CARD_HEIGHT = 60.0;
const double DEFAULT_CARD_WIDTH = 60.0;

const double CARD_MARGIN = 3.0; // transparent
const double WHITE_LINE_HEIGHT = 2.0; // white
const double WHITE_LINE_MARGIN = 4.0; // each side

class CardCollectionComponent extends StatefulComponent {
  final List<logic_card.Card> cards;
  final CardCollectionOrientation orientation;
  final bool faceUp;
  final AcceptCb acceptCallback;
  final bool dragChildren;
  final DropType _acceptType;
  final Comparator<logic_card.Card> comparator;
  final double width;
  final double height;
  final double widthCard;
  final double heightCard;
  final Color _backgroundColor;
  final Color _altColor;
  final double rotation; // This angle is in radians.

  DropType get acceptType => _acceptType ?? DropType.none;
  Color get backgroundColor => _backgroundColor ?? material.Colors.grey[500];
  Color get altColor => _altColor ?? material.Colors.grey[500];

  CardCollectionComponent(
      this.cards, this.faceUp, this.orientation,
      {this.dragChildren: false,
      DropType acceptType,
      this.acceptCallback: null,
      this.comparator: null,
      this.width: DEFAULT_WIDTH,
      this.height: DEFAULT_HEIGHT,
      this.widthCard: DEFAULT_CARD_WIDTH,
      this.heightCard: DEFAULT_CARD_HEIGHT,
      Color backgroundColor,
      Color altColor,
      this.rotation: 0.0})
      : _acceptType = acceptType,
        _backgroundColor = backgroundColor,
        _altColor = altColor;

  CardCollectionComponentState createState() =>
      new CardCollectionComponentState();
}

class CardCollectionComponentState extends State<CardCollectionComponent> {
  String status = 'bar';

  bool _handleWillAccept(dynamic data) {
    print('will accept?');
    print(data);
    return true;
  }

  void _handleAccept(component_card.Card data) {
    print('accept');
    setState(() {
      status = 'ACCEPT ${data.card.toString()}';
      config.acceptCallback(data.card, config.cards);
    });
  }

  void _handleAcceptMultiple(CardCollectionComponent data) {
    print('acceptMulti');
    setState(() {
      status = 'ACCEPT multi: ${data.cards.toString()}';
      config.acceptCallback(data.cards, config.cards);
    });
  }

  List<logic_card.Card> get _sortedCards {
    assert(config.comparator != null);
    List<logic_card.Card> cs = new List<logic_card.Card>();
    cs.addAll(config.cards);
    cs.sort(config.comparator);
    return cs;
  }

  // returns null if it's up to the container (like a Flex) to figure this out.
  double get desiredHeight {
    switch (config.orientation) {
      case CardCollectionOrientation.vert:
        return config.height;
      case CardCollectionOrientation.horz:
      case CardCollectionOrientation.fan:
      case CardCollectionOrientation.show1:
        return _produceRowHeight;
      case CardCollectionOrientation.suit:
        return _produceRowHeight * 4 + _whiteLineHeight * 3;
      default:
        assert(false);
        return null;
    }
  }

  // returns null if it's up to the container (like a Flex) to figure this out.
  double get desiredWidth {
    switch (config.orientation) {
      case CardCollectionOrientation.vert:
      case CardCollectionOrientation.show1:
        return _produceColumnWidth;
      case CardCollectionOrientation.horz:
      case CardCollectionOrientation.fan:
      case CardCollectionOrientation.suit:
        return config.width;
      default:
        assert(false);
        return null;
    }
  }

  double get _produceColumnWidth => config.widthCard + CARD_MARGIN * 2;
  Widget _produceColumn(List<Widget> cardWidgets) {
    // Let's do a stack of positioned cards!
    List<Widget> kids = new List<Widget>();

    double h = config.height ?? config.heightCard * 5;
    double spacing = math.min(config.heightCard + CARD_MARGIN * 2,
        (h - config.heightCard - 2 * CARD_MARGIN) / (cardWidgets.length - 1));

    for (int i = 0; i < cardWidgets.length; i++) {
      kids.add(new Positioned(
          top: CARD_MARGIN + spacing * i,
          left: CARD_MARGIN,
          child: cardWidgets[i]));
    }
    return new Container(
        decoration: new BoxDecoration(backgroundColor: config.backgroundColor),
        height: config.height,
        width: _produceColumnWidth,
        child: new Stack(kids));
  }

  double get _produceRowHeight => config.heightCard + CARD_MARGIN * 2;
  Widget _produceRow(List<Widget> cardWidgets, {emptyBackgroundImage: ""}) {
    if (cardWidgets.length == 0) {
      // Just return a centered background image.
      return new Container(
          decoration:
              new BoxDecoration(backgroundColor: config.backgroundColor),
          height: _produceRowHeight,
          width: config.width,
          child: new Center(
              child: new Opacity(
                  opacity: 0.45,
                  child: new Container(
                      height: config.heightCard,
                      child: emptyBackgroundImage == ""
                          ? null
                          : new NetworkImage(src: emptyBackgroundImage)))));
    }

    // Let's do a stack of positioned cards!
    List<Widget> kids = new List<Widget>();

    double w = config.width ?? config.widthCard * 5;
    double spacing = math.min(config.widthCard + CARD_MARGIN * 2,
        (w - config.widthCard - 2 * CARD_MARGIN) / (cardWidgets.length - 1));

    for (int i = 0; i < cardWidgets.length; i++) {
      kids.add(new Positioned(
          top: CARD_MARGIN,
          left: CARD_MARGIN + spacing * i,
          child: cardWidgets[i]));
    }
    return new Container(
        decoration: new BoxDecoration(backgroundColor: config.backgroundColor),
        height: _produceRowHeight,
        width: config.width,
        child: new Stack(kids));
  }

  Widget _produceSingle(List<Widget> cardWidgets) {
    List<Widget> kids = new List<Widget>();

    for (int i = 0; i < cardWidgets.length; i++) {
      kids.add(new Positioned(
          top: CARD_MARGIN, left: CARD_MARGIN, child: cardWidgets[i]));
    }
    return new Container(
        decoration: new BoxDecoration(backgroundColor: config.backgroundColor),
        height: _produceRowHeight,
        width: _produceColumnWidth,
        child: new Stack(kids));
  }

  double get _whiteLineHeight => WHITE_LINE_HEIGHT;

  Widget wrapCards(List<Widget> cardWidgets) {
    switch (config.orientation) {
      case CardCollectionOrientation.vert:
        return _produceColumn(cardWidgets);
      case CardCollectionOrientation.horz:
        return _produceRow(cardWidgets);
      case CardCollectionOrientation.fan:
      // unimplemented, so we'll fall through to show1, for now.
      // Probably a Stack + Positioned
      case CardCollectionOrientation.show1:
        return _produceSingle(cardWidgets);
      case CardCollectionOrientation.suit:
        List<Widget> cs = new List<Widget>();
        List<Widget> ds = new List<Widget>();
        List<Widget> hs = new List<Widget>();
        List<Widget> ss = new List<Widget>();

        List<logic_card.Card> theCards =
            config.comparator != null ? this._sortedCards : config.cards;
        for (int i = 0; i < theCards.length; i++) {
          // Group by suit. Then sort.
          logic_card.Card c = theCards[i];
          switch (c.identifier[0]) {
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
            decoration:
                new BoxDecoration(backgroundColor: material.Colors.white),
            child: new Stack(<Widget>[
              new Positioned(
                  top: 0.0,
                  child: _produceRow(ss,
                      emptyBackgroundImage: "images/suits/Spade.png")),
              new Positioned(
                  top: _produceRowHeight + _whiteLineHeight,
                  child: _produceRow(hs,
                      emptyBackgroundImage: "images/suits/Heart.png")),
              new Positioned(
                  top: 2 * _produceRowHeight + 2 * _whiteLineHeight,
                  child: _produceRow(cs,
                      emptyBackgroundImage: "images/suits/Club.png")),
              new Positioned(
                  top: 3 * _produceRowHeight + 3 * _whiteLineHeight,
                  child: _produceRow(ds,
                      emptyBackgroundImage: "images/suits/Diamond.png"))
            ]));
      default:
        assert(false);
        return null;
    }
  }

  Widget build(BuildContext context) {
    return _buildCollection();
  }

  Widget _buildCollection() {
    List<Widget> cardComponents = new List<Widget>();
    List<logic_card.Card> cs =
        config.comparator != null ? this._sortedCards : config.cards;

    for (int i = 0; i < cs.length; i++) {
      component_card.Card c = new component_card.Card(cs[i], config.faceUp,
          width: config.widthCard,
          height: config.heightCard,
          rotation: config.rotation);

      if (config.dragChildren) {
        cardComponents.add(new Draggable(
            child: c,
            data: c,
            feedback: new Opacity(child: c, opacity: 0.5)));
      } else {
        cardComponents.add(c);
      }
    }

    // Let's draw a stack of cards with DragTargets.
    // TODO(alexfandrianto): In many cases, card collections shouldn't have draggable cards.
    // Additionally, it may be worthwhile to restrict it to 1 at a time.
    switch (config.acceptType) {
      case DropType.none:
        return new Container(
            decoration:
                new BoxDecoration(backgroundColor: config.backgroundColor),
            height: this.desiredHeight,
            width: this.desiredWidth,
            child: wrapCards(cardComponents));
      case DropType.card:
        return new DragTarget<component_card.Card>(
            onWillAccept: _handleWillAccept, onAccept: _handleAccept,
            builder: (BuildContext context, List<component_card.Card> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  backgroundColor:
                      data.isEmpty ? config.backgroundColor : config.altColor),
              height: this.desiredHeight,
              width: this.desiredWidth,
              child: wrapCards(cardComponents));
        });
      case DropType.card_collection:
        return new DragTarget<CardCollectionComponent>(
            onWillAccept: _handleWillAccept,
            onAccept: _handleAcceptMultiple, builder:
                (BuildContext context, List<CardCollectionComponent> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  backgroundColor:
                      data.isEmpty ? config.backgroundColor : config.altColor),
              height: this.desiredHeight,
              width: this.desiredWidth,
              child: wrapCards(cardComponents));
        });
      default:
        assert(false);
        return null;
    }
  }
}
