// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// reposition handles changing image positioning on the screen

package reposition

import (
	"hearts/img/coords"
	"hearts/img/direction"
	"hearts/img/staticimg"
	"hearts/img/texture"
	"hearts/img/uistate"
	"hearts/logic/card"
	"hearts/logic/player"

	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
)

const (
	// animationFrameCount is the number of frames it will take to complete any animation
	animationFrameCount = 60
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

func SetTableDropColors(u *uistate.UIState) {
	blueTargetIndex := u.CurTable.WhoseTurn()
	for i, d := range u.DropTargets {
		if i == blueTargetIndex {
			u.Eng.SetSubTex(d.GetNode(), d.GetAlt())
			d.SetDisplayingImage(false)
		} else {
			u.Eng.SetSubTex(d.GetNode(), d.GetImage())
			d.SetDisplayingImage(true)
		}
	}
}

func SetSplitDropColors(u *uistate.UIState) {
	blueTargetIndex := u.CurTable.WhoseTurn()
	for i, d := range u.DropTargets {
		if (u.CurPlayerIndex+i)%u.NumPlayers == blueTargetIndex {
			u.Eng.SetSubTex(d.GetNode(), d.GetAlt())
			d.SetDisplayingImage(false)
		} else {
			u.Eng.SetSubTex(d.GetNode(), d.GetImage())
			d.SetDisplayingImage(true)
		}
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

// Animation for the 'pass' action, when app is in the table view
func AnimateTableCardPass(cards []*card.Card, toPlayer int, u *uistate.UIState) {
	for cardNum, animCard := range cards {
		cardDim := animCard.GetDimensions()
		dropTargetXY := u.DropTargets[toPlayer].GetCurrent()
		dropTargetDim := u.DropTargets[toPlayer].GetDimensions()
		targetCenter := dropTargetXY.PlusVec(dropTargetDim.DividedBy(2))
		xPlayerBlockSize := 2*u.PlayerIconDim.X + u.Padding
		yPlayerBlockSize := u.TopPadding + 2*u.TableCardDim.Y + 3*u.Padding + u.PlayerIconDim.Y
		blockEdge := targetCenter.MinusVec(cardDim.Times(1.5).Plus(u.Padding))
		var destination *coords.Vec
		switch toPlayer {
		case 0:
			destination = coords.MakeVec(
				blockEdge.X+float32(cardNum)*(u.Padding+cardDim.X),
				u.WindowSize.Y-yPlayerBlockSize-u.TableCardDim.Y)
		case 1:
			destination = coords.MakeVec(
				xPlayerBlockSize,
				blockEdge.Y+float32(cardNum)*(u.Padding+cardDim.Y))
		case 2:
			destination = coords.MakeVec(
				blockEdge.X+float32(cardNum)*(u.Padding+cardDim.X),
				yPlayerBlockSize)
		case 3:
			destination = coords.MakeVec(
				u.WindowSize.X-xPlayerBlockSize-u.TableCardDim.X,
				blockEdge.Y+float32(cardNum)*(u.Padding+cardDim.Y))
		}
		if cardNum < len(cards)-1 {
			animateCardNoChannel(animCard, destination, cardDim, u)
		} else {
			c := make(chan bool)
			animateCardMovement(c, animCard, destination, cardDim, u)
			<-c
		}
	}
}

// Animation for the 'take' action, when app is in the table view
func AnimateTableCardTake(cards []*card.Card, p *player.Player, u *uistate.UIState) {
	for cardNum, animCard := range cards {
		destinationPos := p.GetPassedFrom()[cardNum].GetInitial()
		if cardNum < len(cards)-1 {
			animateCardNoChannel(animCard, destinationPos, animCard.GetDimensions(), u)
		} else {
			c := make(chan bool)
			animateCardMovement(c, animCard, destinationPos, animCard.GetDimensions(), u)
			<-c
		}
	}
}

// Animation for the 'play' action, when app is in the table view
func AnimateTableCardPlay(animCard *card.Card, playerInt int, u *uistate.UIState) {
	destination := u.DropTargets[playerInt]
	destinationPos := destination.GetCurrent()
	destinationDim := destination.GetDimensions()
	ch := make(chan bool)
	animateCardMovement(ch, animCard, destinationPos, destinationDim, u)
	<-ch
	animCard.SetFrontDisplay(u.Eng)
}

// Animation for the 'pass' action, when app is in the hand view
func AnimateHandCardPass(ch chan bool, animImages []*staticimg.StaticImg, animCards []*card.Card, u *uistate.UIState) {
	for _, i := range animImages {
		dims := i.GetDimensions()
		to := coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y-u.WindowSize.Y)
		AnimateImageNoChannel(i, to, dims, u)
	}
	for i, c := range animCards {
		dims := c.GetDimensions()
		to := coords.MakeVec(c.GetCurrent().X, c.GetCurrent().Y-u.WindowSize.Y)
		if i < len(animCards)-1 {
			animateCardNoChannel(c, to, dims, u)
		} else {
			animateCardMovement(ch, c, to, dims, u)
		}
	}
}

// Animation for the 'take' action, when app is in the hand view
func AnimateHandCardTake(ch chan bool, animImages []*staticimg.StaticImg, u *uistate.UIState) {
	for i, image := range animImages {
		destination := coords.MakeVec(image.GetCurrent().X, image.GetCurrent().Y-u.WindowSize.Y)
		if i < len(animImages)-1 {
			AnimateImageNoChannel(image, destination, image.GetDimensions(), u)
		} else {
			animateImageMovement(ch, image, destination, image.GetDimensions(), u)
		}
	}
}

// Animation to bring in the take slot
func AnimateInTake(u *uistate.UIState) {
	imgs := append(u.Other, u.DropTargets...)
	passedCards := u.CurTable.GetPlayers()[u.CurPlayerIndex].GetPassedTo()
	for _, i := range imgs {
		dims := i.GetDimensions()
		var to *coords.Vec
		if passedCards == nil {
			to = coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y+u.WindowSize.Y)
		} else {
			to = coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y+u.WindowSize.Y)
		}
		AnimateImageNoChannel(i, to, dims, u)
	}
	for _, c := range passedCards {
		dims := c.GetDimensions()
		to := coords.MakeVec(c.GetCurrent().X, c.GetCurrent().Y+u.WindowSize.Y)
		animateCardNoChannel(c, to, dims, u)
	}
}

