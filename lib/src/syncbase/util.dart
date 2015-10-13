// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


import 'package:ether/syncbase_client.dart' show Perms, SyncbaseClient;

const appName = 'app';
const dbName = 'db';
const tableNameLog = 'table';
const tableNameSettings = 'table_settings';
const tableNameSettingsUser = 'table_settings_personal';

// TODO(alexfandrianto): This may need to be the global mount table with a
// proxy. Otherwise, it will be difficult for other users to run.
// https://github.com/vanadium/issues/issues/782
const mtAddr = '/192.168.86.254:8101';
const sgPrefix = 'croupier/%%sync';
const sgName = 'discovery';

typedef void updateCallbackT(String key, String value);

String openPermsJson =
    '{"Admin":{"In":["..."]},"Write":{"In":["..."]},"Read":{"In":["..."]},"Resolve":{"In":["..."]},"Debug":{"In":["..."]}}';
Perms openPerms = SyncbaseClient.perms(openPermsJson);

log(String msg) {
  DateTime now = new DateTime.now();
  print('$now $msg');
}
