// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:sky/widgets.dart';

List<Widget> flexChildren(List<Widget> children) {
  List<Widget> flexWidgets = new List<Widget>();
  children.forEach(
      (child) => flexWidgets.add(new Flexible(child: child)));
  return flexWidgets;
}
