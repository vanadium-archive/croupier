// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// view handles the loading of new UI screens.
// Currently supported screens: Opening, Table, Pass, Take, Play, Score
// Future support: All screens part of the discovery process

package view

import (
	"sort"
	"strconv"

	"hearts/img/coords"
	"hearts/img/direction"
	"hearts/img/reposition"
	"hearts/img/staticimg"
	"hearts/img/texture"
	"hearts/img/uistate"
	"hearts/logic/card"

	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
)

// Opening View: Only temporary, for debugging, while discovery is not integrated
func LoadOpeningView(u *uistate.UIState) {
	u.CurView = uistate.Opening
	resetScene(u)
	buttonX := (u.WindowSize.X - u.CardDim.X) / 2
	tableButtonY := (u.WindowSize.Y - 2*u.CardDim.Y - u.Padding) / 2
	passButtonY := tableButtonY + u.CardDim.Y + u.Padding
	tableButtonXY := coords.MakeVec(buttonX, tableButtonY)
	passButtonXY := coords.MakeVec(buttonX, passButtonY)
	tableButtonPos := coords.MakePosition(tableButtonXY, tableButtonXY, u.CardDim)
	passButtonPos := coords.MakePosition(passButtonXY, passButtonXY, u.CardDim)
	tableButtonImage := u.Texs["BakuSquare.png"]
	passButtonImage := u.Texs["Clubs-2.png"]
	tableButton := texture.MakeImgWithAlt(tableButtonImage, tableButtonImage, tableButtonPos, true, u.Eng, u.Scene)
	passButton := texture.MakeImgWithAlt(passButtonImage, passButtonImage, passButtonPos, true, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, tableButton)
	u.Buttons = append(u.Buttons, passButton)
}

