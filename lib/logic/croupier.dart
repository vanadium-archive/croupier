// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'game/game.dart' show Game, GameType;
import 'create_game.dart' as cg;
import 'croupier_settings.dart' show CroupierSettings;
import '../src/syncbase/settings_manager.dart' show SettingsManager;

enum CroupierState {
  Welcome,
  Settings,
  ChooseGame,
  AwaitGame,
  ArrangePlayers,
  PlayGame
}

typedef void NoArgCb();

class Croupier {
  CroupierState state;
  SettingsManager settings_manager;
  CroupierSettings settings; // null, but loaded asynchronously.
  Map<String,
      CroupierSettings> settings_everyone; // empty, but loaded asynchronously
  Game game; // null until chosen
  NoArgCb informUICb;

  Croupier() {
    state = CroupierState.Welcome;
    settings_everyone = new Map<String, CroupierSettings>();
    settings_manager = new SettingsManager(_updateSettingsEveryoneCb);

    settings_manager.load().then((String csString) {
      settings = new CroupierSettings.fromJSONString(csString);
      settings_manager.createSyncgroup(); // don't wait for this future.
    });
  }

  // Updates the settings_everyone map as people join the main Croupier syncgroup
  // and change their settings.
  void _updateSettingsEveryoneCb(String key, String json) {
    settings_everyone[key] = new CroupierSettings.fromJSONString(json);
    if (this.informUICb != null) {
      this.informUICb();
    }
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
        if (data == null) {
          // Back button pressed.
          break;
        }
        // data should be the game id here.
        GameType gt = data as GameType;
        game = cg.createGame(gt, 0); // Start as player 0 of whatever game type.
        break;
      case CroupierState.AwaitGame:
        // Note that if we were in await game, we must have been advertising.
        settings_manager.stopAdvertiseSettings();

        if (data == null) {
          // Back button pressed.
          break;
        }

        // data would probably be the game id again.
        GameType gt = data as GameType;
        game = cg.createGame(gt, 0); // Start as player 0 of whatever game type.
        break;
      case CroupierState.ArrangePlayers:
        // Note that if we were arranging players, we must have been scanning.
        settings_manager.stopScanSettings();

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

    // TODO(alexfandrianto): We may want to have a splash screen or something
    // when the user first loads the app. It takes a few seconds before the
    // Syncbase tables are created.
    if (settings == null) {
      return; // you can't switch till the settings are present.
    }

    // The nextState you are switching to may require some behind-the-scenes
    // work.
    switch (nextState) {
      case CroupierState.ArrangePlayers:
        settings_manager.scanSettings(); // don't wait for this future.
        break;
      case CroupierState.AwaitGame:
        settings_manager.advertiseSettings(); // don't wait for this future.
        break;
      default:
    }

    state = nextState;
  }
}
