// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library game_component;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../logic/card.dart' as logic_card;
import '../logic/croupier.dart' show Croupier;
import '../logic/croupier_settings.dart' show CroupierSettings;
import '../logic/game/game.dart' show Game, GameType;
import '../logic/hearts/hearts.dart' show HeartsGame, HeartsPhase, HeartsType;
import '../logic/solitaire/solitaire.dart' show SolitaireGame, SolitairePhase;
import '../styles/common.dart' as style;
import 'board.dart' show HeartsBoard;
import 'card.dart' as component_card;
import 'card_collection.dart'
    show CardCollectionComponent, DropType, CardCollectionOrientation, AcceptCb;
import 'croupier_profile.dart' show CroupierProfileComponent;
import '../sound/sound_assets.dart';

part 'hearts/hearts.part.dart';
part 'proto/proto.part.dart';
part 'solitaire/solitaire.part.dart';

abstract class GameComponent extends StatefulComponent {
  final Croupier croupier;
  final SoundAssets sounds;
  Game get game => croupier.game;
  final VoidCallback gameEndCallback;
  final double width;
  final double height;

  GameComponent(this.croupier, this.sounds, this.gameEndCallback,
      {Key key, this.width, this.height})
      : super(key: key);
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
    if (this.mounted) {
      setState(() {});
    }
  }

  // A helper that most subclasses use in order to quit their respective games.
  void _quitGameCallback() {
    setState(() {
      config.gameEndCallback();
    });
  }

  // A helper that subclasses might override to create buttons.
  Widget _makeButton(String text, VoidCallback callback) {
    return new FlatButton(
        child: new Text(text, style: style.Text.liveNow), onPressed: callback);
  }

  @override
  Widget build(BuildContext context); // still UNIMPLEMENTED

  void _cardLevelMapProcessAllVisible(List<int> visibleCardCollectionIndexes) {
    Game game = config.game;

    for (int i = 0; i < visibleCardCollectionIndexes.length; i++) {
      int index = visibleCardCollectionIndexes[i];
      for (int j = 0; j < game.cardCollections[index].length; j++) {
        _cardLevelMapProcess(game.cardCollections[index][j]);
      }
    }
  }

  void _cardLevelMapProcess(logic_card.Card logicCard) {
    component_card.GlobalCardKey key = new component_card.GlobalCardKey(
        logicCard, component_card.CardUIType.card);
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

  bool _isMoving(logic_card.Card c) {
    CardAnimationData data = cardLevelMap[c];
    RenderBox box = context.findRenderObject();
    Point localOld =
        data.oldPoint != null ? box.globalToLocal(data.oldPoint) : null;
    Point localNew = box.globalToLocal(data.newPoint);

    // We also need confirmation from the ZCard that we are moving.
    component_card.GlobalCardKey zCardKey =
        new component_card.GlobalCardKey(c, component_card.CardUIType.zCard);
    component_card.ZCardState zCardKeyState = zCardKey.currentState;

    // It is moving if there is an old position, the new one isn't equal to the
    // old one, and the ZCard hasn't arrived at the new position yet.
    return localOld != null &&
        localOld != localNew &&
        localNew != zCardKeyState?.localPosition;
  }

  // Helper to build the card animation layer.
  // Note: This isn't a component because of its dependence on Widgets.
  Widget buildCardAnimationLayer(List<int> visibleCardCollectionIndexes) {
    // It's possible that some cards need to be moved after this build.
    // If so, we can catch it in the next frame.
    Scheduler.instance.addPostFrameCallback((Duration d) {
      _cardLevelMapProcessAllVisible(visibleCardCollectionIndexes);
    });

    List<Widget> positionedCards = new List<Widget>();

    // Sort the cards by z-index. If a card is animating, it gets a z bonus.
    List<logic_card.Card> orderedKeys = cardLevelMap.keys.toList()
      ..sort((logic_card.Card a, logic_card.Card b) {
        bool isMovingA = _isMoving(a);
        bool isMovingB = _isMoving(b);

        // Moving cards take much higher priority.
        if (isMovingA && !isMovingB) {
          return 1;
        } else if (!isMovingA && isMovingB) {
          return -1;
        }

        // If both are moving/non-moving, we break ties with the z-index.
        double diff = cardLevelMap[a].z - cardLevelMap[b].z;
        return diff.sign.toInt();
      });

    orderedKeys.forEach((logic_card.Card c) {
      // Don't show a card if it isn't part of a visible collection.
      if (!visibleCardCollectionIndexes.contains(config.game.findCard(c))) {
        cardLevelMap.remove(c); // It is an old card, which we can clean up.
        assert(!cardLevelMap.containsKey(c));
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
            child: new Stack(children: positionedCards)));
  }
}

GameComponent createGameComponent(
    Croupier croupier, SoundAssets sounds, VoidCallback gameEndCallback,
    {Key key, double width, double height}) {
  switch (croupier.game.gameType) {
    case GameType.proto:
      return new ProtoGameComponent(croupier, sounds, gameEndCallback,
          key: key, width: width, height: height);
    case GameType.hearts:
      return new HeartsGameComponent(croupier, sounds, gameEndCallback,
          key: key, width: width, height: height);
    case GameType.solitaire:
      return new SolitaireGameComponent(croupier, sounds, gameEndCallback,
          key: key, width: width, height: height);
    default:
      // We're probably not ready to serve the other games yet.
      assert(false);
      return null;
  }
}

abstract class GameArrangeComponent extends StatefulComponent {
  final Croupier croupier;
  final double width;
  final double height;
  GameArrangeComponent(this.croupier, {this.width, this.height, Key key})
      : super(key: key);
}

GameArrangeComponent createGameArrangeComponent(Croupier croupier,
    {double width, double height, Key key}) {
  switch (croupier.game.gameType) {
    case GameType.hearts:
      return new HeartsArrangeComponent(croupier,
          width: width, height: height, key: key);
    default:
      // We can't arrange this game.
      throw new UnimplementedError(
          "We cannot arrange the game type: ${croupier.game.gameType}");
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
