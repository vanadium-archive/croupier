// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

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

	_ "image/gif"
	_ "image/jpeg"

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
	startTime        = time.Now()
	eng              = glsprite.Engine()
	scene            *sprite.Node
	sprites          []*sprite.Node
	spritesXY        [][]float32
	initialSpritesXY [][]float32
	curSpriteIndex   = -1
	lastMouseXY      = []float32{-1, -1}
	numCards         = 4
	numDropTargets   = 3
	numDecks         = 2
	cardWidth        = float32(175)
	cardHeight       = float32(245)
	dropWidth        = float32(768 / 2)
	dropHeight       = float32(620 / 2)
	paddingSize      = float32(cardWidth / 5)
	middleSize       = float32(cardHeight)
	windowSize       = []float32{-1, -1}
)

func main() {
	app.Main(func(a app.App) {
		var sz size.Event
		for e := range a.Events() {
			switch e := app.Filter(e).(type) {
			case size.Event:
				sz = e
				windowSize[0] = float32(sz.WidthPx)
				windowSize[1] = float32(sz.HeightPx)
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
		//i > numDropTargets excludes drop targets, draw, and discard so they can't move
		for i := len(sprites) - 1; i >= numDropTargets+2; i-- {
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
		//checking if draw or discard is clicked
		for i := 1; i >= 0; i-- {
			if t.X >= spritesXY[i][0] &&
				t.Y >= spritesXY[i][1] &&
				t.X <= spritesXY[i][2]+spritesXY[i][0] &&
				t.Y <= spritesXY[i][3]+spritesXY[i][1] {
				if i == 0 {
					//draw is clicked
					numCards++
					loadScene()
				} else {
					//discard is clicked
					if numCards > 0 {
						numCards--
						loadScene()
					}
				}
			}
		}
	case "move":
		if curSpriteIndex > -1 {
			eng.SetTransform(sprites[curSpriteIndex], f32.Affine{
				{spritesXY[curSpriteIndex][2], 0, spritesXY[curSpriteIndex][0] + t.X - lastMouseXY[0]},
				{0, spritesXY[curSpriteIndex][3], spritesXY[curSpriteIndex][1] + t.Y - lastMouseXY[1]},
			})
			spritesXY[curSpriteIndex][0] = spritesXY[curSpriteIndex][0] + t.X - lastMouseXY[0]
			spritesXY[curSpriteIndex][1] = spritesXY[curSpriteIndex][1] + t.Y - lastMouseXY[1]
			lastMouseXY[0] = t.X
			lastMouseXY[1] = t.Y
		}
	case "end":
		onTarget := false
		for i := 2; i < numDropTargets+2; i++ {
			if curSpriteIndex > -1 &&
				spritesXY[curSpriteIndex][0]+spritesXY[curSpriteIndex][2]/2 >= spritesXY[i][0] &&
				spritesXY[curSpriteIndex][1]+spritesXY[curSpriteIndex][3]/2 >= spritesXY[i][1] &&
				spritesXY[curSpriteIndex][0]+spritesXY[curSpriteIndex][2]/2 <= spritesXY[i][2]+spritesXY[i][0] &&
				spritesXY[curSpriteIndex][1]+spritesXY[curSpriteIndex][3]/2 <= spritesXY[i][3]+spritesXY[i][1] {
				eng.SetTransform(sprites[curSpriteIndex], f32.Affine{
					{spritesXY[curSpriteIndex][2], 0, spritesXY[i][0] + spritesXY[i][2]/2 - spritesXY[curSpriteIndex][2]/2},
					{0, spritesXY[curSpriteIndex][3], spritesXY[i][1] + spritesXY[i][3]/2 - spritesXY[curSpriteIndex][3]/2},
				})
				spritesXY[curSpriteIndex][0] = spritesXY[i][0] + spritesXY[i][2]/2 - spritesXY[curSpriteIndex][2]/2
				spritesXY[curSpriteIndex][1] = spritesXY[i][1] + spritesXY[i][3]/2 - spritesXY[curSpriteIndex][3]/2
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

func addSprite(x float32, y float32, xSize float32, ySize float32, spriteTex sprite.SubTex) {
	n := newNode()
	eng.SetSubTex(n, spriteTex)
	eng.SetTransform(n, f32.Affine{
		{xSize, 0, x},
		{0, ySize, y},
	})
	sprites = append(sprites, n)
	spritesXY = append(spritesXY, []float32{x, y, xSize, ySize})
	initialSpritesXY = append(initialSpritesXY, []float32{x, y, xSize, ySize})
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

	dropXScaler := (float32(numDropTargets)*dropWidth + float32(numDropTargets+1)*paddingSize) / windowSize[0]
	cardXScaler := (float32(numCards)*cardWidth + (float32(numCards)+1)*paddingSize) / windowSize[0]
	deckXScaler := (float32(numDecks+2)*cardWidth + (float32(numDecks+2)+1)*paddingSize) / windowSize[0]
	yScaler := (dropHeight + cardHeight + middleSize + 4*paddingSize) / windowSize[1]
	cardTexs := []sprite.SubTex{texs[card1], texs[card2], texs[card3], texs[card4]}
	for yScaler > cardXScaler {
		cardXScaler += (cardWidth + paddingSize) / windowSize[0]
	}
	//deck and discard must be added first
	addSprite((2*paddingSize+cardWidth)/deckXScaler, (2*paddingSize+cardHeight)/yScaler,
		cardWidth/deckXScaler, cardHeight/yScaler, texs[draw])
	addSprite((3*paddingSize+2*cardWidth)/deckXScaler, (2*paddingSize+cardHeight)/yScaler,
		cardWidth/deckXScaler, cardHeight/yScaler, texs[discard])

	//all drop targets must be added before all cards
	for i := 0; i < numDropTargets; i++ {
		addSprite((float32(i+1)*paddingSize+float32(i)*dropWidth)/dropXScaler, (cardHeight+middleSize+3*paddingSize)/yScaler,
			dropWidth/dropXScaler, dropHeight/yScaler, texs[dropTarget])
	}
	for i := 0; i < numCards; i++ {
		addSprite((float32(i+1)*paddingSize+float32(i)*cardWidth)/cardXScaler, paddingSize/yScaler,
			cardWidth/cardXScaler, cardHeight/cardXScaler, cardTexs[i%len(cardTexs)])
	}
}

const (
	card1 = iota
	card2
	card3
	card4
	dropTarget
	draw
	discard
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

	a3, err := asset.Open("deck.jpeg")
	if err != nil {
		log.Fatal(err)
	}
	defer a3.Close()

	img3, _, err := image.Decode(a3)
	if err != nil {
		log.Fatal(err)
	}
	t3, err := eng.LoadTexture(img3)
	if err != nil {
		log.Fatal(err)
	}

	return []sprite.SubTex{
		card1:      sprite.SubTex{t, image.Rect(15, 15, 190, 260)},
		card2:      sprite.SubTex{t, image.Rect(195, 60, 370, 305)},
		card3:      sprite.SubTex{t, image.Rect(375, 107, 550, 350)},
		card4:      sprite.SubTex{t, image.Rect(555, 135, 730, 377)},
		dropTarget: sprite.SubTex{t2, image.Rect(0, 0, 766, 620)},
		draw:       sprite.SubTex{t3, image.Rect(0, 0, 1506/2, 1052)},
		discard:    sprite.SubTex{t3, image.Rect(1506/2, 0, 1506, 1052)},
	}
}
