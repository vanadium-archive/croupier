// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier_settings.dart' show CroupierSettings;
import '../styles/common.dart' as style;

enum CroupierProfileComponentOrientation {
  DEFAULT,
  MINI,
  HORIZONTAL,
  TEXT_ONLY
}

class CroupierProfileComponent extends StatelessComponent {
  final CroupierSettings settings;
  final double height;
  final double width;
  final CroupierProfileComponentOrientation orientation;

  static const double padAmount = 4.0;

  CroupierProfileComponent(
      {CroupierSettings settings,
      this.height,
      this.width,
      this.orientation: CroupierProfileComponentOrientation.DEFAULT})
      : settings = settings ?? new CroupierSettings.placeholder();

  CroupierProfileComponent.mini(
      {CroupierSettings settings, double height, double width})
      : this(
            settings: settings,
            height: height,
            width: width,
            orientation: CroupierProfileComponentOrientation.MINI);

  CroupierProfileComponent.horizontal({CroupierSettings settings})
      : this(
            settings: settings,
            orientation: CroupierProfileComponentOrientation.HORIZONTAL);

  CroupierProfileComponent.textOnly({CroupierSettings settings})
      : this(
            settings: settings,
            orientation: CroupierProfileComponentOrientation.TEXT_ONLY);

  Widget build(BuildContext context) {
    switch (orientation) {
      case CroupierProfileComponentOrientation.DEFAULT:
        return new Container(
            height: this.height,
            width: this.width,
            padding: const EdgeDims.all(padAmount),
            child: new Card(
                color: new Color(settings.color),
                child: new Column(children: [
                  new AssetImage(
                      name: CroupierSettings.makeAvatarUrl(settings.avatar)),
                  new Text(settings.name, style: style.Text.largeStyle)
                ], justifyContent: FlexJustifyContent.spaceAround)));
      case CroupierProfileComponentOrientation.MINI:
        return new Container(
            width: this.width,
            height: this.height,
            padding: const EdgeDims.all(padAmount),
            child: new Card(
                color: new Color(settings.color),
                child: new Row(children: [
                  new AssetImage(
                      name: CroupierSettings.makeAvatarUrl(settings.avatar),
                      fit: ImageFit.scaleDown)
                ], justifyContent: FlexJustifyContent.spaceAround)));
      case CroupierProfileComponentOrientation.HORIZONTAL:
        return new Card(
            color: new Color(settings.color),
            child: new Container(
                padding: const EdgeDims.all(padAmount),
                child: new Row(children: [
                  new AssetImage(
                      name: CroupierSettings.makeAvatarUrl(settings.avatar),
                      fit: ImageFit.scaleDown),
                  new Text(settings.name, style: style.Text.hugeStyle)
                ], justifyContent: FlexJustifyContent.collapse)));
      case CroupierProfileComponentOrientation.TEXT_ONLY:
        return new Card(
            color: new Color(settings.color),
            child: new Container(
                padding: const EdgeDims.all(padAmount),
                child: new Row(children: [
                  new Text(settings.name, style: style.Text.largeStyle)
                ], justifyContent: FlexJustifyContent.collapse)));
    }
  }
}
