// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'util.dart' as util;
import '../../logic/game/game.dart' as logic_game;
import '../../logic/croupier_settings.dart' show CroupierSettings;

class SettingsManager {
  final util.updateCallbackT updateCallback;
  final util.updateCallbackT updateGamesCallback;
  final util.updateCallbackT updatePlayerFoundCallback;

  SettingsManager(this.updateCallback, this.updateGamesCallback,
      this.updatePlayerFoundCallback);

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

  void stopScanSettings() {}

  Future advertiseSettings(logic_game.GameStartData gsd) {
    return new Future(() => null);
  }

  void stopAdvertiseSettings() {}

  Future createGameSyncgroup(String type, int gameID) {
    return new Future(() => null);
  }

  Future joinGameSyncgroup(String sgName, int gameID) {
    return new Future(() => null);
  }
}
