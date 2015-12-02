// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

class AppSettings {
  String deviceID;
  String mounttable;

  AppSettings.fromJson(String json) {
    Map map = JSON.decode(json);
    deviceID = map['deviceID'];
    mounttable = map['mounttable'];
  }
}

const String settingsFilePath = '/sdcard/croupier_settings.json';

Future<AppSettings> getSettings() async {
  String settingsJson = await new File(settingsFilePath).readAsString();
  return new AppSettings.fromJson(settingsJson);
}
