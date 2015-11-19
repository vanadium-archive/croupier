// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/croupier_settings.dart' show CroupierSettings;

import 'package:flutter/material.dart';

class CroupierProfileComponent extends StatelessComponent {
  final CroupierSettings settings;
  CroupierProfileComponent(this.settings);

  Widget build(BuildContext context) {
    return new Container(
        decoration:
            new BoxDecoration(backgroundColor: new Color(settings.color)),
        child: new Column(
            [new AssetImage(name: CroupierSettings.makeAvatarUrl(settings.avatar)), new Text(settings.name)]));
  }
}
