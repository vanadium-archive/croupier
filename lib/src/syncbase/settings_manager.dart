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

import '../../logic/croupier_settings.dart' show CroupierSettings;
import 'croupier_client.dart' show CroupierClient;
import 'discovery_client.dart' show DiscoveryClient;
import 'util.dart' as util;

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:discovery/discovery.dart' as discovery;
import 'package:syncbase/syncbase_client.dart' as sc;

class SettingsManager {
  final util.updateCallbackT updateCallback;
  final CroupierClient _cc;
  sc.SyncbaseTable tb;

  static const String _discoverySettingsKey = "settings";
  static const String _personalKey = "personal";
  static const String _settingsWatchSyncPrefix = "users";

  SettingsManager([this.updateCallback]) : _cc = new CroupierClient();

  String _settingsDataKey(int userID) {
    return "${_settingsWatchSyncPrefix}/${userID}/settings";
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
    _startWatch(watchStream); // Don't wait for this future.
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
  Future _startWatch(Stream<sc.WatchChange> watchStream) async {
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

      if (this.updateCallback != null) {
        this.updateCallback(key, value);
      }
    }
  }

  // Best called after load(), to ensure that there are settings in the table.
  Future createSyncgroup() async {
    int id = await _getUserID();

    _cc.createSyncgroup(
        _cc.makeSyncgroupName(await _syncSuffix()), util.tableNameSettings,
        prefix: this._settingsDataKey(id));
  }

  // When starting the settings manager, there may be settings already in the
  // store. Make sure to load those.
  Future _loadSettings(sc.SyncbaseTable tb) async {
    tb
        .scan(new sc.RowRange.prefix(_settingsWatchSyncPrefix))
        .forEach((sc.KeyValue kv) {
      if (kv.key.endsWith("/settings")) {
        // Then we can process the value as if it were settings data.
        this.updateCallback(kv.key, UTF8.decode(kv.value));
      }
    });
  }

  // TODO(alexfandrianto): It is possible that the more efficient way of
  // scanning is to do it for only short bursts. In that case, we should call
  // stopScanSettings a few seconds after starting it.

  // Someone who is creating a game should scan for players who wish to join.
  Future scanSettings() async {
    SettingsScanHandler ssh = new SettingsScanHandler(_cc);
    _cc.discoveryClient.scan(_discoverySettingsKey, "CroupierSettings", ssh);
  }

  void stopScanSettings() {
    _cc.discoveryClient.stopScan(_discoverySettingsKey);
  }

  // Someone who wants to join a game should advertise their presence.
  Future advertiseSettings() async {
    String suffix = await _syncSuffix();
    _cc.discoveryClient.advertise(
        _discoverySettingsKey,
        DiscoveryClient.serviceMaker(
            interfaceName: "CroupierSettings",
            addrs: <String>[_cc.makeSyncgroupName(suffix)]));
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

  Future<String> _syncSuffix() async {
    int id = await _getUserID();

    return "${util.sgSuffix}${id}";
  }
}

// Implementation of the ScanHandler for Settings information.
// Upon finding a settings advertiser, you want to join the syncgroup that
// they're advertising.
class SettingsScanHandler extends discovery.ScanHandler {
  CroupierClient _cc;

  SettingsScanHandler(this._cc);

  void found(discovery.Service s) {
    util.log(
        "SettingsScanHandler Found ${s.instanceUuid} ${s.instanceName} ${s.addrs}");

    _cc.joinSyncgroup(s.addrs[0]);
  }

  void lost(List<int> instanceId) {
    util.log("SettingsScanHandler Lost ${instanceId}");

    // TODO(alexfandrianto): Leave the syncgroup?
    // Looks like leave isn't actually implemented, so we can't do this.
  }
}
