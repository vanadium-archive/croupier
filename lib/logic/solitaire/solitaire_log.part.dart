// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of solitaire;

class SolitaireLog extends GameLog {
  LogWriter logWriter;
  Set<String> seenKeys; // the seen ones can be ignored.

  SolitaireLog() {
    // TODO(alexfandrianto): The Game ID needs to be part of this constructor.
    seenKeys = new Set<String>();
  }

  @override
  void setGame(Game g) {
    this.game = g;
    logWriter = new LogWriter(handleSyncUpdate, [0]);
    logWriter.associatedUser = this.game.playerNumber;
    logWriter.logPrefix = "${game.gameID}/log";
  }

  void handleSyncUpdate(String key, String cmd) {
    // In this game, we can execute commands in any order.
    // However, we must avoid repeated keys.
    if (!seenKeys.contains(key)) {
      SolitaireCommand sc = new SolitaireCommand.fromCommand(cmd);
      this.update(sc);
      seenKeys.add(key);
    } else {
      print("The log is ignoring repeated key: ${key}");
    }
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

  @override
  void close() {
    logWriter.close();
  }
}
