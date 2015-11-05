// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// server handles advertising (to be fleshed out when discovery is added), and all local syncbase updates

package server

import (
	"fmt"

	"v.io/v23/context"
	"v.io/v23/security"
	"v.io/v23/security/access"
	wire "v.io/v23/services/syncbase/nosql"
	"v.io/v23/syncbase"
	_ "v.io/x/ref/runtime/factories/generic"

	"hearts/img/uistate"
)

var (
	appName   = "x"
	dbName    = "y"
	tableName = "z"
)

// Will be fleshed out with addition of discovery
func Advertise(ctx *context.T) func() {
	ctx, stop := context.WithCancel(ctx)
	return stop
}

// Puts key and value into the syncbase table
func AddKeyValue(service syncbase.Service, ctx *context.T, key, value string) bool {
	app := service.App(appName)
	db := app.NoSQLDatabase(dbName, nil)
	table := db.Table(tableName)
	err := table.Put(ctx, key, value)
	if err != nil {
		fmt.Println("PUT ERROR: ", err)
		return false
	}
	return true
}

// Creates an app, db and table in syncbase if they don't already exist
func CreateTable(u *uistate.UIState) {
	app := u.Service.App(appName)
	if isThere, err := app.Exists(u.Ctx); err != nil {
		fmt.Println("APP EXISTS ERROR: ", err)
	} else if !isThere {
		if app.Create(u.Ctx, nil) != nil {
			fmt.Println("APP ERROR: ", err)
		}
	}
	db := app.NoSQLDatabase(dbName, nil)
	if isThere, err := db.Exists(u.Ctx); err != nil {
		fmt.Println("DB EXISTS ERROR: ", err)
	} else if !isThere {
		if db.Create(u.Ctx, nil) != nil {
			fmt.Println("DB ERROR: ", err)
		}
	}
	table := db.Table(tableName)
	if isThere, err := table.Exists(u.Ctx); err != nil {
		fmt.Println("TABLE EXISTS ERROR: ", err)
	} else if !isThere {
		if table.Create(u.Ctx, nil) != nil {
			fmt.Println("TABLE ERROR: ", err)
		}
	}
}

// Attempts to join a syncgroup; upon failure, creates a new one
func CreateOrJoinSyncgroup(u *uistate.UIState, sgName string) {
	allAccess := access.AccessList{In: []security.BlessingPattern{"..."}}
	permissions := access.Permissions{
		"Admin":   allAccess,
		"Write":   allAccess,
		"Read":    allAccess,
		"Resolve": allAccess,
		"Debug":   allAccess,
	}
	app := u.Service.App(appName)
	db := app.NoSQLDatabase(dbName, nil)
	sg := db.Syncgroup(sgName)
	myInfo := wire.SyncgroupMemberInfo{8}
	_, err := sg.Join(u.Ctx, myInfo)
	if err == nil {
		fmt.Println("Successfully joined syncgroup")
	} else {
		fmt.Printf("err: %v\n", err)
		fmt.Println("Creating Syncgroup")
		pref := wire.TableRow{tableName, ""}
		prefs := []wire.TableRow{pref}
		tables := []string{"/ns.dev.v.io:8101/users/emshack@google.com/croupier"}
		spec := wire.SyncgroupSpec{
			Description: "croupier syncgroup",
			Perms:       permissions,
			Prefixes:    prefs,
			MountTables: tables,
			IsPrivate:   false}
		err := sg.Create(u.Ctx, spec, myInfo)
		if err != nil {
			fmt.Println("SYNCGROUP CREATE ERROR: ", err)
		}
	}
}
