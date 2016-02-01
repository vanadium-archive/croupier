// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'package:syncbase/syncbase_client.dart' show Perms, SyncbaseClient;

const String appName = 'app';
const String dbName = 'db';
const String tableNameGames = 'games';
const String tableNameSettings = 'table_settings';

String makeSgPrefix(String mounttable, String deviceID) {
  return "${mounttable}/croupier-${deviceID}/%%sync";
}

const String sgSuffix = 'discovery';
const String sgSuffixGame = 'gaming';

const String discoveryInterfaceName = 'CroupierSettingsAndGame';

const String settingsPersonalKey = "personal";
const String settingsWatchSyncPrefix = "users";

typedef void keyValueCallback(String key, String value);
typedef Future asyncKeyValueCallback(String key, String value, bool duringScan);

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

const String separator = "/";

String gameIDFromGameKey(String gameKey) {
  List<String> parts = gameKey.split(separator);
  return parts[0];
}

String playerUpdateTypeFromPlayerKey(String playerKey) {
  return _getPartFromBack(playerKey, 0);
}

String playerIDFromPlayerKey(String playerKey) {
  return _getPartFromBack(playerKey, 1);
}

String gameOwnerKey(int gameID) {
  return "${gameID}/owner";
}

String gameTypeKey(int gameID) {
  return "${gameID}/type";
}

String gameStatusKey(int gameID) {
  return "${gameID}/status";
}

String gameSyncgroupKey(int gameID) {
  return "${gameID}/game_sg";
}

String playerSettingsKeyFromData(int gameID, int userID) {
  return "${gameID}/players/${userID}/settings_sg";
}

String playerNumberKeyFromData(int gameID, int userID) {
  return "${gameID}/players/${userID}/player_number";
}

bool isSettingsKey(String key) {
  return key.indexOf(settingsWatchSyncPrefix) == 0 && key.endsWith("/settings");
}

String settingsDataKeyFromUserID(int userID) {
  return "${settingsWatchSyncPrefix}/${userID}/settings";
}

String userIDFromSettingsDataKey(String dataKey) {
  List<String> parts = dataKey.split("/");
  return parts[parts.length - 2];
}

String _getPartFromBack(String input, int indexFromLast) {
  List<String> parts = input.split(separator);
  return parts[parts.length - 1 - indexFromLast];
}
