// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:syncbase/syncbase_client.dart' show Perms, SyncbaseClient;

const String appName = 'app';
const String dbName = 'db';
const String tableNameGames = 'games';
const String tableNameSettings = 'table_settings';

// TODO(alexfandrianto): This may need to be the global mount table with a
// proxy. Otherwise, it will be difficult for other users to run.
// https://github.com/vanadium/issues/issues/782
const String mtAddr = '/192.168.86.254:8101';
const String sgPrefix = 'croupierAlex/%%sync';
const String sgSuffix = 'discovery';
const String sgSuffixGame = 'gaming';

const String discoveryInterfaceName = 'CroupierSettingsAndGame2';

typedef void NoArgCb();
typedef void keyValueCallback(String key, String value);

const String openPermsJson =
    '{"Admin":{"In":["..."]},"Write":{"In":["..."]},"Read":{"In":["..."]},"Resolve":{"In":["..."]},"Debug":{"In":["..."]}}';
Perms openPerms = SyncbaseClient.perms(openPermsJson);

void log(String msg) {
  DateTime now = new DateTime.now();
  print('$now $msg');
}

// data should contain a JSON-encoded logic_game.GameStartData
String syncgameSuffix(String data) {
  return "${sgSuffixGame}-${data}";
}

String syncgamePrefix(int gameID) {
  return "${gameID}";
}

const String syncgameSettingsAttr = "settings_sgname";
const String syncgameGameStartDataAttr = "game_start_data";
