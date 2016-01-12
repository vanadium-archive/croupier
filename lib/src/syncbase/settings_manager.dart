// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Since this file includes Sky/Mojo, it will need to be mocked out for unit
/// tests.
/// Unfortunately, imports can't be replaced, so the best thing to do is to swap
/// out the whole file.
///
/// The goal of the SettingsManager is to handle viewing and editing of the
/// Croupier Settings.
/// loadSettings: Get the settings of the current player or specified userID.
/// saveSettings: For the current player and their userID, save settings.
/// In the background, these values will be synced.
/// When setting up a syncgroup, the userIDs are very important.

import '../../settings/client.dart' as settings_client;
import '../../logic/game/game.dart' as logic_game;
import '../../logic/croupier_settings.dart' show CroupierSettings;
import 'croupier_client.dart' show CroupierClient;
import 'discovery_client.dart' show DiscoveryClient;
import 'util.dart' as util;

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:v23discovery/discovery.dart' as discovery;
import 'package:syncbase/syncbase_client.dart' as sc;

class SettingsManager {
  final util.keyValueCallback updateSettingsCallback;
  final util.keyValueCallback updateGamesCallback;
  final util.keyValueCallback updatePlayerFoundCallback;
  final util.keyValueCallback updateGameStatusCallback;
  final util.asyncKeyValueCallback updateGameLogCallback;
  final CroupierClient _cc;
  sc.SyncbaseTable tb;

  static const String _discoveryGameAdKey = "discovery-game-ad";

  // The game subscription. Cancel when done listening.
  StreamSubscription<sc.WatchChange> _gameSubscription;

  SettingsManager(
      settings_client.AppSettings appSettings,
      this.updateSettingsCallback,
      this.updateGamesCallback,
      this.updatePlayerFoundCallback,
      this.updateGameStatusCallback,
      this.updateGameLogCallback)
      : _cc = new CroupierClient(appSettings);

  Future _prepareSettingsTable() async {
    if (tb != null) {
      return; // Then we're already prepared.
    }

    sc.SyncbaseDatabase db = await _cc.createDatabase();
    tb = await _cc.createTable(db, util.tableNameSettings);

    // Start to watch the stream for the shared settings table.
    await _cc.watchEverything(db, util.tableNameSettings,
        util.settingsWatchSyncPrefix, _onSettingsChange);
  }

  // In the case of the settings manager, we're checking for any changes to
  // any person's Croupier Settings.
  Future _onSettingsChange(String key, String value, bool duringScan) async {
    this.updateSettingsCallback(util.userIDFromSettingsDataKey(key), value);
  }

  // Guaranteed to be called when the program starts.
  // If no Croupier Settings exist, then random ones are created.
  Future<String> load() async {
    util.log('SettingsManager.load');
    await _prepareSettingsTable();

    int userID = await _getUserID();
    if (userID == null) {
      CroupierSettings settings = new CroupierSettings.random();
      String jsonStr = settings.toJSONString();
      await this.save(settings.userID, jsonStr);
      return jsonStr;
    } else {
      return await _tryReadData(tb, util.settingsDataKeyFromUserID(userID));
    }
  }

  Future<String> _tryReadData(sc.SyncbaseTable st, String rowkey) async {
    var row = st.row(rowkey);
    if (!(await row.exists())) {
      print("${rowkey} did not exist");
      return null;
    }
    return UTF8.decode(await row.get());
  }

  // Note: only the current user is allowed to save settings.
  // This means we can also save their user id.
  // All other settings will be synced instead.
  Future save(int userID, String jsonString) async {
    util.log('SettingsManager.save');
    await _prepareSettingsTable();

    await tb.row(util.settingsPersonalKey).put(UTF8.encode("${userID}"));
    await tb
        .row(util.settingsDataKeyFromUserID(userID))
        .put(UTF8.encode(jsonString));
  }

  // Best called after load(), to ensure that there are settings in the table.
  Future createSettingsSyncgroup() async {
    int id = await _getUserID();

    _cc.createSyncgroup(
        await _mySettingsSyncgroupName(), util.tableNameSettings,
        prefix: util.settingsDataKeyFromUserID(id));
  }

