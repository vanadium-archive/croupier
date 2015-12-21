// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show UTF8;
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show shell;
import 'package:syncbase/src/naming/util.dart' as naming;
import 'package:syncbase/syncbase_client.dart' as sc;
import 'package:v23discovery/discovery.dart' as discovery;

import '../../settings/client.dart' as settings_client;
import 'discovery_client.dart' show DiscoveryClient;
import 'util.dart' as util;

class CroupierClient {
  final sc.SyncbaseClient _syncbaseClient;
  final DiscoveryClient _discoveryClient;
  final settings_client.AppSettings appSettings;
  static final String syncbaseServerUrl = Platform.environment[
          'SYNCBASE_SERVER_URL'] ??
      'https://mojo.v.io/syncbase_server.mojo';

  static final String discoveryTestKey = "TEST";

  // We want CroupierClient to be a singleton for simplicity purposes.
  // This prevents duplicate table/database creation.
  // TODO(alexfandrianto): This is not a singleton if I give arguments.
  // That means later runs will ignore the settings.
  // https://github.com/vanadium/issues/issues/964
  static CroupierClient _singleton;
  factory CroupierClient(settings_client.AppSettings appSettings) {
    _singleton ??= new CroupierClient._internal(appSettings);
    return _singleton;
  }
  factory CroupierClient.singleton() {
    assert(_singleton != null);
    return _singleton;
  }

  CroupierClient._internal(this.appSettings)
      : _syncbaseClient =
            new sc.SyncbaseClient(shell.connectToService, syncbaseServerUrl),
        _discoveryClient = new DiscoveryClient() {
    print('Fetching syncbase_server.mojo from $syncbaseServerUrl');

    // TODO(alexfandrianto): Remove this test advertisement once we are more
    // comfortable with Discovery.
    String interfaceName = "HelloWorld!";
    _discoveryClient.scan(discoveryTestKey,
        'v.InterfaceName="${interfaceName}"', new MyScanHandler());
    _discoveryClient.advertise(
        discoveryTestKey,
        DiscoveryClient.serviceMaker(
            interfaceName: interfaceName, addrs: ["dummy address"]));
  }

  DiscoveryClient get discoveryClient => _discoveryClient;

  // TODO(alexfandrianto): Try not to call this twice at the same time.
  // That would lead to very race-y behavior.
  Future<sc.SyncbaseDatabase> createDatabase() async {
    util.log('CroupierClient.createDatabase');
    var app = _syncbaseClient.app(util.appName);
    if (!(await app.exists())) {
      await app.create(util.openPerms);
    }
    util.log('CroupierClient.got app');
    var db = app.noSqlDatabase(util.dbName);
    if (!(await db.exists())) {
      await db.create(util.openPerms);
    }
    util.log('CroupierClient.got db');
    return db;
  }

  // Use Table Lock to sort out multiple calls to createTable.
  Map<String, Completer<sc.SyncbaseTable>> _tableLock =
      new Map<String, Completer<sc.SyncbaseTable>>();
  Future<sc.SyncbaseTable> createTable(
      sc.SyncbaseDatabase db, String tableName) async {
    if (_tableLock[tableName] != null) {
      return _tableLock[tableName].future;
    }
    _tableLock[tableName] = new Completer<sc.SyncbaseTable>();
    sc.SyncbaseTable table = db.table(tableName);
    if (!(await table.exists())) {
      await table.create(util.openPerms);
    }
    util.log('CroupierClient: ${tableName} is ready');
    _tableLock[tableName].complete(table);
    return table;
  }

  // Creates (or joins) a syncgroup with the associated parameters.
  Future<sc.SyncbaseSyncgroup> createSyncgroup(String sgName, String tableName,
      {String prefix, String description, sc.Perms permissions}) async {
    util.log("CroupierClient: Creating syncgroup ${sgName}");

    // TODO(alexfandrianto): destroy is still unimplemented. Thus, we must do a
    // join or create for this syncgroup.
    try {
      util.log("CroupierClient: But first attempting to join ${sgName}");
      sc.SyncbaseSyncgroup sg = await joinSyncgroup(sgName);
      util.log("CroupierClient: Successfully joined ${sgName}");
      return sg;
    } catch (e) {
      util.log(
          "CroupierClient: ${sgName} doesn't exist, so actually creating it.");
    }

    var myInfo = sc.SyncbaseClient.syncgroupMemberInfo(syncPriority: 3);
    String mtName = this.appSettings.mounttable;

    sc.SyncbaseSyncgroup sg = await _getSyncgroup(sgName);
    var sgSpec = sc.SyncbaseClient.syncgroupSpec(
        // Sync the entire table.
        [sc.SyncbaseClient.syncgroupPrefix(tableName, prefix ?? "")],
        description: description ?? 'test syncgroup',
        perms: permissions ?? util.openPerms,
        mountTables: [mtName]);

    util.log('SGSPEC = $sgSpec');

    await sg.create(sgSpec, myInfo);

    return sg;
  }

