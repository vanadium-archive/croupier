// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' as widgets;
import 'package:flutter/rendering.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../logic/card.dart' as logic_card;

enum CardAnimationType { none, normal, long }

enum CardUIType { card, zCard }

typedef void TapCallback(logic_card.Card card);

class GlobalCardKey extends widgets.GlobalKey {
  logic_card.Card card;
  CardUIType type;

  GlobalCardKey(this.card, this.type) : super.constructor();

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
  final CardAnimationType animationType;
  final double z;

  // These points are in local coordinates.
  final Point startingPosition;
  final Point endingPosition;

  ZCard(Card dataComponent, this.startingPosition, this.endingPosition)
      : super(key: new GlobalCardKey(dataComponent.card, CardUIType.zCard)),
        card = dataComponent.card,
        faceUp = dataComponent.faceUp,
        width = dataComponent.width ?? 40.0,
        height = dataComponent.height ?? 40.0,
        rotation = dataComponent.rotation ?? 0.0,
        animationType = dataComponent.animationType,
        z = dataComponent.z;

  ZCardState createState() => new ZCardState();
}

class Card extends widgets.StatefulComponent {
  final logic_card.Card card;
  final bool faceUp;
  final double width;
  final double height;
  final double rotation;
  final bool useKey;
  final bool visible;
  final TapCallback tapCallback;
  final CardAnimationType animationType;
  final double z;

  Card(logic_card.Card card, this.faceUp,
      {double width,
      double height,
      double rotation,
      bool useKey: false,
      this.visible: true,
      CardAnimationType animationType,
      this.tapCallback,
      this.z})
      : animationType = animationType ?? CardAnimationType.none,
        card = card,
        width = width ?? 40.0,
        height = height ?? 40.0,
        rotation = rotation ?? 0.0,
        useKey = useKey,
        super(key: useKey ? new GlobalCardKey(card, CardUIType.card) : null);

  // Use this helper to help create a Card clone.
  // Used by the drag and drop layer.
  Card clone({bool visible}) {
    return new Card(this.card, this.faceUp,
        width: width,
        height: height,
        rotation: rotation,
        useKey: false,
        visible: visible ?? this.visible,
        animationType: CardAnimationType.none,
        z: z);
  }

  // Check if the data between these Cards matches.
  // This isn't == since I don't want to override that and hashCode.
  bool isMatchWith(Card c) {
    return c.card == card &&
        c.faceUp == faceUp &&
        c.width == width &&
        c.height == height &&
        c.rotation == rotation &&
        c.useKey == useKey &&
        c.visible == visible &&
        c.animationType == animationType &&
        c.z == z;
  }

  CardState createState() => new CardState();
}

class CardState extends widgets.State<Card> {
  Point getGlobalPosition() {
    RenderBox box = context.findRenderObject();
    return box.localToGlobal(Point.origin);
  }

  widgets.Widget build(widgets.BuildContext context) {
    widgets.Widget image = new widgets.GestureDetector(
        onTap: config.tapCallback != null
            ? () => config.tapCallback(config.card)
            : null,
        child: new widgets.Opacity(
            opacity: config.visible ? 1.0 : 0.0,
            child: new widgets.Transform(
                child: _imageFromCard(
                    config.card, config.faceUp, config.width, config.height),
                transform:
                    new vector_math.Matrix4.identity().rotateZ(config.rotation),
                alignment: new FractionalOffset(0.5, 0.5))));

    return image;
  }
}

widgets.Widget _imageFromCard(
    logic_card.Card c, bool faceUp, double width, double height) {
  // TODO(alexfandrianto): Instead of 'default', what if we were told which theme to use?
  String imageName =
      "images/default/${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
  return new widgets.AssetImage(name: imageName, width: width, height: height);
}

class ZCardState extends widgets.State<ZCard> {
  Tween<Point> _positionTween;
  AnimationController _animationController;
  List<
      Point> _pointQueue; // at least 1 longer than the current animation index.
  int _animationIndex;

  @override
  void initState() {
    super.initState();
    _initialize();
    _updatePosition();
  }

  void _initialize() {
    _pointQueue = new List<Point>();
    _animationIndex = 0;
    if (config.startingPosition != null) {
      _pointQueue.add(config.startingPosition);
    }
    _pointQueue.add(config.endingPosition);
    _animationController =
        new AnimationController(duration: this.animationDuration);
    _animationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _animationIndex++;
        _tryAnimate();
      }
    });
  }

  Duration get animationDuration {
    switch (config.animationType) {
      case CardAnimationType.none:
        return const Duration(milliseconds: 0);
      case CardAnimationType.normal:
        return const Duration(milliseconds: 200);
      case CardAnimationType.long:
        return const Duration(milliseconds: 1000);
      default:
        print("Unexpected animation type: ${config.animationType}");
        assert(false);
        return null;
    }
  }

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
    _updatePosition();
  }

  // A callback that sets up the animation from point a to point b.
  void _updatePosition() {
    if (config.animationType == CardAnimationType.none ||
        _pointQueue.length == 1) {
      Point endingLocation = config.endingPosition;
      _positionTween =
          new Tween<Point>(begin: endingLocation, end: endingLocation);
      _animationController.value = 0.0;
      _animationIndex = _pointQueue.length - 1;
      return;
    }

    _tryAnimate();
  }

  bool _needsAnimation() {
    return _animationIndex < _pointQueue.length - 1;
  }

  // Return the current animation position of the ZCard.
  Point get localPosition {
    return _positionTween.evaluate(_animationController);
  }

  void _tryAnimate() {
    // Let animations finish... (Is this a good idea?)
    if (!_animationController.isAnimating && _needsAnimation()) {
      Point startingLocation = _pointQueue[_animationIndex];
      Point endingLocation = _pointQueue[_animationIndex + 1];
      _positionTween =
          new Tween<Point>(begin: startingLocation, end: endingLocation);
      _animationController.value = 0.0;
      _animationController.duration = this.animationDuration;
      _animationController.play(AnimationDirection.forward);
    }
  }

  widgets.Widget build(widgets.BuildContext context) {
    widgets.Widget image = new widgets.Transform(
        child: _imageFromCard(
            config.card, config.faceUp, config.width, config.height),
        transform: new vector_math.Matrix4.identity().rotateZ(config.rotation),
        alignment: new FractionalOffset(0.5, 0.5));

    // Prepare the transition, which is a fixed pixel translation.
    widgets.Widget retWidget = new widgets.AnimatedBuilder(
        animation: _animationController,
        builder: (widgets.BuildContext c, widgets.Widget child) {
      Matrix4 transform = new Matrix4.identity()
        ..translate(localPosition.x, localPosition.y);
      return new widgets.Transform(transform: transform, child: child);
    }, child: image);

    return retWidget;
  }
}
