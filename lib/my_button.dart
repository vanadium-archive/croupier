import 'package:sky/widgets/basic.dart';

final BoxDecoration _decoration = new BoxDecoration(
  backgroundColor: const Color(0xFFFF00FF),
  borderRadius: 5.0/*,
  gradient: new LinearGradient(
    endPoints: [ Point.origin, const Point(0.0, 36.0) ],
    colors: [ const Color(0xFFEEEEEE), const Color(0xFFCCCCCC) ]
  )*/
);

class MyButton extends Component {
  final Widget child;
  final Function onPressed;
  final Function onPointerDown;
  final Function onPointerMove;
  final Function onPointerUp;

  MyButton({this.child, this.onPressed, this.onPointerDown, this.onPointerMove, this.onPointerUp});

  Container makeContainer() {
    return new Container(
      height: 36.0,
      padding: const EdgeDims.all(8.0),
      margin: const EdgeDims.symmetric(horizontal: 8.0),
      decoration: _decoration,
      child: new Center(
        child: this.child
      )
    );
  }

  Widget build() {
    return new Listener(
      // Listeners have these possibly fields https://github.com/domokit/sky_engine/blob/2e8843893b9c1cef0f0f9d9e00d384fca7a70d23/sky/packages/sky/lib/widgets/framework.dart
      onGestureTap: (e) {
        print('MyButton was tapped!');
        if (this.onPressed != null) {
          this.onPressed(e);
        }
      },
      onPointerDown: (e) {
        print('MyButton was scrolled!');
        if (this.onPointerDown != null) {
          this.onPointerDown(e);
        }
      },
      onPointerMove: (e) {
        print('MyButton continues to be scrolled!');
        if (this.onPointerMove != null) {
          this.onPointerMove(e);
        }
      },
      onPointerUp: (e) {
        print('MyButton pointer up!');
        if (this.onPointerUp != null) {
          this.onPointerUp(e);
        }
      },
      child: makeContainer()
    );
  }
}