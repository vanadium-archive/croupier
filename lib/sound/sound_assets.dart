// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_sprites/flutter_sprites.dart';

/// SoundAssets are used to play sounds in the game.
class SoundAssets {
  SoundAssets(this._bundle) {
    _soundEffectPlayer = new SoundEffectPlayer(20);
  }

  AssetBundle _bundle;
  SoundEffectPlayer _soundEffectPlayer;
  Map<String, SoundEffect> _soundEffects = <String, SoundEffect>{};

  Future load(String name) async {
    _soundEffects[name] =
        await _soundEffectPlayer.load(await _bundle.load('sounds/$name.wav'));
  }

  void play(String name) {
    _soundEffectPlayer.play(_soundEffects[name]);
  }
}
