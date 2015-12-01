// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier_settings.dart' show CroupierSettings;
import '../styles/common.dart' as style;

class CroupierProfileComponent extends StatelessComponent {
  final CroupierSettings settings;
  final double height;
  final double width;
  final bool isMini;

  static const double padAmount = 4.0;

  CroupierProfileComponent(
      {CroupierSettings settings, this.height, this.width, this.isMini: false})
      : settings = settings ?? new CroupierSettings.placeholder();

  Widget build(BuildContext context) {
    if (!isMini) {
      return new Card(
          color: new Color(settings.color),
          child: new Container(
              height: this.height,
              width: this.width,
              padding: const EdgeDims.all(padAmount),
              child: new Column([
                new AssetImage(
                    name: CroupierSettings.makeAvatarUrl(settings.avatar)),
                new Text(settings.name, style: style.Text.liveNow)
              ], justifyContent: FlexJustifyContent.spaceAround)));
    } else {
      return new Card(
          color: new Color(settings.color),
          child: new Container(
              width: this.width,
              height: this.height,
              padding: const EdgeDims.all(padAmount),
              child: new Row([
                new AssetImage(
                    name: CroupierSettings.makeAvatarUrl(settings.avatar),
                    width: this.width != null ? this.width - padAmount : null,
                    height:
                        this.height != null ? this.height - padAmount : null,
                    fit: ImageFit.scaleDown)
              ], justifyContent: FlexJustifyContent.collapse)));
    }
  }
}
