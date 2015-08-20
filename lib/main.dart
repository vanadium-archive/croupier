//import 'package:sky/widgets/basic.dart';

//import 'card.dart' as card;
//import 'my_button.dart';
//import 'dart:sky' as sky;
//import 'package:vector_math/vector_math.dart' as vector_math;
//import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

import 'logic/game.dart' show Game;
import 'components/game.dart' show GameComponent;

class CroupierApp extends App {
  Game game;

  CroupierApp() : super() {
    this.game = new Game.hearts(0);
  }

  Widget build() {
    return new GameComponent(this.game);
  }
}

void main() {
  runApp(new CroupierApp());
}