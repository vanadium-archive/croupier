// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of solitaire;

class SolitaireLog extends GameLog {
  LogWriter logWriter;

  SolitaireLog() {
    logWriter = new LogWriter(handleSyncUpdate, [0]);
  }

  @override
  void setGame(Game g) {
    this.game = g;
    logWriter.associatedUser = this.game.playerNumber;
  }

  void handleSyncUpdate(String key, String cmd) {
    // In Solitaire, we can ignore the key because this is a single player game,
    // and the Solitaire schema only has TURN_BASED moves.
    SolitaireCommand sc = new SolitaireCommand.fromCommand(cmd);
    this.update(sc);
  }

  @override
  void addToLogCb(List<GameCommand> log, GameCommand newCommand) {
    logWriter.write(newCommand.simultaneity, newCommand.command);
  }

  @override
  List<GameCommand> updateLogCb(
      List<GameCommand> current, List<GameCommand> other, int mismatchIndex) {
    // Note: The Solitaire schema avoids all conflict, so this should never be called.
    assert(false);
    return current;
  }
}
