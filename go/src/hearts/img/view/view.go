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
	"time"

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

func LoadArrangeView(u *uistate.UIState) {
	u.CurView = uistate.Arrange
	<-time.After(1 * time.Second)
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	sitImg := u.Texs["SitSpot.png"]
	watchImg := u.Texs["WatchSpot.png"]
	arrangeBlockLength := u.WindowSize.X - 4*u.Padding
	if u.WindowSize.Y < u.WindowSize.X {
		arrangeBlockLength = u.WindowSize.Y - 4*u.Padding
	}
	arrangeDim := coords.MakeVec(arrangeBlockLength/3-4*u.Padding, arrangeBlockLength/3-4*u.Padding)
	nilDim := coords.MakeVec(0, 0)
	// player 0 seat
	sitPos := coords.MakeVec((u.WindowSize.X-arrangeDim.X)/2, u.WindowSize.Y-arrangeDim.Y-2*u.Padding)
	if u.PlayerData[0] == 0 {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, arrangeDim, u))
	} else {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, nilDim, u))
		avatar := uistate.GetAvatar(0, u)
		u.BackgroundImgs = append(u.BackgroundImgs, texture.MakeImgWithoutAlt(avatar, sitPos, arrangeDim, u))
	}
	// player 1 seat
	sitPos = coords.MakeVec((u.WindowSize.X-arrangeDim.X)/2-arrangeDim.X-2*u.Padding, u.WindowSize.Y-2*arrangeDim.Y-4*u.Padding)
	if u.PlayerData[1] == 0 {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, arrangeDim, u))
	} else {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, nilDim, u))
		avatar := uistate.GetAvatar(0, u)
		u.BackgroundImgs = append(u.BackgroundImgs, texture.MakeImgWithoutAlt(avatar, sitPos, arrangeDim, u))
	}
	// player 2 seat
	sitPos = coords.MakeVec((u.WindowSize.X-arrangeDim.X)/2, u.WindowSize.Y-3*arrangeDim.Y-6*u.Padding)
	if u.PlayerData[2] == 0 {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, arrangeDim, u))
	} else {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, nilDim, u))
		avatar := uistate.GetAvatar(0, u)
		u.BackgroundImgs = append(u.BackgroundImgs, texture.MakeImgWithoutAlt(avatar, sitPos, arrangeDim, u))
	}
	// player 3 seat
	sitPos = coords.MakeVec((u.WindowSize.X-arrangeDim.X)/2+arrangeDim.X+2*u.Padding, u.WindowSize.Y-2*arrangeDim.Y-4*u.Padding)
	if u.PlayerData[3] == 0 {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, arrangeDim, u))
	} else {
		u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(sitImg, sitPos, nilDim, u))
		avatar := uistate.GetAvatar(0, u)
		u.BackgroundImgs = append(u.BackgroundImgs, texture.MakeImgWithoutAlt(avatar, sitPos, arrangeDim, u))
	}
	// table
	watchPos := coords.MakeVec((u.WindowSize.X-arrangeDim.X)/2, u.WindowSize.Y-2*arrangeDim.Y-4*u.Padding)
	u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(watchImg, watchPos, arrangeDim, u))
}

// Waiting view: Displays the word "Waiting". To be displayed when players are waiting for a new round to be dealt
// TODO(emshack): Integrate this with Arrange view and Score view so that a separate screen is not necessary
func LoadWaitingView(u *uistate.UIState) {
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	center := u.WindowSize.DividedBy(2)
	maxWidth := u.WindowSize.X - 2*u.Padding
	scaler := float32(3)
	textImgs := texture.MakeStringImgCenterAlign("Waiting...", "", "", true, center, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
}

// Discovery view: Displays a menu of possible games to join
func LoadDiscoveryView(discChan chan []string, u *uistate.UIState) {
	u.CurView = uistate.Discovery
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	newGameImg := u.Texs["NewGame.png"]
	newGameDim := coords.MakeVec(2*u.CardDim.X, u.CardDim.Y)
	newGamePos := coords.MakeVec((u.WindowSize.X-newGameDim.X)/2, u.TopPadding)
	u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(newGameImg, newGamePos, newGameDim, u))
	buttonNum := 1
	go func() {
		for u.CurView == uistate.Discovery {
			sgSet := <-discChan
			joinGameImg := u.Texs["JoinGame.png"]
			joinGamePos := coords.MakeVec(newGamePos.X, newGamePos.Y+float32(buttonNum)*(newGameDim.Y+u.Padding))
			u.Buttons = append(u.Buttons, texture.MakeImgWithoutAlt(joinGameImg, joinGamePos, newGameDim, u))
			u.Buttons[buttonNum].SetInfo(sgSet)
			buttonNum++
		}
	}()
}

