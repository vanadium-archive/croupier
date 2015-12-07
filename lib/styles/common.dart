// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class Text {
  static final Color secondaryTextColor = Colors.grey[500];
  static final Color errorTextColor = Colors.red[500];
  static final TextStyle titleStyle = new TextStyle(fontSize: 18.0);
  static final TextStyle subtitleStyle =
      new TextStyle(fontSize: 12.0, color: secondaryTextColor);
  static final TextStyle liveNow =
      new TextStyle(fontSize: 12.0, color: theme.accentColor);
  static final TextStyle error = new TextStyle(color: errorTextColor);
  static final TextStyle hugeStyle = new TextStyle(fontSize: 32.0);
  static final TextStyle hugeRedStyle =
      new TextStyle(fontSize: 32.0, color: errorTextColor);
  static final TextStyle largeStyle = new TextStyle(fontSize: 24.0);
  static final TextStyle largeRedStyle =
      new TextStyle(fontSize: 24.0, color: errorTextColor);
}

class Size {
  static const double thumbnailWidth = 250.0;
  static const double listHeight = 150.0;
  static const double thumbnailNavHeight = 150.0;
  static const double thumbnailNavWidth = 267.0;
}

class Spacing {
  static final EdgeDims extraSmallPadding = new EdgeDims.all(2.0);
  static final EdgeDims smallPadding = new EdgeDims.all(5.0);
  static final EdgeDims normalPadding = new EdgeDims.all(10.0);
  static final EdgeDims normalMargin = new EdgeDims.all(2.0);
  static final EdgeDims listItemMargin = new EdgeDims.TRBL(3.0, 6.0, 0.0, 6.0);
  static final EdgeDims thumbnailNavMargin = new EdgeDims.all(3.0);
}

class Box {
  static final BoxDecoration liveNow = new BoxDecoration(
      border: new Border.all(color: theme.accentColor), borderRadius: 2.0);
  static final BoxDecoration border = new BoxDecoration(
      border: new Border.all(color: theme.primaryColor), borderRadius: 2.0);
  static final BoxDecoration borderInactive = new BoxDecoration(
      border: new Border.all(color: Colors.grey[300]), borderRadius: 2.0);
}

ThemeData theme = new ThemeData(
    primarySwatch: Colors.blueGrey, accentColor: Colors.orangeAccent[700]);
