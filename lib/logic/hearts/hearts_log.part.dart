// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of hearts;

class HeartsLog extends GameLog {
  LogWriter logWriter;

  HeartsLog() {
    logWriter = new LogWriter(handleSyncUpdate, [0, 1, 2, 3]);
  }

  @override
  void setGame(Game g) {
    this.game = g;
    logWriter.associatedUser = this.game.playerNumber;
  }

  void handleSyncUpdate(String key, String cmd) {
    // In Hearts, we can ignore the key. Our in-memory log does not need to
    // guarantee the event order of the INDEPENDENT phase, which can reference
    // keys from the "earlier" actions of other players.
    HeartsCommand hc = new HeartsCommand.fromCommand(cmd);
    this.update(hc);
  }

  @override
  void addToLogCb(List<GameCommand> log, GameCommand newCommand) {
    logWriter.write(newCommand.simultaneity, newCommand.command);
  }

  @override
  List<GameCommand> updateLogCb(
      List<GameCommand> current, List<GameCommand> other, int mismatchIndex) {
    // Note: The Hearts schema avoids all conflict, so this should never be called.
    assert(false);
    return current;
  }

  @override
  void close() {
    logWriter.close();
  }
}