// Table View: Displays the table. Intended for public devices
func LoadTableView(u *uistate.UIState) {
	u.CurView = uistate.Table
	resetImgs(u)
	resetScene(u)
	scaler := float32(4)
	maxWidth := 4 * u.TableCardDim.X
	// adding four drop targets for trick
	dropTargetImage := u.Texs["trickDrop.png"]
	dropTargetDimensions := u.CardDim
	dropTargetX := (u.WindowSize.X - u.CardDim.X) / 2
	var dropTargetY float32
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetY = u.WindowSize.Y/2 + u.CardDim.Y/2 + u.Padding
	} else {
		dropTargetY = u.WindowSize.Y/2 + u.Padding
	}
	dropTargetXY := coords.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos := coords.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget := texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.Eng, u.Scene)
	u.DropTargets = append(u.DropTargets, dropTarget)
	// card on top of first drop target
	dropCard := u.CurTable.GetTrick()[0]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u.Texs, u.Eng, u.Scene)
		dropCard.Move(dropTargetXY, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// second drop target
	dropTargetY = (u.WindowSize.Y - u.CardDim.Y) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetX = u.WindowSize.X/2 - u.CardDim.X - u.Padding
	} else {
		dropTargetX = u.WindowSize.X/2 - 3*u.CardDim.X/2 - u.Padding
	}
	dropTargetXY = coords.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = coords.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.Eng, u.Scene)
	u.DropTargets = append(u.DropTargets, dropTarget)
	// card on top of second drop target
	dropCard = u.CurTable.GetTrick()[1]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u.Texs, u.Eng, u.Scene)
		dropCard.Move(dropTargetXY, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// third drop target
	dropTargetX = (u.WindowSize.X - u.CardDim.X) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetY = u.WindowSize.Y/2 - 3*u.CardDim.Y/2 - u.Padding
	} else {
		dropTargetY = u.WindowSize.Y/2 - u.Padding - u.CardDim.Y
	}
	dropTargetXY = coords.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = coords.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.Eng, u.Scene)
	u.DropTargets = append(u.DropTargets, dropTarget)
	// card on top of third drop target
	dropCard = u.CurTable.GetTrick()[2]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u.Texs, u.Eng, u.Scene)
		dropCard.Move(dropTargetXY, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// fourth drop target
	dropTargetY = (u.WindowSize.Y - u.CardDim.Y) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetX = u.WindowSize.X/2 + u.Padding
	} else {
		dropTargetX = u.WindowSize.X/2 + u.CardDim.X/2 + u.Padding
	}
	dropTargetXY = coords.MakeVec(dropTargetX, dropTargetY)
	dropTargetPos = coords.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
	dropTarget = texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.Eng, u.Scene)
	u.DropTargets = append(u.DropTargets, dropTarget)
	// card on top of fourth drop target
	dropCard = u.CurTable.GetTrick()[3]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u.Texs, u.Eng, u.Scene)
		dropCard.Move(dropTargetXY, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// adding 4 player icons, text, and device icons
	playerIconImage := u.CurTable.GetPlayers()[0].GetImage()
	playerIconX := (u.WindowSize.X - u.PlayerIconDim.X) / 2
	playerIconY := u.WindowSize.Y - u.TableCardDim.Y - u.BottomPadding - u.Padding - u.PlayerIconDim.Y
	playerIconXY := coords.MakeVec(playerIconX, playerIconY)
	playerIconPos := coords.MakePosition(playerIconXY, playerIconXY, u.PlayerIconDim)
	playerIcon := texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.Eng, u.Scene)
	if u.Debug {
		u.Buttons = append(u.Buttons, playerIcon)
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs, playerIcon)
	}
	// player 0's name
	center := coords.MakeVec(playerIconX+u.PlayerIconDim.X/2, playerIconY-30)
	textImgs := texture.MakeStringImgCenterAlign(u.CurTable.GetPlayers()[0].GetName(), "", "", true, center, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 0's device icon
	deviceIconImage := u.Texs["phoneIcon.png"]
	deviceIconDim := coords.MakeVec(u.PlayerIconDim.X/2, u.PlayerIconDim.Y/2)
	deviceIconX := playerIconXY.X + u.PlayerIconDim.X
	deviceIconY := playerIconXY.Y
	deviceIconXY := coords.MakeVec(deviceIconX, deviceIconY)
	deviceIconPos := coords.MakePosition(deviceIconXY, deviceIconXY, deviceIconDim)
	deviceIcon := texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, deviceIcon)
	// player 1's icon
	playerIconImage = u.CurTable.GetPlayers()[1].GetImage()
	playerIconX = u.BottomPadding
	playerIconY = (u.WindowSize.Y+2*u.BottomPadding+u.PlayerIconDim.Y-(float32(len(u.CurTable.GetPlayers()[1].GetHand()))*(u.TableCardDim.Y-u.Overlap.Y)+u.TableCardDim.Y))/2 - u.PlayerIconDim.Y - u.Padding
	playerIconXY = coords.MakeVec(playerIconX, playerIconY)
	playerIconPos = coords.MakePosition(playerIconXY, playerIconXY, u.PlayerIconDim)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.Eng, u.Scene)
	if u.Debug {
		u.Buttons = append(u.Buttons, playerIcon)
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs, playerIcon)
	}
	// player 1's name
	start := coords.MakeVec(playerIconX, playerIconY-30)
	textImgs = texture.MakeStringImgLeftAlign(u.CurTable.GetPlayers()[1].GetName(), "", "", true, start, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 1's device icon
	deviceIconImage = u.Texs["tabletIcon.png"]
	deviceIconX = playerIconXY.X + u.PlayerIconDim.X
	deviceIconY = playerIconXY.Y + u.PlayerIconDim.Y - deviceIconDim.Y
	deviceIconXY = coords.MakeVec(deviceIconX, deviceIconY)
	deviceIconPos = coords.MakePosition(deviceIconXY, deviceIconXY, deviceIconDim)
	deviceIcon = texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, deviceIcon)
	// player 2's icon
	playerIconImage = u.CurTable.GetPlayers()[2].GetImage()
	playerIconX = (u.WindowSize.X - u.PlayerIconDim.X) / 2
	playerIconY = u.TopPadding + u.TableCardDim.Y + u.Padding
	playerIconXY = coords.MakeVec(playerIconX, playerIconY)
	playerIconPos = coords.MakePosition(playerIconXY, playerIconXY, u.PlayerIconDim)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.Eng, u.Scene)
	if u.Debug {
		u.Buttons = append(u.Buttons, playerIcon)
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs, playerIcon)
	}
	// player 3's name
	center = coords.MakeVec(playerIconX+u.PlayerIconDim.X/2, playerIconY+u.PlayerIconDim.Y+5)
	textImgs = texture.MakeStringImgCenterAlign(u.CurTable.GetPlayers()[2].GetName(), "", "", true, center, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 2's device icon
	deviceIconImage = u.Texs["watchIcon.png"]
	deviceIconX = playerIconXY.X + u.PlayerIconDim.X
	deviceIconY = playerIconXY.Y + u.PlayerIconDim.Y - deviceIconDim.Y
	deviceIconXY = coords.MakeVec(deviceIconX, deviceIconY)
	deviceIconPos = coords.MakePosition(deviceIconXY, deviceIconXY, deviceIconDim)
	deviceIcon = texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, deviceIcon)
	// player 3's icon
	playerIconImage = u.CurTable.GetPlayers()[3].GetImage()
	playerIconX = u.WindowSize.X - u.BottomPadding - u.PlayerIconDim.X
	playerIconY = (u.WindowSize.Y+2*u.BottomPadding+u.PlayerIconDim.Y-(float32(len(u.CurTable.GetPlayers()[3].GetHand()))*(u.TableCardDim.Y-u.Overlap.Y)+u.TableCardDim.Y))/2 - u.PlayerIconDim.Y - u.Padding
	playerIconXY = coords.MakeVec(playerIconX, playerIconY)
	playerIconPos = coords.MakePosition(playerIconXY, playerIconXY, u.PlayerIconDim)
	playerIcon = texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.Eng, u.Scene)
	if u.Debug {
		u.Buttons = append(u.Buttons, playerIcon)
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs, playerIcon)
	}
	// player 3's name
	end := coords.MakeVec(playerIconX+u.PlayerIconDim.X, playerIconY-30)
	textImgs = texture.MakeStringImgRightAlign(u.CurTable.GetPlayers()[3].GetName(), "", "", true, end, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 3's device icon
	deviceIconImage = u.Texs["laptopIcon.png"]
	deviceIconX = playerIconXY.X - deviceIconDim.X
	deviceIconY = playerIconXY.Y + u.PlayerIconDim.Y - deviceIconDim.Y
	deviceIconXY = coords.MakeVec(deviceIconX, deviceIconY)
	deviceIconPos = coords.MakePosition(deviceIconXY, deviceIconXY, deviceIconDim)
	deviceIcon = texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, deviceIcon)
	// adding cards
	for _, p := range u.CurTable.GetPlayers() {
		hand := p.GetHand()
		for i, c := range hand {
			texture.PopulateCardImage(c, u.Texs, u.Eng, u.Scene)
			cardIndex := coords.MakeVec(float32(len(hand)), float32(i))
			reposition.SetCardPositionTable(c, p.GetPlayerIndex(), cardIndex, u)
			u.Eng.SetSubTex(c.GetNode(), c.GetBack())
			u.TableCards = append(u.TableCards, c)
		}
	}
	if u.Debug {
		addDebugBar(u)
	}
}