// Animation for the 'play' action, when app is in the hand view
func AnimateHandCardPlay(ch chan bool, animCard *card.Card, u *uistate.UIState) {
	imgs := []*staticimg.StaticImg{u.BackgroundImgs[0], u.DropTargets[0]}
	for _, i := range imgs {
		dims := i.GetDimensions()
		to := coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y-u.WindowSize.Y)
		AnimateImageNoChannel(i, to, dims, u)
	}
	to := coords.MakeVec(animCard.GetCurrent().X, animCard.GetCurrent().Y-u.WindowSize.Y)
	animateCardMovement(ch, animCard, to, animCard.GetDimensions(), u)
}

// Animation to bring in the play slot when app is in the hand view and it is the player's turn
func AnimateInPlay(u *uistate.UIState) {
	imgs := []*staticimg.StaticImg{u.BackgroundImgs[0], u.DropTargets[0]}
	for _, i := range imgs {
		dims := i.GetDimensions()
		to := coords.MakeVec(i.GetCurrent().X, i.GetCurrent().Y+u.WindowSize.Y/3+u.TopPadding)
		AnimateImageNoChannel(i, to, dims, u)
	}
}

// Animate playing of a card in the split view
// Should not be called when the player whose hand is being displayed is the player of the card
func AnimateSplitCardPlay(c *card.Card, player int, u *uistate.UIState) {
	dropTarget := u.DropTargets[(u.CurPlayerIndex+player)%u.NumPlayers]
	toPos := dropTarget.GetCurrent()
	toDim := dropTarget.GetDimensions()
	texture.PopulateCardImage(c, u.Texs, u.Eng, u.Scene)
	switch player {
	case (u.CurPlayerIndex + 1) % u.NumPlayers:
		c.Move(coords.MakeVec(-toDim.X, 0), toDim, u.Eng)
	case (u.CurPlayerIndex + 2) % u.NumPlayers:
		c.Move(coords.MakeVec((u.WindowSize.X-toDim.X)/2, -toDim.Y), toDim, u.Eng)
	case (u.CurPlayerIndex + 3) % u.NumPlayers:
		c.Move(coords.MakeVec(u.WindowSize.X, 0), toDim, u.Eng)
	}
	ch := make(chan bool)
	animateCardMovement(ch, c, toPos, toDim, u)
	<-ch
}

