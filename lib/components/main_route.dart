// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import '../styles/common.dart' as style;
import 'croupier.dart' show CroupierComponent;

final GlobalKey _scaffoldKey = new GlobalKey();

class MainRoute extends StatefulComponent {
  final Croupier croupier;

  MainRoute(this.croupier);

  MainRouteState createState() => new MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  Widget build(BuildContext context) {
    return new Scaffold(
        key: _scaffoldKey,
        toolBar: new ToolBar(
            left:
                new IconButton(icon: "navigation/menu", onPressed: _showDrawer),
            center: new Text('Croupier')),
        body: new Material(child: new CroupierComponent(config.croupier)));
  }

  void _showDrawer() {
    showDrawer(
        context: context,
        child: new Block(<Widget>[
          new DrawerHeader(
              child: new Text('Croupier', style: style.Text.titleStyle)),
          new DrawerItem(
              icon: 'action/settings',
              // TODO(alexfandrianto): Fix the Splash Screen, and we won't need
              // to check if settings is null here.
              // https://github.com/vanadium/issues/issues/958
              onPressed:
                  config.croupier.settings != null ? _handleShowSettings : null,
              child: new Text('Settings')),
          // TODO(alexfandrianto): Once Flutter alpha branch is updated, this
          // DrawerItem can have a Switch inside instead of DebugRoute.
          // https://github.com/vanadium/issues/issues/957
          new DrawerItem(
              icon: 'action/build',
              onPressed: _handleShowDebug,
              child: new Text('Debug Mode')),
          new DrawerItem(
              icon: 'action/help', child: new Text('Help & Feedback'))
        ]));
  }

  void _handleShowSettings() {
    Navigator.of(context)
      ..pop()
      ..pushNamed('/settings');
  }

  void _handleShowDebug() {
    Navigator.of(context)
      ..pop()
      ..pushNamed('/debug');
  }
}
