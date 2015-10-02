// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"sort"

	"hearts/direction"
	"hearts/img/reposition"
	"hearts/img/staticimg"
	"hearts/img/texture"
	"hearts/logic/card"
	"hearts/logic/table"

	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
)

func loadOpeningView(t *table.Table) {
	view = Opening
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	texs := texture.LoadTextures(eng)
	buttonX := (windowSize.X - cardDim.X) / 2
	tableButtonY := (windowSize.Y - 2*cardDim.Y - padding) / 2
	passButtonY := (windowSize.Y-2*cardDim.Y-padding)/2 + cardDim.Y + padding
	tableButtonXY := card.MakeVec(buttonX, tableButtonY)
	passButtonXY := card.MakeVec(buttonX, passButtonY)
	tableButtonPos := card.MakePosition(tableButtonXY, tableButtonXY, cardDim)
	passButtonPos := card.MakePosition(passButtonXY, passButtonXY, cardDim)
	tableButtonImage := texs["BakuSquare.png"]
	passButtonImage := texs["Clubs-2.png"]
	tableButton := texture.MakeImgWithAlt(tableButtonImage, tableButtonImage, tableButtonPos, true, eng, scene)
	passButton := texture.MakeImgWithAlt(passButtonImage, passButtonImage, passButtonPos, true, eng, scene)
	buttons = append(buttons, tableButton)
	buttons = append(buttons, passButton)
}

