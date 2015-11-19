// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Since this file includes Sky/Mojo, it will need to be mocked out for unit tests.
/// Unfortunately, imports can't be replaced, so the best thing to do is to swap out the whole file.
///
/// The goal of the LogWriter is to allow clients to write to the log in a
/// consistent, conflict-free manner. Depending on the Simultaneity level, the
/// values written will be done immediately or enter a proposal phase.
///
/// In proposal mode, all other clients must agree on the proposal via a simple
/// consensus strategy. Once all clients agree, all clients follow through with
/// the proposal (writing into their log).
///
/// Watch is used to inform clients of proposal agreements and changes made
/// by this and other clients. When a value is confirmed via watch to be written
/// to the log, the caller is informed via callback.

import 'croupier_client.dart' show CroupierClient;
import 'util.dart' as util;

import 'dart:async';
import 'dart:convert' show UTF8, JSON;

import 'package:syncbase/syncbase_client.dart'
    show SyncbaseNoSqlDatabase, SyncbaseTable, WatchChange, WatchChangeTypes;

enum SimulLevel { TURN_BASED, INDEPENDENT, DEPENDENT }

class LogWriter {
  // This callback is called on each watch update, passing the key and value.
  final util.updateCallbackT updateCallback;

  // The users that we should look for when coming to a proposal consensus.
  final List<int> users;

  // The CroupierClient manages the creation of tables/dbs/syncgroups.
  final CroupierClient _cc;

  // Affects read/write/watch locations of the log writer.
  String logPrefix = ''; // This is usually set to <game_id>/log

  // An internal boolean that should be set to true when watching and reset to
  // false once watch should be turned off.
  bool _watching = false;

  // When a proposal is made (or received), this flag is set to true.
  // Once a consensus has been reached, this is set to false again.
  bool inProposalMode = false;
  Map<String, String> proposalsKnown; // Only updated via watch.
  Set<String> _acceptedProposals =
      new Set<String>(); // Add accepted proposals so that we can ignore them.

  // The associated user helps in the production of unique keys.
  int _associatedUser;
  int get associatedUser => _associatedUser;
  void set associatedUser(int other) {
    // Can be changed while the log is used; this should not be done during a proposal.
    assert(!inProposalMode);
    _associatedUser = other;
  }

  // This holds a reference to the syncbase table we're writing to.
  SyncbaseTable tb;
  static final String tbName = util.tableNameGames;

  // The LogWriter takes a callback for watch updates, the list of users, and
  // the logPrefix to write at on table.
  LogWriter(this.updateCallback, this.users) : _cc = new CroupierClient() {
    _prepareLog();
  }

  Future _prepareLog() async {
    if (tb != null) {
      return; // Then we're already prepared.
    }

    SyncbaseNoSqlDatabase db = await _cc.createDatabase();
    tb = await _cc.createTable(db, tbName);

    // Start to watch the stream.
    Stream<WatchChange> watchStream =
        db.watch(tbName, this.logPrefix, UTF8.encode("now"));
    _startWatch(watchStream); // Don't wait for this future.
  }

  Future _startWatch(Stream<WatchChange> watchStream) async {
    util.log('watching for changes...');
    _watching = true;

    // This stream never really ends, so it will watch forever.
    // https://github.com/vanadium/issues/issues/833
    // To break out of the watch handler, we can use the _watching flag.
    // However, the for loop will only break on the watch update after _watching
    // is set to false.
    await for (WatchChange wc in watchStream) {
      if (!this._watching) {
        break;
      }

      assert(wc.tableName == tbName);
      util.log('Watch Key: ${wc.rowKey}');
      util.log('Watch Value ${UTF8.decode(wc.valueBytes)}');
      String key = wc.rowKey.replaceFirst("${this.logPrefix}/", "");
      if (key == wc.rowKey) {
        print("Lacks prefix '${this.logPrefix}/', skipping...");
        continue;
      }
      String value;
      switch (wc.changeType) {
        case WatchChangeTypes.put:
          value = UTF8.decode(wc.valueBytes);
          break;
        case WatchChangeTypes.delete:
          value = null;
          break;
        default:
          assert(false);
      }

      if (_isProposalKey(key)) {
        if (value != null && !_acceptedProposals.contains(key)) {
          await _receiveProposal(key, value);
        }
      } else {
        print("Update callback: ${key}, ${value}");
        this.updateCallback(key, value);
      }
    }
  }

  void close() {
    this._watching = false;
  }

