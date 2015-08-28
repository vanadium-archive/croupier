import '../logic/card.dart' show Card;
import '../logic/game.dart' show Game, GameType, Viewer, HeartsGame, HeartsPhase;
import 'board.dart' show Board;
import 'card_collection.dart' show CardCollectionComponent, Orientation;

import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets.dart' show FlatButton;
import 'package:sky/theme/colors.dart' as colors;


class GameComponent extends StatefulComponent {
  Game game;

  GameComponent(this.game) {
    game.updateCallback = update;
  }

  void update() {
    setState(() {});
  }

  void syncConstructorArguments(GameComponent other) {
    this.game = other.game;
  }

  Widget build() {
    switch (game.gameType) {
      case GameType.Proto:
        return buildProto();
      case GameType.Hearts:
        return buildHearts();
      case GameType.Board:
        // Does NOT work in checked mode since it has a Stack of Positioned Stack with Positioned Widgets.
        // Issue and possible workaround? https://github.com/domokit/sky_engine/issues/732
        return new Board(1, [2,3,4], [1, 2, 3, 4]);
      default:
        return null; // unsupported
    }
  }

  _switchPlayersCallback() {
    setState(() {
      game.playerNumber = (game.playerNumber + 1) % 4;
    });
  }

  _updateGameCallback(Card card, List<Card> dest) {
    setState(() {
      try {
        game.move(card, dest);
      } catch(e) {
        print("You can't do that! ${e.toString()}");
        game.debugString = e.toString();
      }
    });
  }

  Widget buildProto() {
    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(cards, game.playerNumber == i, Orientation.horz, _updateGameCallback);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
      child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.show1, _updateGameCallback)
    ));

    cardCollections.add(new FlatButton(
      child: new Text('Switch View'),
      onPressed: _switchPlayersCallback
    ));

    return new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
      child: new Flex(cardCollections, direction: FlexDirection.vertical)
    );
  }

  Widget _makeSwitchViewButton() =>_makeButton('Switch View', _switchPlayersCallback);

  Widget _makeButton(String text, Function callback) {
    return new FlatButton(
      child: new Text(text),
      onPressed: callback
    );
  }

  Widget buildHearts() {
    HeartsGame game = this.game as HeartsGame;

    switch (game.phase) {
      case HeartsPhase.Deal:
        return new Container(
          decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
          child: new Flex([
            new Text('Player ${game.playerNumber}'),
            _makeButton('Deal', game.dealCards),
            _makeSwitchViewButton()
          ], direction: FlexDirection.vertical)
        );
      case HeartsPhase.Pass:
      case HeartsPhase.Take:
      case HeartsPhase.Play:
      case HeartsPhase.Score:
        return showBoard();
      default:
        assert(false);
        return null;
    }
  }

  Widget showBoard() {
    HeartsGame game = this.game as HeartsGame;

    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(game.debugString));

    for (int i = 0; i < 4; i++) {
      List<Card> cards = game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(cards, game.playerNumber == i, Orientation.horz, _updateGameCallback);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Green[500], borderRadius: 5.0),
      child: new CardCollectionComponent(game.cardCollections[4], true, Orientation.show1, _updateGameCallback)
    ));

    cardCollections.add(new FlatButton(
      child: new Text('Switch View'),
      onPressed: _switchPlayersCallback
    ));

    return new Container(
      decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
      child: new Flex(cardCollections, direction: FlexDirection.vertical)
    );
  }
}