func AnimateInSplit(u *uistate.UIState) {
	topOfBanner := u.WindowSize.Y - 4*u.CardDim.Y - 5*u.Padding - u.BottomPadding - 40
	tableImgs := make([]*staticimg.StaticImg, 0)
	bannerImgs := make([]*staticimg.StaticImg, 0)
	cards := make([]*card.Card, 0)
	bannerImgs = append(bannerImgs, u.Other...)
	bannerImgs = append(bannerImgs, u.Buttons[0])
	tableImgs = append(tableImgs, u.DropTargets...)
	tableImgs = append(tableImgs, u.BackgroundImgs[:u.NumPlayers]...)
	cards = append(cards, u.TableCards...)
	for _, card := range cards {
		from := card.GetCurrent()
		to := coords.MakeVec(from.X, from.Y+topOfBanner)
		animateCardNoChannel(card, to, card.GetDimensions(), u)
	}
	for _, img := range tableImgs {
		from := img.GetCurrent()
		to := coords.MakeVec(from.X, from.Y+topOfBanner)
		AnimateImageNoChannel(img, to, img.GetDimensions(), u)
	}
	for i, img := range bannerImgs {
		from := img.GetCurrent()
		to := coords.MakeVec(from.X, from.Y+topOfBanner-10)
		if i == 0 {
			oldDim := img.GetDimensions()
			newDim := coords.MakeVec(oldDim.X, oldDim.Y-10)
			newTo := coords.MakeVec(to.X, to.Y+10)
			AnimateImageNoChannel(img, newTo, newDim, u)
		} else {
			AnimateImageNoChannel(img, to, img.GetDimensions(), u)
		}
	}
}

func AnimateOutSplit(ch chan bool, u *uistate.UIState) {
	topOfBanner := u.WindowSize.Y - 4*u.CardDim.Y - 5*u.Padding - u.BottomPadding - 40
	tableImgs := make([]*staticimg.StaticImg, 0)
	bannerImgs := make([]*staticimg.StaticImg, 0)
	cards := make([]*card.Card, 0)
	bannerImgs = append(bannerImgs, u.Other...)
	bannerImgs = append(bannerImgs, u.Buttons[0])
	tableImgs = append(tableImgs, u.DropTargets...)
	tableImgs = append(tableImgs, u.BackgroundImgs[:u.NumPlayers]...)
	cards = append(cards, u.TableCards...)
	for _, card := range cards {
		from := card.GetCurrent()
		to := coords.MakeVec(from.X, from.Y-topOfBanner)
		animateCardNoChannel(card, to, card.GetDimensions(), u)
	}
	for _, img := range tableImgs {
		from := img.GetCurrent()
		to := coords.MakeVec(from.X, from.Y-topOfBanner)
		AnimateImageNoChannel(img, to, img.GetDimensions(), u)
	}
	for i, img := range bannerImgs {
		from := img.GetCurrent()
		to := coords.MakeVec(from.X, from.Y-topOfBanner+10)
		if i == 0 && i < len(bannerImgs)-1 {
			oldDim := img.GetDimensions()
			newDim := coords.MakeVec(oldDim.X, oldDim.Y+10)
			newTo := coords.MakeVec(to.X, to.Y-10)
			AnimateImageNoChannel(img, newTo, newDim, u)
		} else if i < len(bannerImgs)-1 {
			AnimateImageNoChannel(img, to, img.GetDimensions(), u)
		} else {
			animateImageMovement(ch, img, to, img.GetDimensions(), u)
		}
	}
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
func AnimateTableCardTakeTrick(cards []*card.Card, dir direction.Direction, u *uistate.UIState) {
	for i, animCard := range cards {
		destination := determineDestination(animCard, dir, u.WindowSize)
		if i < len(cards)-1 {
			animateCardNoChannel(animCard, destination, animCard.GetDimensions(), u)
		} else {
			c := make(chan bool)
			animateCardMovement(c, animCard, destination, animCard.GetDimensions(), u)
			<-c
		}
	}
}

func animateImageMovement(c chan bool, animImage *staticimg.StaticImg, endPos, endDim *coords.Vec, u *uistate.UIState) {
	node := animImage.GetNode()
	startPos := animImage.GetCurrent()
	startDim := animImage.GetDimensions()
	iteration := 0
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if iteration < animationFrameCount {
			curXY := animImage.GetCurrent()
			curDim := animImage.GetDimensions()
			XYStep := endPos.MinusVec(startPos).DividedBy(animationFrameCount)
			dimStep := endDim.MinusVec(startDim).DividedBy(animationFrameCount)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animImage.Move(newVec, dimVec, eng)
		} else if iteration == animationFrameCount {
			animImage.Move(endPos, endDim, eng)
			c <- true
		}
	})
}

