// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library game_component;

import '../logic/card.dart' as logic_card;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase, HeartsType;
import '../logic/solitaire/solitaire.dart' show SolitaireGame, SolitairePhase;
import 'board.dart' show HeartsBoard;
import 'card.dart' as component_card;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, CardCollectionOrientation, AcceptCb;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

part 'hearts/hearts.part.dart';
part 'proto/proto.part.dart';
part 'solitaire/solitaire.part.dart';

typedef void NoArgCb();

abstract class GameComponent extends StatefulComponent {
  final Game game;
  final NoArgCb gameEndCallback;
  final double width;
  final double height;

  GameComponent(this.game, this.gameEndCallback, {this.width, this.height});
}

abstract class GameComponentState<T extends GameComponent> extends State<T> {
  Map<logic_card.Card, CardAnimationData> cardLevelMap;

  void initState() {
    super.initState();

    cardLevelMap = new Map<logic_card.Card, CardAnimationData>();
    config.game.updateCallback = update;
  }

  void _reset() {
    cardLevelMap.clear();
  }

  // This callback is used to force the UI to draw when state changes occur
  // outside of the UIs control (e.g., synced data).
  void update() {
    setState(() {});
  }

  // A helper that most subclasses use in order to quit their respective games.
  void _quitGameCallback() {
    setState(() {
      config.gameEndCallback();
    });
  }

  // A helper that subclasses might override to create buttons.
  Widget _makeButton(String text, NoArgCb callback) {
    return new FlatButton(child: new Text(text), onPressed: callback);
  }

  @override
  Widget build(BuildContext context); // still UNIMPLEMENTED

  void _cardLevelMapProcessAllVisible(List<int> visibleCardCollections) {
    Game game = config.game;

    for (int i = 0; i < visibleCardCollections.length; i++) {
      int index = visibleCardCollections[i];
      for (int j = 0; j < game.cardCollections[index].length; j++) {
        _cardLevelMapProcess(game.cardCollections[index][j]);
      }
    }
  }

  void _cardLevelMapProcess(logic_card.Card logicCard) {
    component_card.GlobalCardKey key = new component_card.GlobalCardKey(
        logicCard, component_card.CardUIType.CARD);
    component_card.CardState cardState = key.currentState;
    if (cardState == null) {
      return; // There's nothing we can really do about this card since it hasn't drawn yet.
    }
    Point p = cardState.getGlobalPosition();
    double z = cardState.config.z;
    component_card.Card c = key.currentWidget;

    assert(c == cardState.config);

    CardAnimationData cad = cardLevelMap[logicCard];
    if (cad == null || cad.newPoint != p || cad.z != z) {
      setState(() {
        cardLevelMap[logicCard] = new CardAnimationData(c, cad?.newPoint, p, z);
      });
    } else if (!cad.comp_card.isMatchWith(c)) {
      // Even if the position or z index didn't change, we can still update the
      // card itself. This can help during screen rotations, since the top-left
      // card likely not change positions or z-index.
      setState(() {
        cad.comp_card = c;
      });
    }
  }

  // Helper to build the card animation layer.
  // Note: This isn't a component because of its dependence on Widgets.
  Widget buildCardAnimationLayer(List<int> visibleCardCollections) {
    // It's possible that some cards need to be moved after this build.
    // If so, we can catch it in the next frame.
    scheduler.requestPostFrameCallback((Duration d) {
      _cardLevelMapProcessAllVisible(visibleCardCollections);
    });

    List<Widget> positionedCards = new List<Widget>();

    // Sort the cards by z-index.
    List<logic_card.Card> orderedKeys = cardLevelMap.keys.toList()
      ..sort((logic_card.Card a, logic_card.Card b) {
        double diff = cardLevelMap[a].z - cardLevelMap[b].z;
        return diff.sign.toInt();
      });

    orderedKeys.forEach((logic_card.Card c) {
      // Don't show a card if it isn't part of a visible collection.
      if (!visibleCardCollections.contains(config.game.findCard(c))) {
        cardLevelMap.remove(c); // It is an old card, which we can clean up.
        return;
      }

      CardAnimationData data = cardLevelMap[c];
      RenderBox box = context.findRenderObject();
      Point localOld =
          data.oldPoint != null ? box.globalToLocal(data.oldPoint) : null;
      Point localNew = box.globalToLocal(data.newPoint);

      positionedCards.add(new Positioned(
          key: new GlobalObjectKey(c
              .toString()), //needed, or else the Positioned wrapper may be traded out and animations fail.
          top:
              0.0, // must pass x and y or else it expands to the maximum Stack size.
          left:
              0.0, // must pass x and y or else it expands to the maximum Stack size.
          child: new component_card.ZCard(data.comp_card, localOld, localNew)));
    });

    return new IgnorePointer(
        ignoring: true,
        child: new Container(
            width: config.width,
            height: config.height,
            child: new Stack(positionedCards)));
  }
}

GameComponent createGameComponent(Game game, NoArgCb gameEndCallback,
    {double width, double height}) {
  switch (game.gameType) {
    case GameType.Proto:
      return new ProtoGameComponent(game, gameEndCallback,
          width: width, height: height);
    case GameType.Hearts:
      return new HeartsGameComponent(game, gameEndCallback,
          width: width, height: height);
    case GameType.Solitaire:
      return new SolitaireGameComponent(game, gameEndCallback,
          width: width, height: height);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}

/// CardAnimationData contains the relevant information for a ZCard to be built.
/// It uses the comp_card's properties, the oldPoint, newPoint, and z-index to
/// determine how it needs to animate.
class CardAnimationData {
  component_card.Card comp_card;
  Point oldPoint;
  Point newPoint;
  double z;

  CardAnimationData(this.comp_card, this.oldPoint, this.newPoint, this.z);
}
