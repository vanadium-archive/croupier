// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show UTF8;

import '../../logic/game.dart' show Game;

import 'package:sky/mojo/embedder.dart' show embedder;

import 'package:ether/echo_client.dart' show EchoClient;
import 'package:ether/syncbase_client.dart'
    show Perms, SyncbaseClient, SyncbaseTable;

log(String msg) {
  DateTime now = new DateTime.now();
  print('$now $msg');
}

Perms emptyPerms() => new Perms()..json = '{}';

class SyncbaseEchoImpl {
  final EchoClient _echoClient;
  final SyncbaseClient _syncbaseClient;
  final Game game;

  SyncbaseEchoImpl(this.game)
      : _echoClient = new EchoClient(
            embedder.connectToService, 'https://mojo.v.io/echo_server.mojo'),
        _syncbaseClient = new SyncbaseClient(embedder.connectToService,
            'https://mojo.v.io/syncbase_server.mojo');

  int seq = 0;
  SyncbaseTable tb;
  String sendMsg, recvMsg, putStr, getStr;

  Future doEcho() async {
    log('DemoApp.doEcho');

    sendMsg = seq.toString();
    recvMsg = '';
    seq++;
    log('setState sendMsg done');

    String recvMsgAsync = await _echoClient.echo(sendMsg);

    recvMsg = recvMsgAsync;
    log('setState recvMsg done');

    game.updateCallback(); // tell the UI to set/update state.
  }

  Future doSyncbaseInit() async {
    log('DemoApp.doSyncbaseInit');
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
  }

  Future doPutGet() async {
    log('DemoApp.doPutGet');
    await doSyncbaseInit();

    putStr = seq.toString();
    getStr = '';
    seq++;
    log('setState putStr done');

    // TODO(sadovsky): Switch to tb.put/get once they exist.
    var row = tb.row('key');
    await row.put(UTF8.encode(putStr));
    var getBytes = await row.get();

    getStr = UTF8.decode(getBytes);
    log('setState getStr done');

    game.updateCallback(); // tell the UI to set/update state.
  }
}