  Future<String> _mySettingsSyncgroupName() async {
    return _cc.makeSyncgroupName(await _syncSettingsSuffix());
  }

  // Forward any player changes and game status signals to Croupier's logic.
  // TODO(alexfandrianto): This also watches the log (but doesn't process it.
  Future _onGameChange(String key, String value, bool duringScan) async {
    if (key.indexOf("/players") != -1) {
      if (this.updatePlayerFoundCallback != null) {
        String type = util.playerUpdateTypeFromPlayerKey(key);
        switch (type) {
          case "player_number":
            // Update the player number for this player.
            this.updatePlayerFoundCallback(key, value);
            break;
          case "settings_sg":
            // Join this player's settings syncgroup.
            _cc.joinSyncgroup(value);

            // Also, signal that this player has been found.
            this.updatePlayerFoundCallback(key, null);
            break;
          default:
            print("Unexpected key: ${key} with value ${value}");
            assert(false);
        }
      }
    } else if (key.indexOf("/status") != -1) {
      if (this.updateGameStatusCallback != null) {
        this.updateGameStatusCallback(key, value);
      }
    } else if (key.indexOf("/log") != -1) {
      if (this.updateGameLogCallback != null) {
        await this.updateGameLogCallback(key, value, duringScan);
      }
    }
  }

  Future<logic_game.GameStartData> createGameSyncgroup(
      String type, int gameID) async {
    print("Creating game syncgroup for ${type} and ${gameID}");
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    // Watch all the data in the game.
    assert(_gameSubscription == null);
    _gameSubscription = await _cc.watchEverything(
        db, util.tableNameGames, util.syncgamePrefix(gameID), _onGameChange,
        sorter: (sc.WatchChange a, sc.WatchChange b) {
      return a.rowKey.compareTo(b.rowKey);
    });

    print("Now writing to some rows of ${gameID}");
    // Start up the table and write yourself as player 0.
    await gameTable.row(util.gameTypeKey(gameID)).put(UTF8.encode("${type}"));

    int id = await _getUserID();
    await gameTable.row(util.gameOwnerKey(gameID)).put(UTF8.encode("${id}"));
    await gameTable
        .row(util.playerSettingsKeyFromData(gameID, id))
        .put(UTF8.encode(await _mySettingsSyncgroupName()));

    logic_game.GameStartData gsd =
        new logic_game.GameStartData(type, 0, gameID, id);

    String sgName = _cc.makeSyncgroupName(util.syncgameSuffix("${gsd.gameID}"));

    await gameTable.row(util.gameSyncgroupKey(gameID)).put(UTF8.encode(sgName));

    await _cc.createSyncgroup(sgName, util.tableNameGames,
        prefix: util.syncgamePrefix(gameID));

    return gsd;
  }

  void quitGame() {
    if (_gameSubscription != null) {
      _gameSubscription.cancel();
      _gameSubscription = null;
    }
  }

  Future joinGameSyncgroup(String sgName, int gameID) async {
    print("Now joining game syncgroup at ${sgName} and ${gameID}");

    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    // Watch for the players in the game.
    _gameSubscription = await _cc.watchEverything(
        db, util.tableNameGames, util.syncgamePrefix(gameID), _onGameChange);

    await _cc.joinSyncgroup(sgName);

    int id = await _getUserID();
    await gameTable
        .row(util.playerSettingsKeyFromData(gameID, id))
        .put(UTF8.encode(await _mySettingsSyncgroupName()));
  }

  Future setPlayerNumber(int gameID, int userID, int playerNumber) async {
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    await gameTable
        .row(util.playerNumberKeyFromData(gameID, userID))
        .put(UTF8.encode("${playerNumber}"));
  }

  Future setGameStatus(int gameID, String status) async {
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    await gameTable.row(util.gameStatusKey(gameID)).put(UTF8.encode(status));
  }

  Future<String> getGameStatus(int gameID) async {
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    return _tryReadData(gameTable, util.gameStatusKey(gameID));
  }

