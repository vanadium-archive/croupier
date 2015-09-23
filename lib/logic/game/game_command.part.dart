// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game;

abstract class GameCommand {
  bool canExecute(Game game);
  void execute(Game game);

  String get data;

  bool operator ==(Object other) {
    if (other is GameCommand) {
      return this.data == other.data;
    }
    return false;
  }

  String toString() {
    return data;
  }
}