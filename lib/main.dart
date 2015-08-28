import 'package:sky/widgets.dart';

import 'logic/croupier.dart' show Croupier;
import 'components/croupier.dart' show CroupierComponent;

class CroupierApp extends App {
  Croupier croupier;

  CroupierApp() : super() {
    this.croupier = new Croupier();
  }

  Widget build() {
    return new Container(
        decoration: new BoxDecoration(
            backgroundColor: const Color(0xFF6666FF), borderRadius: 5.0),
        child: new CroupierComponent(this.croupier));
  }
}

void main() {
  runApp(new CroupierApp());
}
