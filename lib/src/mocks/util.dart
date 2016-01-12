// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

typedef void keyValueCallback(String key, String value);
typedef Future asyncKeyValueCallback(String key, String value, bool duringScan);

String gameIDFromGameKey(String gameKey) {
  return null;
}

String playerIDFromPlayerKey(String playerKey) {
  return null;
}
