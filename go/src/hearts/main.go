// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"sort"
	"time"

	"hearts/direction"
	"hearts/img/reposition"
	"hearts/img/resize"
	"hearts/img/staticimg"
	"hearts/img/texture"
	"hearts/logic/card"
	"hearts/logic/table"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
)

const (
	numPlayers    = 4
	cardSize      = 35
	cardWidth     = float32(cardSize)
	cardHeight    = float32(cardSize)
	topPadding    = float32(7)
	bottomPadding = float32(5)
)

var (
	startTime      = time.Now()
	eng            = glsprite.Engine()
	scene          *sprite.Node
	cards          []*card.Card
	backgroundImgs []*staticimg.StaticImg
	emptySuitImgs  []*staticimg.StaticImg
	dropTargets    []*staticimg.StaticImg
	buttons        []*staticimg.StaticImg
	curCard        *card.Card
	// lastMouseXY is in Px: divide by pixelsPerPt to get Pt
	lastMouseXY = []float32{-1, -1}
	// windowSize is in Pt
	windowSize  = []float32{-1, -1}
	pixelsPerPt float32
	padding     = float32(5)
	dir         direction.Direction
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
				oldWidth := windowSize[0]
				oldHeight := windowSize[1]
				updateWindowSize(sz)
				updateImgPositions(oldWidth, oldHeight)
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
	windowSize[0] = float32(sz.WidthPt)
	windowSize[1] = float32(sz.HeightPt)
	pixelsPerPt = float32(sz.WidthPx) / windowSize[0]
}

func updateImgPositions(oldWidth, oldHeight float32) {
	if windowExists(oldWidth, oldHeight) {
		padding = padding * windowSize[0] / oldWidth
	}
	resize.AdjustImgs(oldWidth, oldHeight, cards, dropTargets, backgroundImgs, buttons, emptySuitImgs, windowSize, eng)
}

func windowExists(windowWidth, windowHeight float32) bool {
	return !(windowWidth < 0 || windowHeight < 0)
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
	withinXBounds := t.X/pixelsPerPt >= c.GetX() && t.X/pixelsPerPt <= c.GetWidth()+c.GetX()
	withinYBounds := t.Y/pixelsPerPt >= c.GetY() && t.Y/pixelsPerPt <= c.GetHeight()+c.GetY()
	return withinXBounds && withinYBounds
}

func touchingStaticImg(t touch.Event, s *staticimg.StaticImg) bool {
	withinXBounds := t.X/pixelsPerPt >= s.GetX() && t.X/pixelsPerPt <= s.GetWidth()+s.GetX()
	withinYBounds := t.Y/pixelsPerPt >= s.GetY() && t.Y/pixelsPerPt <= s.GetHeight()+s.GetY()
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
				reposition.ResetCardPosition(lastDroppedCard, cards, emptySuitImgs, padding, windowSize, eng)
			}
			oldY := c.GetInitialY()
			suit := c.GetSuit()
			newX := d.GetX()
			newY := d.GetY()
			width := c.GetWidth()
			height := c.GetHeight()
			curCard.Move(newX, newY, width, height, eng)
			d.SetCardHere(curCard)
			// realign suit the card just left
			reposition.RealignSuit(suit, oldY, cards, emptySuitImgs, padding, windowSize, eng)
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
			// specific to pass screen scenario: if any button is clicked, all cards on drop targets get passed
			passCards(t)
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
				reposition.ResetCardPosition(curCard, cards, emptySuitImgs, padding, windowSize, eng)
			}
		}
		// reset all buttons to 'unpressed' image, in case any had been clicked
		unpressButtons()
		curCard = nil
	}
	lastMouseXY[0] = t.X
	lastMouseXY[1] = t.Y
}

func onPaint(sz size.Event) {
	if scene == nil {
		loadPassScreen()
	}
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(startTime) * 60 / time.Second)
	eng.Render(scene, now, sz)
}

