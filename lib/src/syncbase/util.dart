// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

const appName = 'app';
const dbName = 'db';
const tableNameLog = 'table';
const tableNameSettings = 'table_settings';
const tableNameSettingsUser = 'table_settings_personal';

log(String msg) {
  DateTime now = new DateTime.now();
  print('$now $msg');
}
