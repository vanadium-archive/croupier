// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'game/game.dart' as game_impl;
import 'hearts/hearts.dart' as hearts_impl;
import 'proto/proto.dart' as proto_impl;
import 'solitaire/solitaire.dart' as solitaire_impl;

game_impl.Game createGame(game_impl.GameType gt, bool debugMode,
    {int gameID, bool isCreator}) {
  switch (gt) {
    case game_impl.GameType.Proto:
      return new proto_impl.ProtoGame(gameID: gameID, isCreator: isCreator)
        ..debugMode = debugMode;
    case game_impl.GameType.Hearts:
      return new hearts_impl.HeartsGame(gameID: gameID, isCreator: isCreator)
        ..debugMode = debugMode;
    case game_impl.GameType.Solitaire:
      return new solitaire_impl.SolitaireGame(
          gameID: gameID, isCreator: isCreator)..debugMode = debugMode;
    default:
      assert(false);
      return null;
  }
}