func AnimateImageNoChannel(animImage *staticimg.StaticImg, endPos, endDim *coords.Vec, u *uistate.UIState) {
	node := animImage.GetNode()
	startPos := animImage.GetCurrent()
	startDim := animImage.GetDimensions()
	iteration := 0
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if iteration < animationFrameCount {
			curXY := animImage.GetCurrent()
			curDim := animImage.GetDimensions()
			XYStep := endPos.MinusVec(startPos).DividedBy(animationFrameCount)
			dimStep := endDim.MinusVec(startDim).DividedBy(animationFrameCount)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animImage.Move(newVec, dimVec, eng)
		} else if iteration == animationFrameCount {
			animImage.Move(endPos, endDim, eng)
		}
	})
}

func animateCardMovement(c chan bool, animCard *card.Card, endPos, endDim *coords.Vec, u *uistate.UIState) {
	node := animCard.GetNode()
	startPos := animCard.GetCurrent()
	startDim := animCard.GetDimensions()
	iteration := 0
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if iteration < animationFrameCount {
			curXY := animCard.GetCurrent()
			curDim := animCard.GetDimensions()
			XYStep := endPos.MinusVec(startPos).DividedBy(animationFrameCount)
			dimStep := endDim.MinusVec(startDim).DividedBy(animationFrameCount)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animCard.Move(newVec, dimVec, eng)
		} else if iteration == animationFrameCount {
			animCard.Move(endPos, endDim, eng)
			c <- true
		}
	})
}

func animateCardNoChannel(animCard *card.Card, endPos, endDim *coords.Vec, u *uistate.UIState) {
	node := animCard.GetNode()
	startPos := animCard.GetCurrent()
	startDim := animCard.GetDimensions()
	iteration := 0
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		iteration++
		if iteration < animationFrameCount {
			curXY := animCard.GetCurrent()
			curDim := animCard.GetDimensions()
			XYStep := endPos.MinusVec(startPos).DividedBy(animationFrameCount)
			dimStep := endDim.MinusVec(startDim).DividedBy(animationFrameCount)
			newVec := curXY.PlusVec(XYStep)
			dimVec := curDim.PlusVec(dimStep)
			animCard.Move(newVec, dimVec, eng)
		} else if iteration == animationFrameCount {
			animCard.Move(endPos, endDim, eng)
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
	pos := cardPositionTable(playerIndex, cardIndex, u)
	c.SetInitial(pos)
	c.Move(pos, u.TableCardDim, u.Eng)
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
	pos := coords.MakeVec(x, y)
	c.SetInitial(pos)
	c.Move(pos, u.CardDim, u.Eng)
}
