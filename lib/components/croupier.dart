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
                      logic_croupier.CroupierState.JoinGame))
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
            child: new Column([
              _buildArrangePlayers(),
              new FlatButton(
                  child: new Text('Back'),
                  onPressed: makeSetStateCallback(
                      logic_croupier.CroupierState.Welcome))
            ]));
      case logic_croupier.CroupierState.PlayGame:
        return new Container(
            padding: new EdgeDims.only(top: ui.window.padding.top),
            child: component_game.createGameComponent(config.croupier, () {
              config.croupier.game.quit();
              makeSetStateCallback(logic_croupier.CroupierState.Welcome)();
            },
                width: ui.window.size.width,
                height: ui.window.size.height - ui.window.padding.top));
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
      if (!needsArrangement || playerNumber == null) {
        CroupierSettings cs = config.croupier.settings_everyone[userID];
        // cs could be null if this settings data hasn't synced yet.
        // If so, a placeholder is shown instead.
        profileWidgets.add(new CroupierProfileComponent(settings: cs));
      }
    });

    return new Grid(profileWidgets, maxChildExtent: 120.0);
  }

  Widget _buildArrangePlayers() {
    List<Widget> allWidgets = new List<Widget>();

    logic_game.GameArrangeData gad = config.croupier.game.gameArrangeData;
    Iterable<int> playerNumbers = config.croupier.players_found.values;

    // Allow games that can start with these players to begin.
    // Debug Mode should also go through.
    NoArgCb onPressed;
    if (gad.canStart(playerNumbers) || config.croupier.debugMode) {
      onPressed = () {
        makeSetStateCallback(logic_croupier.CroupierState.PlayGame)();

        // Since playerNumber starts out as null, we should set it to -1 if
        // the person pressed Start Game without sitting.
        if (config.croupier.game.playerNumber == null) {
          config.croupier.game.playerNumber = -1;
        }
        config.croupier.game.startGameSignal();
      };
    }

    // Always include the Start Game Button.
    allWidgets.add(
        new FlatButton(child: new Text('Start Game'), onPressed: onPressed));

    // Games that need arrangement can show their game arrange component.
    if (gad.needsArrangement) {
      allWidgets.add(component_game.createGameArrangeComponent(config.croupier,
          width: ui.window.size.width, height: ui.window.size.height / 2));
    }

    // Then show the profile widgets of those who have joined the game.
    allWidgets.add(_buildPlayerProfiles(gad.needsArrangement));

    return new Column(allWidgets);
  }
}
