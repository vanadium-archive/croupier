// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../logic/croupier_settings.dart' show CroupierSettings, RandomSettings;

import 'package:flutter/material.dart';

typedef void NoArgCb();
typedef void OneStringCb(String data);
typedef void SaveDataCb(int userID, String jsonData);

enum DialogType { Text, ColorPicker, ImagePicker }

const String nameKey = "name";
const String colorKey = "color";
const String avatarKey = "avatar";

Map<String, GlobalKey> globalKeys = {
  nameKey: new GlobalKey(),
  colorKey: new GlobalKey(),
  avatarKey: new GlobalKey()
};

Map<String, DialogType> dialogTypes = {
  nameKey: DialogType.Text,
  colorKey: DialogType.ColorPicker,
  avatarKey: DialogType.ImagePicker
};

class CroupierSettingsComponent extends StatefulComponent {
  final NavigatorState navigator;
  final CroupierSettings settings;
  final SaveDataCb saveDataCb;
  final NoArgCb backCb;

  CroupierSettingsComponent(this.navigator, this.settings, this.saveDataCb, this.backCb);

  CroupierSettingsComponentState createState() =>
      new CroupierSettingsComponentState();
}

class CroupierSettingsComponentState extends State<CroupierSettingsComponent> {
  Map<String, String> _tempData = new Map<String, String>();

  void initState() {
    super.initState();

    _initializeTemp();
  }

  void _initializeTemp() {
    _tempData[nameKey] = config.settings.name;
    _tempData[colorKey] = "${config.settings.color}";
    _tempData[avatarKey] = config.settings.avatar;
  }

  Widget _makeColoredRectangle(int colorInfo, String text, NoArgCb cb) {
    return new Container(
        decoration: new BoxDecoration(backgroundColor: new Color(colorInfo)),
        child: new FlatButton(
            child: new Text(""), enabled: cb != null, onPressed: cb));
  }

  Widget _makeImageButton(String url, NoArgCb cb) {
    return new FlatButton(
        child: new NetworkImage(src: url), enabled: cb != null, onPressed: cb);
  }

  Widget build(BuildContext context) {
    List<Widget> w = new List<Widget>();
    w.add(_makeButtonRow(nameKey, new Text(config.settings.name)));
    w.add(_makeButtonRow(colorKey,
        _makeColoredRectangle(config.settings.color, "", null)));
    w.add(_makeButtonRow(
        avatarKey, new NetworkImage(src: config.settings.avatar)));

    w.add(new FlatButton(child: new Text("Return"), onPressed: config.backCb));
    return new Column(w);
  }

  Widget _makeButtonRow(String type, Widget child) {
    String capType = _capitalize(type);
    return new FlatButton(
        onPressed: () => _handlePressed(type),
        child: new Row([
          new Flexible(
              flex: 1,
              child: new Text(capType, style: Theme.of(context).text.subhead)),
          new Flexible(flex: 3, child: child)
        ], justifyContent: FlexJustifyContent.start));
  }

  void _handlePressed(String type) {
    var capType = _capitalize(type);
    showDialog(config.navigator, (NavigatorState navigator) {
      switch (dialogTypes[type]) {
        case DialogType.Text:
          return new Dialog(
              title: new Text(capType),
              content: new Input(
                  key: globalKeys[type],
                  placeholder: capType,
                  initialValue: config.settings.getStringValue(type),
                  keyboardType: KeyboardType.TEXT,
                  onChanged: _makeHandleChanged(type)), onDismiss: () {
            navigator.pop();
          }, actions: [
            new FlatButton(child: new Text('CANCEL'), onPressed: () {
              navigator.pop();
            }),
            new FlatButton(child: new Text('SAVE'), onPressed: () {
              navigator.pop(_tempData[type]);
            }),
          ]);
        case DialogType.ColorPicker:
          List<Widget> flexColors = new List<Widget>();
          List<int> colors = <int>[
            0xcfefefef,
            0xcfff3333,
            0xcf33ff33,
            0xcf3333ff,
            0xcf101010,
            0xcf33ffff,
            0xcfff33ff,
            0xcfffff33,
          ];
          for (int i = 0; i < colors.length; i++) {
            int c = colors[i];
            flexColors.add(_makeColoredRectangle(c, "", () {
              // TODO(alexfandrianto): Remove this hack-y subtraction once the
              // Dart + Android issue with int.parse is fixed.
              navigator.pop("${c - 0xcf000000}");
            }));
          }

          return new Dialog(
              title: new Text(capType),
              content: new Grid(flexColors, maxChildExtent: 75.0),
              onDismiss: () {
            navigator.pop();
          }, actions: [
            new FlatButton(child: new Text('CANCEL'), onPressed: () {
              navigator.pop();
            })
          ]);
        case DialogType.ImagePicker:
          List<Widget> flexAvatars = new List<Widget>();
          for (int i = 0; i < RandomSettings.avatars.length; i++) {
            String avatar = RandomSettings.avatars[i];
            flexAvatars.add(_makeImageButton(avatar, () {
              navigator.pop(avatar);
            }));
          }

          return new Dialog(
              title: new Text(capType),
              content: new Grid(flexAvatars, maxChildExtent: 75.0),
              onDismiss: () {
            navigator.pop();
          }, actions: [
            new FlatButton(child: new Text('CANCEL'), onPressed: () {
              navigator.pop();
            })
          ]);
        default:
          assert(false);
          return null;
      }
    }).then((String data) => _persist(type, data));
  }

  void _persist(String type, String data) {
    if (data == null) {
      return;
    }
    setState(() {
      config.settings.setStringValue(type, data);
      config.saveDataCb(config.settings.userID,
          config.settings.toJSONString());
    });
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  OneStringCb _makeHandleChanged(String type) {
    return (String data) {
      setState(() {
        print("Updating ${type} with ${data}");
        _tempData[type] = data;
      });
    };
  }
}
