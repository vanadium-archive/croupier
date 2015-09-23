// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:sky' as sky;

import 'package:sky/widgets.dart' as widgets;
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
        child: new widgets.Transform(
            transform: new vector_math.Matrix4.identity()
                .translate(displacement.dx, displacement.dy),
            child: new widgets.Opacity(
                child: child,
                opacity: displacement != widgets.Offset.zero ? 0.5 : 1.0)));
  }

  widgets.EventDisposition _startDrag(sky.PointerEvent event) {
    print("Drag Start");
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
    print("Drag Cancel");
    setState(() {
      dragController.cancel();
      dragController = null;
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _drop(sky.PointerEvent event) {
    print("Drag Drop");
    setState(() {
      dragController.update(new widgets.Point(event.x, event.y));
      dragController.drop();
      dragController = null;

      displacement = widgets.Offset.zero;
    });
    return widgets.EventDisposition.consumed;
  }
}
