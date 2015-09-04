import '../logic/card.dart' as logic_card;
import 'card.dart' as component_card;
import 'draggable.dart' show Draggable;
import 'package:sky/widgets.dart';
import 'package:sky/theme/colors.dart' as colors;

enum Orientation { vert, horz, fan, show1 }
enum DropType { none, card, card_collection } // I can see that both would be nice, but I'm not sure how to do that yet.

class CardCollectionComponent extends StatefulComponent {
  List<logic_card.Card> cards;
  Orientation orientation;
  bool faceUp;
  Function parentCallback;
  bool dragChildren;
  DropType acceptType;

  String status = 'bar';

  CardCollectionComponent(
      this.cards, this.faceUp, this.orientation, this.parentCallback,
      {this.dragChildren: false, this.acceptType: DropType.none});

  void syncConstructorArguments(CardCollectionComponent other) {
    cards = other.cards;
    orientation = other.orientation;
    faceUp = other.faceUp;
    parentCallback = other.parentCallback;
    dragChildren = other.dragChildren;
    acceptType = other.acceptType;
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

  List<Widget> flexCards(List<Widget> cardWidgets) {
    List<Widget> flexWidgets = new List<Widget>();
    cardWidgets.forEach(
        (cardWidget) => flexWidgets.add(new Flexible(child: cardWidget)));
    return flexWidgets;
  }

  Widget wrapCards(List<Widget> cardWidgets) {
    switch (this.orientation) {
      case Orientation.vert:
        return new Flex(flexCards(cardWidgets),
            direction: FlexDirection.vertical);
      case Orientation.horz:
        return new Flex(flexCards(cardWidgets));
      case Orientation.fan:
      // unimplemented, so we'll fall through to show1, for now.
      // Probably a Stack + Positioned
      case Orientation.show1:
        return new Stack(cardWidgets);
      default:
        assert(false);
        return null;
    }
  }

  Widget build() {
    Widget w = new Container(
      decoration: new BoxDecoration(
        backgroundColor: colors.Green[500], borderRadius: 5.0),
      child:_buildHearts()
    );
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
    for (int i = 0; i < cards.length; i++) {
      component_card.Card c = new component_card.Card(cards[i], faceUp);

      if (dragChildren) {
        cardComponents.add(new Draggable<component_card.Card>(c));
      } else {
        cardComponents.add(c);
      }
    }

    // Let's draw a stack of cards with DragTargets.
    // TODO(alexfandrianto): In many cases, card collections shouldn't have draggable cards.
    // Additionally, it may be worthwhile to restrict it to 1 at a time.
    switch(this.acceptType) {
      case DropType.none:
        return new Container(
            decoration: new BoxDecoration(
                border: new Border.all(
                    width: 3.0,
                    color: colors.white),
                backgroundColor: colors.Grey[500]),
            height: 80.0,
            margin: new EdgeDims.all(10.0),
            child: wrapCards(cardComponents)
        );
      case DropType.card:
        return new DragTarget<component_card.Card>(
            onWillAccept: _handleWillAccept,
            onAccept: _handleAccept, builder: (List<component_card.Card> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(
                      width: 3.0,
                      color: data.isEmpty ? colors.white : colors.Blue[500]),
                  backgroundColor: data.isEmpty
                      ? colors.Grey[500]
                      : colors.Green[500]),
              height: 80.0,
              margin: new EdgeDims.all(10.0),
              child: wrapCards(cardComponents));
        });
      case DropType.card_collection:
        return new DragTarget<CardCollectionComponent>(
            onWillAccept: _handleWillAccept,
            onAccept: _handleAcceptMultiple, builder: (List<CardCollectionComponent> data, _) {
          return new Container(
              decoration: new BoxDecoration(
                  border: new Border.all(
                      width: 3.0,
                      color: data.isEmpty ? colors.white : colors.Blue[500]),
                  backgroundColor: data.isEmpty
                      ? colors.Grey[500]
                      : colors.Green[500]),
              height: 80.0,
              margin: new EdgeDims.all(10.0),
              child: wrapCards(cardComponents));
          });
    }

  }
}
