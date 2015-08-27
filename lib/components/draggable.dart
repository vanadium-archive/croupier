import 'package:sky/widgets.dart' as widgets;
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart' as vector_math;

class Draggable<T extends widgets.Widget> extends widgets.StatefulComponent {
  widgets.DragController dragController;
  widgets.Offset displacement = widgets.Offset.zero;
  T child;

  Draggable(this.child);

  void syncConstructorArguments(Draggable other) {
    child = other.child;
  }

  widgets.Widget build() {
    return new widgets.Listener(
      onPointerDown: _startDrag,
      onPointerMove: _updateDrag,
      onPointerCancel: _cancelDrag,
      onPointerUp: _drop,
      child:     new widgets.Transform(
                  transform: new vector_math.Matrix4.identity().translate(displacement.dx, displacement.dy),
                  child: child)
    );
  }

  widgets.EventDisposition _startDrag(sky.PointerEvent event) {
    setState(() {
      dragController = new widgets.DragController(this.child);
      dragController.update(new widgets.Point(event.x, event.y));
      displacement = widgets.Offset.zero;
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _updateDrag(sky.PointerEvent event) {
    setState(() {
      dragController.update(new widgets.Point(event.x, event.y));
      displacement += new widgets.Offset(event.dx, event.dy);
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _cancelDrag(sky.PointerEvent event) {
    setState(() {
      dragController.cancel();
      dragController = null;
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _drop(sky.PointerEvent event) {
    setState(() {
      dragController.update(new widgets.Point(event.x, event.y));
      dragController.drop();
      dragController = null;

      displacement = widgets.Offset.zero;
    });
    return widgets.EventDisposition.consumed;
  }
}
