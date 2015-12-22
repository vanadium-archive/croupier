// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class Text {
  static final TextStyle titleStyle = new TextStyle(fontSize: 18.0);
  static final TextStyle subtitleStyle =
      new TextStyle(fontSize: 12.0, color: secondaryTextColor);
  static final TextStyle liveNow =
      new TextStyle(fontSize: 12.0, color: theme.accentColor);
  static final TextStyle error = new TextStyle(color: errorColor);
  static final TextStyle hugeStyle = new TextStyle(fontSize: 32.0);
  static final TextStyle hugeRedStyle =
      new TextStyle(fontSize: 32.0, color: errorColor);
  static final TextStyle largeStyle = new TextStyle(fontSize: 24.0);
  static final TextStyle largeRedStyle =
      new TextStyle(fontSize: 24.0, color: errorColor);
  static final TextStyle splash =
      new TextStyle(fontSize: 16.0, color: Colors.white);
}

class Size {
  static const double splashLogo = 75.0;
  static const double settingsSize = 125.0;
}

class Spacing {
  static final EdgeDims smallPaddingSide =
      new EdgeDims.symmetric(horizontal: 5.0);
  static final EdgeDims smallPadding = new EdgeDims.all(5.0);
  static final EdgeDims normalPadding = new EdgeDims.all(10.0);
}

class Box {
  static final BoxDecoration liveNow = new BoxDecoration(
      border: new Border.all(color: theme.accentColor), borderRadius: 2.0);
  static final BoxDecoration liveBackground =
      new BoxDecoration(backgroundColor: theme.accentColor);
  static final BoxDecoration background =
      new BoxDecoration(backgroundColor: theme.primaryColor);
  static final BoxDecoration brightBackground =
      new BoxDecoration(backgroundColor: theme.primarySwatch[100]);
  static final BoxDecoration errorBackground =
      new BoxDecoration(backgroundColor: errorColor);
  static final BoxDecoration border = new BoxDecoration(
      border: new Border.all(color: theme.primaryColor), borderRadius: 2.0);
  static final BoxDecoration borderInactive = new BoxDecoration(
      border: new Border.all(color: Colors.grey[300]), borderRadius: 2.0);
}

Color secondaryTextColor = Colors.grey[500];
Color errorColor = Colors.red[500];
ThemeData theme = new ThemeData(
    primarySwatch: Colors.blueGrey, accentColor: Colors.orangeAccent[700]);