func loadTableView(t *table.Table) {
	view = Table
	cards = make([]*card.Card, 0)
	backgroundImgs = make([]*staticimg.StaticImg, 0)
	emptySuitImgs = make([]*staticimg.StaticImg, 0)
	dropTargets = make([]*staticimg.StaticImg, 0)
	buttons = make([]*staticimg.StaticImg, 0)
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	texs := texture.LoadTextures(eng)
	// adding four drop targets for trick
	dropTargetImage := texs["trickDrop.png"]
	dropTargetDimensions := cardDim
	dropTargetX := (windowSize.X - cardDim.X) / 2
	var dropTargetY float32
	if windowSize.X < windowSize.Y {
		dropTargetY = windowSize.Y/2 + cardDim.Y/2 + padding
	} else {
		dropTargetY = windowSize.Y/2 + padding
	}
	dropTargetXY := card.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos := card.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget := texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
	dropTargets = append(dropTargets, dropTarget)
	// second drop target
	dropTargetY = (windowSize.Y - cardDim.Y) / 2
	if windowSize.X < windowSize.Y {
		dropTargetX = windowSize.X/2 - cardDim.X - padding
	} else {
		dropTargetX = windowSize.X/2 - 3*cardDim.X/2 - padding
	}
	dropTargetXY = card.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = card.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
	dropTargets = append(dropTargets, dropTarget)
	// third drop target
	dropTargetX = (windowSize.X - cardDim.X) / 2
	if windowSize.X < windowSize.Y {
		dropTargetY = windowSize.Y/2 - 3*cardDim.Y/2 - padding
	} else {
		dropTargetY = windowSize.Y/2 - padding - cardDim.Y
	}
	dropTargetXY = card.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = card.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
	dropTargets = append(dropTargets, dropTarget)
	// fourth drop target
	dropTargetY = (windowSize.Y - cardDim.Y) / 2
	if windowSize.X < windowSize.Y {
		dropTargetX = windowSize.X/2 + padding
	} else {
		dropTargetX = windowSize.X/2 + cardDim.X/2 + padding
	}
	dropTargetXY = card.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = card.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
	dropTargets = append(dropTargets, dropTarget)
	overlap := 3 * tableCardDim.X / 4
	// adding 4 player icons and device icons
	playerIconImage := texs["player0.jpeg"]
	playerIconDimensions := cardDim
	playerIconX := (windowSize.X-cardDim.X)/2
	playerIconY := windowSize.Y-tableCardDim.Y-bottomPadding-padding-cardDim.Y
	playerIconXY := card.MakeVec(playerIconX, playerIconY)
	playerIconPos := card.MakePosition(playerIconXY, playerIconXY, playerIconDimensions)
	playerIcon := texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, eng, scene)
	backgroundImgs = append(backgroundImgs, playerIcon)
	// player 0's device icon
	deviceIconImage := texs["phoneIcon.png"]
	deviceIconDimensions := card.MakeVec(playerIconDimensions.X/4, playerIconDimensions.Y/4)
	addPlayerDeviceIcon(deviceIconImage, deviceIconDimensions, playerIconXY, playerIconDimensions)
	// player 1's icon
	playerIconImage = texs["player1.jpeg"]
	playerIconX = bottomPadding
	playerIconY = (windowSize.Y+2*bottomPadding+cardDim.Y-(float32(len(t.GetPlayers()[1].GetHand()))*(tableCardDim.Y-overlap)+tableCardDim.Y))/2-cardDim.Y-padding
	playerIconXY = card.MakeVec(playerIconX, playerIconY)
	playerIconPos = card.MakePosition(playerIconXY, playerIconXY, playerIconDimensions)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, eng, scene)
	backgroundImgs = append(backgroundImgs, playerIcon)
    // player 1's device icon
    deviceIconImage = texs["tabletIcon.png"]
	addPlayerDeviceIcon(deviceIconImage, deviceIconDimensions, playerIconXY, playerIconDimensions)
	// player 2's icon
	playerIconImage = texs["player2.jpeg"]
	playerIconX = (windowSize.X - cardDim.X) / 2
	playerIconY = topPadding + tableCardDim.Y + padding
	playerIconXY = card.MakeVec(playerIconX, playerIconY)
	playerIconPos = card.MakePosition(playerIconXY, playerIconXY, playerIconDimensions)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, eng, scene)
	backgroundImgs = append(backgroundImgs, playerIcon)
	// player 2's device icon
    deviceIconImage = texs["watchIcon.png"]
	addPlayerDeviceIcon(deviceIconImage, deviceIconDimensions, playerIconXY, playerIconDimensions)
	// player 3's icon
	playerIconImage = texs["player3.jpeg"]
	playerIconX = windowSize.X - bottomPadding - cardDim.X
	playerIconY = (windowSize.Y+2*bottomPadding+cardDim.Y-(float32(len(t.GetPlayers()[3].GetHand()))*(tableCardDim.Y-overlap)+tableCardDim.Y))/2 - cardDim.Y - padding
	playerIconXY = card.MakeVec(playerIconX, playerIconY)
	playerIconPos = card.MakePosition(playerIconXY, playerIconXY, playerIconDimensions)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, eng, scene)
	backgroundImgs = append(backgroundImgs, playerIcon)
	// player 3's device icon
    deviceIconImage = texs["laptopIcon.png"]
	addPlayerDeviceIcon(deviceIconImage, deviceIconDimensions, playerIconXY, playerIconDimensions)
	// adding cards
	for _, p := range t.GetPlayers() {
		hand := p.GetHand()
		for i, c := range hand {
			texture.PopulateCardImage(c, texs, eng, scene)
			cardIndex := card.MakeVec(float32(len(hand)), float32(i))
			paddingVec := card.MakeVec(topPadding, bottomPadding)
			reposition.SetCardPositionTable(c, p.GetPlayerIndex(), cardIndex, paddingVec, windowSize, tableCardDim, cardScaler, overlap, eng, scene)
			eng.SetSubTex(c.GetNode(), c.GetBack())
			cards = append(cards, c)
		}
	}
}

func addPlayerDeviceIcon(deviceIconImage sprite.SubTex, deviceIconDimensions card.Vec, playerIconXY card.Vec, playerIconDimensions card.Vec) {
	deviceIconX := playerIconXY.X+playerIconDimensions.X-deviceIconDimensions.X/2
	deviceIconY := playerIconXY.Y+playerIconDimensions.Y-deviceIconDimensions.Y/2
	deviceIconXY := card.MakeVec(deviceIconX, deviceIconY)
	deviceIconPos := card.MakePosition(deviceIconXY, deviceIconXY, deviceIconDimensions)
	deviceIcon := texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, eng, scene)
	backgroundImgs = append(backgroundImgs, deviceIcon)
}

