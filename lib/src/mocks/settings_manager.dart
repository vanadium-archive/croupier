// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import '../../logic/croupier_settings.dart' show CroupierSettings;
import '../../logic/game/game.dart' as logic_game;
import '../../settings/client.dart' as settings_client;
import 'util.dart' as util;

class SettingsManager {
  final util.keyValueCallback updateCallback;
  final util.keyValueCallback updateGamesCallback;
  final util.keyValueCallback updatePlayerFoundCallback;
  final util.keyValueCallback updateGameStatusCallback;
  final util.asyncKeyValueCallback updateGameLogCallback;

  SettingsManager(
      settings_client.AppSettings _,
      this.updateCallback,
      this.updateGamesCallback,
      this.updatePlayerFoundCallback,
      this.updateGameStatusCallback,
      this.updateGameLogCallback);

  Map<String, String> _data = new Map<String, String>();

  Future<String> load([int userID]) {
    if (userID == null) {
      if (_data["settings"] == null) {
        CroupierSettings settings = new CroupierSettings.random();
        String jsonStr = settings.toJSONString();
        _data["settings"] = jsonStr;
      }
      return new Future<String>(() => _data["settings"]);
    }
    return new Future<String>(() => _data["${userID}"]);
  }

  Future save(int userID, String data) {
    _data["settings"] = data;
    _data["${userID}"] = data;
    return new Future(() => null);
  }

  Future createSettingsSyncgroup() {
    return new Future(() => null);
  }

  Future scanSettings() {
    return new Future(() => null);
  }

  Future stopScanSettings() {
    return new Future(() => null);
  }

  Future advertiseSettings(logic_game.GameStartData gsd) {
    return new Future(() => null);
  }

  Future stopAdvertiseSettings() {
    return new Future(() => null);
  }

  Future createGameSyncgroup(String type, int gameID) {
    return new Future(() => null);
  }

  Future joinGameSyncgroup(String sgName, int gameID) {
    return new Future(() => null);
  }

  Future setPlayerNumber(int gameID, int userID, int playerNumber) async {
    return new Future(() => null);
  }

  Future setGameStatus(int gameID, String status) async {
    return new Future(() => null);
  }

  Future<String> getGameStatus(int gameID) async {
    return new Future(() => null);
  }

  Future<logic_game.GameStartData> getGameStartData(int gameID) async {
    return new Future(() => null);
  }

  Future<String> getGameSyncgroup(int gameID) async {
    return new Future(() => null);
  }

  void quitGame() {}
}
