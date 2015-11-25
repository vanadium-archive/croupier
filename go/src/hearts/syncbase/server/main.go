// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// server handles advertising (to be fleshed out when discovery is added), and all local syncbase updates

package server

import (
	"encoding/json"
	"fmt"
	"hearts/img/uistate"
	"hearts/syncbase/util"
	"math/rand"
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
func Advertise(logAddress, settingsAddress string, quit chan bool, ctx *context.T) {
	ctx, stop := context.WithCancel(ctx)
	mdns, err := mdns.New("")
	if err != nil {
		ctx.Fatalf("mDNS failed: %v", err)
	}
	discoveryService := ldiscovery.NewWithPlugins([]ldiscovery.Plugin{mdns})
	gameService := discovery.Service{
		InstanceName:  "A sample game service",
		InterfaceName: util.CroupierInterface,
		Addrs:         []string{settingsAddress, logAddress},
	}
	fmt.Println(gameService)
	if _, err := discoveryService.Advertise(ctx, &gameService, nil); err != nil {
		ctx.Fatalf("Advertise failed: %v", err)
	}
	select {
	case <-signals.ShutdownOnSignals(ctx):
		stop()
	case <-quit:
		stop()
	}
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
	// Add user settings data to represent this player
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

// Creates a new set of gamelog and game settings syncgroups
func CreateSyncgroups(ch chan string, u *uistate.UIState) {
	fmt.Println("Creating Syncgroup")
	u.IsOwner = true
	u.CurPlayerIndex = 0
	// Generate random gameID information to advertise this game
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
	// Create gamelog syncgroup
	logSGName := util.MountPoint + "/croupier/" + util.SBName + "/%%sync/gaming-" + string(value)
	allAccess := access.AccessList{In: []security.BlessingPattern{"..."}}
	permissions := access.Permissions{
		"Admin":   allAccess,
		"Write":   allAccess,
		"Read":    allAccess,
		"Resolve": allAccess,
		"Debug":   allAccess,
	}
	logPref := wire.TableRow{util.LogName, ""}
	logPrefs := []wire.TableRow{logPref}
	tables := []string{util.MountPoint + "/croupier"}
	logSpec := wire.SyncgroupSpec{
		Description: "croupier syncgroup",
		Perms:       permissions,
		Prefixes:    logPrefs,
		MountTables: tables,
		IsPrivate:   false,
	}
	myInfoCreator := wire.SyncgroupMemberInfo{8, true}
	app := u.Service.App(util.AppName)
	db := app.NoSQLDatabase(util.DbName, nil)
	logSG := db.Syncgroup(logSGName)
	err = logSG.Create(u.Ctx, logSpec, myInfoCreator)
	if err != nil {
		fmt.Println("SYNCGROUP CREATE ERROR: ", err)
		ch <- ""
	} else {
		fmt.Println("Syncgroup created")
		u.GameID = gameID
		ch <- logSGName
	}
	// Create game settings syncgroup
	settingsSGName := fmt.Sprintf("%s/croupier/%s/%%%%sync/discovery-%d", util.MountPoint, util.SBName, util.UserID)
	settingsPref := wire.TableRow{util.SettingsName, ""}
	settingsPrefs := []wire.TableRow{settingsPref}
	settingsSpec := wire.SyncgroupSpec{
		Description: "croupier syncgroup",
		Perms:       permissions,
		Prefixes:    settingsPrefs,
		MountTables: tables,
		IsPrivate:   false,
	}
	settingsSG := db.Syncgroup(settingsSGName)
	err = settingsSG.Create(u.Ctx, settingsSpec, myInfoCreator)
	if err != nil {
		fmt.Println("SYNCGROUP CREATE ERROR: ", err)
		ch <- ""
	} else {
		fmt.Println("Syncgroup created")
		ch <- settingsSGName
	}
}
