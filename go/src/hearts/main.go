// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"time"

	"hearts/direction"
	"hearts/img/reposition"
	"hearts/img/resize"
	"hearts/img/staticimg"
	"hearts/logic/card"
	"hearts/logic/table"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"

	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
)

const (
	numPlayers      = 4
	cardSize        = 35
	cardScaler      = float32(.5)
	topPadding      = float32(15)
	bottomPadding   = float32(5)
)

var (
	startTime      = time.Now()
	eng            = glsprite.Engine()
	scene          *sprite.Node
	cards          = make([]*card.Card, 0)
	backgroundImgs = make([]*staticimg.StaticImg, 0)
	emptySuitImgs  = make([]*staticimg.StaticImg, 0)
	dropTargets    = make([]*staticimg.StaticImg, 0)
	buttons        = make([]*staticimg.StaticImg, 0)
	curCard        *card.Card
	// lastMouseXY is in Px: divide by pixelsPerPt to get Pt
	lastMouseXY = card.MakeVec(-1, -1)
	// windowSize is in Pt
	windowSize  = card.MakeVec(-1, -1)
	cardDim = card.MakeVec(cardSize, cardSize)
	tableCardDim = card.MakeVec(cardDim.X*cardScaler, cardDim.Y*cardScaler)
	pixelsPerPt float32
	padding     = float32(5)
	dir         direction.Direction
	view        View
	curTable    = table.InitializeGame(numPlayers)
)

type View string

const (
	Opening View = "O"
	Pass    View = "P"
	Table   View = "T"
)

func main() {
	app.Main(func(a app.App) {
		var sz size.Event
		dir = direction.Right
		for e := range a.Events() {
			switch e := app.Filter(e).(type) {
			case size.Event:
				// rearrange images on screen based on new size
				sz = e
				oldPos := windowSize
				updateWindowSize(sz)
				updateImgPositions(oldPos)
			case touch.Event:
				onTouch(e)
			case paint.Event:
				onPaint(sz)
				a.EndPaint(e)
			}
		}
	})
}

func updateWindowSize(sz size.Event) {
	wsPointer := &windowSize
	wsPointer.SetVec(float32(sz.WidthPt), float32(sz.HeightPt))
	pixelsPerPt = float32(sz.WidthPx) / windowSize.X
}

func updateImgPositions(oldWindow card.Vec) {
	if windowExists(oldWindow) {
		padding = resize.ScaleVar(padding, oldWindow, windowSize)
		cardDim = resize.ScaleVec(cardDim, oldWindow, windowSize)
		tableCardDim = resize.ScaleVec(tableCardDim, oldWindow, windowSize)
		resize.AdjustImgs(oldWindow, cards, dropTargets, backgroundImgs, buttons, emptySuitImgs, windowSize, eng)
	}
}

func windowExists(window card.Vec) bool {
	return !(window.X < 0 || window.Y < 0)
}

// returns a card object if a card was clicked, or nil if no card was clicked
func findClickedCard(t touch.Event) *card.Card {
	// i goes from the end backwards so that it checks cards displayed on top of other cards first
	for i := len(cards) - 1; i >= 0; i-- {
		c := cards[i]
		if touchingCard(t, c) {
			return c
		}
	}
	return nil
}

func touchingCard(t touch.Event, c *card.Card) bool {
	withinXBounds := t.X/pixelsPerPt >= c.GetCurrent().X && t.X/pixelsPerPt <= c.GetDimensions().X+c.GetCurrent().X
	withinYBounds := t.Y/pixelsPerPt >= c.GetCurrent().Y && t.Y/pixelsPerPt <= c.GetDimensions().Y+c.GetCurrent().Y
	return withinXBounds && withinYBounds
}

func touchingStaticImg(t touch.Event, s *staticimg.StaticImg) bool {
	withinXBounds := t.X/pixelsPerPt >= s.GetCurrent().X && t.X/pixelsPerPt <= s.GetDimensions().X+s.GetCurrent().X
	withinYBounds := t.Y/pixelsPerPt >= s.GetCurrent().Y && t.Y/pixelsPerPt <= s.GetDimensions().Y+s.GetCurrent().Y
	return withinXBounds && withinYBounds
}

