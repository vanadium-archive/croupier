// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/croupier.dart' as logic_croupier;

import 'package:sky/widgets_next.dart';

typedef void NoArgCb();
typedef void OneStringCb(String data);

Map<String, GlobalKey> globalKeys = {
  "name": new GlobalKey(),
  "color": new GlobalKey(),
  "avatar": new GlobalKey()
};

class CroupierSettingsComponent extends StatefulComponent {
  final logic_croupier.Croupier croupier;
  final NoArgCb backCb;

  CroupierSettingsComponent(this.croupier, this.backCb);

  CroupierSettingsComponentState createState() => new CroupierSettingsComponentState();
}

class CroupierSettingsComponentState extends State<CroupierSettingsComponent> {
  String _tempName;
  String _tempColor; // will be parsed to an int later.
  String _tempAvatar;

  void initState(_) {
    super.initState(_);

    _initializeTemp();
  }

  void _initializeTemp() {
    _tempName = config.croupier.settings.name;
    _tempColor = "${config.croupier.settings.color}";
    _tempAvatar = config.croupier.settings.avatar;
  }

  Widget build(BuildContext context) {
    List<Widget> w = new List<Widget>();
    w.add(_makeInput("name"));
    // Having multiple Input Widgets on-screen at the same time is bad.
    // https://github.com/flutter/engine/issues/1387
    // Using a Dialog instead of a Text widget requires reworking the app.
    // https://github.com/flutter/engine/issues/243
    w.add(new Container(
      decoration: new BoxDecoration(
            backgroundColor: new Color(config.croupier.settings.color)),
      child: new Text("color")));
    w.add(new NetworkImage(src: config.croupier.settings.avatar));
    //w.add(_makeInput("color"));
    //w.add(_makeInput("avatar"));
    w.add(new FlatButton(child: new Text("Return"), onPressed: config.backCb));
    return new Column(w);
  }

  void _persist() {
    setState(() {
      config.croupier.settings.name = _tempName;
      int newColor;
      // https://github.com/domokit/mojo/issues/192
      // Just calling int.parse will crash SIGSEGV the Dart VM on Android.
      // Note: if the number is too big. If you do a smaller number, it's fine.
      /*try {
        newColor = int.parse(_tempColor);
      } catch (e) {
        print(e);
      }*/
      if (newColor != null) {
        config.croupier.settings.color = newColor;
      }
      config.croupier.settings.avatar = _tempAvatar;
      config.croupier.settings_manager.save(config.croupier.settings.userID, config.croupier.settings.toJSONString());
    });
  }

  Widget _makeInput(String type) {
    var capType = _capitalize(type);
    var keyboardType = type == "color" ? KeyboardType.NUMBER : KeyboardType.TEXT;
    Input i = new Input(
      key: globalKeys[type],
      initialValue: config.croupier.settings.getStringValue(type),
      placeholder: capType,
      keyboardType: keyboardType,
      onChanged: _makeHandleChanged(type)
    );
    FlatButton fb = new FlatButton(child: new Text("Save ${capType}"), onPressed: _persist);

    return new Row([i, fb]);
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  OneStringCb _makeHandleChanged(String type) {
    return (String data) {
      setState(() {
        print(data);
        switch (type) {
          case "name":
            _tempName = data;
            break;
          case "color":
            _tempColor = data;
            break;
          case "avatar":
            _tempAvatar = data;
            break;
          default:
            break;
        }
      });
    };
  }
}