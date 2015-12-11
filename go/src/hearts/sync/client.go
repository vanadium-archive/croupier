// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// client handles pulling data from syncbase. To be fleshed out when discovery is added.

package sync

import (
	"fmt"

	"hearts/img/uistate"
	"hearts/img/view"

	"v.io/v23/context"
	"v.io/v23/discovery"
	wire "v.io/v23/services/syncbase/nosql"
	"v.io/v23/syncbase/nosql"
	ldiscovery "v.io/x/ref/lib/discovery"
	"v.io/x/ref/lib/discovery/plugins/mdns"
	"v.io/x/ref/lib/signals"
	_ "v.io/x/ref/runtime/factories/generic"
)

// Searches for new syncgroups being advertised, sends found syncgroups to sgChan
func ScanForSG(ctx *context.T, quit chan bool, u *uistate.UIState) {
	mdns, err := mdns.New("")
	if err != nil {
		ctx.Fatalf("Plugin failed: %v", err)
	}
	ds := ldiscovery.NewWithPlugins([]ldiscovery.Plugin{mdns})
	fmt.Printf("Start scanning...\n")
	ch, err := ds.Scan(ctx, fmt.Sprintf("v.InterfaceName = \"%s\"", CroupierInterface))
	if err != nil {
		ctx.Fatalf("Scan failed: %v", err)
	}
	instances := make(map[string]string)
loop:
	for {
		select {
		case update := <-ch:
			GetSG(instances, update, u)
			view.LoadDiscoveryView(u)
		case <-signals.ShutdownOnSignals(ctx):
			break loop
		case <-quit:
			break loop
		}
	}
}

// Returns the addresses of any discovered syncgroups that contain croupier game information
func GetSG(instances map[string]string, update discovery.Update, u *uistate.UIState) {
	switch uType := update.(type) {
	case discovery.UpdateFound:
		found := uType.Value
		instances[string(found.Service.InstanceId)] = found.Service.InstanceName
		fmt.Printf("Discovered %q: Instance=%x, Interface=%q, Addrs=%v\n", found.Service.InstanceName, found.Service.InstanceId, found.Service.InterfaceName, found.Service.Addrs)
		key := found.Service.InstanceId
		ds := uistate.MakeDiscStruct(found.Service.Attrs["settings_sgname"], found.Service.Addrs[0], found.Service.Attrs["game_start_data"])
		if ds != nil {
			settingsAddr := ds.SettingsAddr
			JoinSettingsSyncgroup(settingsAddr, u)
			u.DiscGroups[key] = ds
		}
	case discovery.UpdateLost:
		lost := uType.Value
		name, ok := instances[string(lost.InstanceId)]
		if !ok {
			name = "unknown"
		}
		delete(instances, string(lost.InstanceId))
		u.DiscGroups[lost.InstanceId] = nil
		fmt.Printf("Lost %q: Instance=%x\n", name, lost.InstanceId)
	}
}

// Returns a watchstream of the data in the table
func WatchData(tableName, prefix string, u *uistate.UIState) (nosql.WatchStream, error) {
	db := u.Service.App(AppName).NoSQLDatabase(DbName, nil)
	resumeMarker, err := db.GetResumeMarker(u.Ctx)
	if err != nil {
		fmt.Println("RESUMEMARKER ERR: ", err)
	}
	return db.Watch(u.Ctx, tableName, prefix, resumeMarker)
}

// Returns a scanstream of the data in the table
func ScanData(tableName, prefix string, u *uistate.UIState) nosql.ScanStream {
	app := u.Service.App(AppName)
	db := app.NoSQLDatabase(DbName, nil)
	table := db.Table(tableName)
	rowRange := nosql.Range(prefix, "")
	return table.Scan(u.Ctx, rowRange)
}

// Joins gamelog syncgroup
func JoinLogSyncgroup(logName string, u *uistate.UIState) bool {
	fmt.Println("Joining gamelog syncgroup")
	u.IsOwner = false
	app := u.Service.App(AppName)
	db := app.NoSQLDatabase(DbName, nil)
	logSg := db.Syncgroup(logName)
	myInfoJoiner := wire.SyncgroupMemberInfo{8, false}
	_, err := logSg.Join(u.Ctx, myInfoJoiner)
	if err != nil {
		fmt.Println("SYNCGROUP JOIN ERROR: ", err)
		return false
	} else {
		fmt.Println("Syncgroup joined")
		if u.LogSG != logName {
			resetGame(logName, false, u)
		}
		return true
	}
}

// Joins player settings syncgroup
func JoinSettingsSyncgroup(settingsName string, u *uistate.UIState) {
	fmt.Println("Joining user settings syncgroup")
	app := u.Service.App(AppName)
	db := app.NoSQLDatabase(DbName, nil)
	settingsSg := db.Syncgroup(settingsName)
	myInfoJoiner := wire.SyncgroupMemberInfo{8, false}
	_, err := settingsSg.Join(u.Ctx, myInfoJoiner)
	if err != nil {
		fmt.Println("SYNCGROUP JOIN ERROR: ", err)
	} else {
		fmt.Println("Syncgroup joined")
	}
}

func NumInSG(logName string, u *uistate.UIState) int {
	app := u.Service.App(AppName)
	db := app.NoSQLDatabase(DbName, nil)
	sg := db.Syncgroup(logName)
	members, err := sg.GetMembers(u.Ctx)
	if err != nil {
		fmt.Println(err)
	}
	return len(members)
}
