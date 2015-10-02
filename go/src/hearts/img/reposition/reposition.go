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
func ResetCardPosition(c *card.Card, eng sprite.Engine) {
	c.Move(c.GetInitial(), c.GetDimensions(), eng)
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
func RealignSuit(suitNum card.Suit, oldY float32, cards []*card.Card, emptySuitImgs []*staticimg.StaticImg, padding float32, windowSize card.Vec, eng sprite.Engine) {
	cardsToAlign := make([]*card.Card, 0)
	for _, c := range cards {
		if c.GetSuit() == suitNum && c.GetCurrent().Y == oldY {
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
		dimVec := c.GetDimensions()
		diff := float32(len(cardsToAlign))*(padding+dimVec.X) - (windowSize.X - padding)
		x := padding + float32(i)*(padding+dimVec.X)
		if diff > 0 && i > 0 {
			x -= diff * float32(i) / float32(len(cardsToAlign)-1)
		}
		y := oldY
		curVec := card.MakeVec(x, y)
		c.Move(curVec, dimVec, eng)
		c.SetInitialPos(curVec)
	}
}

// Drags card curCard along with the mouse
func DragCard(curCard *card.Card, pixelsPerPt float32, lastMouseXY card.Vec, eng sprite.Engine, t touch.Event) {
	newX := curCard.GetCurrent().X + (t.X-lastMouseXY.X)/pixelsPerPt
	newY := curCard.GetCurrent().Y + (t.Y-lastMouseXY.Y)/pixelsPerPt
	newVec := card.MakeVec(newX, newY)
	curCard.Move(newVec, curCard.GetDimensions(), eng)
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
		x := animCard.GetCurrent().X
		y := animCard.GetCurrent().Y
		switch dir {
		case direction.Right:
			x = x + moveSpeed
		case direction.Left:
			x = x - moveSpeed
		case direction.Across:
			y = y - moveSpeed
		}
		dimVec := animCard.GetDimensions()
		newVec := card.MakeVec(x, y)
		animCard.SetPos(newVec, dimVec)
		position := f32.Affine{
			{dimVec.X, 0, x + dimVec.X/2},
			{0, dimVec.Y, y + dimVec.Y/2},
		}
		position.Rotate(&position, float32(t)*float32(animRotationScaler))
		position.Translate(&position, -.5, -.5)
		eng.SetTransform(node, position)
	})
}

type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

// Used for node.Arranger
func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }

// Given a card object, populates it with its positioning values and sets its position on-screen for the table view
// cardIndex has an X of the total number of cards in hand, and a Y of the position within the hand of the current card
// padding has an X of the padding along the top edge, and a Y of the padding along each other edge
func SetCardPositionTable(c *card.Card, playerIndex int, cardIndex,	padding, windowSize, cardDim card.Vec, cardScaler, overlap float32,	eng sprite.Engine, scene *sprite.Node) {
	xyVec := cardPositionTable(playerIndex, cardScaler, overlap, padding, windowSize, cardIndex, cardDim)
	c.Move(xyVec, cardDim, eng)
	c.SetInitialPos(xyVec)
}

func cardPositionTable(playerIndex int, cardScaler, overlap float32, padding, windowSize, cardIndex, cardDim card.Vec) card.Vec{
	var x float32
	var y float32
	switch playerIndex {
	case 0:
		x = horizontalPlayerCardX(windowSize, cardIndex, cardDim, padding.Y, overlap)
		y = windowSize.Y - cardDim.Y - padding.Y
	case 1:
		x = padding.Y
		y = verticalPlayerCardY(windowSize, cardIndex, cardDim, padding.Y, overlap, cardScaler)
	case 2:
		x = horizontalPlayerCardX(windowSize, cardIndex, cardDim, padding.Y, overlap)
		y = padding.X
	case 3:
		x = windowSize.X - padding.Y - cardDim.X
		y = verticalPlayerCardY(windowSize, cardIndex, cardDim, padding.Y, overlap, cardScaler)
	}
	return card.MakeVec(x, y)
}

func horizontalPlayerCardX(windowSize, cardIndex, cardDim card.Vec, edgePadding, overlap float32) float32 {
	return (windowSize.X+edgePadding-(float32(cardIndex.X)*(cardDim.X-overlap)+cardDim.X))/2 + float32(cardIndex.Y)*(cardDim.X-overlap)
}

func verticalPlayerCardY(windowSize, cardIndex, cardDim card.Vec, edgePadding, overlap, cardScaler float32) float32 {
	return (cardDim.Y/cardScaler+windowSize.Y+2*edgePadding-(float32(cardIndex.X)*(cardDim.Y-overlap)+cardDim.Y))/2 + float32(cardIndex.Y)*(cardDim.Y-overlap)
}

// Given a card object, populates it with its positioning values and sets its position on-screen for the player hand view
// padding has an X of the padding between cards, and a Y of the padding along the bottom
func SetCardPositionHand(c *card.Card, indexInSuit int, suitCounts []int, cardDim card.Vec,	padding, windowSize card.Vec, eng sprite.Engine, scene *sprite.Node) {
	suitCount := float32(suitCounts[c.GetSuit()])
	heightScaler := float32(4-c.GetSuit())
	diff := suitCount*(padding.X+cardDim.X) - (windowSize.X - padding.X)
	x := padding.X + float32(indexInSuit)*(padding.X+cardDim.X)
	if diff > 0 && indexInSuit > 0 {
		x -= diff * float32(indexInSuit) / (suitCount - 1)
	}
	y := windowSize.Y - heightScaler*(cardDim.Y+padding.X) - padding.Y
	xyVec := card.MakeVec(x, y)
	c.Move(xyVec, cardDim, eng)
	c.SetInitialPos(xyVec)
}
