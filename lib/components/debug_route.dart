// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import '../styles/common.dart' as style;

// TODO(alexfandrianto): Remove this file once Flutter alpha branch is updated
// and this route's Switch can be placed within the DrawerItem.
// https://github.com/vanadium/issues/issues/957
class DebugRoute extends StatefulComponent {
  final Croupier croupier;

  DebugRoute(this.croupier);

  DebugRouteState createState() => new DebugRouteState();
}

class DebugRouteState extends State<DebugRoute> {
  Widget build(BuildContext context) {
    return new Scaffold(
        toolBar: _buildToolBar(), body: _buildDebugPane(context));
  }

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
            icon: "navigation/arrow_back",
            onPressed: () => Navigator.of(context).pop()),
        center: new Text("Debug Settings"));
  }

  Widget _buildDebugPane(BuildContext context) {
    return new Row([
      new Text('Debug Mode', style: style.Text.titleStyle),
      new Switch(value: config.croupier.debugMode, onChanged: _handleDebugMode),
    ],
        justifyContent: FlexJustifyContent.spaceAround,
        alignItems: FlexAlignItems.start);
  }

  void _handleDebugMode(bool value) {
    print("new value is ${value}. Old is ${config.croupier.debugMode}");
    setState(() {
      config.croupier.debugMode = value;
      if (config.croupier.game != null) {
        config.croupier.game.debugMode = value;
      }
    });
  }
}
