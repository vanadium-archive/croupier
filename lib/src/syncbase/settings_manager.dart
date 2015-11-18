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
  final util.updateCallbackT updateSettingsCallback;
  final util.updateCallbackT updateGamesCallback;
  final util.updateCallbackT updatePlayerFoundCallback;
  final CroupierClient _cc;
  sc.SyncbaseTable tb;

  static const String _discoverySettingsKey = "settings";
  static const String _personalKey = "personal";
  static const String _settingsWatchSyncPrefix = "users";

  SettingsManager(this.updateSettingsCallback, this.updateGamesCallback,
      this.updatePlayerFoundCallback)
      : _cc = new CroupierClient();

  String _settingsDataKey(int userID) {
    return "${_settingsWatchSyncPrefix}/${userID}/settings";
  }

  String _settingsDataKeyUserID(String dataKey) {
    List<String> parts = dataKey.split("/");
    return parts[parts.length - 2];
  }

  Future _prepareSettingsTable() async {
    if (tb != null) {
      return; // Then we're already prepared.
    }

    sc.SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    tb = await _cc.createTable(db, util.tableNameSettings);

    // Start to watch the stream for the shared settings table.
    Stream<sc.WatchChange> watchStream = db.watch(util.tableNameSettings,
        _settingsWatchSyncPrefix, await db.getResumeMarker());
    _startWatchSettings(watchStream); // Don't wait for this future.
    _loadSettings(tb); // Don't wait for this future.
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
      return await _tryReadData(tb, this._settingsDataKey(userID));
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

    await tb.row(_personalKey).put(UTF8.encode("${userID}"));
    await tb.row(this._settingsDataKey(userID)).put(UTF8.encode(jsonString));
  }

  // This watch method ensures that any changes are propagated to the caller.
  // In the case of the settings manager, we're checking for any changes to
  // any person's Croupier Settings.
  Future _startWatchSettings(Stream<sc.WatchChange> watchStream) async {
    util.log('Settings watching for changes...');
    // This stream never really ends, so I guess we'll watch forever.
    await for (sc.WatchChange wc in watchStream) {
      assert(wc.tableName == util.tableNameSettings);
      util.log('Watch Key: ${wc.rowKey}');
      util.log('Watch Value ${UTF8.decode(wc.valueBytes)}');
      String key = wc.rowKey;
      String value;
      switch (wc.changeType) {
        case sc.WatchChangeTypes.put:
          value = UTF8.decode(wc.valueBytes);
          break;
        case sc.WatchChangeTypes.delete:
          value = null;
          break;
        default:
          assert(false);
      }

      if (this.updateSettingsCallback != null) {
        this.updateSettingsCallback(_settingsDataKeyUserID(key), value);
      }
    }
  }

  // Best called after load(), to ensure that there are settings in the table.
  Future createSettingsSyncgroup() async {
    int id = await _getUserID();

    _cc.createSyncgroup(
        _cc.makeSyncgroupName(await _syncSuffix()), util.tableNameSettings,
        prefix: this._settingsDataKey(id));
  }

  // This watch method ensures that any changes are propagated to the caller.
  // In this case, we're forwarding any player changes to the Croupier logic.
  Future _startWatchPlayers(Stream<sc.WatchChange> watchStream) async {
    util.log('Players watching for changes...');
    // This stream never really ends, so I guess we'll watch forever.
    await for (sc.WatchChange wc in watchStream) {
      assert(wc.tableName == util.tableNameGames);
      util.log('Watch Key: ${wc.rowKey}');
      util.log('Watch Value ${UTF8.decode(wc.valueBytes)}');
      String key = wc.rowKey;
      String value;
      switch (wc.changeType) {
        case sc.WatchChangeTypes.put:
          value = UTF8.decode(wc.valueBytes);
          break;
        case sc.WatchChangeTypes.delete:
          value = null;
          break;
        default:
          assert(false);
      }

      if (this.updatePlayerFoundCallback != null) {
        String playerID = _getPartFromBack(key, "/", 1);
        this.updatePlayerFoundCallback(playerID, value);

        // Also, you should be sure to join this person's syncgroup.
        _cc.joinSyncgroup(
            _cc.makeSyncgroupName(await _syncSuffix(int.parse(playerID))));
      }
    }
  }

  Future<logic_game.GameStartData> createGameSyncgroup(
      String type, int gameID) async {
    print("Creating game syncgroup for ${type} and ${gameID}");
    sc.SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    // Watch for the players in the game.
    Stream<sc.WatchChange> watchStream = db.watch(util.tableNameGames,
        util.syncgamePrefix(gameID) + "/players", await db.getResumeMarker());
    _startWatchPlayers(watchStream); // Don't wait for this future.

    print("Now writing to some rows of ${gameID}");
    // Start up the table and write yourself as player 0.
    await gameTable.row("${gameID}/type").put(UTF8.encode("${type}"));

    int id = await _getUserID();
    await gameTable.row("${gameID}/owner").put(UTF8.encode("${id}"));
    await gameTable
        .row("${gameID}/players/${id}/player_number")
        .put(UTF8.encode("0"));

    logic_game.GameStartData gsd =
        new logic_game.GameStartData(type, 0, gameID, id);

    await _cc.createSyncgroup(
        _cc.makeSyncgroupName(util.syncgameSuffix(gsd.toJSONString())),
        util.tableNameGames,
        prefix: util.syncgamePrefix(gameID));

    return gsd;
  }

  Future joinGameSyncgroup(String sgName, int gameID) async {
    print("Now joining game syncgroup at ${sgName} and ${gameID}");
    sc.SyncbaseSyncgroup sg = await _cc.joinSyncgroup(sgName);

    sc.SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    sc.SyncbaseTable gameTable = await _cc.createTable(db, util.tableNameGames);

    // Watch for the players in the game.
    Stream<sc.WatchChange> watchStream = db.watch(util.tableNameGames,
        util.syncgamePrefix(gameID) + "/players", await db.getResumeMarker());
    _startWatchPlayers(watchStream); // Don't wait for this future.

    // Also write yourself to the table as player |NUM_PLAYERS - 1|
    Map<String, sc.SyncgroupMemberInfo> fellowPlayers = await sg.getMembers();
    print("I have found! ${fellowPlayers} ${fellowPlayers.length}");

    int id = await _getUserID();
    int playerNumber = fellowPlayers.length - 1;
    gameTable
        .row("${gameID}/players/${id}/player_number")
        .put(UTF8.encode("${playerNumber}"));
  }

  // When starting the settings manager, there may be settings already in the
  // store. Make sure to load those.
  Future _loadSettings(sc.SyncbaseTable tb) async {
    tb
        .scan(new sc.RowRange.prefix(_settingsWatchSyncPrefix))
        .forEach((sc.KeyValue kv) {
      if (kv.key.endsWith("/settings")) {
        // Then we can process the value as if it were settings data.
        this.updateSettingsCallback(
            _settingsDataKeyUserID(kv.key), UTF8.decode(kv.value));
      }
    });
  }

  // TODO(alexfandrianto): It is possible that the more efficient way of
  // scanning is to do it for only short bursts. In that case, we should call
  // stopScanSettings a few seconds after starting it.

  // Someone who is creating a game should scan for players who wish to join.
  Future scanSettings() async {
    SettingsScanHandler ssh =
        new SettingsScanHandler(_cc, this.updateGamesCallback);
    _cc.discoveryClient
        .scan(_discoverySettingsKey, 'v.InterfaceName="${util.discoveryInterfaceName}"', ssh);
  }

  void stopScanSettings() {
    _cc.discoveryClient.stopScan(_discoverySettingsKey);
  }

  // Someone who wants to join a game should advertise their presence.
  Future advertiseSettings(logic_game.GameStartData gsd) async {
    String suffix = await _syncSuffix();
    String gameSuffix = util.syncgameSuffix(gsd.toJSONString());
    _cc.discoveryClient.advertise(
        _discoverySettingsKey,
        DiscoveryClient.serviceMaker(
            interfaceName: util.discoveryInterfaceName,
            addrs: <String>[
              _cc.makeSyncgroupName(suffix),
              _cc.makeSyncgroupName(gameSuffix)
            ]));
  }

  void stopAdvertiseSettings() {
    _cc.discoveryClient.stopAdvertise(_discoverySettingsKey);
  }

  Future<int> _getUserID() async {
    String result = await _tryReadData(tb, _personalKey);
    if (result == null) {
      return null;
    }
    return int.parse(result);
  }

  Future<String> _syncSuffix([int userID]) async {
    int id = userID;
    if (id == null) {
      id = await _getUserID();
    }

    return "${util.sgSuffix}-${id}";
  }
}

