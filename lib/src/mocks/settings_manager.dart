// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

typedef void updateCallbackT(String key, String value);

class SettingsManager {
  final updateCallbackT updateCallback;

  SettingsManager(this.updateCallback);

  Map<String, String> _data = new Map<String, String>();

  Future<String> load([int userID]) {
    if (userID == null) {
      return new Future<String>(() => _data["settings"]);
    }
    return new Future<String>(() => _data["${userID}"]);
  }

  Future save(int userID, String data) {
    _data["settings"] = data;
    _data["${userID}"] = data;
    return new Future(() => null);
  }
}
