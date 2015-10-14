// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;

import 'package:flutter/material.dart' as widgets;
import 'package:vector_math/vector_math_64.dart' as vector_math;

class Card extends widgets.StatelessComponent {
  final logic_card.Card card;
  final bool faceUp;
  final double _width;
  final double _height;
  final double rotation;

  double get width => _width ?? 40.0;
  double get height => _height ?? 40.0;

  Card(this.card, this.faceUp,
      {double width, double height, this.rotation: 0.0})
      : _width = width,
        _height = height;

  widgets.Widget build(widgets.BuildContext context) {
    // TODO(alexfandrianto): This isn't a nice way of doing Rotation.
    // The reason is that you must know the width and height of the image.
    // Feature Request: https://github.com/flutter/engine/issues/1452
    return new widgets.Listener(
        child: new widgets.Container(
            width: width,
            height: height,
            child: new widgets.Transform(
                child: _imageFromCard(card, faceUp),
                transform: new vector_math.Matrix4.identity()
                    .translate(this.width / 2, this.height / 2)
                    .rotateZ(this.rotation)
                    .translate(-this.width / 2, -this.height / 2))));
  }

  static widgets.Widget _imageFromCard(logic_card.Card c, bool faceUp) {
    // TODO(alexfandrianto): Instead of 'default', what if we were told which theme to use?
    String imageName =
        "images/default/${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
