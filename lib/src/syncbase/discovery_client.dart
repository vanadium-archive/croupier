// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:v23discovery/discovery.dart' as discovery;
import 'package:flutter/services.dart' show shell;

/// Make this into the Dart Discovery client
/// https://github.com/vanadium/issues/issues/835
class DiscoveryClient {
  final Map<String, discovery.Advertiser> _advertisers = new Map();
  final Map<String, discovery.Scanner> _scanners = new Map();

  static final String _discoveryUrl = 'https://mojo2.v.io/discovery.mojo';
  final discovery.Client _discoveryClient =
      new discovery.Client(shell.connectToService, _discoveryUrl);

  static discovery.Service serviceMaker(
      {String instanceId,
      String instanceName,
      String interfaceName,
      Map<String, String> attrs,
      List<String> addrs}) {
    // Discovery requires that some of these values must be set.
    assert(interfaceName != null && interfaceName != '');
    assert(addrs != null && addrs.length > 0);
    return new discovery.Service()
      ..instanceId = instanceId
      ..instanceName = instanceName
      ..interfaceName = interfaceName
      ..attrs = attrs
      ..addrs = addrs;
  }

  // Scans for this query and handles found/lost objects with the handler.
  // Keeps track of this scanner via the key.
  Future scan(
      String key, String query, Function onFound, Function onLost) async {
    // Return the existing scan if one is already going.
    if (_scanners.containsKey(key)) {
      return _scanners[key];
    }

    discovery.Scanner scanner = await _discoveryClient.scan(query);
    _scanners[key] = scanner;

    scanner.onUpdate.listen((discovery.ScanUpdate update) {
      if (update.updateType == discovery.UpdateType.found) {
        onFound(update.service);
      } else {
        onLost(update.service.instanceId);
      }
    });

    print('Scanning begins!');
    return _scanners[key];
  }

  // This sends a stop signal to the scanner.
  Future stopScan(String key) async {
    if (!_scanners.containsKey(key)) {
      return;
    }
    await _scanners[key].stop();
    _scanners.remove(key);
  }

  // Advertises the given service information. Keeps track of the advertiser
  // handle via the key.
  Future advertise(String key, discovery.Service service,
      {List<String> visibility}) async {
    // Return the existing advertisement if one is already going.
    if (_advertisers.containsKey(key)) {
      return _advertisers[key];
    }
    _advertisers[key] =
        await _discoveryClient.advertise(service, visibility: visibility);

    return _advertisers[key];
  }

  // This sends a stop signal to the advertiser.
  Future stopAdvertise(String key) async {
    if (!_advertisers.containsKey(key)) {
      return;
    }
    await _advertisers[key].stop();
    _advertisers.remove(key);
  }
}
