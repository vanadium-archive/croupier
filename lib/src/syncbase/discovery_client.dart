// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:v23discovery/discovery.dart' as discovery;
import 'package:flutter/services.dart' show shell;

class ProxyHandlePair<T> {
  final T proxy;
  int handle;

  ProxyHandlePair(this.proxy, this.handle);
}

/// Make this into the Dart Discovery client
/// https://github.com/vanadium/issues/issues/835
class DiscoveryClient {
  final Map<String, ProxyHandlePair<discovery.AdvertiserProxy>> advertisers =
      new Map<String, ProxyHandlePair<discovery.AdvertiserProxy>>();
  final Map<String, ProxyHandlePair<discovery.ScannerProxy>> scanners =
      new Map<String, ProxyHandlePair<discovery.ScannerProxy>>();

  static final String discoveryUrl = 'https://mojo2.v.io/discovery.mojo';

  DiscoveryClient() {}

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
  Future scan(String key, String query, discovery.ScanHandler handler) async {
    // Cancel the scan if one is already going for this key.
    if (scanners.containsKey(key)) {
      stopScan(key);
    }

    discovery.ScannerProxy s = new discovery.ScannerProxy.unbound();

    print('Starting up discovery scanner ${key}. Looking for ${query}');

    shell.connectToService(discoveryUrl, s);

    // Use a ScanHandlerStub (Mojo-encodable interface) to wrap the scan handler.
    discovery.ScanHandlerStub shs = new discovery.ScanHandlerStub.unbound();
    shs.impl = handler;

    print('Scanning begins!');
    return s.ptr
        .scan(query, shs)
        .then((discovery.ScannerScanResponseParams response) {
      print(
          "${key} scanning started. The cancel handle is ${response.handle}.");
      scanners[key] =
          new ProxyHandlePair<discovery.ScannerProxy>(s, response.handle);
    });
  }

  // This sends a stop signal to the scanner. Since it is non-blocking, the
  // scan handle may not stop instantaneously.
  void stopScan(String key) {
    if (scanners[key] != null) {
      print("Stopping scan for ${key}.");
      scanners[key].proxy.ptr.stop(scanners[key].handle);
      scanners[key].proxy.close(); // don't wait for this future.
      scanners.remove(key);
    }
  }

  // Advertises the given service information. Keeps track of the advertiser
  // handle via the key.
  Future advertise(String key, discovery.Service serviceInfo,
      {List<String> visibility}) async {
    // Cancel the advertisement if one is already going for this key.
    if (advertisers.containsKey(key)) {
      stopAdvertise(key);
    }

    discovery.AdvertiserProxy a = new discovery.AdvertiserProxy.unbound();

    print(
        'Starting up discovery advertiser ${key}. Broadcasting for ${serviceInfo.instanceName}');

    shell.connectToService(discoveryUrl, a);

    return a.ptr
        .advertise(serviceInfo, visibility ?? <String>[])
        .then((discovery.AdvertiserAdvertiseResponseParams response) {
      print(
          "${key} advertising started. The cancel handle is ${response.handle}.");
      advertisers[key] =
          new ProxyHandlePair<discovery.AdvertiserProxy>(a, response.handle);
    });
  }

  // This sends a stop signal to the advertiser. Since it is non-blocking, the
  // advertise handle may not stop instantaneously.
  void stopAdvertise(String key) {
    if (advertisers[key] != null) {
      print("Stopping advertise for ${key}.");
      advertisers[key].proxy.ptr.stop(advertisers[key].handle);
      advertisers[key].proxy.close(); // don't wait for this future.
      advertisers.remove(key);
    }
  }
}
