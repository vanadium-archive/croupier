// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of game;

abstract class GameLog {
  Game game;
  List<GameCommand> log = new List<GameCommand>();
  // This list is normally empty, but may grow if multiple commands arrive.
  List<GameCommand> pendingCommands = new List<GameCommand>();
  bool hasFired = false; // if true, halts processing of later pendingCommands}
  AsyncKeyValueCallback watchUpdateCb; // May be null.

  void setGame(Game g) {
    this.game = g;
  }

  void add(GameCommand gc) {
    pendingCommands.add(gc);
    _tryPendingCommand();
  }

  void _tryPendingCommand() {
    if (pendingCommands.length > 0 && !hasFired) {
      GameCommand gc = pendingCommands[0];
      if (gc.canExecute(game)) {
        hasFired = true;
        addToLogCb(log, gc);
      } else {
        // What can we do if the first command isn't allowed to fire?
        throw new StateError("Cannot run ${gc.command}");
      }
    }
  }

  void update(GameCommand newCmd) {
    _updateAndRun(newCmd);
    _runUpdateCallback();

    // Now that we've run this command, let's try our other pending commands.
    _tryPendingCommand();
  }

  void _updateAndRun(GameCommand newCmd) {
    log.add(newCmd);
    if (pendingCommands.length > 0 && pendingCommands[0] == newCmd) {
      pendingCommands.removeAt(0);
      hasFired = false;
    }
    newCmd.execute(game);
    game.triggerEvents();
  }

  void _runUpdateCallback() {
    if (game.updateCallback != null) {
      game.updateCallback();
    }
  }

  // TODO(alexfandrianto): We may want to remove 'merge', since nobody uses it.
  // This would also let us remove updateLogCb (conflict resolution callback).
  void merge(List<GameCommand> otherLog) {
    int numMatches = 0;
    while (numMatches < log.length &&
        numMatches < otherLog.length &&
        log[numMatches] == otherLog[numMatches]) {
      numMatches++;
    }

    // At this point, i is at the farthest point of common-ness.
    // If i matches the log length, then take the rest of the other log.
    if (numMatches == log.length) {
      for (int j = numMatches; j < otherLog.length; j++) {
        _updateAndRun(otherLog[j]);
      }
      _runUpdateCallback();
    } else if (numMatches == otherLog.length) {
      // We seem to have done more valid moves, so we can just ignore the other side.
      // TODO(alexfandrianto): If we play a game with actual 'undo' moves,
      // do we want to record them or erase history?
      print('Ignoring shorter log');
    } else {
      // This case is weird, we have some amount of common log and some mismatch.
      // Ask the game itself what to do.
      print('Oh no! A conflict!');
      log = updateLogCb(log, otherLog, numMatches);
      // What we need to do here is to undo the moves that didn't match and then replay the new ones.
      assert(false);
      // TODO(alexfandrianto): At worst, we can also just reset the game and play through all of it. (No UI updates till the end).
    }

    // Now that we got an update, let's try our other pending commands.
    _tryPendingCommand();
  }

  @override
  String toString() => log.toString();

  // UNIMPLEMENTED: Let subclasses override this.
  void addToLogCb(List<GameCommand> log, GameCommand newCommand);
  List<GameCommand> updateLogCb(
      List<GameCommand> current, List<GameCommand> other, int mismatchIndex);
}