// Table View: Displays the table. Intended for public devices
func LoadTableView(u *uistate.UIState) {
	u.CurView = uistate.Table
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	scaler := float32(4)
	maxWidth := 4 * u.TableCardDim.X
	// adding four drop targets for trick
	dropTargetImage := u.Texs["trickDrop.png"]
	dropTargetAlt := u.Texs["trickDropBlue.png"]
	dropTargetDimensions := u.CardDim
	dropTargetX := (u.WindowSize.X - u.CardDim.X) / 2
	var dropTargetY float32
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetY = u.WindowSize.Y/2 + u.CardDim.Y/2 + u.Padding
	} else {
		dropTargetY = u.WindowSize.Y/2 + u.Padding
	}
	dropTargetPos := coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// card on top of first drop target
	dropCard := u.CurTable.GetTrick()[0]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// second drop target
	dropTargetY = (u.WindowSize.Y - u.CardDim.Y) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetX = u.WindowSize.X/2 - u.CardDim.X - u.Padding
	} else {
		dropTargetX = u.WindowSize.X/2 - 3*u.CardDim.X/2 - u.Padding
	}
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// card on top of second drop target
	dropCard = u.CurTable.GetTrick()[1]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// third drop target
	dropTargetX = (u.WindowSize.X - u.CardDim.X) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetY = u.WindowSize.Y/2 - 3*u.CardDim.Y/2 - u.Padding
	} else {
		dropTargetY = u.WindowSize.Y/2 - u.Padding - u.CardDim.Y
	}
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// card on top of third drop target
	dropCard = u.CurTable.GetTrick()[2]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// fourth drop target
	dropTargetY = (u.WindowSize.Y - u.CardDim.Y) / 2
	if u.WindowSize.X < u.WindowSize.Y {
		dropTargetX = u.WindowSize.X/2 + u.Padding
	} else {
		dropTargetX = u.WindowSize.X/2 + u.CardDim.X/2 + u.Padding
	}
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// card on top of fourth drop target
	dropCard = u.CurTable.GetTrick()[3]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.Cards = append(u.Cards, dropCard)
	}
	// adding 4 player icons, text, and device icons
	playerIconImage := uistate.GetAvatar(0, u)
	playerIconX := (u.WindowSize.X - u.PlayerIconDim.X) / 2
	playerIconY := u.WindowSize.Y - u.TableCardDim.Y - u.BottomPadding - u.Padding - u.PlayerIconDim.Y
	playerIconPos := coords.MakeVec(playerIconX, playerIconY)
	if u.Debug {
		u.Buttons = append(u.Buttons,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	}
	// player 0's name
	center := coords.MakeVec(playerIconX+u.PlayerIconDim.X/2, playerIconY-30)
	name := uistate.GetName(0, u)
	textImgs := texture.MakeStringImgCenterAlign(name, "", "", true, center, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 0's device icon
	deviceIconImage := uistate.GetDevice(0, u)
	deviceIconDim := u.PlayerIconDim.DividedBy(2)
	deviceIconPos := coords.MakeVec(playerIconPos.X+u.PlayerIconDim.X, playerIconPos.Y)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, deviceIconDim, u))
	// player 1's icon
	playerIconImage = uistate.GetAvatar(1, u)
	playerIconX = u.BottomPadding
	playerIconY = (u.WindowSize.Y+2*u.BottomPadding+u.PlayerIconDim.Y-
		(float32(len(u.CurTable.GetPlayers()[1].GetHand()))*
			(u.TableCardDim.Y-u.Overlap.Y)+u.TableCardDim.Y))/2 -
		u.PlayerIconDim.Y - u.Padding
	playerIconPos = coords.MakeVec(playerIconX, playerIconY)
	if u.Debug {
		u.Buttons = append(u.Buttons,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	}
	// player 1's name
	start := coords.MakeVec(playerIconX, playerIconY-30)
	name = uistate.GetName(1, u)
	textImgs = texture.MakeStringImgLeftAlign(name, "", "", true, start, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 1's device icon
	deviceIconImage = uistate.GetDevice(1, u)
	deviceIconPos = coords.MakeVec(playerIconPos.X+u.PlayerIconDim.X, playerIconPos.Y+u.PlayerIconDim.Y-deviceIconDim.Y)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, deviceIconDim, u))
	// player 2's icon
	playerIconImage = uistate.GetAvatar(2, u)
	playerIconX = (u.WindowSize.X - u.PlayerIconDim.X) / 2
	playerIconY = u.TopPadding + u.TableCardDim.Y + u.Padding
	playerIconPos = coords.MakeVec(playerIconX, playerIconY)
	if u.Debug {
		u.Buttons = append(u.Buttons,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	}
	// player 2's name
	center = coords.MakeVec(playerIconX+u.PlayerIconDim.X/2, playerIconY+u.PlayerIconDim.Y+5)
	name = uistate.GetName(2, u)
	textImgs = texture.MakeStringImgCenterAlign(name, "", "", true, center, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 2's device icon
	deviceIconImage = uistate.GetDevice(2, u)
	deviceIconPos = coords.MakeVec(playerIconPos.X+u.PlayerIconDim.X, playerIconPos.Y+u.PlayerIconDim.Y-deviceIconDim.Y)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, deviceIconDim, u))
	// player 3's icon
	playerIconImage = uistate.GetAvatar(3, u)
	playerIconX = u.WindowSize.X - u.BottomPadding - u.PlayerIconDim.X
	playerIconY = (u.WindowSize.Y+2*u.BottomPadding+u.PlayerIconDim.Y-
		(float32(len(u.CurTable.GetPlayers()[3].GetHand()))*
			(u.TableCardDim.Y-u.Overlap.Y)+u.TableCardDim.Y))/2 -
		u.PlayerIconDim.Y - u.Padding
	playerIconPos = coords.MakeVec(playerIconX, playerIconY)
	if u.Debug {
		u.Buttons = append(u.Buttons,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	} else {
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, u.PlayerIconDim, u))
	}
	// player 3's name
	end := coords.MakeVec(playerIconX+u.PlayerIconDim.X, playerIconY-30)
	name = uistate.GetName(3, u)
	textImgs = texture.MakeStringImgRightAlign(name, "", "", true, end, scaler, maxWidth, u)
	for _, img := range textImgs {
		u.BackgroundImgs = append(u.BackgroundImgs, img)
	}
	// player 3's device icon
	deviceIconImage = uistate.GetDevice(3, u)
	deviceIconPos = coords.MakeVec(playerIconPos.X-deviceIconDim.X, playerIconPos.Y+u.PlayerIconDim.Y-deviceIconDim.Y)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(deviceIconImage, deviceIconPos, deviceIconDim, u))
	//adding cards
	for _, p := range u.CurTable.GetPlayers() {
		// cards in hand
		hand := p.GetHand()
		for i, c := range hand {
			texture.PopulateCardImage(c, u)
			cardIndex := coords.MakeVec(float32(len(hand)), float32(i))
			reposition.SetCardPositionTable(c, p.GetPlayerIndex(), cardIndex, u)
			u.Eng.SetSubTex(c.GetNode(), c.GetBack())
			u.TableCards = append(u.TableCards, c)
		}
		// cards that have been passed
		passed := p.GetPassedTo()
		for i, c := range passed {
			var passer int
			switch u.CurTable.GetDir() {
			case direction.Right:
				passer = (p.GetPlayerIndex() + 1) % u.NumPlayers
			case direction.Across:
				passer = (p.GetPlayerIndex() + 2) % u.NumPlayers
			case direction.Left:
				passer = (p.GetPlayerIndex() + 3) % u.NumPlayers
			}
			cardIndexVec := coords.MakeVec(float32(len(hand)+len(passed)), float32(len(hand)+i))
			initial := reposition.CardPositionTable(passer, cardIndexVec, u)
			c.SetInitial(initial)
			if !p.GetDoneTaking() {
				texture.PopulateCardImage(c, u)
				c.SetBackDisplay(u.Eng)
				pos := reposition.DetermineTablePassPosition(c, i, p.GetPlayerIndex(), u)
				c.Move(pos, u.TableCardDim, u.Eng)
				u.TableCards = append(u.TableCards, c)
			}
		}
	}
	if u.Debug {
		addDebugBar(u)
	}
	reposition.SetTableDropColors(u)
}

