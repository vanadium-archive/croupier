// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library game_component;

import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase, HeartsType;
import '../logic/solitaire/solitaire.dart' show SolitaireGame, SolitairePhase;
import 'board.dart' show HeartsBoard;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, Orientation, AcceptCb;

import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;

part 'hearts/hearts.part.dart';
part 'proto/proto.part.dart';
part 'solitaire/solitaire.part.dart';

typedef void NoArgCb();

abstract class GameComponent extends StatefulComponent {
  final Game game;
  final NoArgCb gameEndCallback;
  final double width;
  final double height;

  GameComponent(this.game, this.gameEndCallback,
      {this.width, this.height});
}

abstract class GameComponentState<T extends GameComponent> extends State<T> {
  void initState() {
    super.initState();

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

GameComponent createGameComponent(
    Game game, NoArgCb gameEndCallback,
    {double width, double height}) {
  switch (game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(game, gameEndCallback,
          width: width, height: height);
    case GameType.Hearts:
      return new HeartsGameComponent(game, gameEndCallback,
          width: width, height: height);
    case GameType.Solitaire:
      return new SolitaireGameComponent(game, gameEndCallback,
          width: width, height: height);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}
