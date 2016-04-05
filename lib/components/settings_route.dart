// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import 'croupier_settings.dart' show CroupierSettingsComponent;

class SettingsRoute extends StatelessWidget {
  final Croupier croupier;

  SettingsRoute(this.croupier);

  @override
  Widget build(BuildContext context) => new CroupierSettingsComponent(
      croupier.settings, croupier.settingsManager.save);
}
