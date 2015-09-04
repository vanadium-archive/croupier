// Copyright 2014 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build darwin linux

// An app that demonstrates the sprite package.
//
// Note: This demo is an early preview of Go 1.5. In order to build this
// program as an Android APK using the gomobile tool.
//
// See http://godoc.org/golang.org/x/mobile/cmd/gomobile to install gomobile.
//
// Get the sprite example and use gomobile to build or install it on your device.
//
//   $ go get -d golang.org/x/mobile/example/sprite
//   $ gomobile build golang.org/x/mobile/example/sprite # will build an APK
//
//   # plug your Android device to your computer or start an Android emulator.
//   # if you have adb installed on your machine, use gomobile install to
//   # build and deploy the APK to an Android target.
//   $ gomobile install golang.org/x/mobile/example/sprite
//
// Switch to your device or emulator to start the Basic application from
// the launcher.
// You can also run the application on your desktop by running the command
// below. (Note: It currently doesn't work on Windows.)
//   $ go install golang.org/x/mobile/example/sprite && sprite



package main

import (
	"image"
	"log"
	//"math"
	"time"

	_ "image/jpeg"
	_ "image/gif"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/exp/app/debug"
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
	//"golang.org/x/mobile/event/mouse"
	"golang.org/x/mobile/event/touch"

	//gc "github.com/rthornton128/goncurses"
)

var (
	startTime = time.Now()
	eng       = glsprite.Engine()
	scene     *sprite.Node
	sprites   []*sprite.Node
	spritesXY [][]float32
	initialSpritesXY [][]float32
	curSpriteIndex = -1
	lastMouseXY	  = []float32{-1,-1}
	numDropTargets = 0
)

func main() {
	app.Main(func(a app.App) {
		var sz size.Event
		for e := range a.Events() {
			switch e := app.Filter(e).(type) {
			case size.Event:
				sz = e
			case touch.Event:
				onTouch(e)
			case paint.Event:
				onPaint(sz)
				a.EndPaint(e)
			}
		}
	})
}

func onTouch(t touch.Event) {
	switch t.Type.String() {
	case "begin":
		//i > numDropTargets excludes drop targets so they can't move
		for i := len(sprites)-1; i >= numDropTargets; i-- {
			if t.X >= spritesXY[i][0] && 
			   t.Y >= spritesXY[i][1] &&
			   t.X <= spritesXY[i][2]+spritesXY[i][0] &&
			   t.Y <= spritesXY[i][3]+spritesXY[i][1] {
			   		curSpriteIndex = i
			   		lastMouseXY[0] = t.X
			   		lastMouseXY[1] = t.Y
			   		return
			   }
		}
	case "move":
		if curSpriteIndex > -1 {
			eng.SetTransform(sprites[curSpriteIndex], f32.Affine{
				{spritesXY[curSpriteIndex][2], 0, spritesXY[curSpriteIndex][0]+t.X-lastMouseXY[0]},
				{0, spritesXY[curSpriteIndex][3], spritesXY[curSpriteIndex][1]+t.Y-lastMouseXY[1]},
			})
			spritesXY[curSpriteIndex][0] = spritesXY[curSpriteIndex][0]+t.X-lastMouseXY[0]
			spritesXY[curSpriteIndex][1] = spritesXY[curSpriteIndex][1]+t.Y-lastMouseXY[1]
			lastMouseXY[0] = t.X
			lastMouseXY[1] = t.Y
		}
	case "end":
		onTarget := false
		for i := 0; i < numDropTargets; i++ {
			if curSpriteIndex > -1 && 
			   spritesXY[curSpriteIndex][0] + spritesXY[curSpriteIndex][2]/2 >= spritesXY[i][0] && 
			   spritesXY[curSpriteIndex][1] + spritesXY[curSpriteIndex][3]/2 >= spritesXY[i][1] && 
			   spritesXY[curSpriteIndex][0] + spritesXY[curSpriteIndex][2]/2 <= spritesXY[i][2]+spritesXY[i][0] &&
			   spritesXY[curSpriteIndex][1] + spritesXY[curSpriteIndex][3]/2 <= spritesXY[i][3]+spritesXY[i][1] {
			   		eng.SetTransform(sprites[curSpriteIndex], f32.Affine{
						{spritesXY[curSpriteIndex][2], 0, spritesXY[i][0]+spritesXY[i][2]/2-spritesXY[curSpriteIndex][2]/2},
						{0, spritesXY[curSpriteIndex][3], spritesXY[i][1]+spritesXY[i][3]/2-spritesXY[curSpriteIndex][3]/2},
					})
					spritesXY[curSpriteIndex][0] = spritesXY[i][0]+spritesXY[i][2]/2-spritesXY[curSpriteIndex][2]/2
					spritesXY[curSpriteIndex][1] = spritesXY[i][1]+spritesXY[i][3]/2-spritesXY[curSpriteIndex][3]/2
					onTarget = true
			}
		}
		if onTarget == false && curSpriteIndex > -1 {
			eng.SetTransform(sprites[curSpriteIndex], f32.Affine{
				{initialSpritesXY[curSpriteIndex][2], 0, initialSpritesXY[curSpriteIndex][0]},
				{0, initialSpritesXY[curSpriteIndex][3], initialSpritesXY[curSpriteIndex][1]},
			})
			spritesXY[curSpriteIndex][0] = initialSpritesXY[curSpriteIndex][0]
			spritesXY[curSpriteIndex][1] = initialSpritesXY[curSpriteIndex][1]
		}
		curSpriteIndex = -1
	}
}

