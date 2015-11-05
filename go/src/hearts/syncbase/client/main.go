// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// client handles pulling data from syncbase. To be fleshed out when discovery is added.

package client

import (
	"fmt"

	"hearts/img/uistate"
	"v.io/v23/syncbase"
	"v.io/v23/syncbase/nosql"
	_ "v.io/x/ref/runtime/factories/generic"
)

var (
	appName   = "x"
	dbName    = "y"
	tableName = "z"
)

func GetService() syncbase.Service {
	service := syncbase.NewService("users/emshack@google.com/croupier/syncbase")
	return service
}

func WatchData(u *uistate.UIState) (nosql.WatchStream, error) {
	db := u.Service.App(appName).NoSQLDatabase(dbName, nil)
	prefix := ""
	resumeMarker, err := db.GetResumeMarker(u.Ctx)
	if err != nil {
		fmt.Println("RESUMEMARKER ERR: ", err)
	}
	return db.Watch(u.Ctx, tableName, prefix, resumeMarker)
}
