import '../logic/card.dart' show Card;
import 'card.dart' show CardComponent, CardDragData;
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets.dart' show DragTarget;
import 'card_constants.dart' as card_constants;
import 'package:sky/theme/colors.dart' as colors;
import 'package:vector_math/vector_math.dart' as vector_math;

enum Orientation {
  vert, horz, fan, show1
}

class CardCollectionComponent extends StatefulComponent {
  final List<Card> cards;
  final Orientation orientation;
  final bool faceUp;
  final Function parentHandleAccept;

  String status = 'bar';

  CardCollectionComponent(this.cards, this.faceUp, this.orientation, this.parentHandleAccept);

  void syncFields(CardCollectionComponent other) {
    //assert(false); // Why do we need to do this?
  }

  void _handleAccept(CardDragData data) {
    setState(() {
      status = 'ACCEPT';
    });
    this.parentHandleAccept(data.card, this.cards);
  }

  Widget build() {
    // Let's just do horizontal for now, it's too complicated otherwise.

    double cardDelta = card_constants.CARD_WIDTH;
    if (cards.length > 6) {
      //cardDelta = card_constants.CARD_WIDTH / cards.length; // just make it tiny
      cardDelta -= card_constants.CARD_WIDTH * (cards.length - 6) / cards.length;
    }

    List<Widget> cardComponents = new List<Widget>();
    cardComponents.add(new Text(status));
    for (int i = 0; i < cards.length; i++) {
      // Positioned seems correct, but it causes an error when rendering. Constraints aren't matched?
      /*cardComponents.add(new Positioned(
        top: 0.0,
        // left: i * cardDelta,
        child: new CardComponent(cards[i], faceUp)
      ));*/
      cardComponents.add(new Transform(
        transform: new vector_math.Matrix4.identity().translate(i * cardDelta, 40.0),
        child: new CardComponent(cards[i], faceUp)
      ));
    }


    // Just draw a stack of cards...
    //return new Stack(cardComponents);


    /*List<Widget> cardComponents = new List<Widget>();
    for (int i = 0; i < cards.length; i++) {
      cardComponents.add(new CardComponent(cards[i], faceUp));
    }
    return new Flex(cardComponents);*/

    // Let's draw a stack of cards with DragTargets.
    return new DragTarget<CardDragData>(
      onAccept: _handleAccept,
      builder: (List<CardDragData> data, _) {
        return new Container(
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? colors.white : colors.Blue[500]
            ),
            backgroundColor: data.isEmpty ? colors.Grey[500] : colors.Green[500]
          ),
          height: 150.0,
          margin: new EdgeDims.all(10.0),
          child: new Stack(cardComponents)
        );
      }
    );
  }
}