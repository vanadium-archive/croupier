// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"image"
	"log"
	"math"
	"time"

	_ "image/png"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
)

var (
	startTime          = time.Now()
	eng                = glsprite.Engine()
	scene              *sprite.Node
	cards              []*sprite.Node
	cardsXY            [][]float32
	initialCardsXY     [][]float32
	curCardIndex       = -1
	lastMouseXY        = []float32{-1, -1}
	cardWidth          = float32(100)
	cardHeight         = float32(100)
	windowSize         = []float32{-1, -1}
	swipeMoveThreshold = 70
	swipeTimeThreshold = .5
	swipeStart         time.Time
	animSpeedScaler    = .1
	animRotationScaler = .15
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
		for i := len(cards) - 1; i >= 0; i-- {
			if t.X >= getCardX(i) &&
				t.Y >= getCardY(i) &&
				t.X <= cardWidth+getCardX(i) &&
				t.Y <= cardHeight+getCardY(i) {
				swipeStart = time.Now()
				curCardIndex = i
				node := getCardNode(i)
				node.Arranger = nil
				lastMouseXY[0] = t.X
				lastMouseXY[1] = t.Y
				return
			}
		}
	case "move":
		if curCardIndex > -1 {
			eng.SetTransform(cards[curCardIndex], f32.Affine{
				{cardWidth, 0, getCardX(curCardIndex) + t.X - lastMouseXY[0]},
				{0, cardHeight, getCardY(curCardIndex) + t.Y - lastMouseXY[1]},
			})
			setCardX(curCardIndex, getCardX(curCardIndex)+t.X-lastMouseXY[0])
			setCardY(curCardIndex, getCardY(curCardIndex)+t.Y-lastMouseXY[1])
			lastMouseXY[0] = t.X
			lastMouseXY[1] = t.Y
		}
	case "end":
		if curCardIndex > -1 {
			xDiff := getCardX(curCardIndex) - getInitialX(curCardIndex)
			yDiff := getCardY(curCardIndex) - getInitialY(curCardIndex)
			timeDiff := time.Since(swipeStart).Seconds()
			if (math.Abs(float64(xDiff))+math.Abs(float64(yDiff))) >= float64(swipeMoveThreshold) && timeDiff <= float64(swipeTimeThreshold) {
				animate(xDiff, yDiff, t)
			} else {
				eng.SetTransform(cards[curCardIndex], f32.Affine{
					{cardWidth, 0, getInitialX(curCardIndex)},
					{0, cardHeight, getInitialY(curCardIndex)},
				})
				setCardX(curCardIndex, getInitialX(curCardIndex))
				setCardY(curCardIndex, getInitialY(curCardIndex))
			}
		}
		curCardIndex = -1
	}
}

func animate(xDiff float32, yDiff float32, touch touch.Event) {
	index := curCardIndex
	curCardIndex = -1
	node := getCardNode(index)
	startTime := -1
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		if startTime == -1 {
			startTime = int(t)
		}
		moveSpeed := float32(int(t)-startTime) * float32(animSpeedScaler)
		x := getCardX(index)
		y := getCardY(index)
		if math.Abs(float64(xDiff)) > math.Abs(float64(yDiff)) {
			if xDiff > 0 {
				x = x + moveSpeed
			} else {
				x = x - moveSpeed
			}
		} else {
			if yDiff > 0 {
				y = y + moveSpeed
			} else {
				y = y - moveSpeed
			}
		}
		setCardX(index, x)
		setCardY(index, y)
		position := f32.Affine{
			{cardWidth, 0, x + cardWidth/2},
			{0, cardHeight, y + cardHeight/2},
		}
		position.Rotate(&position, float32(t)*float32(animRotationScaler))
		position.Translate(&position, -.5, -.5)
		eng.SetTransform(node, position)
	})
}

func onPaint(sz size.Event) {
	if scene == nil {
		loadScene()
	}
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(startTime) * 60 / time.Second)
	eng.Render(scene, now, sz)
}

func newNode() *sprite.Node {
	n := &sprite.Node{}
	eng.Register(n)
	scene.AppendChild(n)
	return n
}

func addCard(x float32, y float32, spriteTex sprite.SubTex) {
	n := newNode()
	eng.SetSubTex(n, spriteTex)
	eng.SetTransform(n, f32.Affine{
		{cardWidth, 0, x},
		{0, cardHeight, y},
	})
	cards = append(cards, n)
	cardsXY = append(cardsXY, []float32{x, y})
	initialCardsXY = append(initialCardsXY, []float32{x, y})
}

func getCardX(cardIndex int) float32 {
	return cardsXY[cardIndex][0]
}

func setCardX(cardIndex int, newX float32) {
	cardsXY[cardIndex][0] = newX
}

func getCardY(cardIndex int) float32 {
	return cardsXY[cardIndex][1]
}

func setCardY(cardIndex int, newY float32) {
	cardsXY[cardIndex][1] = newY
}

func getCardNode(cardIndex int) *sprite.Node {
	return cards[cardIndex]
}

func getInitialX(cardIndex int) float32 {
	return initialCardsXY[cardIndex][0]
}

func getInitialY(cardIndex int) float32 {
	return initialCardsXY[cardIndex][1]
}

func loadScene() {
	cards = make([]*sprite.Node, 0)
	cardsXY = make([][]float32, 0)
	initialCardsXY = make([][]float32, 0)
	texs := loadTextures()
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	for _, v := range texs {
		x := windowSize[0]/2 - cardWidth/2
		y := windowSize[1]/2 - cardHeight/2
		addCard(x, y, v)
	}
}

func loadTextures() map[string]sprite.SubTex {
	allTexs := make(map[string]sprite.SubTex)
	files := []string{"Clubs-2.png", "Clubs-3.png", "Clubs-4.png", "Clubs-5.png", "Clubs-6.png", "Clubs-7.png", "Clubs-8.png",
		"Clubs-9.png", "Clubs-10.png", "Clubs-Jack.png", "Clubs-Queen.png", "Clubs-King.png", "Clubs-Ace.png",
		"Diamonds-2.png", "Diamonds-3.png", "Diamonds-4.png", "Diamonds-5.png", "Diamonds-6.png", "Diamonds-7.png", "Diamonds-8.png",
		"Diamonds-9.png", "Diamonds-10.png", "Diamonds-Jack.png", "Diamonds-Queen.png", "Diamonds-King.png", "Diamonds-Ace.png",
		"Spades-2.png", "Spades-3.png", "Spades-4.png", "Spades-5.png", "Spades-6.png", "Spades-7.png", "Spades-8.png",
		"Spades-9.png", "Spades-10.png", "Spades-Jack.png", "Spades-Queen.png", "Spades-King.png", "Spades-Ace.png",
		"Hearts-2.png", "Hearts-3.png", "Hearts-4.png", "Hearts-5.png", "Hearts-6.png", "Hearts-7.png", "Hearts-8.png",
		"Hearts-9.png", "Hearts-10.png", "Hearts-Jack.png", "Hearts-Queen.png", "Hearts-King.png", "Hearts-Ace.png"}
	for _, f := range files {
		a, err := asset.Open(f)
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
		allTexs[f] = sprite.SubTex{t, image.Rect(0, 0, 100, 100)}
	}
	return allTexs
}

type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }
