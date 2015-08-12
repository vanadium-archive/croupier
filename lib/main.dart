import 'package:sky/widgets/basic.dart';

import 'card.dart';
import 'my_button.dart';
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart' as vector_math;

class HelloWorldApp extends App {
  int counter = 0;
  String debug = '';
  int counter2 = 0;
  // String debug2 = '';
  // Accumulators for the current scroll.
  double dx = 0.0;
  double dy = 0.0;

  Card c = new Card.fromString("classic h1");

  Transform makeTransform() {
    return new Transform(
      child: new MyButton(
        child: new Text('Engage'),
        onPressed: _handleOnPressedCallback,
        onPointerDown: _handleOnPointerDownCallback,
        onPointerMove: _handleOnPointerMoveCallback
      ),
      transform: new vector_math.Matrix4.identity().translate(dx, dy)
    );
  }

  void _handleOnPressedCallback(sky.Event e) {
    setState(() {
      counter++;
      sky.PointerEvent ge = e as sky.PointerEvent;
      debug = '(${ge.x.toStringAsFixed(3)}, ${ge.y.toStringAsFixed(3)})';//ge.toString();
    });
  }

  void _handleOnPointerDownCallback(sky.Event e) {
    setState(() {
      counter2++;
      //dx = 0.0;
      //dy = 0.0;
      //sky.PointerEvent ge = e as sky.PointerEvent;
      //debug2 = '${ge.x} ${ge.y}';
      // The field names were found from here: https://github.com/domokit/sky_engine/blob/01ff5c383fc88647c08f11a0d3392238b8bc99de/sky/engine/core/events/GestureEvent.h
      //'${ge.x} ${ge.y}';
      //'${ge.dx} ${ge.dy}'; I didn't see this on scroll either though... T_T
      //'${ge.velocityX} ${ge.velocityY}'; Is this for fling?
    });
  }

  void _handleOnPointerMoveCallback(sky.Event e) {
    setState(() {
      sky.PointerEvent ge = e as sky.PointerEvent;
      dx += ge.dx;
      dy += ge.dy;
      // debug3 = '${ge.dx} ${ge.dy}'; // Was this one for scroll update then?
      // The field names were found from here: https://github.com/domokit/sky_engine/blob/01ff5c383fc88647c08f11a0d3392238b8bc99de/sky/engine/core/events/GestureEvent.h
      //'${ge.x} ${ge.y}';
      //'${ge.dx} ${ge.dy}'; I didn't see this on scroll either though... T_T
      //'${ge.velocityX} ${ge.velocityY}'; Is this for fling?

      //this.rt.transform.translate(ge.dx, ge.dy);
      //this.rt.setIdentity();
      //this.translate(dx, dy);
    });
  }

  Widget build() {
    return new Center(child: new Block([
      new Center(child: new Text('Hello, world!')),
      new Center(child: new Text('Tap #${counter}: ${debug}')),
      new Center(child: new Text('Scroll #${counter2}: (${dx.toStringAsFixed(3)}, ${dy.toStringAsFixed(3)})')),
      new Center(child: new Text('We did it!')),
      new Center(child: new MyToolBar()),
      makeTransform(),
      new CardComponent(c, true)
    ]));
  }
}

void main() {
  runApp(new HelloWorldApp());
}

/*import 'package:sky/widgets/basic.dart';


class DemoApp extends App {
  Widget build() {
    return new Center(child: new MyToolBar());
  }
}

void main() {
  runApp(new DemoApp());
}*/

class MyToolBar extends Component {
  Widget build() {
    return new Container(
      decoration: const BoxDecoration(
        backgroundColor: const Color(0xFF00FFFF)
      ),
      height: 56.0,
      padding: const EdgeDims.symmetric(horizontal: 8.0),
      child: new Flex([
        new NetworkImage(src: 'menu.png', width: 25.0, height: 25.0),
        new Flexible(child: new Text('My awesome toolbar')),
        new NetworkImage(src: 'search.png', width: 25.0, height: 25.0),
      ])
    );
  }
}

// A component must build its widget in order to be a Widget.
// Widgets, however, just are what they are.
// Everything extends off Widget, but some are Component and some aren't, like
// the RenderObjectWrapper's. How do they manage to draw themselves? syncChild is the thing that is generally called.

// sky/widgets/basic.dart has all of these...
// So if I want to position something on my own... I could use Padding/Center in terms of widgets.
// But which one takes a Point or Offset?
// Hm... So I think we want to just position, we could use a Container or Transform
// Transform uses a matrix4 which is really inconvenient...
// new Matrix4.identity().scale? .rotate? .translate?
// RenderTransform works too instead of Transform. I guess.