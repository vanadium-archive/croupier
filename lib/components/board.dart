import './card.dart' show Card;
import '../logic/card.dart' as logic_card;
import 'package:sky/widgets.dart' as widgets;
import 'package:vector_math/vector_math.dart' as vector_math;
import 'dart:math' as math;
import 'package:sky/theme/colors.dart' as colors;

const cardHeight = 96;
const cardWidth = 71;

class CardCluster extends widgets.Component {
  List<int> cards; // the indicies of the cards in the center, in clockwise order
  int startingPos;
  CardCluster(this.startingPos, this.cards);

  widgets.Widget build() {
    var widgetsList = [];
    for (int i = 0; i < cards.length; i++) {
      var posMod = (startingPos + i) % 4;
      switch (posMod) {
        case 0:
          widgetsList.add(new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI).translate(0, -cardHeight / 2),
              child: new Card(logic_card.Card.All[cards[i]], true)
          ));
          break;
        case 1:
          widgetsList.add(new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI/2.0).translate(0, cardWidth/2),
              child: new Card(logic_card.Card.All[cards[i]], true)
          ));
          break;
        case 2:
          widgetsList.add(new widgets.Transform(
              transform: new vector_math.Matrix4.identity().translate(-cardWidth, cardWidth / 2),
              child: new Card(logic_card.Card.All[cards[i]], true)
          ));
          break;
        case 3:
          widgetsList.add(new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI/2.0).translate(0, -cardHeight/2),
              child: new Card(logic_card.Card.All[cards[i]], true)
          ));
          break;
      }
    }
    return new widgets.Container(child: new widgets.Stack(widgetsList));
  }
}

class PlayerHand extends widgets.Component {
  int count;
  PlayerHand(this.count);

  widgets.Widget build() {
    List<widgets.Positioned> cards = [];
    for (int i = 0; i < count; i++) {
      cards.add(new widgets.Positioned(child: new Card(logic_card.Card.All[0], false),
        top: 0.0,
        left: cardWidth*i/2.0));
    }
    return new widgets.Stack(cards);
  }
}

class Board extends widgets.Component {
  CardCluster centerCluster;
  List<PlayerHand> hands; // counts of cards in players hands, in clockwise order

  Board(int firstCardPlayedPosition, List<int> cards, List<int> playerHandCount) :
    centerCluster = new CardCluster(firstCardPlayedPosition, cards) {
      assert(playerHandCount.length == 4);
      hands = new List<PlayerHand>();
      for (int count in playerHandCount) {
        hands.add(new PlayerHand(count));
      }
  }

  widgets.Widget build() {
    return new widgets.Container(
      decoration: new widgets.BoxDecoration(backgroundColor: colors.Pink[500]),
      child: new widgets.Stack(
        [
          new widgets.Positioned(child: hands[0],
            top: 0.0,
            left: 250.0),
          new widgets.Positioned(child: new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI/2.0),
              child: hands[1]
              ),
            left: 100.0,
            top: 400.0),
          new widgets.Positioned(child: new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI),
              child: hands[2]
            ),
            top: 820.0,
            left: 350.0),
          new widgets.Positioned(child: new widgets.Transform(
              transform: new vector_math.Matrix4.identity().rotateZ(math.PI/2.0),
              child: hands[3]
            ),
            left: 500.0,
            top: 400.0),
          new widgets.Positioned(child: centerCluster,
            top: 400.0,
            left: 300.0),
        ]
      )
    );
  }
}