  Future write(SimulLevel s, String value) async {
    util.log('LogWriter.write start');
    await _prepareLog();

    assert(!inProposalMode);
    String key = _logKey(associatedUser);
    if (s == SimulLevel.DEPENDENT) {
      inProposalMode = true;
      proposalsKnown = new Map<String, String>();

      String proposalData = JSON.encode({"key": key, "value": value});
      String propKey = _proposalKey(associatedUser);
      await _writeData(propKey, proposalData);
      proposalsKnown[propKey] = proposalData;

      // TODO(alexfandrianto): Remove when we have 4 players going at once.
      // For quick development purposes, we may wish to keep this block.
      // FAKE: Do some bonus work. Where "everyone else" accepts the proposal.
      // Normally, one would rely on watch and the syncgroup peers to do this.
      /*for (int i = 0; i < users.length; i++) {
        if (users[i] != associatedUser) {
          // DO NOT AWAIT HERE. It must be done "asynchronously".
          _writeData(_proposalKey(users[i]), proposalData);
        }
      }*/

      return;
    }
    await _writeData(key, value);
  }

  // Helper that writes data to the "store" and calls the update callback.
  Future _writeData(String key, String value) async {
    var row = tb.row("${this.logPrefix}/${key}");
    await row.put(UTF8.encode(value));
  }

  /*
  // _readData could be helpful eventually, but it's not needed yet.
  Future<String> _readData(String key) async {
    var row = tb.row("${this.logPrefix}/${key}");
    if (!(await row.exists())) {
      print("${key} did not exist");
      return null;
    }
    var getBytes = await row.get();

    return UTF8.decode(getBytes);
  }
  */

  Future _deleteData(String key) async {
    var row = tb.row(key);
    await row.delete();
  }

  // Helper that returns the log key using a mixture of timestamp + user.
  String _logKey(int user) {
    int ms = new DateTime.now().millisecondsSinceEpoch;
    String key = "${ms}-${user}";
    return key;
  }

  bool _ownsProposal(String key, String proposalData) {
    return _proposalSayer(key) == _proposalOwner(proposalData);
  }

  int _proposalSayer(String key) {
    return int.parse(key.split("/").last);
  }

  int _proposalOwner(String proposalData) {
    Map<String, String> pp = JSON.decode(proposalData);
    String keyP = pp["key"];
    return int.parse(keyP.split("-").last);
  }

  // Helper that handles a proposal update for the associatedUser.
  Future _receiveProposal(String key, String proposalData) async {
    // If this is a separate device, it may not be in proposal mode yet.
    // Set to be in proposal mode now.
    if (!inProposalMode) {
      inProposalMode = true;
      proposalsKnown = new Map<String, String>();
    }

    // Let us update our proposal map.
    proposalsKnown[key] = proposalData;

    // Let's obtain our own proposal data.
    var pKey = _proposalKey(associatedUser);
    var pData = proposalsKnown[pKey];

    // We only have to update our proposal if the updating person is the owner.
    // This avoids repeated and potentially race-y watch updates.
    // By sharing the bare minimum, sync/watch should avoid races.
    if (_ownsProposal(key, proposalData)) {
      if (pData != null) {
        // Potentially change your proposal, if that person has higher priority.
        Map<String, String> pp = JSON.decode(pData);
        Map<String, String> op = JSON.decode(proposalData);
        String keyP = pp["key"];
        String keyO = op["key"];
        if (keyO.compareTo(keyP) < 0) {
          // Then switch proposals.
          await _writeData(pKey, proposalData);
        }
      } else {
        // Otherwise, you have no proposal, so take theirs.
        await _writeData(pKey, proposalData);
      }
    }

    // Given these changes, check if you can commit the full batch.
    if (await _checkIsProposalDone()) {
      Map<String, String> pp = JSON.decode(pData);
      String key = pp["key"];
      String value = pp["value"];

      _acceptedProposals.add(key);
      print("All proposals accepted. Proceeding with ${key} ${value}");
      // WOULD DO A BATCH!
      for (int i = 0; i < users.length; i++) {
        await _deleteData(_proposalKey(users[i]));
      }
      // TODO(alexfandrianto): It seems that this will trigger multiple watch
      // updates even though the data written is the same value to the same key.
      // I think this is intended, so to work around it, the layer above will
      // be sure to ignore updates to repeated keys.
      await _writeData(key, value);

      proposalsKnown = null;
      inProposalMode = false;
    }
  }

  // More helpers for proposals.
  bool _isProposalKey(String key) {
    return key.indexOf("proposal") == 0;
  }

  String _proposalKey(int user) {
    return "proposal/${user}";
  }

  Future<bool> _checkIsProposalDone() async {
    assert(inProposalMode);
    String theProposal;
    for (int i = 0; i < users.length; i++) {
      String altProposal = proposalsKnown[_proposalKey(users[i])];
      if (altProposal == null) {
        return false;
      } else if (theProposal != null && theProposal != altProposal) {
        return false;
      }
      theProposal = altProposal;
    }
    return true;
  }
}