  // Joins a syncgroup with the given name.
  Future<sc.SyncbaseSyncgroup> joinSyncgroup(String sgName) async {
    util.log("CroupierClient: Joining syncgroup ${sgName}");
    var myInfo = sc.SyncbaseClient.syncgroupMemberInfo(syncPriority: 3);

    sc.SyncbaseSyncgroup sg = await _getSyncgroup(sgName);
    await sg.join(myInfo);
    return sg;
  }

  // Helper to get the SyncbaseSyncgroup object from the string.
  Future<sc.SyncbaseSyncgroup> _getSyncgroup(String sgName) async {
    sc.SyncbaseDatabase db = await createDatabase();
    return db.syncgroup(sgName);
  }

  // Helper that converts a suffix to a syncgroup name.
  String makeSyncgroupName(String suffix) {
    String sgPrefix = util.makeSgPrefix(
        this.appSettings.mounttable, this.appSettings.deviceID);
    String sgName = naming.join(sgPrefix, suffix);
    return sgName;
  }

  // Creates a watch stream that lets you watch a bunch of updates.
  // In order to guarantee that you see everything, it also scans the whole
  // table and sorts the watch updates (if asked).
  // Finally, the return value is a completer that when completed stops
  // listening to the watch stream.
  Future<StreamSubscription<sc.WatchChange>> watchEverything(
      sc.SyncbaseDatabase db,
      String tbName,
      String prefix,
      util.asyncKeyValueCallback onChange,
      {Comparator<sc.WatchChange> sorter}) async {
    util.log('Watching for changes on ${tbName}:${prefix}...');

    // For safety, be certain that the syncbase table at tbName exists.
    await createTable(db, tbName);

    // In order to safely read all watch updates, we have to do a scan first.
    // See https://github.com/vanadium/issues/issues/917
    sc.SyncbaseBatchDatabase sbdb =
        await db.beginBatch(sc.SyncbaseClient.batchOptions(readOnly: true));
    List<int> resumeMarker;
    try {
      resumeMarker = await sbdb.getResumeMarker();

      sc.SyncbaseTable tb = sbdb.table(tbName);

      Stream<sc.KeyValue> scanStream =
          await tb.scan(new sc.RowRange.prefix(prefix));

      // Use an await for loop to ensure that each onChange event is processed
      // in order.
      await for (sc.KeyValue kv in scanStream) {
        String key = kv.key;
        String value = UTF8.decode(kv.value);
        print("Scan found ${key}, ${value}");
        await onChange(key, value, true);
      }
    } finally {
      await sbdb.abort();
    }

    // Now we can start watching from the batch's resume marker.
    Stream<sc.WatchChange> watchStream = db.watch(tbName, prefix, resumeMarker);

    // This list will queue up the changes of a watch batch sequence.
    List<sc.WatchChange> watchSequence = new List<sc.WatchChange>();

    // Define a change handler that will be applied whenever a WatchChange
    // arrives on the watchStream.
    _handleChange(sc.WatchChange wc) async {
      // Accumulate the WatchChange's in watchSequence.
      watchSequence.add(wc);
      if (wc.continued) {
        // Since there are more WatchChange's to collect, do not act yet.
        return;
      } else {
        // 1. Possibly sort the watchSequence by the optional sorter function.
        if (sorter != null) {
          watchSequence.sort(sorter);
        }

        // 2. Then run through each value in order.
        watchSequence.forEach((sc.WatchChange _w) async {
          String key = _w.rowKey;
          String value;
          switch (_w.changeType) {
            case sc.WatchChangeTypes.put:
              value = UTF8.decode(_w.valueBytes);
              break;
            case sc.WatchChangeTypes.delete:
              value = null;
              break;
            default:
              assert(false);
          }

          print("Watch found ${key}, ${value}");
          await onChange(key, value, false);
        });

        // 3. Then clear the watchSequence.
        watchSequence.clear();
      }
    }

    // Start listening on the watch stream using the change handler.
    return watchStream.listen((sc.WatchChange wc) => _handleChange(wc));
  }
}

// Example implementation of a ScanHandler.
class MyScanHandler extends discovery.ScanHandler {
  void found(discovery.Service s) {
    util.log("MYSCANHANDLER Found ${s.instanceId} ${s.instanceName}");
  }

  void lost(String instanceId) {
    util.log("MYSCANHANDLER Lost ${instanceId}");
  }
}
