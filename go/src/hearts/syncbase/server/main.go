// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// server handles advertising (to be fleshed out when discovery is added), and all local syncbase updates

package server

import (
	"math/rand"
	"encoding/json"
	"fmt"
	"hearts/img/uistate"
	"hearts/syncbase/util"
	"v.io/v23/context"
	"v.io/v23/discovery"
	"v.io/v23/security"
	"v.io/v23/security/access"
	wire "v.io/v23/services/syncbase/nosql"
	"v.io/v23/syncbase"
	ldiscovery "v.io/x/ref/lib/discovery"
	"v.io/x/ref/lib/discovery/plugins/mdns"
	"v.io/x/ref/lib/signals"
	_ "v.io/x/ref/runtime/factories/generic"
)

// Advertises a set of game log and game settings syncgroups
func Advertise(logAddress, settingsAddress string, ctx *context.T) {
	ctx, stop := context.WithCancel(ctx)
	mdns, err := mdns.New("")
	if err != nil {
		ctx.Fatalf("mDNS failed: %v", err)
	}
	discoveryService := ldiscovery.NewWithPlugins([]ldiscovery.Plugin{mdns})
	gameService := discovery.Service{
		InstanceName:  "A sample game service",
		InterfaceName: util.CroupierInterface,
		Addrs: []string{settingsAddress, logAddress},
	}
	fmt.Println(gameService)
	if _, err := discoveryService.Advertise(ctx, gameService, nil); err != nil {
		ctx.Fatalf("Advertise failed: %v", err)
	}
	<-signals.ShutdownOnSignals(ctx)
	stop()
}

// Puts key and value into the syncbase table
func AddKeyValue(service syncbase.Service, ctx *context.T, key, value string) bool {
	app := service.App(util.AppName)
	db := app.NoSQLDatabase(util.DbName, nil)
	table := db.Table(util.LogName)
	valueByte := []byte(value)
	err := table.Put(ctx, key, valueByte)
	if err != nil {
		fmt.Println("PUT ERROR: ", err)
		return false
	}
	return true
}

// Creates an app, db, game log table and game settings table in syncbase if they don't already exist
// Adds appropriate data to settings table
func CreateTables(u *uistate.UIState) {
	app := u.Service.App(util.AppName)
	if isThere, err := app.Exists(u.Ctx); err != nil {
		fmt.Println("APP EXISTS ERROR: ", err)
	} else if !isThere {
		if app.Create(u.Ctx, nil) != nil {
			fmt.Println("APP ERROR: ", err)
		}
	}
	db := app.NoSQLDatabase(util.DbName, nil)
	if isThere, err := db.Exists(u.Ctx); err != nil {
		fmt.Println("DB EXISTS ERROR: ", err)
	} else if !isThere {
		if db.Create(u.Ctx, nil) != nil {
			fmt.Println("DB ERROR: ", err)
		}
	}
	logTable := db.Table(util.LogName)
	if isThere, err := logTable.Exists(u.Ctx); err != nil {
		fmt.Println("TABLE EXISTS ERROR: ", err)
	} else if !isThere {
		if logTable.Create(u.Ctx, nil) != nil {
			fmt.Println("TABLE ERROR: ", err)
		}
	}
	settingsTable := db.Table(util.SettingsName)
	if isThere, err := settingsTable.Exists(u.Ctx); err != nil {
		fmt.Println("TABLE EXISTS ERROR: ", err)
	} else if !isThere {
		if settingsTable.Create(u.Ctx, nil) != nil {
			fmt.Println("TABLE ERROR: ", err)
		}
	}
	settingsMap := make(map[string]interface{})
	settingsMap["userID"] = util.UserID
	settingsMap["avatar"] = util.UserAvatar
	settingsMap["name"] = util.UserName
	settingsMap["color"] = util.UserColor
	value, err := json.Marshal(settingsMap)
	if err != nil {
		fmt.Println("WE HAVE A HUGE PROBLEM:", err)
	}
	settingsTable.Put(u.Ctx, fmt.Sprintf("users/%d/settings", util.UserID), value)
}

// Creates a new syncgroup
func CreateSyncgroup(ch chan string, u *uistate.UIState) {
	fmt.Println("Creating Syncgroup")
	gameID := rand.Intn(1000000)
	gameMap := make(map[string]interface{})
	gameMap["type"] = "Hearts"
	gameMap["playerNumber"] = 0
	gameMap["gameID"] = gameID
	gameMap["ownerID"] = util.UserID
	value, err := json.Marshal(gameMap)
	if err != nil {
		fmt.Println("WE HAVE A HUGE PROBLEM:", err)
	}
	sgName := util.MountPoint + "/croupier/" + util.SBName + "/%%sync/gaming-" + string(value)
	allAccess := access.AccessList{In: []security.BlessingPattern{"..."}}
	permissions := access.Permissions{
		"Admin":   allAccess,
		"Write":   allAccess,
		"Read":    allAccess,
		"Resolve": allAccess,
		"Debug":   allAccess,
	}
	pref := wire.TableRow{util.LogName, ""}
	prefs := []wire.TableRow{pref}
	tables := []string{util.MountPoint + "/croupier"}
	spec := wire.SyncgroupSpec{
		Description: "croupier syncgroup",
		Perms:       permissions,
		Prefixes:    prefs,
		MountTables: tables,
		IsPrivate:   false,
	}
	myInfoCreator := wire.SyncgroupMemberInfo{8, true}
	app := u.Service.App(util.AppName)
	db := app.NoSQLDatabase(util.DbName, nil)
	sg := db.Syncgroup(sgName)
	err = sg.Create(u.Ctx, spec, myInfoCreator)
	if err != nil {
		fmt.Println("SYNCGROUP CREATE ERROR: ", err)
		ch <- ""
	} else {
		fmt.Println("Syncgroup created")
		u.GameID = gameID
		ch <- sgName
	}
}

// Creates a new syncgroup
func CreateSettingsSyncgroup(ch chan string, u *uistate.UIState) {
	fmt.Println("Creating Settings Syncgroup")
	sgName := fmt.Sprintf("%s/croupier/%s/%%%%sync/discovery-%d", util.MountPoint, util.SBName, util.UserID)
	allAccess := access.AccessList{In: []security.BlessingPattern{"..."}}
	permissions := access.Permissions{
		"Admin":   allAccess,
		"Write":   allAccess,
		"Read":    allAccess,
		"Resolve": allAccess,
		"Debug":   allAccess,
	}
	pref := wire.TableRow{util.SettingsName, ""}
	prefs := []wire.TableRow{pref}
	tables := []string{util.MountPoint + "/croupier"}
	spec := wire.SyncgroupSpec{
		Description: "croupier syncgroup",
		Perms:       permissions,
		Prefixes:    prefs,
		MountTables: tables,
		IsPrivate:   false,
	}
	myInfoCreator := wire.SyncgroupMemberInfo{8, true}
	app := u.Service.App(util.AppName)
	db := app.NoSQLDatabase(util.DbName, nil)
	sg := db.Syncgroup(sgName)
	err := sg.Create(u.Ctx, spec, myInfoCreator)
	if err != nil {
		fmt.Println("SYNCGROUP CREATE ERROR: ", err)
		ch <- ""
	} else {
		fmt.Println("Syncgroup created")
		ch <- sgName
	}
}
