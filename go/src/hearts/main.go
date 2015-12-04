// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// main.go is the master file for Croupier Hearts. It runs the app.

package main

import (
	"flag"
	"time"

	"v.io/v23"
	"v.io/v23/security"
	"v.io/v23/security/access"
	"v.io/v23/syncbase"
	"v.io/x/lib/vlog"

	"hearts/img/resize"
	"hearts/img/texture"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/table"
	"hearts/sync"
	"hearts/touchhandler"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/event/lifecycle"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/app/debug"
	"golang.org/x/mobile/exp/gl/glutil"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
)

var (
	fps *debug.FPS
)

func main() {
	app.Main(func(a app.App) {
		var glctx gl.Context
		var sz size.Event
		u := uistate.MakeUIState()
		for e := range a.Events() {
			switch e := a.Filter(e).(type) {
			case lifecycle.Event:
				switch e.Crosses(lifecycle.StageVisible) {
				case lifecycle.CrossOn:
					glctx, _ = e.DrawContext.(gl.Context)
					onStart(glctx, u)
					a.Send(paint.Event{})
				case lifecycle.CrossOff:
					glctx = nil
					onStop(u)
				}
			case size.Event:
				if !u.Done {
					// rearrange images on screen based on new size
					sz = e
					resize.UpdateImgPositions(sz, u)
				}
			case touch.Event:
				touchhandler.OnTouch(e, u)
			case paint.Event:
				if !u.Done {
					if glctx == nil || e.External {
						continue
					}
					onPaint(glctx, sz, u)
					a.Publish()
					a.Send(paint.Event{}) // keep animating
				}
			}
		}
	})
}

func onStart(glctx gl.Context, u *uistate.UIState) {
	flag.Set("v23.credentials", "/sdcard/credentials")
	vlog.Log.Configure(vlog.OverridePriorConfiguration(true), vlog.LogToStderr(true))
	vlog.Log.Configure(vlog.OverridePriorConfiguration(true), vlog.Level(0))
	ctx, shutdown := v23.Init()
	u.Shutdown = shutdown
	u.Ctx = ctx
	u.Service = syncbase.NewService(sync.MountPoint + "/croupier/" + sync.SBName)
	namespace := v23.GetNamespace(u.Ctx)
	allAccess := access.AccessList{In: []security.BlessingPattern{"..."}}
	permissions := access.Permissions{
		"Admin":   allAccess,
		"Write":   allAccess,
		"Read":    allAccess,
		"Resolve": allAccess,
		"Debug":   allAccess,
	}
	namespace.SetPermissions(u.Ctx, sync.MountPoint, permissions, "")
	namespace.SetPermissions(u.Ctx, sync.MountPoint+"/croupier", permissions, "")
	u.Service.SetPermissions(u.Ctx, permissions, "")
	u.Images = glutil.NewImages(glctx)
	if u.Debug {
		fps = debug.NewFPS(u.Images)
	}
	u.Eng = glsprite.Engine(u.Images)
	u.Texs = texture.LoadTextures(u.Eng)
	u.CurTable = table.InitializeGame(u.NumPlayers, u.Texs)
	sync.CreateTables(u)
	// Create watch stream to update game state based on Syncbase updates
	go sync.UpdateSettings(u)
}

func onStop(u *uistate.UIState) {
	u.Eng.Release()
	if u.Debug {
		fps.Release()
	}
	u.Images.Release()
	u.Done = true
	u.Shutdown()
}

func onPaint(glctx gl.Context, sz size.Event, u *uistate.UIState) {
	if u.CurView == uistate.None {
		discChan := make(chan []string)
		u.ScanChan = make(chan bool)
		go sync.ScanForSG(discChan, u.Ctx, u.ScanChan)
		view.LoadDiscoveryView(discChan, u)
	}
	glctx.ClearColor(1, 1, 1, 1)
	glctx.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(u.StartTime) * 60 / time.Second)
	u.Eng.Render(u.Scene, now, sz)
	if u.Debug {
		fps.Draw(sz)
	}
}
