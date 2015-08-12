library card;

import 'package:sky/widgets/basic.dart';
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart' as vector_math;

import 'my_button.dart';

class Card {
  String deck;
  String identifier;

  Card(this.deck, this.identifier);
  Card.fromString(String data) {
    List<String> parts = data.split(" ");
    assert(parts.length == 2);
    this
      ..deck = parts[0]
      ..identifier = parts[1];
  }

  toString() => "${deck} ${identifier}";

  get string => toString();
}

class CardComponent extends StatefulComponent {
  // Stateful components
  double dx;
  double dy;
  bool faceUp;

  final Card card;
  final Function pointerUpCb;

  static Widget imageFromCard(Card c, bool faceUp) {
    String imageName = "${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new NetworkImage(src: imageName);
  }

  CardComponent(this.card, bool faceUp, [this.pointerUpCb = null]) {
    this.faceUp = faceUp;
    dx = 0.0;
    dy = 0.0;
  }

  void syncFields(CardComponent other) {
    this.dx = other.dx;
    this.dy = other.dy;
    this.faceUp = other.faceUp;
  }

  void _onPressed(sky.Event e) {
    setState(() {
      this.faceUp = !this.faceUp;
    });
  }

  void _onPointerMove(sky.Event e) {
    sky.GestureEvent ge = e as sky.GestureEvent;
    setState(() {
      dx += ge.dx;
      dy += ge.dy;
    });
  }

  void _onPointerUp(sky.Event e) {
    //sky.PointerEvent pe = e as sky.PointerEvent;
    setState(() {
      if (this.pointerUpCb != null) {
        //TODO(alexfandrianto): Left off here!!! MISSING SEMICOLON
        pointerUpCb(this.dx, this.dy, this.faceUp);
      }
      this.dx = 0.0;
      this.dy = 0.0;
      this.faceUp = true;
    });
  }

  Widget build() {
    return new Transform(
      child: new MyButton(
        child: imageFromCard(this.card, faceUp),
        onPressed: _onPressed,
        //onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp
      ),
      transform: new vector_math.Matrix4.identity().translate(-dx, dy)
    );
  }
}

// I think we should be free to move cards around the screen as we please.
// However, that doesn't mean we can tap them willy nilly or let go of them so easily.
// I propose that.
// Card follows you onScroll.
// But onPressed and on