// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:sky/widgets.dart';
import 'package:sky/material.dart' show Colors;

import 'logic/croupier.dart' show Croupier;
import 'components/croupier.dart' show CroupierComponent;

class CroupierApp extends StatefulComponent {
  final NavigatorState navigator;
  CroupierApp(this.navigator);

  CroupierAppState createState() => new CroupierAppState();
}

class CroupierAppState extends State<CroupierApp> {
  Croupier croupier;

  void initState() {
    super.initState();
    this.croupier = new Croupier();
  }

  Widget build(BuildContext context) {
    return new Container(
        decoration: new BoxDecoration(
            backgroundColor: const Color(0xFF6666FF), borderRadius: 5.0),
        child: new DefaultTextStyle(
            style: Theme.of(context).text.body1,
            child: new CroupierComponent(config.navigator, this.croupier)));
  }
}

void main() {
  runApp(new App(
      title: 'Croupier',
      routes: <String, RouteBuilder>{
        "/": (NavigatorState navigator, Route route) =>
            new CroupierApp(navigator)
      },
      theme: new ThemeData(
          brightness: ThemeBrightness.light, primarySwatch: Colors.purple)));
}
