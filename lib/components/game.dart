import '../logic/card.dart' show Card;
import '../logic/game.dart' show Game, GameType;
import 'card_collection.dart' show CardCollectionComponent, Orientation;
import 'package:sky/widgets/basic.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'board.dart' show Board;

class GameComponent extends StatefulComponent {
  Game game;

  GameComponent(this.game);

  void syncFields(GameComponent other) {
    this.game = other.game;
  }

  Widget build() {
    switch (game.gameType) {
      case GameType.Hearts:
        //return buildHearts();
        // Code to display board:
        return new Board(1, [2,3,4], [1, 2, 3, 4]);
      default:
        return null; // unsupported
    }
  }

  _updateGameCallback(Card card, List<Card> dest) {
    setState(() {
      game.move(card, dest);
    });
  }

  Widget buildHearts() {
    List<Widget> cardCollections = new List<Widget>();

    // debugString
    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(cards, true, Orientation.horz, _updateGameCallback);

      /*cardCollections.add(new Positioned(
        top: i * (card_constants.CARD_HEIGHT + 20.0),
        child: c
      ));*/

      /*cardCollections.add(new Transform(
        transform: new vector_math.Matrix4.identity().translate(0.0, i * (card_constants.CARD_HEIGHT + 20.0)),
        child: c
      ));*/

      cardCollections.add(c); // flex
    }

    // game.cardCollections[4] is a discard pile
    /*cardCollections.add(new Transform(
      transform: new vector_math.Matrix4.identity().translate(0.0, 4 * (card_constants.CARD_HEIGHT + 20.0)),
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.horz, _parentHandleAccept)
      )
    ));*/
    /*cardCollections.add(new Positioned(
      top: 4 * (card_constants.CARD_HEIGHT + 20.0),
      child: new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.horz)
      )
    ));*/

    cardCollections.add(new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
      child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.show1, _updateGameCallback)
    ));

    // game.cardCollections[5] is just not shown


    return new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
      child: new Flex(cardCollections, direction: FlexDirection.vertical)//new Stack(cardCollections)
    );
  }
}
