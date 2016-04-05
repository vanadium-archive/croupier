// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import '../logic/croupier.dart' show Croupier;
import '../styles/common.dart' as style;
import 'croupier.dart' show CroupierComponent;
import 'croupier_profile.dart' show CroupierProfileComponent;
import '../sound/sound_assets.dart';

final GlobalKey _scaffoldKey = new GlobalKey();

class MainRoute extends StatefulWidget {
  final Croupier croupier;
  final SoundAssets sounds;

  MainRoute(this.croupier, this.sounds);

  @override
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

  @override
  Widget build(BuildContext context) {
    if (config.croupier.settings == null) {
      return _buildSplashScreen();
    }
    return new Scaffold(
        key: _scaffoldKey,
        appBar: new AppBar(
            leading: new IconButton(
                icon: Icons.menu,
                onPressed: () => _scaffoldKey.currentState?.openDrawer()),
            title: new Text('Croupier')),
        body: new Material(
            child: new CroupierComponent(config.croupier, config.sounds)),
        drawer: _buildDrawer());
  }

  Widget _buildSplashScreen() {
    var stack = new Stack(children: [
      new AssetImage(name: 'images/splash/background.png', fit: ImageFit.cover),
      new Row(children: [
        new AssetImage(
            name: 'images/splash/flutter.png', width: style.Size.splashLogo),
        new AssetImage(
            name: 'images/splash/vanadium.png', width: style.Size.splashLogo)
      ], mainAxisAlignment: MainAxisAlignment.center),
      new Container(
          child: new Row(
              children: [
                new Text('Loading Croupier...', style: style.Text.splash)
              ],
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center),
          padding: style.Spacing.normalPadding)
    ]);
    return stack;
  }

  Widget _buildDrawer() {
    return new Drawer(child: new Block(children: <Widget>[
      new DrawerHeader(child: new BlockBody(children: [
        new CroupierProfileComponent(
            settings: config.croupier.settings,
            width: style.Size.settingsWidth,
            height: style.Size.settingsHeight),
        new Text('Croupier', style: style.Text.titleStyle)
      ])),
      new DrawerItem(
          icon: Icons.settings,
          // TODO(alexfandrianto): Fix the Splash Screen, and we won't need
          // to check if settings is null here.
          // https://github.com/vanadium/issues/issues/958
          onPressed:
              config.croupier.settings != null ? _handleShowSettings : null,
          child: new Text('Settings')),
      new DrawerItem(
          icon: Icons.build,
          child: new Row(children: [
            new Text('Debug Mode'),
            new Switch(
                value: config.croupier.debugMode, onChanged: _handleDebugMode)
          ], mainAxisAlignment: MainAxisAlignment.spaceBetween)),
      new DrawerItem(icon: Icons.help, child: new Text('Help & Feedback'))
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
