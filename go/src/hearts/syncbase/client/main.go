// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// client handles pulling data from syncbase. To be fleshed out when discovery is added.

package client

import (
	"fmt"
	"strings"
	"encoding/json"
	"hearts/img/uistate"
	"hearts/syncbase/util"
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
func ScanForSG(sgChan chan []string, ctx *context.T) {
	mdns, err := mdns.New("")
	if err != nil {
		ctx.Fatalf("Plugin failed: %v", err)
	}
	ds := ldiscovery.NewWithPlugins([]ldiscovery.Plugin{mdns})
	fmt.Printf("Start scanning...\n")
	ch, err := ds.Scan(ctx, "")
	if err != nil {
		ctx.Fatalf("Scan failed: %v", err)
	}
	instances := make(map[string]string)
loop:
	for {
		select {
		case update := <-ch:
			sgNames := GetSG(instances, update)
			if sgNames != nil {
				sgChan <- sgNames
			}
		case <-signals.ShutdownOnSignals(ctx):
			break loop
		}
	}
}

// Returns the addresses of any discovered syncgroups that contain croupier game information
func GetSG(instances map[string]string, update discovery.Update) []string {
	switch u := update.(type) {
	case discovery.UpdateFound:
		found := u.Value
		instances[string(found.Service.InstanceUuid)] = found.Service.InstanceName
		fmt.Printf("Discovered %q: Instance=%x, Interface=%q, Addrs=%v\n", found.Service.InstanceName, found.Service.InstanceUuid, found.Service.InterfaceName, found.Service.Addrs)
		if found.Service.InterfaceName == util.CroupierInterface {
			return found.Service.Addrs
		}
	case discovery.UpdateLost:
		lost := u.Value
		name, ok := instances[string(lost.InstanceUuid)]
		if !ok {
			name = "unknown"
		}
		delete(instances, string(lost.InstanceUuid))
		fmt.Printf("Lost %q: Instance=%x\n", name, lost.InstanceUuid)
	}
	return nil
}

// Returns a watchstream of the gamelog data
func WatchData(u *uistate.UIState) (nosql.WatchStream, error) {
	db := u.Service.App(util.AppName).NoSQLDatabase(util.DbName, nil)
	prefix := ""
	resumeMarker, err := db.GetResumeMarker(u.Ctx)
	if err != nil {
		fmt.Println("RESUMEMARKER ERR: ", err)
	}
	return db.Watch(u.Ctx, util.LogName, prefix, resumeMarker)
}

// Joins a set of gamelog and game settings syncgroups
func JoinSyncgroups(ch chan bool, logName, settingsName string, u *uistate.UIState) {
	fmt.Println("Joining syncgroup")
	app := u.Service.App(util.AppName)
	db := app.NoSQLDatabase(util.DbName, nil)
	logSg := db.Syncgroup(logName)
	settingsSg := db.Syncgroup(settingsName)
	myInfoJoiner := wire.SyncgroupMemberInfo{8, false}
	_, err := logSg.Join(u.Ctx, myInfoJoiner)
	_, err2 := settingsSg.Join(u.Ctx, myInfoJoiner)
	if err != nil || err2 != nil {
		fmt.Println("SYNCGROUP JOIN ERROR: ", err)
		ch <- false
	} else {
		fmt.Println("Syncgroup joined")
		tmp := strings.Split(logName, "-")
		lasttmp := tmp[len(tmp)-1]
		tmpMap := make(map[string]interface{})
		err = json.Unmarshal([]byte(lasttmp), &tmpMap)
		if err != nil {
			fmt.Println("ERROR UNMARSHALLING")
		}
		u.GameID = int(tmpMap["gameID"].(float64))
		ch <- true
	}
}
