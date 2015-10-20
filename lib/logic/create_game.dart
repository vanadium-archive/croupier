// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'game/game.dart' as game_impl;
import 'hearts/hearts.dart' as hearts_impl;
import 'proto/proto.dart' as proto_impl;
import 'solitaire/solitaire.dart' as solitaire_impl;

game_impl.Game createGame(game_impl.GameType gt, int pn) {
  switch (gt) {
    case game_impl.GameType.Proto:
      return new proto_impl.ProtoGame(pn);
    case game_impl.GameType.Hearts:
      return new hearts_impl.HeartsGame(pn);
    case game_impl.GameType.Solitaire:
      return new solitaire_impl.SolitaireGame(pn);
    default:
      assert(false);
      return null;
  }
}
