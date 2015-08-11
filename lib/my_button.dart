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
  final Function onScrollStart;
  final Function onScrollUpdate;

  MyButton({this.child, this.onPressed, this.onScrollStart, this.onScrollUpdate});

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
      onGestureScrollStart: (e) {
        print('MyButton was scrolled!');
        if (this.onScrollStart != null) {
          this.onScrollStart(e);
        }
      },
      onGestureScrollUpdate: (e) {
        print('MyButton continues to be scrolled!');
        if (this.onScrollUpdate != null) {
          this.onScrollUpdate(e);
        }
      },
      child: makeContainer()
    );
  }
}