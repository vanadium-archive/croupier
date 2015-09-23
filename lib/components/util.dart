import 'package:sky/widgets.dart';

List<Widget> flexChildren(List<Widget> children) {
  List<Widget> flexWidgets = new List<Widget>();
  children.forEach(
      (child) => flexWidgets.add(new Flexible(child: child)));
  return flexWidgets;
}