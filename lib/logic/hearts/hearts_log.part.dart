// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of hearts;

class HeartsLog extends GameLog {
  LogWriter logWriter;

  HeartsLog() {
    logWriter = new LogWriter(handleSyncUpdate);
  }

  Map<String, String> _toLogData(
      List<GameCommand> log, GameCommand newCommand) {
    Map<String, String> data = new Map<String, String>();
    for (int i = 0; i < log.length; i++) {
      data["${i}"] = log[i].data;
    }
    data["${log.length}"] = newCommand.data;
    return data;
  }

  List<HeartsCommand> _logFromData(Map<String, String> data) {
    List<HeartsCommand> otherlog = new List<HeartsCommand>();
    otherlog.length = data.length;
    data.forEach((String k, String v) {
      otherlog[int.parse(k)] = new HeartsCommand(v);
    });
    return otherlog;
  }

  void handleSyncUpdate(Map<String, String> data) {
    this.update(_logFromData(data));
  }

  void addToLogCb(List<GameCommand> log, GameCommand newCommand) {
    logWriter.write(_toLogData(log, newCommand));
  }

  List<GameCommand> updateLogCb(
      List<GameCommand> current, List<GameCommand> other, int mismatchIndex) {
    // TODO(alexfandrianto): How do you handle conflicts with Hearts?
    assert(false);
    return current;
  }
}