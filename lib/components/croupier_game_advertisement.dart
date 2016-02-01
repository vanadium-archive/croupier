// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'croupier_profile.dart';
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' as game;
import '../styles/common.dart' as style;

class CroupierGameAdvertisementComponent extends StatelessComponent {
  final CroupierSettings settings;
  final game.GameStartData gameStartData;
  final VoidCallback onTap;

  CroupierGameAdvertisementComponent(this.gameStartData,
      {CroupierSettings settings, this.onTap})
      : settings = settings ?? new CroupierSettings.placeholder();

  Widget build(BuildContext context) {
    return new GestureDetector(
        child: new Card(
            child: new Row(children: [
          new Card(
              child: new CroupierProfileComponent(
                  settings: settings,
                  height: style.Size.settingsHeight,
                  width: style.Size.settingsWidth)),
          new Text(game.gameTypeToString(gameStartData.gameType),
              style: style.Text.hugeStyle),
        ])),
        onTap: onTap);
  }
}
