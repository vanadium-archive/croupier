import '../logic/croupier.dart' as logic_croupier;
import '../logic/game.dart' as logic_game;
import 'game.dart' show createGameComponent;

import 'package:sky/widgets.dart';

import 'dart:sky' as sky;

class CroupierComponent extends StatefulComponent {
  logic_croupier.Croupier croupier;

  CroupierComponent(this.croupier) : super();

  void syncConstructorArguments(CroupierComponent other) {
    croupier = other.croupier;
  }

  Function makeSetStateCallback(logic_croupier.CroupierState s,
      [var data = null]) {
    return () => setState(() {
          croupier.setState(s, data);
        });
  }

  Widget build() {
    switch (croupier.state) {
      case logic_croupier.CroupierState.Welcome:
        // in which we show them a UI to start a new game, join a game, or change some settings.
        return new Container(
            padding: new EdgeDims.only(top: sky.view.paddingTop),
            child: new Flex([
              new FlatButton(
                  child: new Text('Create Game'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ChooseGame)),
              new FlatButton(child: new Text('Join Game')),
              new FlatButton(child: new Text('Settings'))
            ], direction: FlexDirection.vertical));
      case logic_croupier.CroupierState.Settings:
        return null; // in which we let them pick an avatar, name, and color. And return to the previous screen after (NOT IMPLEMENTED YET)
      case logic_croupier.CroupierState.ChooseGame:
        // in which we let them pick a game out of the many possible games... There aren't that many.
        return new Container(
            padding: new EdgeDims.only(top: sky.view.paddingTop),
            child: new Flex([
              new FlatButton(
                  child: new Text('Proto'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.PlayGame,
                      logic_game.GameType.Proto)),
              new FlatButton(
                  child: new Text('Hearts'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.PlayGame,
                      logic_game.GameType.Hearts)),
              new FlatButton(child: new Text('Poker')),
              new FlatButton(child: new Text('Solitaire')),
              new FlatButton(
                  child: new Text('Syncbase Echo'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.PlayGame,
                      logic_game.GameType.SyncbaseEcho))
            ], direction: FlexDirection.vertical));
      case logic_croupier.CroupierState.AwaitGame:
        return null; // in which players wait for game invitations to arrive.
      case logic_croupier.CroupierState.ArrangePlayers:
        return null; // If needed, lists the players around and what devices they'd like to use.
      case logic_croupier.CroupierState.PlayGame:
        return new Container(
            padding: new EdgeDims.only(top: sky.view.paddingTop),
            child: createGameComponent(croupier.game,
                makeSetStateCallback(logic_croupier.CroupierState.Welcome)));
      default:
        assert(false);
        return null;
    }
  }
}
