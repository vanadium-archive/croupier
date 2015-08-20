//import 'package:sky/widgets/basic.dart';

import 'card.dart' as card;
import 'my_button.dart';
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

class HelloWorldApp extends App {
  int counter = 0;
  String debug = '';
  int counter2 = 0;
  // String debug2 = '';
  // Accumulators for the current scroll.
  double dx = 0.0;
  double dy = 0.0;

  // Used for drag/drop of the square
  DragController _dragController;
  Offset _displacement = Offset.zero;

  // Positioning of the dotX and dotY
  double dotX = 10.0;
  double dotY = 10.0 + sky.view.paddingTop;

  String debug3 = '';

  Container makeTransform() {
    return new Container(
      child: new MyButton(
        child: new Text('Engage'),
        onPressed: _handleOnPressedCallback,
        onPointerDown: _handleOnPointerDownCallback,
        onPointerMove: _handleOnPointerMoveCallback
      ),
      padding: const EdgeDims.all(8.0),
      //margin: const EdgeDims.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(
        backgroundColor: const Color(0xFF0000FF),
        borderRadius: 5.0
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

  EventDisposition _startDrag(sky.PointerEvent event) {
    setState(() {
      _dragController = new DragController(new DragData("Orange"));
      _dragController.update(new Point(event.x, event.y));
      _displacement = Offset.zero;
      debug3 = "START ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return EventDisposition.consumed;
  }

  EventDisposition _updateDrag(sky.PointerEvent event) {
    setState(() {
      _dragController.update(new Point(event.x, event.y));
      _displacement += new Offset(event.dx, event.dy);
      debug3 = "DRAG ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return EventDisposition.consumed;
  }

  EventDisposition _cancelDrag(sky.PointerEvent event) {
    setState(() {
      _dragController.cancel();
      _dragController = null;
      debug3 = "CANCELED";
    });
    return EventDisposition.consumed;
  }

  EventDisposition _drop(sky.PointerEvent event) {
    setState(() {
      _dragController.update(new Point(event.x, event.y));
      _dragController.drop();
      _dragController = null;

      dotX += _displacement.dx;
      dotY += _displacement.dy;
      _displacement = Offset.zero;
      debug3 = "DROP ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return EventDisposition.consumed;
  }

  Widget build() {
    return new Center(child: new Flex([
      new Center(child: new Text('Hello, world!')),
      new Center(child: new Text('Tap #${counter}: ${debug}')),
      new Center(child: new Text('Scroll #${counter2}: (${dx.toStringAsFixed(3)}, ${dy.toStringAsFixed(3)})')),
      new Center(child: new Text('We did it!')),
      new Center(child: new MyToolBar()),
      makeTransform(),
      new Flex([
        new card.CardComponent(new card.Card.fromString("classic h1"), true),
        new card.CardComponent(new card.Card.fromString("classic sk"), true),
        new card.CardComponent(new card.Card.fromString("classic d5"), true)
      ]),
      new Center(child: new Text('Drag: ${debug3}')),
      new Center(child: new Text('X, Y: ${dotX} ${dotY}')),
      new Container(
        decoration: new BoxDecoration(backgroundColor: colors.Pink[500]),
        child: new Stack([
          new Flex([
            new ExampleDragTarget(),
            new ExampleDragTarget()
          ]),
          new Positioned(
            top: _dragController != null ? dotY + _displacement.dy : -1000.0,
            left: _dragController != null ? dotX + _displacement.dx : -1000.0,
            child: new IgnorePointer(
              child: new Opacity(
                opacity: 1.0,
                child: new Dot()
              )
            )
          ),
          new Listener(
            onPointerDown: _startDrag,
            onPointerMove: _updateDrag,
            onPointerCancel: _cancelDrag,
            onPointerUp: _drop,
            child: new Positioned(
              top: dotY,
              left: dotX,
              child: new Opacity(
                opacity: _dragController != null ? 0.0 : 1.0,
                child: new Dot()
              )
            )
          )
        ])
      )
    ], direction: FlexDirection.vertical));
  }
}

class Dot extends Component {
  Widget build() {
    return new Container(
      width: 50.0,
      height: 50.0,
      decoration: new BoxDecoration(
        backgroundColor: colors.DeepOrange[500]
      )
    );
  }
}

class DragData {
  DragData(this.text);

  final String text;
}

class ExampleDragTarget extends StatefulComponent {
  String _text = 'ready';

  void syncFields(ExampleDragTarget source) {
  }

  void _handleAccept(DragData data) {
    setState(() {
      _text = data.text;
    });
  }

  Widget build() {
    return new DragTarget<DragData>(
      onAccept: _handleAccept,
      builder: (List<DragData> data, _) {
        return new Container(
          width: 100.0,
          height: 100.0,
          margin: new EdgeDims.all(10.0),
          decoration: new BoxDecoration(
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? colors.white : colors.Blue[500]
            ),
            backgroundColor: data.isEmpty ? colors.Grey[500] : colors.Green[500]
          ),
          child: new Center(
            child: new Text(_text)
          )
        );
      }
    );
  }
}

void main() {
  runApp(new HelloWorldApp());
}

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