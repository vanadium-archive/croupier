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
  final CroupierSettings settings;
  final SaveDataCb saveDataCb;

  CroupierSettingsComponent(this.settings, this.saveDataCb);

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
        child: new FlatButton(child: new Text(""), onPressed: cb));
  }

  Widget _makeImageButton(String url, NoArgCb cb) {
    return new FlatButton(
        child: new AssetImage(name: CroupierSettings.makeAvatarUrl(url)),
        onPressed: cb);
  }

  Widget build(BuildContext context) {
    return new Scaffold(
        toolBar: _buildToolBar(), body: _buildSettingsPane(context));
  }

  Widget _buildToolBar() {
    return new ToolBar(
        left: new IconButton(
            icon: "navigation/arrow_back",
            onPressed: () => Navigator.pop(context)),
        center: new Text("Settings"));
  }

  Widget _buildSettingsPane(BuildContext context) {
    List<Widget> w = new List<Widget>();
    w.add(_makeButtonRow(nameKey, new Text(config.settings.name)));
    w.add(_makeButtonRow(
        colorKey, _makeColoredRectangle(config.settings.color, "", null)));
    w.add(_makeButtonRow(
        avatarKey,
        new AssetImage(
            name: CroupierSettings.makeAvatarUrl(config.settings.avatar))));

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

    Dialog dialog;

    switch (dialogTypes[type]) {
      case DialogType.Text:
        dialog = new Dialog(
            title: new Text(capType),
            content: new Input(
                key: globalKeys[type],
                placeholder: capType,
                initialValue: config.settings.getStringValue(type),
                keyboardType: KeyboardType.TEXT,
                onChanged: _makeHandleChanged(type)),
            actions: [
              new FlatButton(child: new Text('CANCEL'), onPressed: () {
                Navigator.pop(context);
              }),
              new FlatButton(child: new Text('SAVE'), onPressed: () {
                Navigator.pop(context, _tempData[type]);
              }),
            ]);
        break;
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
            Navigator.pop(context, "${c - 0xcf000000}");
          }));
        }

        dialog = new Dialog(
            title: new Text(capType),
            content: new Grid(flexColors, maxChildExtent: 75.0),
            actions: [
              new FlatButton(child: new Text('CANCEL'), onPressed: () {
                Navigator.pop(context);
              })
            ]);
        break;
      case DialogType.ImagePicker:
        List<Widget> flexAvatars = new List<Widget>();
        for (int i = 0; i < RandomSettings.avatars.length; i++) {
          String avatar = RandomSettings.avatars[i];
          flexAvatars.add(_makeImageButton(avatar, () {
            Navigator.pop(context, avatar);
          }));
        }

        dialog = new Dialog(
            title: new Text(capType),
            content: new Grid(flexAvatars, maxChildExtent: 75.0),
            actions: [
              new FlatButton(child: new Text('CANCEL'), onPressed: () {
                Navigator.pop(context);
              })
            ]);
        break;
      default:
        assert(false);
        return null;
    }

    showDialog(context: context, child: dialog)
        .then((String data) => _persist(type, data));
  }

  void _persist(String type, String data) {
    if (data == null) {
      return;
    }
    setState(() {
      config.settings.setStringValue(type, data);
      config.saveDataCb(config.settings.userID, config.settings.toJSONString());
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
