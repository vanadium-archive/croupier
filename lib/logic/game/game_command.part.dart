// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game;

abstract class GameCommand {
  final String phase;
  final String data;
  final SimulLevel simultaneity;

  GameCommand(this.phase, this.data,
      {this.simultaneity: SimulLevel.independent});

  // UNIMPLEMENTED
  bool canExecute(Game game);
  void execute(Game game);

  String get command => toString();

  bool operator ==(Object other) {
    if (other is GameCommand) {
      return this.command == other.command;
    }
    return false;
  }

  String toString() {
    return "${phase}|${data}";
  }
}