// Decides which view of the player's hand to load based on what steps of the round they have completed
// Likely just for debugging
func LoadPassOrTakeOrPlay(u *uistate.UIState) {
	p := u.CurTable.GetPlayers()[u.CurPlayerIndex]
	if p.GetDoneTaking() || u.CurTable.GetDir() == direction.None {
		LoadPlayView(u)
	} else if p.GetDonePassing() {
		LoadTakeView(u)
	} else {
		LoadPassView(u)
	}
}

// Score View: Shows current player standings at the end of every round, including the end of the game
func LoadScoreView(roundScores, winners []int, u *uistate.UIState) {
	u.CurView = uistate.Score
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	addScoreViewHeaderText(u)
	addPlayerScores(roundScores, u)
	addScoreButton(len(winners) > 0, u)
}

// Pass View: Shows player's hand and allows them to pass cards
func LoadPassView(u *uistate.UIState) {
	u.CurView = uistate.Pass
	resetAnims(u)
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
func LoadTakeView(u *uistate.UIState) {
	u.CurView = uistate.Take
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	addHeader(u)
	addGrayTakeBar(u)
	addHand(u)
	moveTakeCards(u)
	if u.Debug {
		addDebugBar(u)
	}
	// animate in take bar
	reposition.AnimateInTake(u)
}

// Play View: Shows player's hand and allows them to play cards
func LoadPlayView(u *uistate.UIState) {
	u.CurView = uistate.Play
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	addPlaySlot(u)
	addHand(u)
	addPlayHeader(getTurnText(u), false, u)
	if u.Debug {
		addDebugBar(u)
	}
	// animate in play slot if relevant
	if u.CurTable.WhoseTurn() == u.CurPlayerIndex && u.CurTable.AllDonePassing() {
		reposition.AnimateInPlay(u)
	}
}

func LoadSplitView(reloading bool, u *uistate.UIState) {
	u.CurView = uistate.Split
	resetAnims(u)
	resetImgs(u)
	resetScene(u)
	addPlayHeader(getTurnText(u), !reloading, u)
	addSplitViewPlayerIcons(!reloading, u)
	addHand(u)
	if u.Debug {
		addDebugBar(u)
	}
	reposition.SetSplitDropColors(u)
	if !reloading {
		reposition.AnimateInSplit(u)
	}
}

// TODO(emshack): When go mobile implements sprite.engine.Unregister, use this instead
func ChangePlayMessage(message string, u *uistate.UIState) {
	// remove text and replace with message
	var emptyTex sprite.SubTex
	for _, img := range u.Other {
		u.Eng.SetSubTex(img.GetNode(), emptyTex)
	}
	u.Eng.SetSubTex(u.Buttons[0].GetNode(), emptyTex)
	u.Other = make([]*staticimg.StaticImg, 0)
	u.Buttons = make([]*staticimg.StaticImg, 0)
	addPlayHeader(message, false, u)
}

func addSplitViewPlayerIcons(beforeSplitAnimation bool, u *uistate.UIState) {
	topOfBanner := u.WindowSize.Y - 4*u.CardDim.Y - 5*u.Padding - u.BottomPadding - 40
	splitWindowSize := coords.MakeVec(u.WindowSize.X, topOfBanner+u.TopPadding)
	dropTargetImage := u.Texs["trickDrop.png"]
	dropTargetAlt := u.Texs["trickDropBlue.png"]
	dropTargetDimensions := u.CardDim
	playerIconDimensions := u.CardDim.Minus(4)
	// first drop target
	dropTargetX := (splitWindowSize.X - u.CardDim.X) / 2
	dropTargetY := splitWindowSize.Y/2 + u.Padding
	if beforeSplitAnimation {
		dropTargetY -= topOfBanner
	}
	dropTargetPos := coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// first player icon
	playerIconImage := uistate.GetAvatar(u.CurPlayerIndex, u)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(playerIconImage, dropTargetPos.Plus(2), playerIconDimensions, u))
	// card on top of first drop target
	dropCard := u.CurTable.GetTrick()[u.CurPlayerIndex]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.TableCards = append(u.TableCards, dropCard)
	}
	// second drop target
	dropTargetY = (splitWindowSize.Y - u.CardDim.Y) / 2
	if beforeSplitAnimation {
		dropTargetY -= topOfBanner
	}
	dropTargetX = splitWindowSize.X/2 - 3*u.CardDim.X/2 - u.Padding
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// second player icon
	playerIconImage = uistate.GetAvatar((u.CurPlayerIndex+1)%u.NumPlayers, u)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(playerIconImage, dropTargetPos.Plus(2), playerIconDimensions, u))
	// card on top of second drop target
	dropCard = u.CurTable.GetTrick()[(u.CurPlayerIndex+1)%len(u.CurTable.GetPlayers())]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.TableCards = append(u.TableCards, dropCard)
	}
	// third drop target
	dropTargetX = (splitWindowSize.X - u.CardDim.X) / 2
	dropTargetY = splitWindowSize.Y/2 - u.Padding - u.CardDim.Y
	if beforeSplitAnimation {
		dropTargetY -= topOfBanner
	}
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// third player icon
	playerIconImage = uistate.GetAvatar((u.CurPlayerIndex+2)%u.NumPlayers, u)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(playerIconImage, dropTargetPos.Plus(2), playerIconDimensions, u))
	// card on top of third drop target
	dropCard = u.CurTable.GetTrick()[(u.CurPlayerIndex+2)%len(u.CurTable.GetPlayers())]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.TableCards = append(u.TableCards, dropCard)
	}
	// fourth drop target
	dropTargetY = (splitWindowSize.Y - u.CardDim.Y) / 2
	if beforeSplitAnimation {
		dropTargetY -= topOfBanner
	}
	dropTargetX = splitWindowSize.X/2 + u.CardDim.X/2 + u.Padding
	dropTargetPos = coords.MakeVec(dropTargetX, dropTargetY)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithAlt(dropTargetImage, dropTargetAlt, dropTargetPos, dropTargetDimensions, true, u))
	// fourth player icon
	playerIconImage = uistate.GetAvatar((u.CurPlayerIndex+3)%u.NumPlayers, u)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(playerIconImage, dropTargetPos.Plus(2), playerIconDimensions, u))
	// card on top of fourth drop target
	dropCard = u.CurTable.GetTrick()[(u.CurPlayerIndex+3)%len(u.CurTable.GetPlayers())]
	if dropCard != nil {
		texture.PopulateCardImage(dropCard, u)
		dropCard.Move(dropTargetPos, dropTargetDimensions, u.Eng)
		u.TableCards = append(u.TableCards, dropCard)
	}
}

