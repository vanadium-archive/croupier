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
  final Map<String,
          Future<ProxyHandlePair<discovery.AdvertiserProxy>>> _advertisers =
      new Map<String, Future<ProxyHandlePair<discovery.AdvertiserProxy>>>();
  final Map<String, Future<ProxyHandlePair<discovery.ScannerProxy>>> _scanners =
      new Map<String, Future<ProxyHandlePair<discovery.ScannerProxy>>>();
  final Map<String, Future> _stoppingAdvertisers = new Map<String, Future>();
  final Map<String, Future> _stoppingScanners = new Map<String, Future>();

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
    // Return the existing scan if one is already going.
    if (_scanners.containsKey(key)) {
      return _scanners[key];
    }

    Future _scanHelper() async {
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

        return new ProxyHandlePair<discovery.ScannerProxy>(s, response.handle);
      });
    }

    // Otherwise, set _scanners[key] and do the preparation inside the future
    // so that stopScan can stop it if the two are called back to back.
    _scanners[key] = _scanHelper();

    return _scanners[key];
  }

  // This sends a stop signal to the scanner. Handles repeated stop calls on
  // the same key by returning the same Future.
  Future stopScan(String key) {
    if (!_scanners.containsKey(key)) {
      return new Future.value();
    }
    if (_stoppingScanners.containsKey(key)) {
      return _stoppingScanners[key];
    }

    _stoppingScanners[key] = _stopScanHelper(key);

    return _stoppingScanners[key].then((_) {
      // Success! Let's clean up both _scanners and _stoppingScanners.
      _scanners.remove(key);
      _stoppingScanners.remove(key);
    }).catchError((e) {
      // Failure. We can only clean up _stoppingScanners.
      _stoppingScanners.remove(key);
      throw e;
    });
  }

  Future _stopScanHelper(String key) async {
    ProxyHandlePair<discovery.ScannerProxy> sp = await _scanners[key];
    await sp.proxy.ptr.stop(sp.handle);
    await sp.proxy.close();
    print("Scan was stopped for ${key}!");
  }

  // Advertises the given service information. Keeps track of the advertiser
  // handle via the key.
  Future advertise(String key, discovery.Service serviceInfo,
      {List<String> visibility}) async {
    // Return the existing advertisement if one is already going.
    if (_advertisers.containsKey(key)) {
      return _advertisers[key];
    }

    Future _advertiseHelper() async {
      discovery.AdvertiserProxy a = new discovery.AdvertiserProxy.unbound();

      print(
          'Starting up discovery advertiser ${key}. Broadcasting for ${serviceInfo.instanceName}');

      shell.connectToService(discoveryUrl, a);

      return a.ptr
          .advertise(serviceInfo, visibility ?? <String>[])
          .then((discovery.AdvertiserAdvertiseResponseParams response) {
        print(
            "${key} advertising started. The cancel handle is ${response.handle}.");

        return new ProxyHandlePair<discovery.AdvertiserProxy>(
            a, response.handle);
      });
    }

    // Otherwise, set _advertisers[key] and do the preparation inside the future
    // so that stopAdvertise can stop it if the two are called back to back.
    _advertisers[key] = _advertiseHelper();

    return _advertisers[key];
  }

  // This sends a stop signal to the advertiser. Handles repeated stop calls on
  // the same key by returning the same Future.
  Future stopAdvertise(String key) {
    if (!_advertisers.containsKey(key)) {
      return new Future.value();
    }
    if (_stoppingAdvertisers.containsKey(key)) {
      return _stoppingAdvertisers[key];
    }

    _stoppingAdvertisers[key] = _stopAdvertiseHelper(key);

    return _stoppingAdvertisers[key].then((_) {
      // Success! Let's clean up both _advertisers and _stoppingAdvertisers.
      _advertisers.remove(key);
      _stoppingAdvertisers.remove(key);
    }).catchError((e) {
      // Failure. We can only clean up _stoppingAdvertisers.
      _stoppingAdvertisers.remove(key);
      throw e;
    });
  }

  Future _stopAdvertiseHelper(String key) async {
    ProxyHandlePair<discovery.AdvertiserProxy> ap = await _advertisers[key];
    await ap.proxy.ptr.stop(ap.handle);
    await ap.proxy.close();
    print("Advertise was stopped for ${key}!");
  }
}