String _getPartFromBack(String input, String separator, int indexFromLast) {
  List<String> parts = input.split(separator);
  return parts[parts.length - 1 - indexFromLast];
}

// Implementation of the ScanHandler for Settings information.
// Upon finding a settings advertiser, you want to join the syncgroup that
// they're advertising.
class SettingsScanHandler extends discovery.ScanHandler {
  CroupierClient _cc;
  Map<List<int>, String> settingsAddrs;
  Map<List<int>, String> gameAddrs;
  util.updateCallbackT updateGamesCallback;

  SettingsScanHandler(this._cc, this.updateGamesCallback) {
    settingsAddrs = new Map<List<int>, String>();
    gameAddrs = new Map<List<int>, String>();
  }

  void found(discovery.Service s) {
    util.log(
        "SettingsScanHandler Found ${s.instanceUuid} ${s.instanceName} ${s.addrs}");

    if (s.addrs.length == 2) {
      // Note: Assumes 2 addresses.
      settingsAddrs[s.instanceUuid] = s.addrs[0];
      gameAddrs[s.instanceUuid] = s.addrs[1];

      String json = _getPartFromBack(s.addrs[1], "-", 0);
      updateGamesCallback(s.addrs[1], json);

      _cc.joinSyncgroup(s.addrs[0]);
    } else {
      // An unexpected service was found. Who is advertising it?
      // https://github.com/vanadium/issues/issues/846
      util.log("Unexpected service found: ${s.toString()}");
    }
  }

  void lost(List<int> instanceId) {
    util.log("SettingsScanHandler Lost ${instanceId}");

    // TODO(alexfandrianto): Leave the syncgroup?
    // Looks like leave isn't actually implemented, so we can't do this.
    String addr = gameAddrs[instanceId];
    if (addr != null) {
      List<String> parts = addr.split("-");
      String gameID = parts[parts.length - 1];
      updateGamesCallback(gameID, null);
    }
    settingsAddrs.remove(instanceId);
    gameAddrs.remove(instanceId);
  }
}
