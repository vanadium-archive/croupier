// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../logic/croupier.dart' as logic_croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' as logic_game;
import '../styles/common.dart' as style;
import 'croupier_game_advertisement.dart'
    show CroupierGameAdvertisementComponent;
import 'croupier_profile.dart' show CroupierProfileComponent;
import 'game.dart' as component_game;

typedef void NoArgCb();

GlobalObjectKey _gameKey = new GlobalObjectKey("CroupierGameKey");

class CroupierComponent extends StatefulComponent {
  final logic_croupier.Croupier croupier;

  CroupierComponent(this.croupier);

  CroupierComponentState createState() => new CroupierComponentState();
}

class CroupierComponentState extends State<CroupierComponent> {
  NoArgCb makeSetStateCallback(logic_croupier.CroupierState s,
      [var data = null]) {
    return () => setState(() {
          config.croupier.setState(s, data);
        });
  }

  Widget build(BuildContext context) {
    switch (config.croupier.state) {
      case logic_croupier.CroupierState.Welcome:
        // in which we show them a UI to start a new game, join a game, or change some settings.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Column([
              new FlatButton(
                  child: new Text('Create Game', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ChooseGame)),
              new FlatButton(
                  child: new Text('Join Game', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.JoinGame)),
              new FlatButton(
                  child: new Text('Resume Game', style: style.Text.titleStyle),
                  onPressed: config.croupier.settings.hasLastGame
                      ? makeSetStateCallback(
                          logic_croupier.CroupierState.ResumeGame,
                          config.croupier.settings.lastGameID)
                      : null),
              new CroupierProfileComponent(
                  settings: config.croupier.settings,
                  width: style.Size.settingsSize,
                  height: style.Size.settingsSize)
            ]));
      case logic_croupier.CroupierState.ChooseGame:
        // in which we let them pick a game out of the many possible games... There aren't that many.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Flex([
              new FlatButton(
                  child: new Text('Proto', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Proto)),
              new FlatButton(
                  child: new Text('Hearts', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Hearts)),
              new FlatButton(
                  child: new Text('Poker', style: style.Text.titleStyle)),
              new FlatButton(
                  child: new Text('Solitaire', style: style.Text.titleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.ArrangePlayers,
                      logic_game.GameType.Solitaire)),
              new FlatButton(
                  child: new Text('Back', style: style.Text.subtitleStyle),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.Welcome))
            ], direction: FlexDirection.vertical));
      case logic_croupier.CroupierState.JoinGame:
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
                  logic_croupier.CroupierState.ArrangePlayers, gsd),
              settings: cs));
        });

        gameAdWidgets.add(new FlatButton(
            child: new Text('Back', style: style.Text.subtitleStyle),
            onPressed:
                makeSetStateCallback(logic_croupier.CroupierState.Welcome)));

        // in which players wait for game invitations to arrive.
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: new Column(gameAdWidgets));
      case logic_croupier.CroupierState.ArrangePlayers:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: _buildArrangePlayers());
      case logic_croupier.CroupierState.PlayGame:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: component_game.createGameComponent(config.croupier,
                makeSetStateCallback(logic_croupier.CroupierState.Welcome),
                width: ui.window.size.width,
                height: ui.window.size.height - ui.window.padding.top,
                key: _gameKey));

      case logic_croupier.CroupierState.ResumeGame:
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
    double size = style.Size.settingsSize;
    config.croupier.players_found.forEach((int userID, int playerNumber) {
      if (!needsArrangement || playerNumber == null) {
        // Note: Even if cs is null, a placeholder will be shown instead.
        CroupierSettings cs = config.croupier.settings_everyone[userID];
        bool isMe = config.croupier.settings.userID == userID;
        Widget cpc = new Container(
            decoration: isMe ? style.Box.liveNow : null,
            child: new CroupierProfileComponent(
                settings: cs, height: size, width: size));

        // If the player profiles can be arranged, they should be draggable too.
        if (needsArrangement) {
          profileWidgets.add(new Draggable<CroupierSettings>(
              child: cpc, feedback: cpc, data: cs));
        } else {
          profileWidgets.add(cpc);
        }
      }
    });

    if (needsArrangement) {
      return new ScrollableViewport(
          child: new Row(profileWidgets),
          scrollDirection: ScrollDirection.horizontal);
    }
    return new MaxTileWidthGrid(profileWidgets, maxTileWidth: size);
  }

  Widget _buildArrangePlayers() {
    List<Widget> allWidgets = new List<Widget>();

    logic_game.GameArrangeData gad = config.croupier.game.gameArrangeData;
    Iterable<int> playerNumbers = config.croupier.players_found.values;

    allWidgets.add(new Flexible(
        flex: 0,
        child: new Row([
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
          height: ui.window.size.height * 0.50));
    }

    // Allow games that can start with these players to begin.
    // Debug Mode should also go through.
    NoArgCb startCb;
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
          child: new Row([
            new Container(
                decoration: new BoxDecoration(
                    backgroundColor: startCb != null
                        ? style.theme.accentColor
                        : Colors.grey[300]),
                padding: style.Spacing.smallPadding,
                child: new FlatButton(
                    child: new Text("Start Game", style: style.Text.hugeStyle),
                    onPressed: startCb))
          ], justifyContent: FlexJustifyContent.spaceAround)));
    }
    allWidgets.add(new Flexible(
        flex: 0,
        child: new FlatButton(
            child: new Text('Back'),
            onPressed:
                makeSetStateCallback(logic_croupier.CroupierState.Welcome))));

    return new Column(allWidgets);
  }
}
