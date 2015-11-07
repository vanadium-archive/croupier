// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert' show JSON;

enum SimulLevel { TURN_BASED, INDEPENDENT, DEPENDENT }

typedef void updateCallbackT(String key, String value);

class LogWriter {
  final updateCallbackT updateCallback;
  final List<int> users;
  String logPrefix; // This can be completely ignored.

  bool inProposalMode = false;
  int associatedUser;

  int _fakeTime = 0;
  int _getNextTime() {
    _fakeTime++;
    return _fakeTime;
  }

  LogWriter(this.updateCallback, this.users);

  Map<String, String> _data = new Map<String, String>();

  void write(SimulLevel s, String value) {
    assert(!inProposalMode);

    String key = _logKey(associatedUser);
    if (s == SimulLevel.DEPENDENT) {
      // We have to do extra work with "proposals".
      inProposalMode = true;
      String proposalData = JSON.encode({"key": key, "value": value});
      _data[_proposalKey(associatedUser)] = proposalData;

      // FAKE: Do some bonus work. Where "everyone else" accepts the proposal.
      for (int i = 0; i < users.length; i++) {
        if (users[i] != associatedUser) {
          _data[_proposalKey(users[i])] = proposalData;
          _receiveProposal(proposalData);
        }
      }

      return;
    }

    _writeData(key, value);
  }

  // Helper that returns the log key using a mixture of timestamp + user.
  String _logKey(int user) {
    int ms = _getNextTime();
    String key = "${ms}-${user}";
    return key;
  }

  // Helper that writes data to the "store" and calls the update callback.
  void _writeData(String key, String value) {
    _data[key] = value;
    updateCallback(key, value);
  }

  // Helper that handles a proposal update for a user.
  void _receiveProposal(String proposalData) {
    assert(inProposalMode);

    // First check if something is already in data.
    var pKey = _proposalKey(associatedUser);
    String pData = _data[pKey];
    if (pData != null) {
      // Potentially change your proposal, if that person has higher priority.
      Map<String, String> pp = JSON.decode(pData);
      Map<String, String> op = JSON.decode(proposalData);
      String keyP = pp["key"];
      String keyO = op["key"];
      if (keyO.compareTo(keyP) < 0) {
        // Then switch proposals.
        _data[pKey] = proposalData;
      }
    } else {
      // Otherwise, you have no proposal, so take theirs.
      _data[pKey] = proposalData;
    }

    // Given these changes, check if you can commit the full batch.
    if (_checkIsProposalDone()) {
      Map<String, String> pp = JSON.decode(pData);
      String key = pp["key"];
      String value = pp["value"];

      // WOULD DO A BATCH!
      _writeData(key, value);
      for (int i = 0; i < users.length; i++) {
        _data.remove(_proposalKey(users[i]));
      }

      inProposalMode = false;
    }
  }

  // More helpers for proposals.
  String _proposalKey(int user) {
    return "proposal${user}";
  }

  bool _checkIsProposalDone() {
    assert(inProposalMode);
    String theProposal;
    for (int i = 0; i < users.length; i++) {
      String altProposal = _data[_proposalKey(users[i])];
      if (altProposal == null) {
        return false;
      } else if (theProposal != null && theProposal != altProposal) {
        return false;
      }
      theProposal = altProposal;
    }
    return true;
  }

  void close() {}
}
