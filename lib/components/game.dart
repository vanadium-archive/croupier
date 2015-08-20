import '../logic/card.dart' show Card;
import '../logic/game.dart' show Game, GameType;
import 'card_collection.dart' show CardCollectionComponent, Orientation;
import 'package:sky/widgets/basic.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'card_constants.dart' as card_constants;
import 'package:vector_math/vector_math.dart' as vector_math;

class GameComponent extends StatefulComponent {
  final Game game;

  GameComponent(this.game);

  void syncFields(GameComponent other) {}

  Widget build() {
    switch (game.gameType) {
      case GameType.Hearts:
        return buildHearts();
      default:
        return null; // unsupported
    }
  }

  void _parentHandleAccept(Card card, List<Card> toList) {
    // That means that this card was dragged to this other Card collection component.
    setState(() {
      game.move(card, toList);
    });
  }

  Widget buildHearts() {
    List<Widget> cardCollections = new List<Widget>();
    for (int i = 0; i < 4; i++) {
      List<Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(cards, true, Orientation.horz, _parentHandleAccept);

      cardCollections.add(new Positioned(
        top: i * (card_constants.CARD_HEIGHT + 20.0),
        child: c
      ));

      /*cardCollections.add(new Transform(
        transform: new vector_math.Matrix4.identity().translate(0.0, i * (card_constants.CARD_HEIGHT + 20.0)),
        child: c
      ));*/
    }

    // game.cardCollections[4] is a discard pile
    cardCollections.add(new Transform(
      transform: new vector_math.Matrix4.identity().translate(0.0, 4 * (card_constants.CARD_HEIGHT + 20.0)),
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.horz, _parentHandleAccept)
      )
    ));
    /*cardCollections.add(new Positioned(
      top: 4 * (card_constants.CARD_HEIGHT + 20.0),
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.horz)
      )
    ));*/

    // game.cardCollections[5] is just not shown

    return new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
      child: new Stack(cardCollections)
    );
  }
}