func loadPassScreen() {
	numSuits := 4
	numDropTargets := 3
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	t := table.InitializeGame(numPlayers)
	t.Deal()
	cards = t.GetPlayers()[0].GetHand()
	dropTargets = make([]*staticimg.StaticImg, 0)
	backgroundImgs = make([]*staticimg.StaticImg, 0)
	emptySuitImgs = make([]*staticimg.StaticImg, 0)
	buttons = make([]*staticimg.StaticImg, 0)
	sort.Sort(card.CardSorter(cards))
	clubCount := 0
	diamondCount := 0
	spadeCount := 0
	heartCount := 0
	for i := 0; i < len(cards); i++ {
		switch cards[i].GetSuit() {
		case card.Club:
			clubCount++
		case card.Diamond:
			diamondCount++
		case card.Spade:
			spadeCount++
		case card.Heart:
			heartCount++
		}
	}
	suitCounts := []int{clubCount, diamondCount, spadeCount, heartCount}
	texs := texture.LoadTextures(eng)
	// adding blue banner for croupier header
	headerImage := texs["blue.png"]
	headerX := float32(0)
	headerY := float32(0)
	headerWidth := windowSize[0]
	var headerHeight float32
	if 2*cardHeight < headerWidth/4 {
		headerHeight = 2 * cardHeight
	} else {
		headerHeight = headerWidth / 4
	}
	headerPos := card.MakePosition(headerX, headerY, headerX, headerY, headerWidth, headerHeight)
	header := texture.MakeImgWithoutAlt(headerImage, headerPos, eng, scene)
	backgroundImgs = append(backgroundImgs, header)
	// adding croupier name on top of banner
	headerTextImage := texs["croupierName.png"]
	var headerTextWidth float32
	var headerTextHeight float32
	if headerHeight-topPadding > headerWidth/6 {
		headerTextWidth = headerWidth / 2
		headerTextHeight = headerTextWidth / 3
	} else {
		headerTextHeight = 2 * headerHeight / 3
		headerTextWidth = headerTextHeight * 3
	}
	headerTextX := headerX + (headerWidth-headerTextWidth)/2
	headerTextY := headerY + (headerHeight-headerTextHeight+topPadding)/2
	headerTextPos := card.MakePosition(headerTextX, headerTextY, headerTextX, headerTextY, headerTextWidth, headerTextHeight)
	headerText := texture.MakeImgWithoutAlt(headerTextImage, headerTextPos, eng, scene)
	backgroundImgs = append(backgroundImgs, headerText)
	// adding blue background banner for drop targets
	topOfHand := windowSize[1] - 5*(cardHeight+padding) - (2 * padding / 5) - bottomPadding
	passBannerImage := texs["blue.png"]
	passBannerX := float32(0)
	passBannerY := topOfHand - (2 * padding)
	passBannerWidth := windowSize[0]
	passBannerHeight := cardHeight + (4 * padding / 5)
	passBannerPos := card.MakePosition(passBannerX, passBannerY, passBannerX, passBannerY, passBannerWidth, passBannerHeight)
	passBanner := texture.MakeImgWithoutAlt(passBannerImage, passBannerPos, eng, scene)
	backgroundImgs = append(backgroundImgs, passBanner)
	// adding drop targets
	dropTargetImage := texs["white.png"]
	dropTargetWidth := cardWidth
	dropTargetHeight := cardHeight
	dropTargetY := passBannerY + (2 * padding / 5)
	for i := 0; i < numDropTargets; i++ {
		dropTargetX := windowSize[0]/2 - (dropTargetWidth+float32(numDropTargets)*(padding+dropTargetWidth))/2 + float32(i)*(padding+dropTargetWidth)
		dropTargetPos := card.MakePosition(dropTargetX, dropTargetY, dropTargetX, dropTargetY, dropTargetWidth, dropTargetHeight)
		newTarget := texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
		dropTargets = append(dropTargets, newTarget)
	}
	// adding pass button
	pressedImg := texs["passPressed.png"]
	unpressedImg := texs["passUnpressed.png"]
	buttonWidth := cardWidth
	buttonHeight := cardHeight / 2
	buttonX := windowSize[0]/2 + (float32(numDropTargets)*(padding+buttonWidth)-buttonWidth)/2
	buttonY := passBannerY + (2 * padding / 5)
	buttonPos := card.MakePosition(buttonX, buttonY, buttonX, buttonY, buttonWidth, buttonHeight)
	button := texture.MakeImgWithAlt(unpressedImg, pressedImg, buttonPos, true, eng, scene)
	buttons = append(buttons, button)
	// adding arrow below pass button
	var arrow *staticimg.StaticImg
	if dir == direction.Right {
		arrowImage := texs["rightArrow.png"]
		arrowWidth := cardWidth
		arrowHeight := cardHeight / 2
		arrowX := windowSize[0]/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardHeight/2
		arrowPos := card.MakePosition(arrowX, arrowY, arrowX, arrowY, arrowWidth, arrowHeight)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	} else if dir == direction.Left {
		arrowImage := texs["leftArrow.png"]
		arrowWidth := cardWidth
		arrowHeight := cardHeight / 2
		arrowX := windowSize[0]/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardHeight/2
		arrowPos := card.MakePosition(arrowX, arrowY, arrowX, arrowY, arrowWidth, arrowHeight)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	} else if dir == direction.Across {
		arrowImage := texs["acrossArrow.png"]
		arrowWidth := cardWidth / 4
		arrowHeight := cardHeight / 2
		arrowX := windowSize[0]/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardHeight/2
		arrowPos := card.MakePosition(arrowX, arrowY, arrowX, arrowY, arrowWidth, arrowHeight)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	}
	backgroundImgs = append(backgroundImgs, arrow)
	// adding gray background banners for each suit
	suitBannerImage := texs["gray.jpeg"]
	suitBannerX := float32(0)
	suitBannerWidth := windowSize[0]
	suitBannerHeight := cardHeight + (4 * padding / 5)
	for i := 0; i < numSuits; i++ {
		suitBannerY := windowSize[1] - float32(i+1)*(cardHeight+padding) - (2 * padding / 5) - bottomPadding
		suitBannerPos := card.MakePosition(suitBannerX, suitBannerY, suitBannerX, suitBannerY, suitBannerWidth, suitBannerHeight)
		suitBanner := texture.MakeImgWithoutAlt(suitBannerImage, suitBannerPos, eng, scene)
		backgroundImgs = append(backgroundImgs, suitBanner)
	}
	// adding suit image to any empty suit in hand
	for i, c := range suitCounts {
		var texKey string
		switch i {
		case 0:
			texKey = "Club.png"
		case 1:
			texKey = "Diamond.png"
		case 2:
			texKey = "Spade.png"
		case 3:
			texKey = "Heart.png"
		}
		suitIconImage := texs[texKey]
		suitIconAlt := texs["gray.png"]
		suitIconX := windowSize[0]/2 - cardWidth/3
		suitIconY := windowSize[1] - float32(4-i)*(cardHeight+padding) + cardHeight/6 - bottomPadding
		suitIconWidth := 2 * cardWidth / 3
		suitIconHeight := 2 * cardHeight / 3
		display := c == 0
		suitIconPos := card.MakePosition(suitIconX, suitIconY, suitIconX, suitIconY, suitIconWidth, suitIconHeight)
		suitIcon := texture.MakeImgWithAlt(suitIconImage, suitIconAlt, suitIconPos, display, eng, scene)
		emptySuitImgs = append(emptySuitImgs, suitIcon)
	}
	// adding clubs
	for i := 0; i < clubCount; i++ {
		numInSuit := i
		texture.PopulateCardImage(cards[i],
			texs,
			numInSuit,
			clubCount,
			diamondCount,
			spadeCount,
			heartCount,
			cardWidth,
			cardHeight,
			padding,
			bottomPadding,
			windowSize,
			eng,
			scene)
	}
	// adding diamonds
	for i := clubCount; i < clubCount+diamondCount; i++ {
		numInSuit := i - clubCount
		texture.PopulateCardImage(cards[i],
			texs,
			numInSuit,
			clubCount,
			diamondCount,
			spadeCount,
			heartCount,
			cardWidth,
			cardHeight,
			padding,
			bottomPadding,
			windowSize,
			eng,
			scene)
	}
	// adding spades
	for i := clubCount + diamondCount; i < clubCount+diamondCount+spadeCount; i++ {
		numInSuit := i - clubCount - diamondCount
		texture.PopulateCardImage(cards[i],
			texs,
			numInSuit,
			clubCount,
			diamondCount,
			spadeCount,
			heartCount,
			cardWidth,
			cardHeight,
			padding,
			bottomPadding,
			windowSize,
			eng,
			scene)
	}
	// adding hearts
	for i := clubCount + diamondCount + spadeCount; i < clubCount+diamondCount+spadeCount+heartCount; i++ {
		numInSuit := i - clubCount - diamondCount - spadeCount
		texture.PopulateCardImage(cards[i],
			texs,
			numInSuit,
			clubCount,
			diamondCount,
			spadeCount,
			heartCount,
			cardWidth,
			cardHeight,
			padding,
			bottomPadding,
			windowSize,
			eng,
			scene)
	}
}
