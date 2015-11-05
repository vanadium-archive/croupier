// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// reposition handles changing image positioning on the screen

package reposition

import (
	"math"
	"time"

	"hearts/img/coords"
	"hearts/img/direction"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/logic/card"
	"hearts/logic/player"

	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
)

const (
	// animationFrameCounter is the number of frames it will take to complete any animation
	// This is a float because it allows for future float operations without requiring conversion each time
	animationFrameCounter = float32(100)
	// animRotationScaler is the speed at which an image rotates, if rotation is involved in an animation
	animRotationScaler = .15
)

// Resets the position of card c to its initial position, then realigns the suit it was in
func ResetCardPosition(c *card.Card, eng sprite.Engine) {
	c.Move(c.GetInitial(), c.GetDimensions(), eng)
}

// Realigns the cards in suit suitNum which are at y index oldY
func RealignSuit(suitNum card.Suit, oldY float32, u *uistate.UIState) {
	cardsToAlign := make([]*card.Card, 0)
	for _, c := range u.Cards {
		if c.GetSuit() == suitNum && c.GetCurrent().Y == oldY {
			cardsToAlign = append(cardsToAlign, c)
		}
	}
	emptySuitImg := u.EmptySuitImgs[suitNum]
	if len(cardsToAlign) == 0 {
		u.Eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetImage())
	} else {
		u.Eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetAlt())
	}
	for i, c := range cardsToAlign {
		dimVec := c.GetDimensions()
		diff := float32(len(cardsToAlign))*(u.Padding+dimVec.X) - (u.WindowSize.X - u.Padding)
		x := u.Padding + float32(i)*(u.Padding+dimVec.X)
		if diff > 0 && i > 0 {
			x -= diff * float32(i) / float32(len(cardsToAlign)-1)
		}
		curVec := coords.MakeVec(x, oldY)
		c.Move(curVec, dimVec, u.Eng)
		c.SetInitial(curVec)
	}
}

// Drags card curCard along with the mouse
func DragCard(t touch.Event, u *uistate.UIState) {
	tVec := coords.MakeVec(t.X, t.Y)
	newVec := u.CurCard.GetCurrent().PlusVec(tVec.MinusVec(u.LastMouseXY).DividedBy(u.PixelsPerPt))
	u.CurCard.Move(newVec, u.CurCard.GetDimensions(), u.Eng)
}

// Drags all input cards and images together with the mouse
func DragImgs(t touch.Event, cards []*card.Card, imgs []*staticimg.StaticImg, u *uistate.UIState) {
	tVec := coords.MakeVec(t.X, t.Y)
	for _, i := range imgs {
		newVec := i.GetCurrent().PlusVec(tVec.MinusVec(u.LastMouseXY).DividedBy(u.PixelsPerPt))
		i.Move(newVec, i.GetDimensions(), u.Eng)
	}
	for _, c := range cards {
		newVec := c.GetCurrent().PlusVec(tVec.MinusVec(u.LastMouseXY).DividedBy(u.PixelsPerPt))
		c.Move(newVec, c.GetDimensions(), u.Eng)
	}
}

// Animation for the 'take' action, when app is in the table view
func AnimateTableCardTake(animCard *card.Card, cardNum int, p *player.Player) {
	initialPos := animCard.GetPosition()
	destinationXY := p.GetPassedFrom()[cardNum].GetInitial()
	destination := coords.MakePosition(destinationXY, destinationXY, initialPos.GetDimensions())
	c := make(chan bool)
	animateCardMovement(c, animCard, initialPos, destination)
	<-c
}

// Animation for the 'pass' action, when app is in the table view
func AnimateTableCardPass(animCard *card.Card, toPlayer, cardNum int, u *uistate.UIState) {
	initialPos := animCard.GetPosition()
	cardDim := initialPos.GetDimensions()
	dropTargetXY := u.DropTargets[toPlayer].GetCurrent()
	dropTargetDim := u.DropTargets[toPlayer].GetDimensions()
	targetCenter := dropTargetXY.PlusVec(dropTargetDim.DividedBy(2))
	distFromTargetX := u.WindowSize.X / 4
	distFromTargetY := u.WindowSize.Y / 5
	blockEdge := targetCenter.MinusVec(cardDim.Times(3).Plus(2 * u.Padding))
	var destination *coords.Vec
	switch toPlayer {
	case 0:
		destination = coords.MakeVec(
			blockEdge.X+float32(cardNum)*(u.Padding+cardDim.X),
			targetCenter.Y+distFromTargetY-cardDim.Y/2)
	case 1:
		destination = coords.MakeVec(
			targetCenter.X-distFromTargetX-cardDim.X/2,
			blockEdge.Y+float32(cardNum)*(u.Padding+cardDim.Y))
	case 2:
		destination = coords.MakeVec(
			blockEdge.X+float32(cardNum)*(u.Padding+cardDim.X),
			targetCenter.Y-distFromTargetY-cardDim.Y/2)
	case 3:
		destination = coords.MakeVec(
			targetCenter.X+distFromTargetX-cardDim.X/2,
			blockEdge.Y+float32(cardNum)*(u.Padding+cardDim.Y))
	}
	destinationPos := coords.MakePosition(destination, destination, cardDim)
	c := make(chan bool)
	animateCardMovement(c, animCard, initialPos, destinationPos)
	<-c
}