// Decides which view of the player's hand to load based on what steps of the round they have completed
func LoadPassOrTakeOrPlay(u *uistate.UIState) {
	p := u.CurTable.GetPlayers()[u.CurPlayerIndex]
	if p.GetDoneTaking() || u.CurTable.GetDir() == direction.None {
		loadPlayView(u)
	} else if p.GetDonePassing() {
		loadTakeView(u)
	} else {
		loadPassView(u)
	}
}

// Score View: Shows current player standings at the end of every round, including the end of the game
func LoadScoreView(winners []int, u *uistate.UIState) {
	u.CurView = uistate.Score
	resetImgs(u)
	resetScene(u)
	// adding score text
	textImgs := make([]*staticimg.StaticImg, 0)
	center := coords.MakeVec(u.WindowSize.X/2, u.WindowSize.Y/4)
	scaler := float32(4)
	maxWidthBanner := u.WindowSize.X - 2*u.Padding
	maxWidthScores := u.WindowSize.X / 2
	if len(winners) == 0 {
		textImgs = texture.MakeStringImgCenterAlign("Current Standings", "", "", true, center, scaler, maxWidthBanner, u)
	} else {
		str := "Game over! Congratulations " + u.CurTable.GetPlayers()[winners[0]].GetName()
		for i := 1; i < len(winners); i++ {
			str += " and " + u.CurTable.GetPlayers()[winners[i]].GetName()
		}
		str += "!"
		textImgs = texture.MakeStringImgCenterAlign(str, "", "", true, center, scaler, maxWidthBanner, u)
	}
	left := coords.MakeVec(u.WindowSize.X/4, center.Y+40)
	for _, p := range u.CurTable.GetPlayers() {
		str := p.GetName() + ": " + strconv.Itoa(p.GetScore())
		newTextImgs := texture.MakeStringImgLeftAlign(str, "", "", true, left, scaler, maxWidthScores, u)
		textImgs = append(textImgs, newTextImgs...)
		left = coords.MakeVec(left.X, left.Y+30)
	}
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// adding play button to move to next round
	pressedImg := u.Texs["playPressed.png"]
	unpressedImg := u.Texs["playUnpressed.png"]
	buttonDim := coords.MakeVec(2*u.CardDim.X, u.CardDim.Y)
	buttonX := (u.WindowSize.X - u.CardDim.X) / 2
	buttonY := u.WindowSize.Y - u.CardDim.Y - u.BottomPadding
	buttonXY := coords.MakeVec(buttonX, buttonY)
	buttonPos := coords.MakePosition(buttonXY, buttonXY, buttonDim)
	button := texture.MakeImgWithAlt(unpressedImg, pressedImg, buttonPos, true, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, button)
}