// returns a button object if a button was clicked, or nil if no button was clicked
func findClickedButton(t touch.Event) *staticimg.StaticImg {
	for _, b := range buttons {
		if touchingStaticImg(t, b) {
			return b
		}
	}
	return nil
}

func passCards(t touch.Event) {
	for _, d := range dropTargets {
		passCard := d.GetCardHere()
		if passCard != nil {
			reposition.SpinAway(passCard, dir, t)
			d.SetCardHere(nil)
		}
	}
}

func dropCardOnTarget(c *card.Card, t touch.Event) bool {
	for _, d := range dropTargets {
		// checking to see if card was dropped onto a drop target
		if touchingStaticImg(t, d) {
			lastDroppedCard := d.GetCardHere()
			if lastDroppedCard != nil {
				reposition.ResetCardPosition(lastDroppedCard, eng)
				if view == Pass {
					reposition.RealignSuit(lastDroppedCard.GetSuit(), lastDroppedCard.GetInitial().Y, cards, emptySuitImgs, padding, windowSize, eng)
				} else if view == Table {
					eng.SetSubTex(lastDroppedCard.GetNode(), lastDroppedCard.GetBack())
					lastDroppedCard.Move(lastDroppedCard.GetCurrent(), tableCardDim, eng)
				}
			}
			oldY := c.GetInitial().Y
			suit := c.GetSuit()
			curCard.Move(d.GetCurrent(), c.GetDimensions(), eng)
			d.SetCardHere(curCard)
			// realign suit the card just left
			if view == Pass {
				reposition.RealignSuit(suit, oldY, cards, emptySuitImgs, padding, windowSize, eng)
			}
			return true
		}
	}
	return false
}

func removeCardFromTarget(c *card.Card) bool {
	for _, d := range dropTargets {
		if d.GetCardHere() == c {
			d.SetCardHere(nil)
			return true
		}
	}
	return false
}

func unpressButtons() {
	for _, b := range buttons {
		eng.SetSubTex(b.GetNode(), b.GetImage())
	}
}

func pressButton(b *staticimg.StaticImg) {
	eng.SetSubTex(b.GetNode(), b.GetAlt())
}

func onTouch(t touch.Event) {
	switch t.Type.String() {
	case "begin":
		curCard = findClickedCard(t)
		b := findClickedButton(t)
		if b != nil {
			pressButton(b)
			if view == Pass {
				// specific to pass screen scenario: if any button is clicked, all cards on drop targets get passed
				passCards(t)
			} else if view == Opening {
				if buttons[0] == b {
					loadTableView(curTable)
				} else {
					loadPassView(curTable)
				}
			}
		}
	case "move":
		// only do anything if the user has clicked on a card: then, drag it
		if curCard != nil {
			reposition.DragCard(curCard, pixelsPerPt, lastMouseXY, eng, t)
		}
	case "end":
		if curCard != nil {
			if !dropCardOnTarget(curCard, t) {
				// check to see if card was removed from a drop target
				removeCardFromTarget(curCard)
				// add card back to hand
				reposition.ResetCardPosition(curCard, eng)
				if view == Pass {
					reposition.RealignSuit(curCard.GetSuit(), curCard.GetInitial().Y, cards, emptySuitImgs, padding, windowSize, eng)
				} else if view == Table {
					eng.SetSubTex(curCard.GetNode(), curCard.GetBack())
					curCard.Move(curCard.GetCurrent(), tableCardDim, eng)
				}
			} else if view == Table {
				eng.SetSubTex(curCard.GetNode(), curCard.GetImage())
				curCard.Move(curCard.GetCurrent(), cardDim, eng)
			}
		}
		// reset all buttons to 'unpressed' image, in case any had been clicked
		unpressButtons()
		curCard = nil
	}
	lastMouseXY.X = t.X
	lastMouseXY.Y = t.Y
}

func onPaint(sz size.Event) {
	if scene == nil {
		curTable.Deal()
		loadOpeningView(curTable)
	}
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(startTime) * 60 / time.Second)
	eng.Render(scene, now, sz)
}
