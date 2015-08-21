import '../logic/card.dart' show Card;
import 'card_constants.dart' as card_constants;
import 'package:sky/widgets.dart' as widgets;
import 'package:sky/theme/colors.dart' as colors;
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart' as vector_math;

class CardComponent extends widgets.StatefulComponent {
  Card card;
  bool faceUp;

  widgets.DragController dragController;
  widgets.Offset displacement = widgets.Offset.zero;
  String status = 'foo';

  CardComponent(this.card, this.faceUp);

  void syncFields(CardComponent other) {
    //assert(false); // Why do we need to do this?
    //dragController = other.dragController;
    //displacement = other.displacement;
    card = other.card;
    faceUp = other.faceUp;
  }

  widgets.Widget build() {
    return new widgets.Listener(
      onPointerDown: _startDrag,
      onPointerMove: _updateDrag,
      onPointerCancel: _cancelDrag,
      onPointerUp: _drop,
      child: new widgets.Container(
        //width: card_constants.CARD_WIDTH,
        //height: card_constants.CARD_HEIGHT,
        child: new widgets.Container(
          decoration: new widgets.BoxDecoration(
            border: new widgets.Border.all(
              width: 3.0,
              color: dragController == null ? colors.Yellow[500] : colors.Red[500]
            ),
            backgroundColor: dragController == null ? colors.Orange[500] : colors.Brown[500]
          ),
          child: new widgets.Transform(
            transform: new vector_math.Matrix4.identity().translate(displacement.dx, displacement.dy),
            child: new widgets.Flex([
              imageFromCard(card, faceUp),
              new widgets.Text(status)
            ], direction: widgets.FlexDirection.vertical)
          )
        )
      )
    );
  }

  static widgets.Widget imageFromCard(Card c, bool faceUp) {
    String imageName = "${c.deck}/${faceUp ? 'up' : 'down'}/${c.identifier}.png";
    return new widgets.NetworkImage(src: imageName);
  }

  widgets.EventDisposition _startDrag(sky.PointerEvent event) {
    setState(() {
      dragController = new widgets.DragController(new CardDragData(this.card));
      dragController.update(new widgets.Point(event.x, event.y));
      displacement = widgets.Offset.zero;
      status = 'dragS ${event.x.toStringAsFixed(0)} ${event.y.toStringAsFixed(0)}';
      //debug3 = "START ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _updateDrag(sky.PointerEvent event) {
    setState(() {
      dragController.update(new widgets.Point(event.x, event.y));
      displacement += new widgets.Offset(event.dx, event.dy);
      status = 'dragU ${event.x.toStringAsFixed(0)} ${event.y.toStringAsFixed(0)}';
      //debug3 = "DRAG ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _cancelDrag(sky.PointerEvent event) {
    setState(() {
      dragController.cancel();
      dragController = null;
      //debug3 = "CANCELED";
      status = 'CNCL ${event.x.toStringAsFixed(0)} ${event.y.toStringAsFixed(0)}';
    });
    return widgets.EventDisposition.consumed;
  }

  widgets.EventDisposition _drop(sky.PointerEvent event) {
    setState(() {
      dragController.update(new widgets.Point(event.x, event.y));
      dragController.drop();
      dragController = null;

      //dotX += _displacement.dx;
      //dotY += _displacement.dy;
      displacement = widgets.Offset.zero;
      status = 'DROP ${event.x.toStringAsFixed(0)} ${event.y.toStringAsFixed(0)}';
      //debug3 = "DROP ${event.x.toStringAsFixed(3)} ${event.y.toStringAsFixed(3)}";
    });
    return widgets.EventDisposition.consumed;
  }
}

class CardDragData {
  final Card card;

  CardDragData(this.card);

  String toString() {
    return card.toString();
  }
}