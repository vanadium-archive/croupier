// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import '../settings/client.dart' show AppSettings;
import '../src/syncbase/settings_manager.dart' show SettingsManager;
import '../src/syncbase/util.dart' as sync_util;
import 'create_game.dart' as cg;
import 'croupier_settings.dart' show CroupierSettings;
import 'game/game.dart'
    show Game, GameType, GameStartData, stringToGameType, gameTypeToString;

enum CroupierState {
  Welcome,
  ChooseGame,
  JoinGame,
  ArrangePlayers,
  PlayGame,
  ResumeGame
}

typedef void NoArgCb();

class Croupier {
  AppSettings appSettings;
  CroupierState state;
  SettingsManager settings_manager;
  CroupierSettings settings; // null, but loaded asynchronously.
  Map<int,
      CroupierSettings> settings_everyone; // empty, but loaded asynchronously
  Map<String, GameStartData> games_found; // empty, but loads asynchronously
  Map<int, int> players_found; // empty, but loads asynchronously
  Game game; // null until chosen
  NoArgCb informUICb;

  // Futures to use in order to cancel scans and advertisements.
  Future _scanFuture;
  Future _advertiseFuture;

  bool debugMode = false; // whether to show debug buttons or not

  Croupier(this.appSettings) {
    state = CroupierState.Welcome;
    settings_everyone = new Map<int, CroupierSettings>();
    games_found = new Map<String, GameStartData>();
    players_found = new Map<int, int>();
    settings_manager = new SettingsManager(
        appSettings,
        _updateSettingsEveryoneCb,
        _updateGamesFoundCb,
        _updatePlayerFoundCb,
        _updateGameStatusCb);

    settings_manager.load().then((String csString) {
      settings = new CroupierSettings.fromJSONString(csString);
      if (this.informUICb != null) {
        this.informUICb();
      }
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

  int userIDFromPlayerNumber(int playerNumber) {
    return players_found.keys.firstWhere(
        (int user) => players_found[user] == playerNumber,
        orElse: () => null);
  }

  void _setCurrentGame(Game g) {
    game = g;
    settings.lastGameID = g.gameID;
    settings_manager.save(settings.userID, settings.toJSONString()); // async
  }

  Game _createNewGame(GameType gt) {
    return cg.createGame(gt, this.debugMode, isCreator: true);
  }

  Game _createExistingGame(GameStartData gsd) {
    return cg.createGame(stringToGameType(gsd.type), this.debugMode,
        gameID: gsd.gameID, playerNumber: gsd.playerNumber);
  }

  void _quitGame() {
    if (game != null) {
      game.quit();
      game = null;
    }
  }

  CroupierSettings settingsFromPlayerNumber(int playerNumber) {
    int userID = userIDFromPlayerNumber(playerNumber);
    if (userID != null) {
      return settings_everyone[userID];
    }
    return null;
  }

  void _updatePlayerFoundCb(String playerKey, String playerNum) {
    String gameIDStr = sync_util.gameIDFromGameKey(playerKey);
    if (game == null || game.gameID != int.parse(gameIDStr)) {
      return; // ignore
    }
    String playerID = sync_util.playerIDFromPlayerKey(playerKey);
    int id = int.parse(playerID);
    if (playerNum == null) {
      if (!players_found.containsKey(id)) {
        // The player exists but has not sat down yet.
        players_found[id] = null;
      }
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

  void _updateGameStatusCb(String statusKey, String newStatus) {
    String gameIDStr = sync_util.gameIDFromGameKey(statusKey);
    if (game == null || game.gameID != int.parse(gameIDStr)) {
      return; // ignore
    }
    switch (newStatus) {
      case "RUNNING":
        if (state == CroupierState.ArrangePlayers) {
          game.startGameSignal();
          setState(CroupierState.PlayGame, null);
        } else if (state == CroupierState.ResumeGame) {
          game.startGameSignal();
        }
        break;
      default:
        print("Ignoring new status: ${newStatus}");
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
        // data should be empty unless nextState is ResumeGame.
        if (nextState != CroupierState.ResumeGame) {
          assert(data == null);
        }
        break;
      case CroupierState.ChooseGame:
        if (data == null) {
          // Back button pressed.
          break;
        }
        assert(nextState == CroupierState.ArrangePlayers);

        // data should be the game id here.
        GameType gt = data as GameType;
        _setCurrentGame(_createNewGame(gt));

        _advertiseFuture = settings_manager
            .createGameSyncgroup(gameTypeToString(gt), game.gameID)
            .then((GameStartData gsd) {
          // The game creator should always sit as player 0, at least initially.
          settings_manager.setPlayerNumber(gsd.gameID, settings.userID, 0);
          // Only the game chooser should be advertising the game.
          return settings_manager.advertiseSettings(gsd);
        }); // don't wait for this future.

        break;
      case CroupierState.JoinGame:
        // Note that if we were in join game, we must have been scanning.
        _scanFuture.then((_) {
          settings_manager.stopScanSettings();
          games_found.clear();
          _scanFuture = null;
        });

        if (data == null) {
          // Back button pressed.
          break;
        }

        // data would probably be the game id again.
        GameStartData gsd = data as GameStartData;
        gsd.playerNumber = null; // At first, there is no player number.
        _setCurrentGame(_createExistingGame(gsd));
        String sgName;
        games_found.forEach((String name, GameStartData g) {
          if (g == gsd) {
            sgName = name;
          }
        });
        assert(sgName != null);

        players_found[gsd.ownerID] = null;
        settings_manager.joinGameSyncgroup(sgName, gsd.gameID).then((_) {
          if (!game.gameArrangeData.needsArrangement) {
            settings_manager.setPlayerNumber(gsd.gameID, settings.userID, 0);
          }
        });

        break;
      case CroupierState.ArrangePlayers:
        // Note that if we were arranging players, we might have been advertising.
        if (_advertiseFuture != null) {
          _advertiseFuture.then((_) {
            settings_manager.stopAdvertiseSettings();
            _advertiseFuture = null;
          });
        }

        // The signal to start or quit is not anything special.
        // data should be empty.
        assert(data == null);
        break;
      case CroupierState.PlayGame:
        break;
      case CroupierState.ResumeGame:
        // Data might be GameStartData. If so, then we must advertise it.
        GameStartData gsd = data;
        if (gsd != null) {
          _advertiseFuture = settings_manager.advertiseSettings(gsd);
        }
        break;
      default:
        assert(false);
    }

    // A simplified way of clearing out the games and players found.
    // They will need to be re-discovered in the future.
    switch (nextState) {
      case CroupierState.Welcome:
        games_found.clear();
        players_found.clear();
        _quitGame();
        break;
      case CroupierState.JoinGame:
        // Start scanning for games since that's what's next for you.
        _scanFuture =
            settings_manager.scanSettings(); // don't wait for this future.
        break;
      case CroupierState.ResumeGame:
        // We need to create the game again.
        int gameIDData = data;
        _resumeGameAsynchronously(gameIDData);
        break;
      default:
        break;
    }

    state = nextState;
  }

  // Resumes the game from the given gameID.
  Future _resumeGameAsynchronously(int gameIDData) async {
    GameStartData gsd = await settings_manager.getGameStartData(gameIDData);
    bool wasOwner = (gsd.ownerID == settings?.userID);
    print(
        "The game was ${gsd.toJSONString()}, and was I the owner? ${wasOwner}");
    _setCurrentGame(_createExistingGame(gsd));

    String sgName = await settings_manager.getGameSyncgroup(gameIDData);
    print("The sg name was ${sgName}");
    await settings_manager.joinGameSyncgroup(sgName, gameIDData);

    // Since initial scan processing is done, we can now set isCreator
    game.isCreator = wasOwner;
    String gameStatus = await settings_manager.getGameStatus(gameIDData);

    print("The game's status was ${gameStatus}");
    // Depending on the game state, we should go to a different screen.
    switch (gameStatus) {
      case "RUNNING":
        // The game is running, so let's play it!
        setState(CroupierState.PlayGame, null);
        break;
      default:
        // We are still arranging players, so we need to advertise our game
        // start data.
        setState(CroupierState.ArrangePlayers, gsd);
        break;
    }

    // And we can ask the UI to redraw
    if (this.informUICb != null) {
      this.informUICb();
    }
  }
}
