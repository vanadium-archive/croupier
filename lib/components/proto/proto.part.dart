// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game_component;

class ProtoGameComponent extends GameComponent {
  ProtoGameComponent(Croupier croupier, SoundAssets sounds, NoArgCb cb,
      {Key key, double width, double height})
      : super(croupier, sounds, cb, key: key, width: width, height: height);

  ProtoGameComponentState createState() => new ProtoGameComponentState();
}

class ProtoGameComponentState extends GameComponentState<ProtoGameComponent> {
  @override
  Widget build(BuildContext context) {
    List<Widget> cardCollections = new List<Widget>();

    cardCollections.add(new Text(config.game.debugString ?? ""));

    for (int i = 0; i < 4; i++) {
      List<logic_card.Card> cards = config.game.cardCollections[i];
      CardCollectionComponent c = new CardCollectionComponent(
          cards, config.game.playerNumber == i, CardCollectionOrientation.horz,
          dragChildren: true,
          acceptType: DropType.card,
          acceptCallback: _makeGameMoveCallback,
          width: config.width);
      cardCollections.add(c); // flex
    }

    cardCollections.add(new Container(
        decoration: new BoxDecoration(
            backgroundColor: Colors.green[500], borderRadius: 5.0),
        child: new CardCollectionComponent(config.game.cardCollections[4], true,
            CardCollectionOrientation.show1,
            dragChildren: true,
            acceptType: DropType.card,
            acceptCallback: _makeGameMoveCallback,
            width: config.width)));

    cardCollections.add(_makeDebugButtons());

    return new Container(
        decoration: new BoxDecoration(backgroundColor: Colors.pink[500]),
        child: new Column(children: cardCollections));
  }

  void _makeGameMoveCallback(logic_card.Card card, List<logic_card.Card> dest) {
    setState(() {
      try {
        config.game.move(card, dest);
      } catch (e) {
        print("You can't do that! ${e.toString()}");
        config.game.debugString = e.toString();
      }
    });
  }

  Widget _makeDebugButtons() {
    if (config.game.debugMode == false) {
      return new Row(children: [
        new Flexible(flex: 4, child: _makeButton('Quit', _quitGameCallback))
      ]);
    }
    return new Row(children: [
      new Text('P${config.game.playerNumber}'),
      _makeButton('Switch View', _switchPlayersCallback),
      _makeButton('Quit', _quitGameCallback)
    ]);
  }

  void _switchPlayersCallback() {
    setState(() {
      config.game.playerNumber = (config.game.playerNumber + 1) % 4;
    });
  }
}
