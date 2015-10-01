// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'util.dart' as util;

import 'dart:async';

import 'package:sky/services.dart' show embedder;
import 'package:ether/syncbase_client.dart'
    show Perms, SyncbaseClient, SyncbaseNoSqlDatabase, SyncbaseTable;

Perms emptyPerms() => new Perms()..json = '{}';

class CroupierClient {
  final SyncbaseClient _syncbaseClient;

  CroupierClient() :
    _syncbaseClient = new SyncbaseClient(embedder.connectToService,
      'https://mojo.v.io/syncbase_server.mojo');

  // TODO(alexfandrianto): Try not to call this twice at the same time.
  // That would lead to very race-y behavior.
  Future<SyncbaseNoSqlDatabase> createDatabase() async {
    util.log('CroupierClient.createDatabase');
    var app = _syncbaseClient.app(util.appName);
    if (!(await app.exists())) {
      await app.create(emptyPerms());
    }
    var db = app.noSqlDatabase(util.dbName);
    if (!(await db.exists())) {
      await db.create(emptyPerms());
    }
    return db;
  }

  // TODO(alexfandrianto): Try not to call this twice at the same time.
  // That would lead to very race-y behavior.
  Future<SyncbaseTable> createTable(SyncbaseNoSqlDatabase db, String tableName) async {
    var table = db.table(tableName);
    if (!(await table.exists())) {
      await table.create(emptyPerms());
    }
    util.log('CroupierClient: ${tableName} is ready');
    return table;
  }

}