  Future<String> getGameSyncgroup(int gameID) async {
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);
    return _tryReadData(gameTable, util.gameSyncgroupKey(gameID));
  }

  Future<logic_game.GameStartData> getGameStartData(int gameID) async {
    sc.SyncbaseDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    String owner = await _tryReadData(gameTable, util.gameOwnerKey(gameID));
    String type = await _tryReadData(gameTable, util.gameTypeKey(gameID));

    int id = await _getUserID();
    String playerNumber =
        await _tryReadData(gameTable, util.playerNumberKeyFromData(gameID, id));
    int pn = playerNumber != null ? int.parse(playerNumber) : null;

    return new logic_game.GameStartData(type, pn, gameID, int.parse(owner));
  }

  // TODO(alexfandrianto): It is possible that the more efficient way of
  // scanning is to do it for only short bursts. In that case, we should call
  // stopScanSettings a few seconds after starting it.

  // Someone who is creating a game should scan for players who wish to join.
  Future scanSettings() async {
    SettingsScanHandler ssh =
        new SettingsScanHandler(_cc, this.updateGamesCallback);
    return _cc.discoveryClient.scan(_discoveryGameAdKey,
        'v.InterfaceName="${util.discoveryInterfaceName}"', ssh);
  }

  Future stopScanSettings() {
    return _cc.discoveryClient.stopScan(_discoveryGameAdKey);
  }

  // Someone who wants to join a game should advertise their presence.
  Future advertiseSettings(logic_game.GameStartData gsd) async {
    String settingsSuffix = await _syncSettingsSuffix();
    String gameSuffix = util.syncgameSuffix("${gsd.gameID}");
    return _cc.discoveryClient.advertise(
        _discoveryGameAdKey,
        DiscoveryClient.serviceMaker(
            interfaceName: util.discoveryInterfaceName,
            attrs: <String, String>{
              util.syncgameSettingsAttr: _cc.makeSyncgroupName(settingsSuffix),
              util.syncgameGameStartDataAttr: gsd.toJSONString()
            },
            addrs: <String>[_cc.makeSyncgroupName(gameSuffix)]));
  }

  Future stopAdvertiseSettings() {
    return _cc.discoveryClient.stopAdvertise(_discoveryGameAdKey);
  }

  Future<int> _getUserID() async {
    String result = await _tryReadData(tb, util.settingsPersonalKey);
    if (result == null) {
      return null;
    }
    return int.parse(result);
  }

  Future<String> _syncSettingsSuffix([int userID]) async {
    int id = userID;
    if (id == null) {
      id = await _getUserID();
    }

    return "${util.sgSuffix}-${id}";
  }
}

// Implementation of the ScanHandler for Settings information.
// Upon finding a settings advertiser, you want to join the syncgroup that
// they're advertising.
class SettingsScanHandler extends discovery.ScanHandler {
  CroupierClient _cc;
  Map<String, String> settingsAddrs;
  Map<String, String> gameAddrs;
  util.keyValueCallback updateGamesCallback;

  SettingsScanHandler(this._cc, this.updateGamesCallback) {
    settingsAddrs = new Map<String, String>();
    gameAddrs = new Map<String, String>();
  }

  void found(discovery.Service s) {
    util.log(
        "SettingsScanHandler Found ${s.instanceId} ${s.instanceName} ${s.addrs}");

    if (s.addrs.length == 1 && s.attrs != null) {
      // Note: Assumes 1 address and attributes for the game.
      settingsAddrs[s.instanceId] = s.attrs[util.syncgameSettingsAttr];
      gameAddrs[s.instanceId] = s.addrs[0];

      String gameSettingsJSON = s.attrs[util.syncgameGameStartDataAttr];
      updateGamesCallback(gameAddrs[s.instanceId], gameSettingsJSON);

      _cc.joinSyncgroup(settingsAddrs[s.instanceId]);
    } else {
      // An unexpected service was found. Who is advertising it?
      // https://github.com/vanadium/issues/issues/846
      util.log("Unexpected service found: ${s.toString()}");
    }
  }

  void lost(String instanceId) {
    util.log("SettingsScanHandler Lost ${instanceId}");

    // TODO(alexfandrianto): Leave the syncgroup?
    // Looks like leave isn't actually implemented, so we can't do this.
    String addr = gameAddrs[instanceId];
    if (addr != null) {
      updateGamesCallback(addr, null);
    }
    settingsAddrs.remove(instanceId);
    gameAddrs.remove(instanceId);
  }
}
