// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import 'card.dart' as component_card;
import 'draggable.dart' show Draggable;
import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Orientation { vert, horz, fan, show1, suit }
enum DropType {
  none,
  card,
  card_collection
  // I can see that both would be nice, but I'm not sure how to do that yet.
}

class CardCollectionComponent extends StatefulComponent {
  List<logic_card.Card> cards;
  Orientation orientation;
  bool faceUp;
  Function parentCallback;
  bool dragChildren;
  DropType acceptType;
  Function comparator;

  String status = 'bar';

  CardCollectionComponent(
      this.cards, this.faceUp, this.orientation, this.parentCallback,
      {this.dragChildren: false, this.acceptType: DropType.none, this.comparator: null});

  void syncConstructorArguments(CardCollectionComponent other) {
    cards = other.cards;
    orientation = other.orientation;
    faceUp = other.faceUp;
    parentCallback = other.parentCallback;
    dragChildren = other.dragChildren;
    acceptType = other.acceptType;
    comparator = other.comparator;
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

  List<Widget> flexChildren(List<Widget> children) {
    List<Widget> flexWidgets = new List<Widget>();
    children.forEach(
        (child) => flexWidgets.add(new Flexible(child: child)));
    return flexWidgets;
  }

  // returns null if it's up to the container (like a Flex) to figure this out.
  double get desiredHeight {
    switch (this.orientation) {
      case Orientation.vert:
        return null;
      case Orientation.horz:
      case Orientation.fan:
      case Orientation.show1:
        return 60.0;
      case Orientation.suit:
        return 240.0;
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
        return 60.0;
      case Orientation.horz:
      case Orientation.fan:
      case Orientation.suit:
        return null;
      default:
        assert(false);
        return null;
    }
  }

  Widget wrapCards(List<Widget> cardWidgets) {
    switch (this.orientation) {
      case Orientation.vert:
        return new Flex(flexChildren(cardWidgets),
            direction: FlexDirection.vertical);
      case Orientation.horz:
        return new Flex(flexChildren(cardWidgets));
      case Orientation.fan:
      // unimplemented, so we'll fall through to show1, for now.
      // Probably a Stack + Positioned
      case Orientation.show1:
        return new Stack(cardWidgets);
      case Orientation.suit:
        if (cards.length == 0) {
          return new Stack(cardWidgets);
        }
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
        return new Flex(flexChildren(<Widget>[
          new Flex(flexChildren(cs)), new Flex(flexChildren(ds)), new Flex(flexChildren(hs)), new Flex(flexChildren(ss))
        ]), direction: FlexDirection.vertical);
      default:
        assert(false);
        return null;
    }
  }

  Widget build() {
    Widget w = new Container(
        decoration: new BoxDecoration(
            backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: _buildHearts());
    return w;
  }

  Widget _buildHearts() {
    List<Widget> cardComponents = new List<Widget>();
    if (cards.length == 0) {
      // TODO(alexfandrianto): I wish I could remove this, but Sky actually
      // complains about a sizing issue when you do that.
      // This is likely related to the Positioning an unsized child bug.
      // I think we have to control our size a bit too much in Sky.
      // https://github.com/domokit/sky_engine/blob/master/sky/packages/sky/lib/src/widgets/sizing.md
      cardComponents.add(new Text("")); // new Text(status)
    }
    List<logic_card.Card> cs = this.comparator != null ? this._sortedCards : this.cards;

    for (int i = 0; i < cs.length; i++) {
      component_card.Card c = new component_card.Card(cs[i], faceUp);

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
                border: new Border.all(width: 3.0, color: colors.white),
                backgroundColor: colors.Grey[500]),
            height: this.desiredHeight,
            width: this.desiredWidth,
            margin: new EdgeDims.all(10.0),
            child: wrapCards(cardComponents));
      case DropType.card:
        return new DragTarget<component_card.Card>(
            onWillAccept: _handleWillAccept, onAccept: _handleAccept,
            builder: (List<component_card.Card> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(
                      width: 3.0,
                      color: data.isEmpty ? colors.white : colors.Blue[500]),
                  backgroundColor:
                      data.isEmpty ? colors.Grey[500] : colors.Green[500]),
              height: this.desiredHeight,
              width: this.desiredWidth,
              margin: new EdgeDims.all(10.0),
              child: wrapCards(cardComponents));
        });
      case DropType.card_collection:
        return new DragTarget<CardCollectionComponent>(
            onWillAccept: _handleWillAccept, onAccept: _handleAcceptMultiple,
            builder: (List<CardCollectionComponent> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(
                      width: 3.0,
                      color: data.isEmpty ? colors.white : colors.Blue[500]),
                  backgroundColor:
                      data.isEmpty ? colors.Grey[500] : colors.Green[500]),
              height: this.desiredHeight,
              width: this.desiredWidth,
              margin: new EdgeDims.all(10.0),
              child: wrapCards(cardComponents));
        });
    }
  }
}