// returns a string which says whose turn it is
func getTurnText(u *uistate.UIState) string {
	var turnText string
	playerTurnNum := u.CurTable.WhoseTurn()
	if playerTurnNum == -1 || !u.CurTable.AllDonePassing() {
		turnText = "Waiting for other players"
	} else if playerTurnNum == u.CurPlayerIndex {
		turnText = "Your turn"
	} else {
		name := uistate.GetName(playerTurnNum, u)
		turnText = name + "'s turn"
	}
	return turnText
}

func addHeader(u *uistate.UIState) {
	// adding blue banner
	headerImage := u.Texs["RoundedRectangle-DBlue.png"]
	headerPos := coords.MakeVec(0, -10)
	headerDimensions := coords.MakeVec(u.WindowSize.X, u.TopPadding+float32(20))
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(headerImage, headerPos, headerDimensions, u))
}

func addPlayHeader(message string, beforeSplitAnimation bool, u *uistate.UIState) {
	// adding blue banner
	headerImage := u.Texs["Rectangle-DBlue.png"]
	var headerDimensions *coords.Vec
	var headerPos *coords.Vec
	if u.CurView == uistate.Play || beforeSplitAnimation {
		headerDimensions = coords.MakeVec(u.WindowSize.X, float32(50))
		headerPos = coords.MakeVec(0, 0)
	} else {
		headerDimensions = coords.MakeVec(u.WindowSize.X, float32(40))
		topOfHand := u.WindowSize.Y - 4*(u.CardDim.Y+u.Padding) - u.BottomPadding
		headerPos = coords.MakeVec(0, topOfHand-headerDimensions.Y-u.Padding)
	}
	u.Other = append(u.Other,
		texture.MakeImgWithoutAlt(headerImage, headerPos, headerDimensions, u))
	// adding pull tab
	pullTabImage := u.Texs["HorizontalPullTab.png"]
	pullTabDim := u.CardDim.DividedBy(2)
	pullTabPos := headerPos.PlusVec(headerDimensions).MinusVec(pullTabDim).Minus(u.Padding)
	u.Buttons = append(u.Buttons,
		texture.MakeImgWithoutAlt(pullTabImage, pullTabPos, pullTabDim, u))
	// adding text
	color := "DBlue"
	scaler := float32(4)
	center := coords.MakeVec(u.WindowSize.X/2, headerPos.Y+headerDimensions.Y-30)
	maxWidth := u.WindowSize.X - pullTabDim.X*2 - u.Padding*4
	u.Other = append(u.Other,
		texture.MakeStringImgCenterAlign(message, color, color, true, center, scaler, maxWidth, u)...)
}

