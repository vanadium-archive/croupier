// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package reposition

import (
	"hearts/direction"
	"hearts/img/staticimg"
	"hearts/logic/card"

	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
)

const (
	animSpeedScaler    = .1
	animRotationScaler = .15
)

// Resets the position of card c to its initial position, then realigns the suit it was in
// Takes as arguments:
// c = the card object to be reset
// cards = the total list of cards displayed on-screen
// emptySuitImgs = the list of staticImg objects showing suit icon in case of a suit becoming empty or populated
// padding = how much space there should be in between cards if the screen is wide enough to accommodate
// windowSize = an array containing the width and height of the app window
// eng = the engine running the app
func ResetCardPosition(c *card.Card, cards []*card.Card, emptySuitImgs []*staticimg.StaticImg, padding float32, windowSize []float32, eng sprite.Engine) {
	newX := c.GetInitialX()
	newY := c.GetInitialY()
	c.Move(newX, newY, c.GetWidth(), c.GetHeight(), eng)
	RealignSuit(c.GetSuit(), newY, cards, emptySuitImgs, padding, windowSize, eng)
}

// Realigns the cards in suit suitNum which are at y index oldY
// Takes as arguments:
// suitNum = the suit to be aligned
// oldY = the y-index of the suit
// cards = the total list of cards displayed on-screen
// emptySuitImgs = the list of staticImg objects showing suit icon in case of a suit becoming empty or populated
// padding = how much space there should be in between cards if the screen is wide enough to accommodate
// windowSize = an array containing the width and height of the app window
// eng = the engine running the app
func RealignSuit(suitNum card.Suit, oldY float32, cards []*card.Card, emptySuitImgs []*staticimg.StaticImg, padding float32, windowSize []float32, eng sprite.Engine) {
	cardsToAlign := make([]*card.Card, 0)
	for _, c := range cards {
		if c.GetSuit() == suitNum && c.GetY() == oldY {
			cardsToAlign = append(cardsToAlign, c)
		}
	}
	emptySuitImg := emptySuitImgs[suitNum]
	if len(cardsToAlign) == 0 {
		eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetImage())
	} else {
		eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetAlt())
	}
	for i, c := range cardsToAlign {
		width := c.GetWidth()
		height := c.GetHeight()
		diff := float32(len(cardsToAlign))*(padding+width) - (windowSize[0] - padding)
		x := padding + float32(i)*(padding+width)
		if diff > 0 && i > 0 {
			x -= diff * float32(i) / float32(len(cardsToAlign)-1)
		}
		y := oldY
		c.Move(x, y, width, height, eng)
		c.SetInitialPos(x, y)
	}
}

// Drags card curCard along with the mouse
func DragCard(curCard *card.Card, pixelsPerPt float32, lastMouseXY []float32, eng sprite.Engine, t touch.Event) {
	newX := curCard.GetX() + (t.X-lastMouseXY[0])/pixelsPerPt
	newY := curCard.GetY() + (t.Y-lastMouseXY[1])/pixelsPerPt
	width := curCard.GetWidth()
	height := curCard.GetHeight()
	curCard.Move(newX, newY, width, height, eng)
}

// Animates a card such that it spins away in direction dir
func SpinAway(animCard *card.Card, dir direction.Direction, touch touch.Event) {
	node := animCard.GetNode()
	startTime := -1
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		if startTime == -1 {
			startTime = int(t)
		}
		moveSpeed := float32(int(t)-startTime) * float32(animSpeedScaler)
		x := animCard.GetX()
		y := animCard.GetY()
		width := animCard.GetWidth()
		height := animCard.GetHeight()
		switch dir {
		case direction.Right:
			x = x + moveSpeed
		case direction.Left:
			x = x - moveSpeed
		case direction.Across:
			y = y - moveSpeed
		}
		animCard.SetPos(x, y, width, height)
		position := f32.Affine{
			{width, 0, x + width/2},
			{0, height, y + height/2},
		}
		position.Rotate(&position, float32(t)*float32(animRotationScaler))
		position.Translate(&position, -.5, -.5)
		eng.SetTransform(node, position)
	})
}

type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

// Used for node.Arranger
func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }
