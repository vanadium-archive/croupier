// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// The goal of log writer is to generically manage game logs.
/// Syncbase will produce values that combine to form a List<GameCommand> while
/// the in-memory GameLog will also hold such a list.
///
/// Updating the GameLog from the Store/Syncbase:
/// GameLog will update to whatever Store data says.
/// If it merges, the game log, then it will write that information off.
/// Case A: Store is farther along than current state.
/// Continue.
/// Case B: Store is somehow behind the current state.
/// Update with the current state of the GameLog (if not sent yet).
/// Case C: Store's log branches off from the curernt GameLog.
/// Depending on phase, resolve the conflict differently and write the resolution.
///
/// Updating the Store:
/// When a new GameCommand is received (that doesn't contradict the existing log),
/// it is added to a list of pending changes and written to the local store.

/// Since this file includes Sky/Mojo, it will need to be mocked out for unit tests.
/// Unfortunately, imports can't be replaced, so the best thing to do is to swap out the whole file.

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:sky/services.dart' show embedder;

import 'package:ether/syncbase_client.dart'
    show Perms, SyncbaseClient, SyncbaseTable;

log(String msg) {
  DateTime now = new DateTime.now();
  print('$now $msg');
}

Perms emptyPerms() => new Perms()..json = '{}';

class LogWriter {
  final Function updateCallback; // Takes in Map<String, String> data
  final SyncbaseClient _syncbaseClient;

  LogWriter(this.updateCallback)
      : _syncbaseClient = new SyncbaseClient(embedder.connectToService,
            'https://mojo.v.io/syncbase_server.mojo');

  int seq = 0;
  SyncbaseTable tb;
  String sendMsg, recvMsg, putStr, getStr;

  Future _doSyncbaseInit() async {
    log('LogWriter.doSyncbaseInit');
    if (tb != null) {
      log('syncbase already initialized');
      return;
    }
    var app = _syncbaseClient.app('app');
    if (!(await app.exists())) {
      await app.create(emptyPerms());
    }
    var db = app.noSqlDatabase('db');
    if (!(await db.exists())) {
      await db.create(emptyPerms());
    }
    var table = db.table('table');
    if (!(await table.exists())) {
      await table.create(emptyPerms());
    }
    tb = table;
    log('syncbase is now initialized');

    // TODO(alexfandrianto): I'm not sure how we setup 'watch', but we would do so here.
  }

  Future write(Map<String, String> data) async {
    log('LogWriter.write start');
    await _doSyncbaseInit();

    var row = tb.row('key');
    await row.put(UTF8.encode(JSON.encode(data)));

    // TODO(alexfandrianto): Normally, we would watch, but since I don't know how, I will just poll here.
    await _poll();
    log('LogWriter.start done');
  }

  Future _poll() async {
    log('LogWriter.poll start');
    await _doSyncbaseInit();

    // Realistically, we wouldn't write it all to a single row, but I don't think it matters right now.
    var row = tb.row('key');
    var getBytes = await row.get();

    Map<String, String> data = JSON.decode(UTF8.decode(getBytes));
    this.updateCallback(data);
    log('LogWriter.poll done');
  }
}