func addPlaySlot(u *uistate.UIState) {
	topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
	// adding blue rectangle
	blueRectImg := u.Texs["RoundedRectangle-LBlue.png"]
	blueRectDim := coords.MakeVec(u.WindowSize.X-4*u.BottomPadding, topOfHand+u.CardDim.Y)
	blueRectPos := coords.MakeVec(2*u.BottomPadding, -blueRectDim.Y)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(blueRectImg, blueRectPos, blueRectDim, u))
	// adding drop target
	dropTargetImg := u.Texs["trickDrop.png"]
	dropTargetPos := coords.MakeVec(u.WindowSize.X/2-u.CardDim.X/2, -u.CardDim.Y-3*u.Padding)
	u.DropTargets = append(u.DropTargets,
		texture.MakeImgWithoutAlt(dropTargetImg, dropTargetPos, u.CardDim, u))
}

func addGrayPassBar(u *uistate.UIState) {
	// adding gray bar
	grayBarImg := u.Texs["RoundedRectangle-Gray.png"]
	blueBarImg := u.Texs["RoundedRectangle-LBlue.png"]
	grayBarDim := u.WindowSize.Minus(4 * u.BottomPadding)
	grayBarPos := coords.MakeVec(2*u.BottomPadding, 40-grayBarDim.Y+u.TopPadding)
	u.Other = append(u.Other,
		texture.MakeImgWithAlt(grayBarImg, blueBarImg, grayBarPos, grayBarDim, true, u))
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
	name := uistate.GetName(receivingPlayer, u)
	color := "Gray"
	altColor := "LBlue"
	center := coords.MakeVec(u.WindowSize.X/2, u.TopPadding+5)
	scaler := float32(3)
	maxWidth := grayBarDim.X
	nameImgs := texture.MakeStringImgCenterAlign(name, color, altColor, true, center, scaler, maxWidth, u)
	u.Other = append(u.Other, nameImgs...)
}

