//import 'package:sky/widgets/basic.dart';

//import 'card.dart' as card;
//import 'my_button.dart';
//import 'dart:sky' as sky;
//import 'package:vector_math/vector_math.dart' as vector_math;
//import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

//import 'logic/game.dart' show Game, HeartsCommand;
//import 'components/game.dart' show GameComponent;
import 'logic/croupier.dart' show Croupier;
import 'components/croupier.dart' show CroupierComponent;

//import 'dart:io';
//import 'dart:convert';
//import 'dart:async';

class CroupierApp extends App {
  Croupier croupier;

  CroupierApp() : super() {
    this.croupier = new Croupier();
  }

  Widget build() {
    return new CroupierComponent(this.croupier);
  }
}

void main() {
  print('started');
  CroupierApp app = new CroupierApp();

  // Had difficulty reading from a file, so I can use this to simulate it.
  // Seems like only NetworkImage exists, but why not also have NetworkFile?
  /*List<String> commands = <String>[
    "Deal:0:classic h1:classic h2:classic h3:classic h4:END",
    "Deal:1:classic d1:classic d2:classic d3:classic d4:END",
    "Deal:2:classic s1:classic s2:classic s3:classic s4:END",
    "Deal:3:classic c1:classic c2:classic c3:classic c4:END",
    "Pass:0:1:classic h2:classic h3:END",
    "Pass:1:2:classic d1:classic d4:END",
    "Play:0:classic h1:END",
    "Play:1:classic d3:END",
    "Play:2:classic d4:END",
    "Play:3:classic c2:END"
  ];
  new Future.delayed(new Duration(seconds: 2)).then((_) {
    for (var i = 0; i < commands.length; i++) {
      new Future.delayed(new Duration(seconds: 1*i)).then((_) {
        app.game.gamelog.add(new HeartsCommand(commands[i]));
      });
    }
  });*/


  runApp(app);
  print('running');
}