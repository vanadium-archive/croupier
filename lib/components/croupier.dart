// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/croupier.dart' as logic_croupier;
import '../logic/game/game.dart' as logic_game;
import 'game.dart' show createGameComponent, NoArgCb;

import 'package:sky/widgets_next.dart';

import 'dart:sky' as sky;

class CroupierComponent extends StatefulComponent {
  final NavigatorState navigator;
  final logic_croupier.Croupier croupier;

  CroupierComponent(this.navigator, this.croupier);

  CroupierComponentState createState() => new CroupierComponentState();
}

class CroupierComponentState extends State<CroupierComponent> {
  sky.Size screenSize;

  void initState(_) {
    super.initState(_);
    // TODO(alexfandrianto): sky.view.width and sky.view.height?
  }

  NoArgCb makeSetStateCallback(logic_croupier.CroupierState s,
      [var data = null]) {
    return () => setState(() {
          config.croupier.setState(s, data);
        });
  }

  void sizeChanged(sky.Size newSize) {
    print(newSize);
    screenSize = newSize;
  }

  Widget build(BuildContext context) {
    return new SizeObserver(callback: sizeChanged, child: _buildHelper());
  }

  Widget _buildHelper() {
    switch (config.croupier.state) {
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
              new FlatButton(child: new Text('Solitaire'))
            ], direction: FlexDirection.vertical));
      case logic_croupier.CroupierState.AwaitGame:
        return null; // in which players wait for game invitations to arrive.
      case logic_croupier.CroupierState.ArrangePlayers:
        return null; // If needed, lists the players around and what devices they'd like to use.
      case logic_croupier.CroupierState.PlayGame:
        return new Container(
            padding: new EdgeDims.only(top: sky.view.paddingTop),
            child: createGameComponent(config.navigator, config.croupier.game,
                makeSetStateCallback(logic_croupier.CroupierState.Welcome),
                width: screenSize.width, height: screenSize.height));
      default:
        assert(false);
        return null;
    }
  }
}