// Animation for the 'pass' action, when app is in the hand view
func AnimateHandCardPass(ch chan bool, animImages []*staticimg.StaticImg, animCards []*card.Card, u *uistate.UIState) {
	ch2 := make(chan bool)
	for _, i := range animImages {
		initial := i.GetPosition()
		destination := coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y-u.WindowSize.Y)
		destinationPos := coords.MakePosition(destination, destination, i.GetDimensions())
		AnimateImageMovement(i, initial, destinationPos)
	}
	for _, c := range animCards {
		initial := c.GetPosition()
		destination := coords.MakeVec(c.GetCurrent().X, c.GetCurrent().Y-u.WindowSize.Y)
		destinationPos := coords.MakePosition(destination, destination, c.GetDimensions())
		animateCardMovement(ch2, c, initial, destinationPos)
	}
	select {
	case <-ch2:
		ch <- true
	case <-time.After(1 * time.Second):
		ch <- false
	}
}

// Animation for the 'take' action, when app is in the hand view
func AnimateHandCardTake(ch chan bool, animImages []*staticimg.StaticImg, u *uistate.UIState) {
	ch2 := make(chan bool)
	for _, i := range animImages {
		initial := i.GetPosition()
		destination := coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y-u.WindowSize.Y)
		destinationPos := coords.MakePosition(destination, destination, i.GetDimensions())
		AnimateImageMovement(i, initial, destinationPos)
	}
	select {
	case <-ch2:
		ch <- true
	case <-time.After(1 * time.Second):
		ch <- false
	}
}

// Animation for the 'play' action, when app is in the hand view
func AnimateHandCardPlay(c chan bool, animCard *card.Card, u *uistate.UIState) {
	initial := animCard.GetPosition()
	destinationXY := determineDestination(animCard, direction.Across, u.WindowSize)
	destinationSize := animCard.GetDimensions()
	destination := coords.MakePosition(destinationXY, destinationXY, destinationSize)
	animateCardMovement(c, animCard, initial, destination)
	<-c
	c <- true
}

// Animation for the 'play' action, when app is in the table view
func AnimateTableCardPlay(c chan bool, animCard *card.Card, playerInt int, u *uistate.UIState) {
	destination := u.DropTargets[playerInt]
	destinationPos := destination.GetPosition()
	initialPos := animCard.GetPosition()
	ch := make(chan bool)
	animateCardMovement(ch, animCard, initialPos, destinationPos)
	<-ch
	animCard.SetFrontDisplay(u.Eng)
	c <- true
}

func determineDestination(animCard *card.Card, dir direction.Direction, windowSize *coords.Vec) *coords.Vec {
	switch dir {
	case direction.Right:
		return coords.MakeVec(windowSize.X+2*animCard.GetDimensions().X, animCard.GetCurrent().Y)
	case direction.Left:
		return coords.MakeVec(0-2*animCard.GetDimensions().X, animCard.GetCurrent().Y)
	case direction.Across:
		return coords.MakeVec(animCard.GetCurrent().X, 0-2*animCard.GetDimensions().Y)
	case direction.Down:
		return coords.MakeVec(animCard.GetCurrent().X, windowSize.Y+2*animCard.GetDimensions().Y)
	// Should not occur
	default:
		return coords.MakeVec(-1, -1)
	}
}

// Animation for when a trick is taken, when app is in the table view
func AnimateTableCardTakeTrick(c chan bool, animCard *card.Card, dir direction.Direction, u *uistate.UIState) {
	initial := animCard.GetPosition()
	destination := determineDestination(animCard, dir, u.WindowSize)
	destinationSize := animCard.GetDimensions()
	destinationPos := coords.MakePosition(destination, destination, destinationSize)
	animateCardMovement(c, animCard, initial, destinationPos)
	<-c
	c <- true
}

func AnimateImageMovement(animImage *staticimg.StaticImg, from, to *coords.Position) {
	node := animImage.GetNode()
	iteration := 0
	initial := from.GetCurrent()
	initialDim := from.GetDimensions()
	destination := to.GetCurrent()
	destinationSize := to.GetDimensions()
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if float32(iteration) < animationFrameCounter {
			curXY := animImage.GetCurrent()
			curDim := animImage.GetDimensions()
			XYStep := destination.MinusVec(initial).DividedBy(animationFrameCounter)
			dimStep := destinationSize.MinusVec(initialDim).DividedBy(animationFrameCounter)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animImage.Move(newVec, dimVec, eng)
		} else if math.Abs(float64(animationFrameCounter)-float64(iteration)) < 0.0001 {
			animImage.Move(destination, destinationSize, eng)
		}
	})
}

