// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Since this file includes Sky/Mojo, it will need to be mocked out for unit tests.
/// Unfortunately, imports can't be replaced, so the best thing to do is to swap out the whole file.
///
/// The goal of the SettingsManager is to handle viewing and editing of the
/// Croupier Settings.
/// loadSettings: Get the settings of the current player or specified userID.
/// saveSettings: For the current player and their userID, save settings.
/// In the background, these values will be synced.
/// When setting up a sync group, the userIDs are very important.

import '../../logic/croupier_settings.dart' as util;
import 'croupier_client.dart' show CroupierClient;
import 'util.dart' as util;

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:ether/syncbase_client.dart'
    show SyncbaseNoSqlDatabase, SyncbaseTable, WatchChange, WatchChangeTypes;

typedef void updateCallbackT(String key, String value);

class SettingsManager {
  final updateCallbackT updateCallback;
  final CroupierClient _cc;

  SyncbaseTable tb;
  SyncbaseTable tbUser;

  SettingsManager([this.updateCallback]) : _cc = new CroupierClient();

  Future _prepareSettingsTable() async {
    if (tb != null && tbUser != null) {
      return; // Then we're already prepared.
    }

    SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    tb = await _cc.createTable(db, util.tableNameSettings);
    tbUser = await _cc.createTable(db, util.tableNameSettingsUser);

    // Start to watch the stream for the shared settings table.
    Stream<WatchChange> watchStream =
        db.watch(util.tableNameSettings, '', await db.getResumeMarker());
    _startWatch(watchStream); // Don't wait for this future.
  }

  Future<String> load([int userID]) async {
    util.log('SettingsManager.load');
    await _prepareSettingsTable();

    if (userID == null) {
      return _tryReadData(tbUser, "settings");
    }
    return _tryReadData(tb, "${userID}");
  }

  Future<String> _tryReadData(SyncbaseTable st, String rowkey) async {
    var row = st.row(rowkey);
    if (!(await row.exists())) {
      print("${rowkey} did not exist");
      return null;
    }
    return UTF8.decode(await row.get());
  }

  // Since only the current user is allowed to save, we should also save to the
  // user's personal settings as well.
  Future save(int userID, String jsonString) async {
    util.log('SettingsManager.save');
    await _prepareSettingsTable();

    await tbUser.row("settings").put(UTF8.encode(jsonString));
    await tb.row("${userID}").put(UTF8.encode(jsonString));
  }

  Future _startWatch(Stream<WatchChange> watchStream) async {
    util.log('Settings watching for changes...');
    // This stream never really ends, so I guess we'll watch forever.
    await for (WatchChange wc in watchStream) {
      assert(wc.tableName == util.tableNameSettings);
      util.log('Watch Key: ${wc.rowKey}');
      util.log('Watch Value ${UTF8.decode(wc.valueBytes)}');
      String key = wc.rowKey;
      String value;
      switch (wc.changeType) {
        case WatchChangeTypes.put:
          value = UTF8.decode(wc.valueBytes);
          break;
        case WatchChangeTypes.delete:
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
}
