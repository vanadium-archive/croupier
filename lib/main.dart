// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/main_route.dart' show MainRoute;
import 'components/settings_route.dart' show SettingsRoute;
import 'logic/croupier.dart' show Croupier;
import 'settings/client.dart' as settings_client;
import 'sound/sound_assets.dart';
import 'styles/common.dart' as style;

class CroupierApp extends StatefulComponent {
  settings_client.AppSettings appSettings;
  SoundAssets sounds;
  CroupierApp(this.appSettings, this.sounds);

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
          "/": (RouteArguments args) => new MainRoute(croupier, config.sounds),
          "/settings": (RouteArguments args) => new SettingsRoute(croupier)
        },
        theme: style.theme);
  }
}

AssetBundle _initBundle() {
  // Note: Code was copied from parts of Flutter that load assets like sound.
  // rootBundle comes from flutter/services.dart
  if (rootBundle != null) return rootBundle;
  return new NetworkAssetBundle(new Uri.directory(Uri.base.origin));
}

Future<SoundAssets> loadAudio() async {
  final AssetBundle _bundle = _initBundle();
  SoundAssets _sounds = new SoundAssets(_bundle);

  // Load sounds in parallel.
  // TODO(alexfandrianto): Sound is turned off since it's not convenient to get
  // HEAD Mojo Shell built with the media service.
  //await Future.wait([_sounds.load("whooshIn"), _sounds.load("whooshOut")]);
  return _sounds;
}

void main() {
  // TODO(alexfandrianto): Perhaps my app will run better if I initialize more
  // things here instead of in Croupier. I added this 500 ms delay because the
  // tablet was sometimes not rendering without it (repainting too early?).
  new Future.delayed(const Duration(milliseconds: 500), () async {
    runApp(new CroupierApp(
        await settings_client.getSettings(), await loadAudio()));
  });
}
