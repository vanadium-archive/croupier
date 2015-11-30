// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'logic/croupier.dart' show Croupier;
import 'components/settings_route.dart' show SettingsRoute;
import 'components/debug_route.dart' show DebugRoute;
import 'components/main_route.dart' show MainRoute;
import 'styles/common.dart' as style;

class CroupierApp extends StatefulComponent {
  CroupierApp();

  CroupierAppState createState() => new CroupierAppState();
}

class CroupierAppState extends State<CroupierApp> {
  Croupier croupier;

  void initState() {
    super.initState();
    this.croupier = new Croupier();
  }

  Widget build(BuildContext context) {
    return new MaterialApp(
        title: 'Croupier',
        routes: <String, RouteBuilder>{
          "/": (RouteArguments args) => new MainRoute(croupier),
          "/settings": (RouteArguments args) => new SettingsRoute(croupier),
          "/debug": (RouteArguments args) => new DebugRoute(croupier)
        },
        theme: style.theme);
  }
}

void main() {
  runApp(new CroupierApp());
}