func addGrayTakeBar(u *uistate.UIState) {
	passedCards := u.CurTable.GetPlayers()[u.CurPlayerIndex].GetPassedTo()
	display := len(passedCards) == 0
	// adding gray bar
	grayBarImg := u.Texs["RoundedRectangle-Gray.png"]
	grayBarAlt := u.Texs["RoundedRectangle-LBlue.png"]
	topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
	var grayBarHeight float32
	if display {
		grayBarHeight = 105
	} else {
		grayBarHeight = topOfHand + u.CardDim.Y
	}
	grayBarDim := coords.MakeVec(u.WindowSize.X-4*u.BottomPadding, grayBarHeight)
	grayBarPos := coords.MakeVec(2*u.BottomPadding, -u.WindowSize.Y-20)
	u.Other = append(u.Other,
		texture.MakeImgWithAlt(grayBarImg, grayBarAlt, grayBarPos, grayBarDim, display, u))
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
	name := uistate.GetName(passingPlayer, u)
	color := "Gray"
	nameAltColor := "LBlue"
	awaitingAltColor := "None"
	center := coords.MakeVec(u.WindowSize.X/2, 20-u.WindowSize.Y)
	scaler := float32(3)
	maxWidth := grayBarDim.X
	u.Other = append(u.Other,
		texture.MakeStringImgCenterAlign(name, color, nameAltColor, display, center, scaler, maxWidth, u)...)
	center = coords.MakeVec(center.X, center.Y+30)
	scaler = float32(5)
	u.Other = append(u.Other,
		texture.MakeStringImgCenterAlign("Awaiting pass", color, awaitingAltColor, display, center, scaler, maxWidth, u)...)
	// adding cards to take, if cards have been passed
	if !display {
		u.Cards = append(u.Cards, passedCards...)
	}
}

func moveTakeCards(u *uistate.UIState) {
	passedCards := u.CurTable.GetPlayers()[u.CurPlayerIndex].GetPassedTo()
	if len(passedCards) > 0 {
		topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
		numCards := float32(3)
		cardXStart := (u.WindowSize.X - (numCards*u.CardDim.X + (numCards-1)*u.Padding)) / 2
		for i, c := range passedCards {
			cardX := cardXStart + float32(i)*(u.Padding+u.CardDim.X)
			cardPos := coords.MakeVec(cardX, topOfHand-u.Padding-u.WindowSize.Y-20)
			c.Move(cardPos, u.CardDim, u.Eng)
			reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
			// invisible drop target holding card
			var emptyTex sprite.SubTex
			d := texture.MakeImgWithoutAlt(emptyTex, cardPos, u.CardDim, u)
			d.SetCardHere(c)
			u.DropTargets = append(u.DropTargets, d)
		}
	}
}