// Pass View: Shows player's hand and allows them to pass cards
func loadPassView(u *uistate.UIState) {
	u.CurView = uistate.Pass
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	addGrayPassBar(u)
	addPassDrops(u)
	addHand(u)
	if u.Debug {
		addDebugBar(u)
	}
}

// Take View: Shows player's hand and allows them to take the cards that have been passed to them
func loadTakeView(u *uistate.UIState) {
	u.CurView = uistate.Take
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	addGrayTakeBar(u)
	addHand(u)
	moveTakeCards(u)
	if u.Debug {
		addDebugBar(u)
	}
}

// Play View: Shows player's hand and allows them to play cards
func loadPlayView(u *uistate.UIState) {
	u.CurView = uistate.Play
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	addHand(u)
	if u.Debug {
		addDebugBar(u)
	}
}

func addHeader(u *uistate.UIState) {
	// adding blue banner
	headerImage := u.Texs["RoundedRectangle-DBlue.png"]
	headerXY := coords.MakeVec(0, -10)
	headerWidth := u.WindowSize.X
	headerHeight := float32(20)
	headerDimensions := coords.MakeVec(headerWidth, headerHeight)
	headerPos := coords.MakePosition(headerXY, headerXY, headerDimensions)
	header := texture.MakeImgWithoutAlt(headerImage, headerPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, header)
}

func addHeaderButton(u *uistate.UIState) {
	// adding blue banner for croupier header
	headerUnpressed := u.Texs["blue.png"]
	headerPressed := u.Texs["bluePressed.png"]
	headerXY := coords.MakeVec(0, 0)
	headerWidth := u.WindowSize.X
	var headerHeight float32
	if 2*u.CardDim.Y < headerWidth/4 {
		headerHeight = 2 * u.CardDim.Y
	} else {
		headerHeight = headerWidth / 4
	}
	headerDimensions := coords.MakeVec(headerWidth, headerHeight)
	headerPos := coords.MakePosition(headerXY, headerXY, headerDimensions)
	header := texture.MakeImgWithAlt(headerUnpressed, headerPressed, headerPos, true, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, header)
	// adding play button
	playUnpressed := u.Texs["playUnpressed.png"]
	playPressed := u.Texs["playPressed.png"]
	playDim := coords.MakeVec(headerHeight, headerHeight/2)
	playX := (u.WindowSize.X - playDim.X) / 2
	playY := (u.TopPadding + playDim.Y) / 2
	playXY := coords.MakeVec(playX, playY)
	playPos := coords.MakePosition(playXY, playXY, playDim)
	play := texture.MakeImgWithAlt(playUnpressed, playPressed, playPos, true, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, play)
}

