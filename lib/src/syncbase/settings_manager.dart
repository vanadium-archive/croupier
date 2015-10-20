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

import '../../logic/croupier_settings.dart' as util;
import 'croupier_client.dart' show CroupierClient;
import 'util.dart' as util;

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:syncbase/syncbase_client.dart' as sc;
import 'package:syncbase/src/naming/util.dart' as naming;

class SettingsManager {
  final util.updateCallbackT updateCallback;
  final CroupierClient _cc;

  sc.SyncbaseTable tb;
  sc.SyncbaseTable tbUser;

  SettingsManager([this.updateCallback]) : _cc = new CroupierClient();

  Future _prepareSettingsTable() async {
    if (tb != null && tbUser != null) {
      return; // Then we're already prepared.
    }

    sc.SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    tb = await _cc.createTable(db, util.tableNameSettings);
    tbUser = await _cc.createTable(db, util.tableNameSettingsUser);

    // Start to watch the stream for the shared settings table.
    Stream<sc.WatchChange> watchStream =
        db.watch(util.tableNameSettings, '', await db.getResumeMarker());
    _startWatch(watchStream); // Don't wait for this future.
    _loadSettings(tb); // Don't wait for this future.

    // Don't wait for this future either.
    // TODO(alexfandrianto): This is a way to debug who is present in the syncgroup.
    // This should be removed in the near future, once we are more certain about
    // the syncgroups we have formed.
    _joinOrCreateSyncgroup().then((var sg) {
      new Timer.periodic(const Duration(seconds: 3), (Timer _) async {
        Map<String, sc.SyncgroupMemberInfo> members = await sg.getMembers();
        print("There are ${members.length} members.");
        print(members);
      });
    });
  }

  Future<String> load([int userID]) async {
    util.log('SettingsManager.load');
    await _prepareSettingsTable();

    if (userID == null) {
      return _tryReadData(tbUser, "settings");
    }
    return _tryReadData(tb, "${userID}");
  }

  Future<String> _tryReadData(sc.SyncbaseTable st, String rowkey) async {
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

  // When starting the settings manager, there may be settings already in the
  // store. Make sure to load those.
  Future _loadSettings(sc.SyncbaseTable tb) async {
    tb.scan(new sc.RowRange.prefix('')).forEach((sc.KeyValue kv) {
      this.updateCallback(kv.key, UTF8.decode(kv.value));
    });
  }


  Future<sc.SyncbaseSyncgroup> _joinOrCreateSyncgroup() async {

    sc.SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    String mtAddr = util.mtAddr;
    String tableName = util.tableNameSettings;

    var mtName = mtAddr;
    var sgPrefix = naming.join(mtName, util.sgPrefix);
    var sgName = naming.join(sgPrefix, util.sgName);
    var sg = db.syncgroup(sgName);

    print('SGNAME = $sgName');

    var myInfo = sc.SyncbaseClient.syncgroupMemberInfo(syncPriority: 3);

    try {
      print('trying to join syncgroup');
      await sg.join(myInfo);
      print('syncgroup join success');
    } catch (e) {
      // Syncgroup does not exist.
      print('syncgroup does not exist, creating it');

      var sgSpec = sc.SyncbaseClient.syncgroupSpec(
          // Sync the entire table.
          [sc.SyncbaseClient.syncgroupPrefix(tableName, '')],
          description: 'test syncgroup',
          perms: util.openPerms,
          mountTables: [mtName]);

      print('SGSPEC = $sgSpec');

      await sg.create(sgSpec, myInfo);
      print('syncgroup create success');
    }

    return sg;
  }

}
