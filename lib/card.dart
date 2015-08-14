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
  bool scrolling;

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
    scrolling = false;
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

  void _onPointerDown(sky.Event e) {
    setState(() {
      scrolling = true;
    });
  }

  void _onPointerMove(sky.Event e) {
    sky.PointerEvent ge = e as sky.PointerEvent;
    setState(() {
      dx += ge.dx;
      dy += ge.dy;
    });
  }

  void _onPointerUp(sky.Event e) {
    //sky.PointerEvent pe = e as sky.PointerEvent;
    setState(() {
      if (this.pointerUpCb != null) {
        pointerUpCb(this.dx, this.dy, this.faceUp);
      }
      this.dx = 0.0;
      this.dy = 0.0;
      this.faceUp = true;
      scrolling = false;
    });
  }

  Widget build() {
    return new Container(
      child: /*new Container(
        child: */new MyButton(
          child: imageFromCard(this.card, faceUp),
          onPressed: _onPressed,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp
        ),
      padding: const EdgeDims.all(8.0),
      //margin: const EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: (this.scrolling ? const Color(0xFFFF0000) : const Color(0xFF0000FF)),
        borderRadius: 5.0
      ),
      transform: new vector_math.Matrix4.identity().translate(dx, dy)
    );
  }
}

// I think we should be free to move cards around the screen as we please.
// However, that doesn't mean we can tap them willy nilly or let go of them so easily.
// I propose that.
// Card follows you onScroll.
// But onPressed and on