func addGrayPassBar(u *uistate.UIState) {
	// adding gray bar
	grayBarImg := u.Texs["RoundedRectangle-Gray.png"]
	blueBarImg := u.Texs["RoundedRectangle-LBlue.png"]
	grayBarXY := coords.MakeVec(2*u.BottomPadding, 40-u.WindowSize.Y+4*u.BottomPadding)
	grayBarDim := coords.MakeVec(u.WindowSize.X-4*u.BottomPadding, u.WindowSize.Y-4*u.BottomPadding)
	grayBarPos := coords.MakePosition(grayBarXY, grayBarXY, grayBarDim)
	grayBar := texture.MakeImgWithAlt(grayBarImg, blueBarImg, grayBarPos, true, u.Eng, u.Scene)
	u.Other = append(u.Other, grayBar)
	// adding name
	var receivingPlayer int
	switch u.CurTable.GetDir() {
	case direction.Right:
		receivingPlayer = (u.CurPlayerIndex + 3) % u.NumPlayers
	case direction.Left:
		receivingPlayer = (u.CurPlayerIndex + 1) % u.NumPlayers
	case direction.Across:
		receivingPlayer = (u.CurPlayerIndex + 2) % u.NumPlayers
	}
	name := u.CurTable.GetPlayers()[receivingPlayer].GetName()
	color := "Gray"
	altColor := "LBlue"
	center := coords.MakeVec(u.WindowSize.X/2, 5)
	scaler := float32(3)
	maxWidth := u.WindowSize.X
	nameImgs := texture.MakeStringImgCenterAlign(name, color, altColor, true, center, scaler, maxWidth, u)
	u.Other = append(u.Other, nameImgs...)
}

func addGrayTakeBar(u *uistate.UIState) {
	passedCards := u.CurTable.GetPlayers()[u.CurPlayerIndex].GetPassedTo()
	display := len(passedCards) == 0
	// adding gray bar
	grayBarImg := u.Texs["RoundedRectangle-Gray.png"]
	grayBarAlt := u.Texs["RoundedRectangle-LBlue.png"]
	grayBarXY := coords.MakeVec(2*u.BottomPadding, -30)
	topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
	var grayBarHeight float32
	if display {
		grayBarHeight = 105
	} else {
		grayBarHeight = topOfHand - u.CardDim.Y
	}
	grayBarDim := coords.MakeVec(u.WindowSize.X-4*u.BottomPadding, grayBarHeight)
	grayBarPos := coords.MakePosition(grayBarXY, grayBarXY, grayBarDim)
	grayBar := texture.MakeImgWithAlt(grayBarImg, grayBarAlt, grayBarPos, display, u.Eng, u.Scene)
	u.Other = append(u.Other, grayBar)
	// adding name
	var passingPlayer int
	switch u.CurTable.GetDir() {
	case direction.Right:
		passingPlayer = (u.CurPlayerIndex + 1) % u.NumPlayers
	case direction.Left:
		passingPlayer = (u.CurPlayerIndex + 3) % u.NumPlayers
	case direction.Across:
		passingPlayer = (u.CurPlayerIndex + 2) % u.NumPlayers
	}
	name := u.CurTable.GetPlayers()[passingPlayer].GetName()
	color := "Gray"
	nameAltColor := "LBlue"
	awaitingAltColor := "None"
	center := coords.MakeVec(u.WindowSize.X/2, 5)
	scaler := float32(3)
	maxWidth := u.WindowSize.X
	nameImgs := texture.MakeStringImgCenterAlign(name, color, nameAltColor, display, center, scaler, maxWidth, u)
	u.Other = append(u.Other, nameImgs...)
	center = coords.MakeVec(center.X, center.Y+40)
	scaler = float32(5)
	awaitingImgs := texture.MakeStringImgCenterAlign("Awaiting pass", color, awaitingAltColor, display, center, scaler, maxWidth, u)
	u.Other = append(u.Other, awaitingImgs...)
	// adding cards to take, if cards have been passed
	if !display {
		u.Cards = append(u.Cards, passedCards...)
	}
}

func moveTakeCards(u *uistate.UIState) {
	passedCards := u.CurTable.GetPlayers()[u.CurPlayerIndex].GetPassedTo()
	if len(passedCards) > 0 {
		topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
		cardY := topOfHand - 3*u.CardDim.Y
		numCards := float32(3)
		cardXStart := (u.WindowSize.X - (numCards*u.CardDim.X + (numCards-1)*u.Padding)) / 2
		for i, c := range passedCards {
			cardX := cardXStart + float32(i)*(u.Padding+u.CardDim.X)
			cardXY := coords.MakeVec(cardX, cardY)
			c.Move(cardXY, u.CardDim, u.Eng)
			reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
			// invisible drop target holding card
			var emptyTex sprite.SubTex
			dropPos := coords.MakePosition(cardXY, cardXY, u.CardDim)
			d := texture.MakeImgWithoutAlt(emptyTex, dropPos, u.Eng, u.Scene)
			d.SetCardHere(c)
			u.DropTargets = append(u.DropTargets, d)
		}
	}
}