func onPaint(sz size.Event) {
	if scene == nil {
		loadScene()
	}
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(startTime) * 60 / time.Second)
	eng.Render(scene, now, sz)
	debug.DrawFPS(sz)
}

func newNode() *sprite.Node {
	n := &sprite.Node{}
	eng.Register(n)
	scene.AppendChild(n)
	return n
}

func addCard(x float32, y float32, xSize float32, ySize float32, cardTex sprite.SubTex) {
	n := newNode()
	eng.SetSubTex(n, cardTex)
	eng.SetTransform(n, f32.Affine{
		{xSize, 0, x},
		{0, ySize, y},
	})
	sprites = append(sprites, n)
	spritesXY = append(spritesXY, []float32{x,y,xSize,ySize})
	initialSpritesXY = append(initialSpritesXY, []float32{x,y,xSize,ySize})
}

func addDropTarget(x float32, y float32, xSize float32, ySize float32, targetTex sprite.SubTex) {
	n := newNode()
	eng.SetSubTex(n, targetTex)
	eng.SetTransform(n, f32.Affine{
		{xSize, 0, x},
		{0, ySize, y},
	})
	numDropTargets++
	sprites = append(sprites, n)
	spritesXY = append(spritesXY, []float32{x,y,xSize,ySize})
	initialSpritesXY = append(initialSpritesXY, []float32{x,y,xSize,ySize})
}

func loadScene() {
	sprites = make([]*sprite.Node, 0)
	spritesXY = make([][]float32, 0)
	initialSpritesXY = make([][]float32, 0)
	texs := loadTextures()
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})

	//all drop targets must be added before all cards
	addDropTarget(10.0, 240.0, 768/4, 620/4, texs[dropTarget])
	addDropTarget(200.0, 240.0, 768/4, 620/4, texs[dropTarget])
	addCard(10.0, 10.0, 175/2, 245/2, texs[card1])
	addCard(110.0, 10.0, 175/2, 245/2, texs[card2])
	addCard(210.0, 10.0, 175/2, 245/2, texs[card3])
	addCard(310.0, 10.0, 175/2, 245/2, texs[card4])

	// n = newNode()
	// n.Arranger = arrangerFunc(func(eng sprite.Engine, n *sprite.Node, t clock.Time) {
	// 	// TODO: use a tweening library instead of manually arranging.
	// 	t0 := uint32(t) % 120
	// 	if t0 < 60 {
	// 		eng.SetSubTex(n, texs[card3])
	// 	} else {
	// 		eng.SetSubTex(n, texs[card4])
	// 	}

	// 	u := float32(t0) / 120
	// 	u = (1 - f32.Cos(u*2*math.Pi)) / 2

	// 	tx := 18 + u*48
	// 	ty := 36 + u*108
	// 	sx := 36 + u*36
	// 	sy := 36 + u*36
	// 	eng.SetTransform(n, f32.Affine{
	// 		{sx, 0, tx},
	// 		{0, sy, ty},
	// 	})
	// })
}

const (
	card1 = iota
	card2
	card3
	card4
	dropTarget
)

func loadTextures() []sprite.SubTex {
	a, err := asset.Open("cards.jpeg")
	if err != nil {
		log.Fatal(err)
	}
	defer a.Close()

	img, _, err := image.Decode(a)
	if err != nil {
		log.Fatal(err)
	}
	t, err := eng.LoadTexture(img)
	if err != nil {
		log.Fatal(err)
	}

	a2, err := asset.Open("dropTarget.jpeg")
	if err != nil {
		log.Fatal(err)
	}
	defer a2.Close()

	img2, _, err := image.Decode(a2)
	if err != nil {
		log.Fatal(err)
	}
	t2, err := eng.LoadTexture(img2)
	if err != nil {
		log.Fatal(err)
	}

	return []sprite.SubTex{
		card1: sprite.SubTex{t, image.Rect(15, 15, 190, 260)},
		card2: sprite.SubTex{t, image.Rect(195, 60, 370, 305)},
		card3: sprite.SubTex{t, image.Rect(375, 107, 550, 350)},
		card4: sprite.SubTex{t, image.Rect(555, 135, 730, 377)},
		dropTarget: sprite.SubTex{t2, image.Rect(0,0,768,620)},
	}
}

//type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

//func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }