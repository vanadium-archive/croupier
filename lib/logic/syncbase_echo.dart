import 'game.dart' show Game, GameType, GameLog, GameCommand;

class SyncbaseEcho extends Game {
  SyncbaseEcho() : super.dummy(GameType.SyncbaseEcho, new SyncbaseEchoLog());
}

class SyncbaseEchoLog extends GameLog {
  void addToLogCb(List<GameCommand> log, GameCommand newCommand) {
    update(new List<GameCommand>.from(log)..add(newCommand));
  }

  List<GameCommand> updateLogCb(
      List<GameCommand> current, List<GameCommand> other, int mismatchIndex) {
    assert(false); // This game can't have conflicts.
    return current;
  }
}
