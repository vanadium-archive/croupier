// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import 'croupier_settings.dart' show CroupierSettingsComponent;

class SettingsRoute extends StatelessComponent {
  final Croupier croupier;

  SettingsRoute(this.croupier);

  Widget build(BuildContext context) {
    return new CroupierSettingsComponent(
        croupier.settings, croupier.settings_manager.save);
  }
}
