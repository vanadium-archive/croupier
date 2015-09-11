// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'game.dart' show Game, GameType;

enum CroupierState {
  Welcome,
  Settings,
  ChooseGame,
  AwaitGame,
  ArrangePlayers,
  PlayGame
}

class Croupier {
  CroupierState state;
  Settings settings;
  Game game; // null until chosen

  Croupier() {
    state = CroupierState.Welcome;
    // settings = new Settings.load(?); // Give it in the croupier constructor. The app itself should load this info.
  }

  // Sets the next part of croupier state.
  // Depending on the originating state, data can contain extra information that we need.
  void setState(CroupierState nextState, var data) {
    switch (state) {
      case CroupierState.Welcome:
        // data should be empty.
        assert(data == null);
        break;
      case CroupierState.Settings:
        // data should be empty.
        // All settings changes affect the croupier settings directly without changing app state.
        assert(data == null);
        break;
      case CroupierState.ChooseGame:
        // data should be the game id here.
        GameType gt = data as GameType;
        game = new Game(gt, 0); // Start as player 0 of whatever game type.
        break;
      case CroupierState.AwaitGame:
        // data would probably be the game id again.
        GameType gt = data as GameType;
        game = new Game(gt, 0); // Start as player 0 of whatever game type.
        break;
      case CroupierState.ArrangePlayers:
        // data should be empty.
        // All rearrangements affect the Game's player number without changing app state.
        break;
      case CroupierState.PlayGame:
        // data should be empty.
        // The signal to start really isn't anything special.
        break;
      default:
        assert(false);
    }

    state = nextState;
  }
}

class Settings {
  String avatar;
  String name;
  String color; // in hex?

  Settings(this.avatar, this.name, this.color);

  // Settings.load(String data) {}
  // String save() { return null; }
}
