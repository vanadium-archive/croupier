// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// util.go stores constants relevant to the syncbase hierarchy

package util

const (
	// switch back to my mountpoint with the following code:
	MountPoint = "users/emshack@google.com"
	//MountPoint        = "/192.168.86.254:8101"
	UserID            = 1112
	UserColor         = 16777215
	UserAvatar        = "woman.png"
	UserName          = "Bob"
	SBName            = "syncbase"
	AppName           = "app"
	DbName            = "db"
	LogName           = "games"
	SettingsName      = "table_settings"
	CroupierInterface = "CroupierSettingsAndGame"
	// Swap the following two lines when running app on a computer vs. mobile device:
	// AddrFile = "src/dataParser/addr"
	AddrFile = "/sdcard/addr.txt"
)
