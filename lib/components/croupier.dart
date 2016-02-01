// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../logic/croupier.dart' as logic_croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' as logic_game;
import '../sound/sound_assets.dart';
import '../styles/common.dart' as style;
import 'croupier_game_advertisement.dart'
    show CroupierGameAdvertisementComponent;
import 'croupier_profile.dart' show CroupierProfileComponent;
import 'game.dart' as component_game;

GlobalObjectKey _gameKey = new GlobalObjectKey("CroupierGameKey");
GlobalObjectKey _gameArrangeKey = new GlobalObjectKey("CroupierGameArrangeKey");

class CroupierComponent extends StatefulComponent {
  final logic_croupier.Croupier croupier;
  final SoundAssets sounds;

  CroupierComponent(this.croupier, this.sounds);

  CroupierComponentState createState() => new CroupierComponentState();
}

class CroupierComponentState extends State<CroupierComponent> {
  VoidCallback makeSetStateCallback(logic_croupier.CroupierState s,
      [var data = null]) {
    return () => setState(() {
          config.croupier.setState(s, data);
        });
  }

  Widget build(BuildContext context) {
    switch (config.croupier.state) {
      case logic_croupier.CroupierState.welcome:
        // in which we show them a UI to start a new game, join a game, or change some settings.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Column(children: [
              new FlatButton(
                  child: new Text('Create Game', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.chooseGame)),
              new FlatButton(
                  child: new Text('Join Game', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.joinGame)),
              new FlatButton(
                  child: new Text('Resume Game', style: style.Text.titleStyle),
                  onPressed: config.croupier.settings.hasLastGame
                      ? makeSetStateCallback(
                          logic_croupier.CroupierState.resumeGame,
                          config.croupier.settings.lastGameID)
                      : null),
              new CroupierProfileComponent(
                  settings: config.croupier.settings,
                  width: style.Size.settingsWidth,
                  height: style.Size.settingsHeight)
            ]));
      case logic_croupier.CroupierState.chooseGame:
        // in which we let them pick a game out of the many possible games... There aren't that many.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Column(children: [
              new FlatButton(
                  child: new Text('Proto', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.arrangePlayers,
                      logic_game.GameType.proto)),
              new FlatButton(
                  child: new Text('Hearts', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.arrangePlayers,
                      logic_game.GameType.hearts)),
              new FlatButton(
                  child: new Text('Poker', style: style.Text.titleStyle)),
              new FlatButton(
                  child: new Text('Solitaire', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.arrangePlayers,
                      logic_game.GameType.solitaire)),
              new FlatButton(
                  child: new Text('Back', style: style.Text.subtitleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.welcome))
            ]));
      case logic_croupier.CroupierState.joinGame:
        // A stateful view, showing the game ads discovered.
        List<Widget> gameAdWidgets = new List<Widget>();
        if (config.croupier.games_found.length == 0) {
          gameAdWidgets.add(
              new Text("Looking for Games...", style: style.Text.titleStyle));
        } else {
          gameAdWidgets
              .add(new Text("Available Games", style: style.Text.titleStyle));
        }

        config.croupier.games_found
            .forEach((String _, logic_game.GameStartData gsd) {
          CroupierSettings cs = config.croupier.settings_everyone[gsd.ownerID];
          gameAdWidgets.add(new CroupierGameAdvertisementComponent(gsd,
              onTap: makeSetStateCallback(
                  logic_croupier.CroupierState.arrangePlayers, gsd),
              settings: cs));
        });

        gameAdWidgets.add(new FlatButton(
            child: new Text('Back', style: style.Text.subtitleStyle),
            onPressed:
                makeSetStateCallback(logic_croupier.CroupierState.welcome)));

        // in which players wait for game invitations to arrive.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Column(children: gameAdWidgets));
      case logic_croupier.CroupierState.arrangePlayers:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: _buildArrangePlayers());
      case logic_croupier.CroupierState.playGame:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: component_game.createGameComponent(
                config.croupier,
                config.sounds,
                makeSetStateCallback(logic_croupier.CroupierState.welcome),
                width: ui.window.size.width,
                height: ui.window.size.height - ui.window.padding.top,
                key: _gameKey));

      case logic_croupier.CroupierState.resumeGame:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Text("Resuming Game...", style: style.Text.titleStyle),
            width: ui.window.size.width,
            height: ui.window.size.height - ui.window.padding.top);
      default:
        assert(false);
        return null;
    }
  }

  // Show the player profiles. If needs arrangement, then the profile is only
  // shown if the person has not sat down yet.
  Widget _buildPlayerProfiles(bool needsArrangement) {
    List<Widget> profileWidgets = new List<Widget>();
    config.croupier.players_found.forEach((int userID, int playerNumber) {
      // Note: Even if cs is null, a placeholder will be shown instead.
      CroupierSettings cs = config.croupier.settings_everyone[userID];
      bool isMe = config.croupier.settings.userID == userID;
      Widget cpc = new Container(
          decoration: isMe ? style.Box.liveNow : null,
          child: new CroupierProfileComponent(
              settings: cs,
              height: style.Size.settingsHeight,
              width: style.Size.settingsWidth));

      // If the player profiles can be arranged, they should be draggable too.
      if (needsArrangement) {
        profileWidgets.add(new Draggable<CroupierSettings>(
            child: cpc, feedback: cpc, data: cs));
      } else {
        profileWidgets.add(cpc);
      }
    });

    if (needsArrangement) {
      return new ScrollableViewport(
          child: new Row(children: profileWidgets),
          scrollDirection: Axis.horizontal);
    }
    return new MaxTileWidthGrid(
        children: profileWidgets, maxTileWidth: style.Size.settingsWidth);
  }

  Widget _buildArrangePlayers() {
    List<Widget> allWidgets = new List<Widget>();

    logic_game.GameArrangeData gad = config.croupier.game.gameArrangeData;
    Iterable<int> playerNumbers = config.croupier.players_found.values;

    allWidgets.add(new Flexible(
        flex: 0,
        child: new Row(children: [
          new Text("${config.croupier.game.gameTypeName}",
              style: style.Text.hugeStyle)
        ], justifyContent: FlexJustifyContent.spaceAround)));

    // Then show the profile widgets of those who have joined the game.
    allWidgets.add(new Flexible(flex: 0, child: new Text("Player List")));
    allWidgets.add(new Flexible(
        flex: 1, child: _buildPlayerProfiles(gad.needsArrangement)));

    if (gad.needsArrangement) {
      // Games that need arrangement can show their game arrange component.
      allWidgets.add(component_game.createGameArrangeComponent(config.croupier,
          width: ui.window.size.width * 0.90,
          height: ui.window.size.height * 0.50,
          key: _gameArrangeKey));
    }

    // Allow games that can start with these players to begin.
    // Debug Mode should also go through.
    VoidCallback startCb;
    if (gad.canStart(playerNumbers) || config.croupier.debugMode) {
      startCb = () {
        config.croupier.settings_manager
            .setGameStatus(config.croupier.game.gameID, "RUNNING");

        // Since playerNumber starts out as null, we should set it to -1 if
        // the person pressed Start Game without sitting.
        if (config.croupier.game.playerNumber == null) {
          config.croupier.game.playerNumber = -1;
        }
      };
    }
    if (config.croupier.game.isCreator) {
      allWidgets.add(new Flexible(
          flex: 0,
          child: new Row(children: [
            new FlatButton(
                child: new Text("Start Game", style: style.Text.hugeStyle),
                onPressed: startCb,
                color: style.theme.accentColor)
          ], justifyContent: FlexJustifyContent.spaceAround)));
    }
    allWidgets.add(new Flexible(
        flex: 0,
        child: new FlatButton(
            child: new Text('Back'),
            onPressed:
                makeSetStateCallback(logic_croupier.CroupierState.welcome))));

    return new Column(children: allWidgets);
  }
}
