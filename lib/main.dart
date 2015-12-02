// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:async';

import 'settings/client.dart' as settings_client;
import 'logic/croupier.dart' show Croupier;
import 'components/settings_route.dart' show SettingsRoute;
import 'components/debug_route.dart' show DebugRoute;
import 'components/main_route.dart' show MainRoute;
import 'styles/common.dart' as style;

class CroupierApp extends StatefulComponent {
  settings_client.AppSettings appSettings;
  CroupierApp(this.appSettings);

  CroupierAppState createState() => new CroupierAppState();
}

class CroupierAppState extends State<CroupierApp> {
  Croupier croupier;

  void initState() {
    super.initState();
    this.croupier = new Croupier(config.appSettings);
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
  // TODO(alexfandrianto): Perhaps my app will run better if I initialize more
  // things here instead of in Croupier. I added this 500 ms delay because the
  // tablet was sometimes not rendering without it (repainting too early?).
  new Future.delayed(const Duration(milliseconds: 500), () async {
    runApp(new CroupierApp(await settings_client.getSettings()));
  });
}