func animateCardMovement(c chan bool, animCard *card.Card, from, to *coords.Position) {
	node := animCard.GetNode()
	iteration := 0
	initial := from.GetCurrent()
	initialDim := from.GetDimensions()
	destinationXY := to.GetCurrent()
	destinationSize := to.GetDimensions()
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if float32(iteration) < animationFrameCounter {
			curXY := animCard.GetCurrent()
			curDim := animCard.GetDimensions()
			XYStep := destinationXY.MinusVec(initial).DividedBy(animationFrameCounter)
			dimStep := destinationSize.MinusVec(initialDim).DividedBy(animationFrameCounter)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animCard.Move(newVec, dimVec, eng)
		} else if float32(iteration) == animationFrameCounter {
			animCard.Move(destinationXY, destinationSize, eng)
			c <- true
		}
	})
}

type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

// Used for node.Arranger
func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }

// Given a card object, populates it with its positioning values and sets its position on-screen for the table view
// cardIndex has an X of the total number of cards in hand, and a Y of the position within the hand of the current card
// padding has an X of the padding along the top edge, and a Y of the padding along each other edge
func SetCardPositionTable(c *card.Card, playerIndex int, cardIndex *coords.Vec, u *uistate.UIState) {
	xyVec := cardPositionTable(playerIndex, cardIndex, u)
	pos := coords.MakePosition(xyVec, xyVec, u.TableCardDim)
	c.SetPos(pos)
	c.Move(xyVec, u.TableCardDim, u.Eng)
}

func cardPositionTable(playerIndex int, cardIndex *coords.Vec, u *uistate.UIState) *coords.Vec {
	var x float32
	var y float32
	switch playerIndex {
	case 0:
		x = horizontalPlayerCardX(u.WindowSize, cardIndex, u.TableCardDim, u.BottomPadding, u.Overlap.X)
		y = u.WindowSize.Y - u.TableCardDim.Y - u.BottomPadding
	case 1:
		x = u.BottomPadding
		y = verticalPlayerCardY(u.WindowSize, cardIndex, u.TableCardDim, u.PlayerIconDim, u.BottomPadding, u.Overlap.Y, u.CardScaler)
	case 2:
		x = horizontalPlayerCardX(u.WindowSize, cardIndex, u.TableCardDim, u.BottomPadding, u.Overlap.X)
		y = u.TopPadding
	case 3:
		x = u.WindowSize.X - u.BottomPadding - u.TableCardDim.X
		y = verticalPlayerCardY(u.WindowSize, cardIndex, u.TableCardDim, u.PlayerIconDim, u.BottomPadding, u.Overlap.Y, u.CardScaler)
	}
	return coords.MakeVec(x, y)
}

func horizontalPlayerCardX(windowSize, cardIndex, cardDim *coords.Vec, edgePadding, overlap float32) float32 {
	return (windowSize.X+edgePadding-(float32(cardIndex.X)*(cardDim.X-overlap)+cardDim.X))/2 + float32(cardIndex.Y)*(cardDim.X-overlap)
}

func verticalPlayerCardY(windowSize, cardIndex, cardDim, playerIconDim *coords.Vec, edgePadding, overlap, cardScaler float32) float32 {
	return (playerIconDim.Y+windowSize.Y+2*edgePadding-(float32(cardIndex.X)*(cardDim.Y-overlap)+cardDim.Y))/2 +
		float32(cardIndex.Y)*(cardDim.Y-overlap)
}

// Given a card object, populates it with its positioning values and sets its position on-screen for the player hand view
func SetCardPositionHand(c *card.Card, indexInSuit int, suitCounts []int, u *uistate.UIState) {
	suitCount := float32(suitCounts[c.GetSuit()])
	heightScaler := float32(4 - c.GetSuit())
	diff := suitCount*(u.Padding+u.CardDim.X) - (u.WindowSize.X - u.Padding)
	x := u.Padding + float32(indexInSuit)*(u.Padding+u.CardDim.X)
	if diff > 0 && indexInSuit > 0 {
		x -= diff * float32(indexInSuit) / (suitCount - 1)
	}
	y := u.WindowSize.Y - heightScaler*(u.CardDim.Y+u.Padding) - u.BottomPadding
	xyVec := coords.MakeVec(x, y)
	pos := coords.MakePosition(xyVec, xyVec, u.CardDim)
	c.SetPos(pos)
	c.Move(xyVec, u.CardDim, u.Eng)
}