func addPassDrops(u *uistate.UIState) {
	// adding blue background banner for drop targets
	topOfHand := u.WindowSize.Y - 5*(u.CardDim.Y+u.Padding) - (2 * u.Padding / 5) - u.BottomPadding
	passBannerImage := u.Texs["Rectangle-LBlue.png"]
	passBannerPos := coords.MakeVec(6*u.BottomPadding, topOfHand-(2*u.Padding))
	passBannerDim := coords.MakeVec(u.WindowSize.X-8*u.BottomPadding, u.CardDim.Y+2*u.Padding)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(passBannerImage, passBannerPos, passBannerDim, u))
	// adding undisplayed pull tab
	pullTabSpotImage := u.Texs["Rectangle-LBlue.png"]
	pullTabImage := u.Texs["VerticalPullTab.png"]
	pullTabSpotPos := coords.MakeVec(2*u.BottomPadding, passBannerPos.Y)
	pullTabSpotDim := coords.MakeVec(4*u.BottomPadding, u.CardDim.Y+2*u.Padding)
	u.Buttons = append(u.Buttons,
		texture.MakeImgWithAlt(pullTabImage, pullTabSpotImage, pullTabSpotPos, pullTabSpotDim, false, u))
	// adding text
	textLeft := coords.MakeVec(pullTabSpotPos.X+pullTabSpotDim.X/2, passBannerPos.Y-20)
	scaler := float32(5)
	maxWidth := passBannerDim.X
	text := texture.MakeStringImgLeftAlign("Pass:", "", "None", true, textLeft, scaler, maxWidth, u)
	u.BackgroundImgs = append(u.BackgroundImgs, text...)
	// adding drop targets
	dropTargetImage := u.Texs["trickDrop.png"]
	dropTargetY := passBannerPos.Y + u.Padding
	numDropTargets := float32(3)
	dropTargetXStart := (u.WindowSize.X - (numDropTargets*u.CardDim.X + (numDropTargets-1)*u.Padding)) / 2
	for i := 0; i < int(numDropTargets); i++ {
		dropTargetX := dropTargetXStart + float32(i)*(u.Padding+u.CardDim.X)
		dropTargetPos := coords.MakeVec(dropTargetX, dropTargetY)
		u.DropTargets = append(u.DropTargets,
			texture.MakeImgWithoutAlt(dropTargetImage, dropTargetPos, u.CardDim, u))
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
		suitBannerPos := coords.MakeVec(suitBannerX, suitBannerY)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(suitBannerImage, suitBannerPos, suitBannerDim, u))
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
		display := c == 0
		suitIconPos := coords.MakeVec(suitIconX, suitIconY)
		suitIconDim := u.CardDim.Times(2).DividedBy(3)
		u.EmptySuitImgs = append(u.EmptySuitImgs,
			texture.MakeImgWithAlt(suitIconImage, suitIconAlt, suitIconPos, suitIconDim, display, u))
	}
	// adding clubs
	for i := 0; i < clubCount; i++ {
		numInSuit := i
		texture.PopulateCardImage(u.Cards[i], u)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding diamonds
	for i := clubCount; i < clubCount+diamondCount; i++ {
		numInSuit := i - clubCount
		texture.PopulateCardImage(u.Cards[i], u)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding spades
	for i := clubCount + diamondCount; i < clubCount+diamondCount+spadeCount; i++ {
		numInSuit := i - clubCount - diamondCount
		texture.PopulateCardImage(u.Cards[i], u)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
	// adding hearts
	for i := clubCount + diamondCount + spadeCount; i < clubCount+diamondCount+spadeCount+heartCount; i++ {
		numInSuit := i - clubCount - diamondCount - spadeCount
		texture.PopulateCardImage(u.Cards[i], u)
		reposition.SetCardPositionHand(u.Cards[i], numInSuit, suitCounts, u)
	}
}

func addScoreViewHeaderText(u *uistate.UIState) {
	top := u.CardDim.Y
	scaler := float32(4)
	maxWidth := u.WindowSize.X / 5
	// adding score text
	scoreCenter := coords.MakeVec(u.WindowSize.X/4, top)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeStringImgCenterAlign("Score:", "", "", true, scoreCenter, scaler, maxWidth, u)...)
	// adding game text
	gameCenter := coords.MakeVec(u.WindowSize.X/2, top)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeStringImgCenterAlign("Round", "", "", true, gameCenter, scaler, maxWidth, u)...)
	// adding total text
	totalCenter := coords.MakeVec(3*u.WindowSize.X/4, top)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeStringImgCenterAlign("Total", "", "", true, totalCenter, scaler, maxWidth, u)...)
}

