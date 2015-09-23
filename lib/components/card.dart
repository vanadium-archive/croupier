// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import 'package:sky/widgets.dart' as widgets;

class Card extends widgets.Component {
  logic_card.Card card;
  bool faceUp;
  double width;
  double height;

  Card(this.card, this.faceUp, {this.width, this.height});

  widgets.Widget build() {
    return new widgets.Listener(
      child: new widgets.Container(
        width: width,
        height: height,
        child: _imageFromCard(card, faceUp)
      )
    );
  }

  static widgets.Widget _imageFromCard(logic_card.Card c, bool faceUp) {
    // TODO(alexfandrianto): Instead of 'default', what if we were told which theme to use?
    String imageName =
        "images/default/${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
