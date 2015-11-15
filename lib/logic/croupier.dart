// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'game/game.dart'
    show Game, GameType, GameStartData, stringToGameType, gameTypeToString;
import 'create_game.dart' as cg;
import 'croupier_settings.dart' show CroupierSettings;
import '../src/syncbase/settings_manager.dart' show SettingsManager;

enum CroupierState {
  Welcome,
  Settings,
  ChooseGame,
  JoinGame,
  ArrangePlayers,
  PlayGame
}

typedef void NoArgCb();

class Croupier {
  CroupierState state;
  SettingsManager settings_manager;
  CroupierSettings settings; // null, but loaded asynchronously.
  Map<int,
      CroupierSettings> settings_everyone; // empty, but loaded asynchronously
  Map<String, GameStartData> games_found; // empty, but loads asynchronously
  Map<int, int> players_found; // empty, but loads asynchronously
  Game game; // null until chosen
  NoArgCb informUICb;

  Croupier() {
    state = CroupierState.Welcome;
    settings_everyone = new Map<int, CroupierSettings>();
    games_found = new Map<String, GameStartData>();
    players_found = new Map<int, int>();
    settings_manager = new SettingsManager(
        _updateSettingsEveryoneCb, _updateGamesFoundCb, _updatePlayerFoundCb);

    settings_manager.load().then((String csString) {
      settings = new CroupierSettings.fromJSONString(csString);
      settings_manager.createSettingsSyncgroup(); // don't wait for this future.
    });
  }

  // Updates the settings_everyone map as people join the main Croupier syncgroup
  // and change their settings.
  void _updateSettingsEveryoneCb(String key, String json) {
    settings_everyone[int.parse(key)] =
        new CroupierSettings.fromJSONString(json);
    if (this.informUICb != null) {
      this.informUICb();
    }
  }

  void _updateGamesFoundCb(String gameAddr, String jsonData) {
    if (jsonData == null) {
      games_found.remove(gameAddr);
    } else {
      GameStartData gsd = new GameStartData.fromJSONString(jsonData);
      games_found[gameAddr] = gsd;
    }
    if (this.informUICb != null) {
      this.informUICb();
    }
  }

  void _updatePlayerFoundCb(String playerID, String playerNum) {
    int id = int.parse(playerID);
    if (playerNum == null) {
      games_found.remove(id);
    } else {
      int playerNumber = int.parse(playerNum);
      players_found[id] = playerNumber;

      // If the player number changed was ours, then set it on our game.
      if (id == settings.userID) {
        game.playerNumber = playerNumber;
      }
    }
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

        // Start scanning for games if that's what's next for you.
        if (nextState == CroupierState.JoinGame) {
          settings_manager.scanSettings(); // don't wait for this future.
        }

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
        assert(nextState == CroupierState.ArrangePlayers);

        // data should be the game id here.
        GameType gt = data as GameType;
        game = cg.createGame(gt, 0); // Start as player 0 of whatever game type.

        settings_manager
            .createGameSyncgroup(gameTypeToString(gt), game.gameID)
            .then((GameStartData gsd) {
          // Only the game chooser should be advertising the game.
          settings_manager
              .advertiseSettings(gsd); // don't wait for this future.
        });

        break;
      case CroupierState.JoinGame:
        // Note that if we were in join game, we must have been scanning.
        settings_manager.stopScanSettings();

        if (data == null) {
          // Back button pressed.
          break;
        }

        // data would probably be the game id again.
        GameStartData gsd = data as GameStartData;
        game = cg.createGame(stringToGameType(gsd.type), gsd.playerNumber,
            gameID: gsd.gameID); // Start as player 0 of whatever game type.
        String sgName;
        games_found.forEach((String name, GameStartData g) {
          if (g == gsd) {
            sgName = name;
          }
        });
        assert(sgName != null);

        settings_manager.joinGameSyncgroup(sgName, gsd.gameID);
        break;
      case CroupierState.ArrangePlayers:
        // Note that if we were arranging players, we might have been advertising.
        settings_manager.stopAdvertiseSettings();

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

    // A simplified way of clearing out the games and players found.
    // They will need to be re-discovered in the future.
    if (nextState == CroupierState.Welcome) {
      games_found = new Map<String, GameStartData>();
      players_found = new Map<int, int>();
    }

    state = nextState;
  }
}
