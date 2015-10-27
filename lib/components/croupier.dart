// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/croupier.dart' as logic_croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' as logic_game;
import 'game.dart' as component_game;
import 'croupier_settings.dart' show CroupierSettingsComponent;
import 'croupier_profile.dart' show CroupierProfileComponent;

import 'package:flutter/material.dart';

import 'dart:ui' as ui;

typedef void NoArgCb();

class CroupierComponent extends StatefulComponent {
  final NavigatorState navigator;
  final logic_croupier.Croupier croupier;

  CroupierComponent(this.navigator, this.croupier);

  CroupierComponentState createState() => new CroupierComponentState();
}

class CroupierComponentState extends State<CroupierComponent> {
  ui.Size screenSize;

  void initState() {
    super.initState();
    // TODO(alexfandrianto): ui.view.width and ui.view.height?

    // Croupier (logic) needs this in case of syncbase watch updates.
    config.croupier.informUICb = _informUICb;
  }

  void _informUICb() {
    setState(() {});
  }

  NoArgCb makeSetStateCallback(logic_croupier.CroupierState s,
      [var data = null]) {
    return () => setState(() {
          config.croupier.setState(s, data);
        });
  }

  void sizeChanged(ui.Size newSize) {
    print(newSize);
    setState(() {
      screenSize = newSize;
    });
  }

  Widget build(BuildContext context) {
    return new SizeObserver(onSizeChanged: sizeChanged, child: _buildHelper());
  }

  Widget _buildHelper() {
    switch (config.croupier.state) {
      case logic_croupier.CroupierState.Welcome:
        // in which we show them a UI to start a new game, join a game, or change some settings.
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: new Column([
              new FlatButton(
                  child: new Text('Create Game'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ChooseGame)),
              new FlatButton(
                  child: new Text('Await Game'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.AwaitGame)),
              new FlatButton(
                  child: new Text('Settings'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.Settings))
            ]));
      case logic_croupier.CroupierState.Settings:
        // in which we let them pick an avatar, name, and color. And return to the previous screen after.
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: new CroupierSettingsComponent(
                config.navigator,
                config.croupier.settings,
                config.croupier.settings_manager.save,
                makeSetStateCallback(logic_croupier.CroupierState.Welcome)));
      case logic_croupier.CroupierState.ChooseGame:
        // in which we let them pick a game out of the many possible games... There aren't that many.
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: new Flex([
              new FlatButton(
                  child: new Text('Proto'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Proto)),
              new FlatButton(
                  child: new Text('Hearts'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Hearts)),
              new FlatButton(child: new Text('Poker')),
              new FlatButton(
                  child: new Text('Solitaire'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Solitaire)),
              new FlatButton(
                  child: new Text('Back'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.Welcome))
            ], direction: FlexDirection.vertical));
      case logic_croupier.CroupierState.AwaitGame:
        // in which players wait for game invitations to arrive.
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: new Column([
              new Text("Waiting for invitations..."),
              new FlatButton(
                  child: new Text('Back'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.Welcome))
            ]));
      case logic_croupier.CroupierState.ArrangePlayers:
        // A stateful view, first showing the players that can be invited.
        List<Widget> profileWidgets = new List<Widget>();
        config.croupier.settings_everyone.forEach((_, CroupierSettings cs) {
          profileWidgets.add(new CroupierProfileComponent(cs));
        });

        // TODO(alexfandrianto): You can only start the game once there are enough players.
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: new Column([
              new Grid(profileWidgets, maxChildExtent: 150.0),
              new FlatButton(
                  child: new Text('Start Game'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.PlayGame)),
              new FlatButton(
                  child: new Text('Back'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ChooseGame))
            ]));
      case logic_croupier.CroupierState.PlayGame:
        return new Container(
            padding: new EdgeDims.only(top: ui.view.paddingTop),
            child: component_game.createGameComponent(
                config.navigator, config.croupier.game, () {
              config.croupier.game.quit();
              makeSetStateCallback(logic_croupier.CroupierState.Welcome)();
            }, width: screenSize.width, height: screenSize.height));
      default:
        assert(false);
        return null;
    }
  }
}
