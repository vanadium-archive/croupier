// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/card.dart' as logic_card;
import 'package:sky/widgets_next.dart' as widgets;

class Card extends widgets.StatelessComponent {
  final logic_card.Card card;
  final bool faceUp;
  final double width;
  final double height;

  Card(this.card, this.faceUp, {this.width, this.height});

  widgets.Widget build(widgets.BuildContext context) {
    return new widgets.Listener(
        child: new widgets.Container(
            width: width, height: height, child: _imageFromCard(card, faceUp)));
  }

  static widgets.Widget _imageFromCard(logic_card.Card c, bool faceUp) {
    // TODO(alexfandrianto): Instead of 'default', what if we were told which theme to use?
    String imageName =
        "images/default/${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }
}
