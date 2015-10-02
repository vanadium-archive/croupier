// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library game_component;

import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase, HeartsType;
import 'board.dart' show HeartsBoard;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, Orientation;

import 'package:sky/widgets_next.dart';
import 'package:sky/material.dart' as material;

part 'hearts/hearts.part.dart';
part 'proto/proto.part.dart';

typedef void NoArgCb();

abstract class GameComponent extends StatefulComponent {
  final NavigatorState navigator;
  final Game game;
  final NoArgCb gameEndCallback;
  final double width;
  final double height;

  GameComponent(this.navigator, this.game, this.gameEndCallback, {this.width, this.height});
}

abstract class GameComponentState<T extends GameComponent> extends State<T> {
  void initState(_) {
    super.initState(_);

    config.game.updateCallback = update;
  }

  // This callback is used to force the UI to draw when state changes occur
  // outside of the UIs control (e.g., synced data).
  void update() {
    setState(() {});
  }

  // A helper that most subclasses use in order to quit their respective games.
  void _quitGameCallback() {
    setState(() {
      config.gameEndCallback();
    });
  }

  // A helper that subclasses might override to create buttons.
  Widget _makeButton(String text, NoArgCb callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  @override
  Widget build(BuildContext context); // still UNIMPLEMENTED
}

GameComponent createGameComponent(NavigatorState navigator, Game game, NoArgCb gameEndCallback,
    {double width, double height}) {
  switch (game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(navigator, game, gameEndCallback,
          width: width, height: height);
    case GameType.Hearts:
      return new HeartsGameComponent(navigator, game, gameEndCallback,
          width: width, height: height);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}