func addPassDrops(u *uistate.UIState) {
	// adding blue background banner for drop targets
	topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
	passBannerImage := u.Texs["Rectangle-LBlue.png"]
	passBannerX := 6 * u.BottomPadding
	passBannerY := topOfHand - (2 * u.Padding)
	passBannerWidth := u.WindowSize.X - 8*u.BottomPadding
	passBannerHeight := u.CardDim.Y + 2*u.Padding
	passBannerXY := coords.MakeVec(passBannerX, passBannerY)
	passBannerDimensions := coords.MakeVec(passBannerWidth, passBannerHeight)
	passBannerPos := coords.MakePosition(passBannerXY, passBannerXY, passBannerDimensions)
	passBanner := texture.MakeImgWithoutAlt(passBannerImage, passBannerPos, u.Eng, u.Scene)
	u.BackgroundImgs = append(u.BackgroundImgs, passBanner)
	// adding undisplayed pull tab
	pullTabSpotImage := u.Texs["Rectangle-LBlue.png"]
	pullTabImage := u.Texs["VerticalPullTab.png"]
	pullTabSpotX := 2 * u.BottomPadding
	pullTabSpotY := passBannerY
	pullTabSpotWidth := 4 * u.BottomPadding
	pullTabSpotHeight := u.CardDim.Y + 2*u.Padding
	pullTabSpotXY := coords.MakeVec(pullTabSpotX, pullTabSpotY)
	pullTabSpotDimensions := coords.MakeVec(pullTabSpotWidth, pullTabSpotHeight)
	pullTabSpotPos := coords.MakePosition(pullTabSpotXY, pullTabSpotXY, pullTabSpotDimensions)
	pullTabSpot := texture.MakeImgWithAlt(pullTabImage, pullTabSpotImage, pullTabSpotPos, false, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, pullTabSpot)
	// adding text
	textLeft := coords.MakeVec(pullTabSpotX+pullTabSpotWidth/2, passBannerY-20)
	scaler := float32(5)
	maxWidth := passBannerWidth
	text := texture.MakeStringImgLeftAlign("Pass:", "", "None", true, textLeft, scaler, maxWidth, u)
	u.BackgroundImgs = append(u.BackgroundImgs, text...)
	// adding drop targets
	dropTargetImage := u.Texs["trickDrop.png"]
	dropTargetDimensions := u.CardDim
	dropTargetY := passBannerY + u.Padding
	numDropTargets := float32(3)
	dropTargetXStart := (u.WindowSize.X - (numDropTargets*dropTargetDimensions.X + (numDropTargets-1)*u.Padding)) / 2
	for i := 0; i < int(numDropTargets); i++ {
		dropTargetX := dropTargetXStart + float32(i)*(u.Padding+dropTargetDimensions.X)
		dropTargetXY := coords.MakeVec(dropTargetX, dropTargetY)
		dropTargetPos := coords.MakePosition(dropTargetXY, dropTargetXY, dropTargetDimensions)
		newTarget := texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.Eng, u.Scene)
		u.DropTargets = append(u.DropTargets, newTarget)
	}
}