func loadPassView(t *table.Table) {
	view = Pass
	cards = make([]*card.Card, 0)
	backgroundImgs = make([]*staticimg.StaticImg, 0)
	emptySuitImgs = make([]*staticimg.StaticImg, 0)
	dropTargets = make([]*staticimg.StaticImg, 0)
	buttons = make([]*staticimg.StaticImg, 0)
	numSuits := 4
	numDropTargets := 3
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	cards = t.GetPlayers()[1].GetHand()
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
	headerXY := card.MakeVec(0, 0)
	headerWidth := windowSize.X
	var headerHeight float32
	if 2*cardDim.Y < headerWidth/4 {
		headerHeight = 2 * cardDim.Y
	} else {
		headerHeight = headerWidth / 4
	}
	headerDimensions := card.MakeVec(headerWidth, headerHeight)
	headerPos := card.MakePosition(headerXY, headerXY, headerDimensions)
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
	headerTextX := headerXY.X + (headerWidth-headerTextWidth)/2
	headerTextY := headerXY.Y + (headerHeight-headerTextHeight+topPadding)/2
	headerTextXY := card.MakeVec(headerTextX, headerTextY)
	headerTextDimensions := card.MakeVec(headerTextWidth, headerTextHeight)
	headerTextPos := card.MakePosition(headerTextXY, headerTextXY, headerTextDimensions)
	headerText := texture.MakeImgWithoutAlt(headerTextImage, headerTextPos, eng, scene)
	backgroundImgs = append(backgroundImgs, headerText)
	// adding blue background banner for drop targets
	topOfHand := windowSize.Y - 5*(cardDim.Y+padding) - (2 * padding / 5) - bottomPadding
	passBannerImage := texs["blue.png"]
	passBannerX := float32(0)
	passBannerY := topOfHand - (2 * padding)
	passBannerWidth := windowSize.X
	passBannerHeight := cardDim.Y + (4 * padding / 5)
	passBannerXY := card.MakeVec(passBannerX, passBannerY)
	passBannerDimensions := card.MakeVec(passBannerWidth, passBannerHeight)
	passBannerPos := card.MakePosition(passBannerXY, passBannerXY, passBannerDimensions)
	passBanner := texture.MakeImgWithoutAlt(passBannerImage, passBannerPos, eng, scene)
	backgroundImgs = append(backgroundImgs, passBanner)
	// adding drop targets
	dropTargetImage := texs["white.png"]
	dropTargetDimensions := cardDim
	dropTargetY := passBannerY + (2 * padding / 5)
	for i := 0; i < numDropTargets; i++ {
		dropTargetX := windowSize.X/2 - (dropTargetDimensions.X+float32(numDropTargets)*(padding+dropTargetDimensions.X))/2 + float32(i)*(padding+dropTargetDimensions.X)
		dropTargetXY := card.MakeVec(dropTargetX, dropTargetY)
		dropTargetPos := card.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
		newTarget := texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, eng, scene)
		dropTargets = append(dropTargets, newTarget)
	}
	// adding pass button
	pressedImg := texs["passPressed.png"]
	unpressedImg := texs["passUnpressed.png"]
	buttonWidth := cardDim.X
	buttonHeight := cardDim.Y / 2
	buttonDimensions := card.MakeVec(buttonWidth, buttonHeight)
	buttonX := windowSize.X/2 + (float32(numDropTargets)*(padding+buttonWidth)-buttonWidth)/2
	buttonY := passBannerY + (2 * padding / 5)
	buttonXY := card.MakeVec(buttonX, buttonY)
	buttonPos := card.MakePosition(buttonXY, buttonXY, buttonDimensions)
	button := texture.MakeImgWithAlt(unpressedImg, pressedImg, buttonPos, true, eng, scene)
	buttons = append(buttons, button)
	// adding arrow below pass button
	var arrow *staticimg.StaticImg
	if dir == direction.Right {
		arrowImage := texs["rightArrow.png"]
		arrowWidth := cardDim.X
		arrowHeight := cardDim.Y / 2
		arrowX := windowSize.X/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardDim.Y/2
		arrowXY := card.MakeVec(arrowX, arrowY)
		arrowDimensions := card.MakeVec(arrowWidth, arrowHeight)
		arrowPos := card.MakePosition(arrowXY, arrowXY, arrowDimensions)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	} else if dir == direction.Left {
		arrowImage := texs["leftArrow.png"]
		arrowWidth := cardDim.X
		arrowHeight := cardDim.Y / 2
		arrowX := windowSize.X/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardDim.Y/2
		arrowXY := card.MakeVec(arrowX, arrowY)
		arrowDimensions := card.MakeVec(arrowWidth, arrowHeight)
		arrowPos := card.MakePosition(arrowXY, arrowXY, arrowDimensions)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	} else if dir == direction.Across {
		arrowImage := texs["acrossArrow.png"]
		arrowWidth := cardDim.X / 4
		arrowHeight := cardDim.Y / 2
		arrowX := windowSize.X/2 + (float32(numDropTargets)*(padding+buttonWidth)-arrowWidth)/2
		arrowY := buttonY + cardDim.Y/2
		arrowXY := card.MakeVec(arrowX, arrowY)
		arrowDimensions := card.MakeVec(arrowWidth, arrowHeight)
		arrowPos := card.MakePosition(arrowXY, arrowXY, arrowDimensions)
		arrow = texture.MakeImgWithoutAlt(arrowImage, arrowPos, eng, scene)
	}
	backgroundImgs = append(backgroundImgs, arrow)
	// adding gray background banners for each suit
	suitBannerImage := texs["gray.jpeg"]
	suitBannerX := float32(0)
	suitBannerWidth := windowSize.X
	suitBannerHeight := cardDim.Y + (4 * padding / 5)
	suitBannerDimensions := card.MakeVec(suitBannerWidth, suitBannerHeight)
	for i := 0; i < numSuits; i++ {
		suitBannerY := windowSize.Y - float32(i+1)*(cardDim.Y+padding) - (2 * padding / 5) - bottomPadding
		suitBannerXY := card.MakeVec(suitBannerX, suitBannerY)
		suitBannerPos := card.MakePosition(suitBannerXY, suitBannerXY, suitBannerDimensions)
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
		suitIconX := windowSize.X/2 - cardDim.X/3
		suitIconY := windowSize.Y - float32(4-i)*(cardDim.Y+padding) + cardDim.Y/6 - bottomPadding
		suitIconWidth := 2 * cardDim.X / 3
		suitIconHeight := 2 * cardDim.Y / 3
		display := c == 0
		suitIconXY := card.MakeVec(suitIconX, suitIconY)
		suitIconDimensions := card.MakeVec(suitIconWidth, suitIconHeight)
		suitIconPos := card.MakePosition(suitIconXY, suitIconXY, suitIconDimensions)
		suitIcon := texture.MakeImgWithAlt(suitIconImage, suitIconAlt, suitIconPos, display, eng, scene)
		emptySuitImgs = append(emptySuitImgs, suitIcon)
	}
	paddingVec := card.MakeVec(padding, bottomPadding)
	// adding clubs
	for i := 0; i < clubCount; i++ {
		numInSuit := i
		texture.PopulateCardImage(cards[i], texs, eng, scene)
		reposition.SetCardPositionHand(cards[i], numInSuit, suitCounts, cardDim, paddingVec, windowSize, eng, scene)
	}
	// adding diamonds
	for i := clubCount; i < clubCount+diamondCount; i++ {
		numInSuit := i - clubCount
		texture.PopulateCardImage(cards[i], texs, eng, scene)
		reposition.SetCardPositionHand(cards[i], numInSuit, suitCounts, cardDim, paddingVec, windowSize, eng, scene)
	}
	// adding spades
	for i := clubCount + diamondCount; i < clubCount+diamondCount+spadeCount; i++ {
		numInSuit := i - clubCount - diamondCount
		texture.PopulateCardImage(cards[i], texs, eng, scene)
		reposition.SetCardPositionHand(cards[i], numInSuit, suitCounts, cardDim, paddingVec, windowSize, eng, scene)
	}
	// adding hearts
	for i := clubCount + diamondCount + spadeCount; i < clubCount+diamondCount+spadeCount+heartCount; i++ {
		numInSuit := i - clubCount - diamondCount - spadeCount
		texture.PopulateCardImage(cards[i], texs, eng, scene)
		reposition.SetCardPositionHand(cards[i], numInSuit, suitCounts, cardDim, paddingVec, windowSize, eng, scene)
	}
}
