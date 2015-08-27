import '../logic/card.dart' as logic_card;
import 'card.dart' show Card;
import 'draggable.dart' show Draggable;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets.dart' show DragTarget;
import 'package:sky/theme/colors.dart' as colors;

enum Orientation {
  vert, horz, fan, show1
}

class CardCollectionComponent extends StatefulComponent {
  List<logic_card.Card> cards;
  Orientation orientation;
  bool faceUp;
  Function parentCallback;

  String status = 'bar';

  CardCollectionComponent(this.cards, this.faceUp, this.orientation, this.parentCallback);

  void syncConstructorArguments(CardCollectionComponent other) {
    //assert(false); // Why do we need to do this?
    //status = other.status;
    cards = other.cards;
    orientation = other.orientation;
    faceUp = other.faceUp;
    parentCallback = other.parentCallback;
  }

  void _handleAccept(Card data) {
    setState(() {
      status = 'ACCEPT ${data.card.toString()}';
      parentCallback(data.card, this.cards);
    });
  }

  List<Widget> flexCards(List<Widget> cardWidgets) {
    List<Widget> flexWidgets = new List<Widget>();
    cardWidgets.forEach((cardWidget) => flexWidgets.add(new Flexible(child: cardWidget)));
    return flexWidgets;
  }

  Widget wrapCards(List<Widget> cardWidgets) {
    switch (this.orientation) {
      case Orientation.vert:
        return new Flex(flexCards(cardWidgets), direction: FlexDirection.vertical);
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
    // Let's just do horizontal for now, it's too complicated otherwise.

    /*double cardDelta = card_constants.CARD_WIDTH;
    if (cards.length > 6) {
      //cardDelta = card_constants.CARD_WIDTH / cards.length; // just make it tiny
      cardDelta -= card_constants.CARD_WIDTH * (cards.length - 6) / cards.length;
    }*/

    List<Widget> cardComponents = new List<Widget>();
    cardComponents.add(new Text(status));
    for (int i = 0; i < cards.length; i++) {
      // Positioned seems correct, but it causes an error when rendering. Constraints aren't matched?
      /*cardComponents.add(new Positioned(
        top: 0.0,
        // left: i * cardDelta,
        child: new Draggable<Card>(Card(cards[i], faceUp))
      ));*/
      /*cardComponents.add(new Transform(
        transform: new vector_math.Matrix4.identity().translate(i * cardDelta, 40.0),
        child: new CardComponent(cards[i], faceUp)
      ));*/
      cardComponents.add(new Draggable<Card>(new Card(cards[i], faceUp))); // flex
    }


    // Just draw a stack of cards...
    //return new Stack(cardComponents);


    /*List<Widget> cardComponents = new List<Widget>();
    for (int i = 0; i < cards.length; i++) {
      cardComponents.add(new Draggable<Card>(new Card(cards[i], faceUp)));
    }
    return new Flex(cardComponents);*/

    // Let's draw a stack of cards with DragTargets.
    return new DragTarget<Card>(
      onAccept: _handleAccept,
      builder: (List<Card> data, _) {
        print(this.cards.length);
        print(data);
        return new Container(
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? colors.white : colors.Blue[500]
            ),
            backgroundColor: data.isEmpty ? colors.Grey[500] : colors.Green[500]
          ),
          height: 80.0,
          margin: new EdgeDims.all(10.0),
          child: wrapCards(cardComponents)//new Stack(cardComponents)
        );
      }
    );
  }
}
