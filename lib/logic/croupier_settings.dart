// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:convert' show JSON;

/// CroupierSettings is a simple struct that contains player-specific settings.
/// Players can modify a subset of their settings via the UI.
class CroupierSettings {
  // Values the user does not set.
  int userID;
  int lastGameID; // Note: Some versions of Croupier do not support lastGameID.
  bool get hasLastGame => lastGameID != null;

  // Values the user can customize
  String avatar;
  String name;
  int color;

  static String makeAvatarUrl(String key) => 'images/avatars/${key}';

  CroupierSettings.random() {
    _randomInitialization();
  }

  CroupierSettings.placeholder() {
    avatar = "Heart.png";
    name = "Loading...";
    color = 0xcfcccccc;
  }

  CroupierSettings.fromJSONString(String json) {
    var data = JSON.decode(json);
    userID = data["userID"];
    lastGameID = data["lastGameID"];
    avatar = data["avatar"];
    name = data["name"];
    color = data["color"];
  }

  String getStringValue(String key) {
    switch (key) {
      case "name":
        return name;
      case "avatar":
        return avatar;
      case "color":
        return "${color}";
      default:
        return null;
    }
  }

  void setStringValue(String key, String data) {
    switch (key) {
      case "name":
        print("Setting name to ${data}");
        name = data;
        break;
      case "avatar":
        print("Setting avatar to ${data}");
        avatar = data;
        break;
      case "color":
        // https://github.com/domokit/mojo/issues/192
        // Just calling int.parse will crash SIGSEGV the Dart VM on Android.
        // Note: if the number is too big. If you do a smaller number, it's fine.
        int newColor =
            0xcf000000; // Remove once Android + Dart can handle larger numbers.
        try {
          newColor += int.parse(data);
        } catch (e) {
          print(e);
        }
        print("Setting color to 0x${newColor}.");
        color = newColor;
        break;
      default:
        return null;
    }
  }

  String toJSONString() {
    return JSON.encode({
      "userID": userID,
      "lastGameID": lastGameID,
      "avatar": avatar,
      "name": name,
      "color": color
    });
  }

  void _randomInitialization() {
    userID = RandomSettings.userID;
    avatar = RandomSettings.avatar;
    name = RandomSettings.name;
    color = RandomSettings.color;
  }
}

class RandomSettings {
  static final List avatars = [
    'Club.png',
    'Diamond.png',
    'Heart.png',
    'Spade.png',
    'cat.png',
    'android.png',
    'man.png',
    'woman.png',
  ];
  static final List names = [
    'Anne',
    'Mary',
    'Jack',
    'Morgan',
    'Roger',
    'Bill',
    'Ragnar',
    'Ed',
    'John',
    'Jane'
  ];
  static final List appellations = [
    'Jackal',
    'King',
    'Red',
    'Stalwart',
    'Axe',
    'Young',
    'Brave',
    'Eager',
    'Wily',
    'Zesty'
  ];

  // Return a random user id.
  static int get userID {
    return new math.Random().nextInt(0xffffff);
  }

  // Return a random image name.
  static String get avatar {
    return avatars[new math.Random().nextInt(avatars.length)];
  }

  // Return a random pirate name
  static String get name {
    var rng = new math.Random();
    int nameIndex = rng.nextInt(names.length);
    int appIndex = rng.nextInt(appellations.length);

    return "${names[nameIndex]} ${appellations[appIndex]}";
  }

  // Return something between 0x00000000 and 0xffffffff
  static int get color {
    return new math.Random().nextInt(0xffffffff);
  }
}
