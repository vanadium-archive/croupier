// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import '../styles/common.dart' as style;
import 'croupier.dart' show CroupierComponent;
import 'croupier_profile.dart' show CroupierProfileComponent;

final GlobalKey _scaffoldKey = new GlobalKey();

class MainRoute extends StatefulComponent {
  final Croupier croupier;

  MainRoute(this.croupier);

  MainRouteState createState() => new MainRouteState();
}

class MainRouteState extends State<MainRoute> {
  @override
  void initState() {
    super.initState();
    // Croupier (logic) needs this in case of syncbase watch updates.
    config.croupier.informUICb = _informUICb;
  }

  void _informUICb() {
    if (this.mounted) {
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    // TODO(alexfandrianto): A better way to do this is to show the splash
    // screen while the Store is initializing.
    // https://github.com/vanadium/issues/issues/958
    if (config.croupier.settings == null) {
      return _buildSplashScreen();
    }
    return new Scaffold(
        key: _scaffoldKey,
        toolBar: new ToolBar(
            left: new IconButton(
                icon: "navigation/menu",
                onPressed: () => _scaffoldKey.currentState?.openDrawer()),
            center: new Text('Croupier')),
        body: new Material(child: new CroupierComponent(config.croupier)),
        drawer: _buildDrawer());
  }

  // TODO(alexfandrianto): Can we do better than this?
  Widget _buildSplashScreen() {
    var stack = new Stack([
      new AssetImage(name: 'images/splash/background.png', fit: ImageFit.cover),
      new Row([
        new AssetImage(
            name: 'images/splash/flutter.png', width: style.Size.splashLogo),
        new AssetImage(
            name: 'images/splash/vanadium.png', width: style.Size.splashLogo)
      ], justifyContent: FlexJustifyContent.center),
      new Container(
          child: new Row(
              [new Text('Loading Croupier...', style: style.Text.splash)],
              alignItems: FlexAlignItems.end,
              justifyContent: FlexJustifyContent.center),
          padding: style.Spacing.normalPadding)
    ]);
    return stack;
  }

  Widget _buildDrawer() {
    return new Drawer(
        child: new Block(<Widget>[
      new DrawerHeader(
          child: new BlockBody([
        new CroupierProfileComponent(
            settings: config.croupier.settings,
            width: style.Size.settingsSize,
            height: style.Size.settingsSize),
        new Text('Croupier', style: style.Text.titleStyle)
      ])),
      new DrawerItem(
          icon: 'action/settings',
          // TODO(alexfandrianto): Fix the Splash Screen, and we won't need
          // to check if settings is null here.
          // https://github.com/vanadium/issues/issues/958
          onPressed:
              config.croupier.settings != null ? _handleShowSettings : null,
          child: new Text('Settings')),
      new DrawerItem(
          icon: 'action/build',
          child: new Row([
            new Text('Debug Mode'),
            new Switch(
                value: config.croupier.debugMode, onChanged: _handleDebugMode)
          ], justifyContent: FlexJustifyContent.spaceBetween)),
      new DrawerItem(icon: 'action/help', child: new Text('Help & Feedback'))
    ]));
  }

  void _handleShowSettings() {
    Navigator.popAndPushNamed(context, '/settings');
  }

  void _handleDebugMode(bool value) {
    setState(() {
      config.croupier.debugMode = value;
      if (config.croupier.game != null) {
        config.croupier.game.debugMode = value;
      }
    });
  }
}
