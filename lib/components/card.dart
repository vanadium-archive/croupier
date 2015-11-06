// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;

import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' as widgets;
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

enum CardAnimationType {
  NONE, OLD_TO_NEW, IN_TOP
}

enum CardUIType {
  CARD, ZCARD
}

class GlobalCardKey extends widgets.GlobalKey {
  logic_card.Card card;
  CardUIType type;

  GlobalCardKey(this.card, this.type): super.constructor();

  bool operator ==(Object other) {
    if (other is! GlobalCardKey) {
      return false;
    }
    GlobalCardKey k = other;
    return k.card == card && k.type == type;
  }

  int get hashCode {
    return 17 * card.hashCode + 33 * type.hashCode;
  }
}

class ZCard extends widgets.StatefulComponent {
  final logic_card.Card card;
  final bool faceUp;
  final double width;
  final double height;
  final double rotation;
  final bool animateEntrance;
  final double z;

  final Point startingPosition;
  final Point endingPosition;

  ZCard(Card dataComponent, this.startingPosition, this.endingPosition) :
    super(key: new GlobalCardKey(dataComponent.card, CardUIType.ZCARD)),
    card = dataComponent.card,
    faceUp = dataComponent.faceUp,
    width = dataComponent.width ?? 40.0,
    height = dataComponent.height ?? 40.0,
    rotation = dataComponent.rotation,
    animateEntrance = dataComponent.animateEntrance,
    z = dataComponent.z;

  _ZCardState createState() => new _ZCardState();
}

class Card extends widgets.StatefulComponent {
  final logic_card.Card card;
  final bool faceUp;
  final double width;
  final double height;
  final double rotation;
  final bool useKey;
  final bool visible;
  final bool animateEntrance;
  final double z;

  Card(logic_card.Card card, this.faceUp,
      {double width, double height, this.rotation: 0.0, bool useKey: false, this.visible: true, this.animateEntrance: true, this.z})
      : card = card,
        width = width ?? 40.0,
        height = height ?? 40.0,
        useKey = useKey,
        super(key: useKey ? new GlobalCardKey(card, CardUIType.CARD) : null);

  // Use this helper to help create a Card clone.
  // Used by the drag and drop layer.
  Card clone({bool visible}) {
    return new Card(this.card, this.faceUp,
      width: width, height: height, rotation: rotation,
      useKey: false, visible: visible ?? this.visible, animateEntrance: false,
      z: z);
  }

  CardState createState() => new CardState();
}

class CardState extends widgets.State<Card> {
  // TODO(alexfandrianto): This bug is why some cards appear slightly off.
  // https://github.com/flutter/engine/issues/1939
  Point getGlobalPosition() {
    RenderBox box = context.findRenderObject();
    return box.localToGlobal(Point.origin);
  }

  widgets.Widget build(widgets.BuildContext context) {
    widgets.Widget image = null;
    if (config.visible) {
      image = new widgets.Transform(
                child: _imageFromCard(config.card, config.faceUp),
                transform: new vector_math.Matrix4.identity()
                    .rotateZ(config.rotation),
                alignment: new FractionalOffset(0.5, 0.5));
    }

    return new widgets.Container(
            width: config.width,
            height: config.height,
            child: image);
  }
}

widgets.Widget _imageFromCard(logic_card.Card c, bool faceUp) {
  // TODO(alexfandrianto): Instead of 'default', what if we were told which theme to use?
  String imageName =
      "images/default/${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
  return new widgets.NetworkImage(src: imageName);
}

class _ZCardState extends widgets.State<ZCard> {
  ValuePerformance<Point> _performance;
  List<Point> _pointQueue; // at least 1 longer than the current animation index.
  int _animationIndex;
  bool _cardUpdateScheduled = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    scheduleUpdatePosition();
  }

  void _initialize() {
    _pointQueue = new List<Point>();
    _animationIndex = 0;
    if (config.startingPosition != null) {
      _pointQueue.add(config.startingPosition);
    }
    _pointQueue.add(config.endingPosition);
    _performance = new ValuePerformance<Point>(
      variable: new AnimatedValue<Point>(Point.origin, curve: Curves.ease),
      duration: const Duration(milliseconds: 250)
    );
    _performance.addStatusListener((PerformanceStatus status) {
      if (status == PerformanceStatus.completed) {
        _animationIndex++;
        _tryAnimate();
      }
    });
  }

  void scheduleUpdatePosition() {
    if (!_cardUpdateScheduled) {
      _cardUpdateScheduled = true;
      scheduleMicrotask(_updatePosition);
    }
  }

  // These microtasks are being scheduled on every build change.
  // Theoretically, this is too often, but to be safe, it is also good to do it.
  @override
  void didUpdateConfig(ZCard oldConfig) {
    if (config.key != oldConfig.key) {
      _initialize();
    } else {
      // Do we need to animate to a new location? If so, add it to the queue.
      if (config.endingPosition != _pointQueue.last) {
        setState(() {
          _pointQueue.add(config.endingPosition);
          _tryAnimate();
        });
      }
    }
    scheduleUpdatePosition();
  }

  // A callback that sets up the animation from point a to point b.
  void _updatePosition() {
    _cardUpdateScheduled = false; // allow the next attempt to schedule _updatePosition to succeed.
    if (!config.animateEntrance || _pointQueue.length == 1) {
      RenderBox box = context.findRenderObject();
      Point endingLocation = box.globalToLocal(config.endingPosition);
      _performance.variable
        ..begin = endingLocation
        ..value = endingLocation
        ..end = endingLocation;
      _performance.progress = 0.0;
      return;
    }

    _tryAnimate();
  }

  bool _needsAnimation() {
    return _animationIndex < _pointQueue.length - 1;
  }

  void _tryAnimate() {
    // Let animations finish... (Is this a good idea?)
    if (!_performance.isAnimating && _needsAnimation()) {
      RenderBox box = context.findRenderObject();
      Point globalStart = _pointQueue[_animationIndex];
      Point globalEnd = _pointQueue[_animationIndex + 1];
      Point startingLocation = box.globalToLocal(globalStart);
      Point endingLocation = box.globalToLocal(globalEnd);
      _performance.variable
        ..begin = startingLocation
        ..value = startingLocation
        ..end = endingLocation;
      _performance.progress = 0.0;
      _performance.play();
    }
  }

  widgets.Widget build(widgets.BuildContext context) {
    widgets.Widget image = new widgets.Transform(
      child: _imageFromCard(config.card, config.faceUp),
      transform: new vector_math.Matrix4.identity()
          .rotateZ(config.rotation),
      alignment: new FractionalOffset(0.5, 0.5));

    // Set up the drag listener.
    widgets.Widget listeningCard = new widgets.Listener(
        child: new widgets.Container(
            width: config.width,
            height: config.height,
            child: image));

    // Set up the slide transition.
    // During animation, we must ignore all events.
    widgets.Widget retWidget = new widgets.IgnorePointer(
      ignoring: _performance.isAnimating,
      child: new widgets.SlideTransition(
        performance: _performance.view,
        position: _performance.variable,
        child: listeningCard
      )
    );

    return retWidget;
  }
}