func addPlayerScores(roundScores []int, u *uistate.UIState) {
	totalScores := make([]int, 0)
	for _, p := range u.CurTable.GetPlayers() {
		totalScores = append(totalScores, p.GetScore())
	}
	maxRoundScore := maxInt(roundScores)
	maxTotalScore := maxInt(totalScores)
	top := u.CardDim.Y
	scaler := float32(5)
	maxWidth := u.WindowSize.X / 4
	rowHeight := u.WindowSize.Y / 6
	for i, p := range u.CurTable.GetPlayers() {
		var color string
		// blue divider
		dividerImage := u.Texs["blue.png"]
		dividerDim := coords.MakeVec(u.WindowSize.X, u.Padding/2)
		dividerPos := coords.MakeVec(0, top+(float32(i)+.5)*rowHeight)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(dividerImage, dividerPos, dividerDim, u))
		// player icon
		playerIconImage := uistate.GetAvatar(i, u)
		playerIconDim := coords.MakeVec(rowHeight/2, rowHeight/2)
		playerIconPos := coords.MakeVec(u.WindowSize.X/4-playerIconDim.X/2, top+(float32(i)+.5)*rowHeight+rowHeight/7)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeImgWithoutAlt(playerIconImage, playerIconPos, playerIconDim, u))
		// player name
		name := uistate.GetName(i, u)
		nameCenter := coords.MakeVec(playerIconPos.X+playerIconDim.X/2, playerIconPos.Y+playerIconDim.Y)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeStringImgCenterAlign(name, "", "", true, nameCenter, scaler, maxWidth, u)...)
		// player round score
		roundScore := roundScores[i]
		if roundScore == maxRoundScore {
			color = "Red"
		} else {
			color = ""
		}
		roundCenter := coords.MakeVec(u.WindowSize.X/2, playerIconPos.Y+playerIconDim.Y/2)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeStringImgCenterAlign(strconv.Itoa(roundScore), color, color, true, roundCenter, scaler, maxWidth, u)...)
		// player total score
		totalScore := p.GetScore()
		if totalScore == maxTotalScore {
			color = "Red"
		} else {
			color = ""
		}
		totalCenter := coords.MakeVec(3*u.WindowSize.X/4, playerIconPos.Y+playerIconDim.Y/2)
		u.BackgroundImgs = append(u.BackgroundImgs,
			texture.MakeStringImgCenterAlign(strconv.Itoa(totalScore), color, color, true, totalCenter, scaler, maxWidth, u)...)
	}
	// final blue divider
	dividerImage := u.Texs["blue.png"]
	dividerDim := coords.MakeVec(u.WindowSize.X, u.Padding/2)
	dividerPos := coords.MakeVec(0, top+(float32(len(u.CurTable.GetPlayers()))+.5)*rowHeight)
	u.BackgroundImgs = append(u.BackgroundImgs,
		texture.MakeImgWithoutAlt(dividerImage, dividerPos, dividerDim, u))
}

func addScoreButton(gameOver bool, u *uistate.UIState) {
	var buttonImg sprite.SubTex
	if gameOver {
		buttonImg = u.Texs["NewGame.png"]
	} else {
		buttonImg = u.Texs["NewRound.png"]
	}
	buttonDim := coords.MakeVec(2*u.CardDim.X, 3*u.CardDim.Y/4)
	buttonPos := coords.MakeVec((u.WindowSize.X-buttonDim.X)/2, u.WindowSize.Y-buttonDim.Y-u.BottomPadding)
	u.Buttons = append(u.Buttons,
		texture.MakeImgWithoutAlt(buttonImg, buttonPos, buttonDim, u))
}

func resetImgs(u *uistate.UIState) {
	u.Cards = make([]*card.Card, 0)
	u.TableCards = make([]*card.Card, 0)
	u.BackgroundImgs = make([]*staticimg.StaticImg, 0)
	u.EmptySuitImgs = make([]*staticimg.StaticImg, 0)
	u.DropTargets = make([]*staticimg.StaticImg, 0)
	u.Buttons = make([]*staticimg.StaticImg, 0)
	u.Other = make([]*staticimg.StaticImg, 0)
	u.CurCard = nil
}

func resetScene(u *uistate.UIState) {
	u.Scene = &sprite.Node{}
	u.Eng.Register(u.Scene)
	u.Eng.SetTransform(u.Scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
}

func resetAnims(u *uistate.UIState) {
	for _, ch := range u.AnimChans {
		ch <- true
	}
	u.AnimChans = make([]chan bool, 0)
}

func addDebugBar(u *uistate.UIState) {
	buttonDim := u.CardDim
	debugTableImage := u.Texs["BakuSquare.png"]
	debugTablePos := u.WindowSize.MinusVec(buttonDim)
	u.Buttons = append(u.Buttons,
		texture.MakeImgWithoutAlt(debugTableImage, debugTablePos, buttonDim, u))
	debugPassImage := u.Texs["Clubs-2.png"]
	debugPassPos := coords.MakeVec(u.WindowSize.X-2*buttonDim.X, u.WindowSize.Y-buttonDim.Y)
	u.Buttons = append(u.Buttons,
		texture.MakeImgWithoutAlt(debugPassImage, debugPassPos, buttonDim, u))
}

// Helper function that returns the largest int in a non-negative int array (not index of largest int)
func maxInt(array []int) int {
	max := 0
	for _, num := range array {
		if num > max {
			max = num
		}
	}
	return max
}