func addHand(u *uistate.UIState) {
	p := u.CurTable.GetPlayers()[u.CurPlayerIndex]
	u.Cards = append(u.Cards, p.GetHand()...)
	sort.Sort(card.CardSorter(u.Cards))
	clubCount := 0
	diamondCount := 0
	spadeCount := 0
	heartCount := 0
	for i := 0; i < len(u.Cards); i++ {
		switch u.Cards[i].GetSuit() {
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
	// adding gray background banners for each suit
	suitBannerImage := u.Texs["gray.jpeg"]
	suitBannerX := float32(0)
	suitBannerWidth := u.WindowSize.X
	suitBannerHeight := u.CardDim.Y + (4 * u.Padding / 5)
	suitBannerDim := coords.MakeVec(suitBannerWidth, suitBannerHeight)
	for i := 0; i < u.NumSuits; i++ {
		suitBannerY := u.WindowSize.Y - float32(i+1)*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
		suitBannerXY := coords.MakeVec(suitBannerX, suitBannerY)
		suitBannerPos := coords.MakePosition(suitBannerXY, suitBannerXY, suitBannerDim)
		suitBanner := texture.MakeImgWithoutAlt(suitBannerImage, suitBannerPos, u.Eng, u.Scene)
		u.BackgroundImgs = append(u.BackgroundImgs, suitBanner)
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
		suitIconImage := u.Texs[texKey]
		suitIconAlt := u.Texs["gray.png"]
		suitIconX := u.WindowSize.X/2 - u.CardDim.X/3
		suitIconY := u.WindowSize.Y - float32(4-i)*(u.CardDim.Y+u.Padding) + u.CardDim.Y/6 - u.BottomPadding
		suitIconWidth := 2 * u.CardDim.X / 3
		suitIconHeight := 2 * u.CardDim.Y / 3
		display := c == 0
		suitIconXY := coords.MakeVec(suitIconX, suitIconY)
		suitIconDim := coords.MakeVec(suitIconWidth, suitIconHeight)
		suitIconPos := coords.MakePosition(suitIconXY, suitIconXY, suitIconDim)
		suitIcon := texture.MakeImgWithAlt(suitIconImage, suitIconAlt, suitIconPos, display, u.Eng, u.Scene)
		u.EmptySuitImgs = append(u.EmptySuitImgs, suitIcon)
	}
	// adding clubs
	for i := 0; i < clubCount; i++ {
		numInSuit := i
		texture.PopulateCardImage(u.Cards[i], u.Texs, u.Eng, u.Scene)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding diamonds
	for i := clubCount; i < clubCount+diamondCount; i++ {
		numInSuit := i - clubCount
		texture.PopulateCardImage(u.Cards[i], u.Texs, u.Eng, u.Scene)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding spades
	for i := clubCount + diamondCount; i < clubCount+diamondCount+spadeCount; i++ {
		numInSuit := i - clubCount - diamondCount
		texture.PopulateCardImage(u.Cards[i], u.Texs, u.Eng, u.Scene)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding hearts
	for i := clubCount + diamondCount + spadeCount; i < clubCount+diamondCount+spadeCount+heartCount; i++ {
		numInSuit := i - clubCount - diamondCount - spadeCount
		texture.PopulateCardImage(u.Cards[i], u.Texs, u.Eng, u.Scene)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
}

func resetImgs(u *uistate.UIState) {
	u.Cards = make([]*card.Card, 0)
	u.TableCards = make([]*card.Card, 0)
	u.BackgroundImgs = make([]*staticimg.StaticImg, 0)
	u.EmptySuitImgs = make([]*staticimg.StaticImg, 0)
	u.DropTargets = make([]*staticimg.StaticImg, 0)
	u.Buttons = make([]*staticimg.StaticImg, 0)
	u.Other = make([]*staticimg.StaticImg, 0)
}

func resetScene(u *uistate.UIState) {
	u.Scene = &sprite.Node{}
	u.Eng.Register(u.Scene)
	u.Eng.SetTransform(u.Scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
}

func addDebugBar(u *uistate.UIState) {
	buttonDim := u.CardDim
	debugTableImage := u.Texs["BakuSquare.png"]
	debugTableX := u.WindowSize.X - buttonDim.X
	debugTableY := u.WindowSize.Y - buttonDim.Y
	debugTableXY := coords.MakeVec(debugTableX, debugTableY)
	debugTablePos := coords.MakePosition(debugTableXY, debugTableXY, buttonDim)
	debugTable := texture.MakeImgWithoutAlt(debugTableImage, debugTablePos, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, debugTable)
	debugPassImage := u.Texs["Clubs-2.png"]
	debugPassX := u.WindowSize.X - 2*buttonDim.X
	debugPassY := u.WindowSize.Y - buttonDim.Y
	debugPassXY := coords.MakeVec(debugPassX, debugPassY)
	debugPassPos := coords.MakePosition(debugPassXY, debugPassXY, buttonDim)
	debugPass := texture.MakeImgWithoutAlt(debugPassImage, debugPassPos, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, debugPass)
}
