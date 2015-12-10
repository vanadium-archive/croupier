// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// touchhandler handles all touch events for the app

package touchhandler

import (
	"fmt"
	"strconv"
	"strings"

	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/sprite"

	"hearts/img/coords"
	"hearts/img/reposition"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"hearts/sync"
)

func OnTouch(t touch.Event, u *uistate.UIState) {
	if t.Type == touch.TypeBegin {
		u.ViewOnTouch = u.CurView
	} else if u.CurView != u.ViewOnTouch {
		return
	}
	switch u.CurView {
	case uistate.Discovery:
		switch t.Type {
		case touch.TypeBegin:
			beginClickDiscovery(t, u)
		case touch.TypeMove:
			moveClickDiscovery(t, u)
		case touch.TypeEnd:
			endClickDiscovery(t, u)
		}
	case uistate.Arrange:
		switch t.Type {
		case touch.TypeBegin:
			beginClickArrange(t, u)
		case touch.TypeMove:
			moveClickArrange(t, u)
		case touch.TypeEnd:
			endClickArrange(t, u)
		}
	case uistate.Table:
		switch t.Type {
		case touch.TypeBegin:
			if u.Debug {
				beginClickTable(t, u)
			}
		}
	case uistate.Pass:
		switch t.Type {
		case touch.TypeBegin:
			beginClickPass(t, u)
		case touch.TypeMove:
			moveClickPass(t, u)
		case touch.TypeEnd:
			endClickPass(t, u)
		}
	case uistate.Take:
		switch t.Type {
		case touch.TypeBegin:
			beginClickTake(t, u)
		case touch.TypeMove:
			if u.CurCard != nil {
				moveClickTake(t, u)
			}
		case touch.TypeEnd:
			if u.CurCard != nil {
				endClickTake(t, u.CurCard, u)
				u.CurCard = nil
			}
		}
	case uistate.Play:
		switch t.Type {
		case touch.TypeBegin:
			beginClickPlay(t, u)
		case touch.TypeMove:
			if u.CurCard != nil {
				moveClickPlay(t, u)
			}
		case touch.TypeEnd:
			if u.CurCard != nil {
				endClickPlay(t, u.CurCard, u)
			}
		}
	case uistate.Split:
		switch t.Type {
		case touch.TypeBegin:
			beginClickSplit(t, u)
		case touch.TypeMove:
			if u.CurCard != nil {
				moveClickSplit(t, u)
			}
		case touch.TypeEnd:
			if u.CurCard != nil {
				endClickSplit(t, u.CurCard, u)
				u.CurCard = nil
			}
		}
	case uistate.Score:
		switch t.Type {
		case touch.TypeBegin:
			beginClickScore(t, u)
		case touch.TypeMove:
			moveClickScore(t, u)
		case touch.TypeEnd:
			endClickScore(t, u)
		}
	}
	u.LastMouseXY.X = t.X
	u.LastMouseXY.Y = t.Y
}

func beginClickDiscovery(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	for _, button := range buttonList {
		pressButton(button, u)
	}
}

func moveClickDiscovery(t touch.Event, u *uistate.UIState) {
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickDiscovery(t touch.Event, u *uistate.UIState) {
	pressed := unpressButtons(u)
	for _, button := range pressed {
		if button == u.Buttons["newGame"] {
			logCh := make(chan string)
			settingsCh := make(chan string)
			go sync.CreateLogSyncgroup(logCh, u)
			go sync.CreateSettingsSyncgroup(settingsCh, u)
			gameStartData := <-logCh
			logName := <-logCh
			settingsName := <-settingsCh
			if logName != "" && settingsName != "" {
				sync.LogSettingsName(settingsName, u)
				u.ScanChan <- true
				u.ScanChan = nil
				u.SGChan = make(chan bool)
				go sync.Advertise(logName, settingsName, gameStartData, u.SGChan, u.Ctx)
				view.LoadArrangeView(u)
			}
		} else {
			for _, b := range u.Buttons {
				if button == b {
					joinLogDone := make(chan bool)
					logAddr := b.GetInfo()
					go sync.JoinLogSyncgroup(joinLogDone, logAddr, u)
					if success := <-joinLogDone; success {
						settingsCh := make(chan string)
						go sync.CreateSettingsSyncgroup(settingsCh, u)
						sgName := <-settingsCh
						if sgName != "" {
							sync.LogSettingsName(sgName, u)
						}
						u.ScanChan <- true
						u.ScanChan = nil
						view.LoadArrangeView(u)
					} else {
						fmt.Println("Failed to join")
					}
				}
			}
		}
	}
}

func beginClickArrange(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["exit"] {
			pressButton(b, u)
		} else if b == u.Buttons["start"] {
			if u.CurTable.AllReadyForNewRound() {
				pressButton(b, u)
			}
		} else if u.CurPlayerIndex < 0 {
			for _, button := range u.Buttons {
				if b == button {
					pressButton(b, u)
				}
			}
		}
	}
}

func moveClickArrange(t touch.Event, u *uistate.UIState) {
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickArrange(t touch.Event, u *uistate.UIState) {
	pressed := unpressButtons(u)
	for _, b := range pressed {
		if b == u.Buttons["exit"] {
			if u.SGChan != nil {
				u.SGChan <- true
				u.SGChan = nil
			}
			u.IsOwner = false
			u.DiscGroups = make(map[string]*uistate.DiscStruct)
			u.ScanChan = make(chan bool)
			go sync.ScanForSG(u.Ctx, u.ScanChan, u)
			view.LoadDiscoveryView(u)
		} else if b == u.Buttons["start"] {
			if u.CurTable.AllReadyForNewRound() {
				successStart := sync.LogGameStart(u)
				for !successStart {
					successStart = sync.LogGameStart(u)
				}
				newHands := u.CurTable.Deal()
				successDeal := sync.LogDeal(u, u.CurPlayerIndex, newHands)
				for !successDeal {
					successDeal = sync.LogDeal(u, u.CurPlayerIndex, newHands)
				}
			}
		} else {
			for key, button := range u.Buttons {
				if b == button && u.CurPlayerIndex < 0 {
					if key == "joinTable" {
						u.CurPlayerIndex = 4
						sync.LogPlayerNum(u)
					} else {
						playerNum := strings.Split(key, "-")[1]
						if u.CurPlayerIndex < 0 {
							u.CurPlayerIndex, _ = strconv.Atoi(playerNum)
							sync.LogReady(u)
							sync.LogPlayerNum(u)
						}
					}
				}
			}
		}
	}
}

func beginClickTable(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		updateViewFromTable(buttonList[0], u)
	}
}

func beginClickPass(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	if u.CurCard != nil {
		reposition.BringNodeToFront(u.CurCard.GetNode(), u)
	}
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["table"] {
			view.LoadTableView(u)
		} else if b == u.Buttons["hand"] {
			view.LoadPassOrTakeOrPlay(u)
		} else if b == u.Buttons["dragPass"] {
			if b.GetDisplayingImage() {
				u.CurImg = b
				for _, img := range u.Other {
					u.Eng.SetSubTex(img.GetNode(), img.GetAlt())
					img.SetDisplayingImage(false)
				}
				blueBanner := u.Other[0]
				reposition.BringNodeToFront(u.BackgroundImgs[1].GetNode(), u)
				reposition.BringNodeToFront(b.GetNode(), u)
				for _, d := range u.DropTargets {
					reposition.BringNodeToFront(d.GetCardHere().GetNode(), u)
				}
				if blueBanner.GetNode().Arranger == nil {
					finalX := blueBanner.GetInitial().X
					finalY := b.GetInitial().Y + b.GetDimensions().Y - blueBanner.GetDimensions().Y
					finalPos := coords.MakeVec(finalX, finalY)
					reposition.AnimateImageNoChannel(blueBanner, finalPos, blueBanner.GetDimensions(), u)
				}
			}
		}
	}
}

func moveClickPass(t touch.Event, u *uistate.UIState) {
	if u.CurImg != nil {
		imgs := make([]*staticimg.StaticImg, 0)
		cards := make([]*card.Card, 0)
		pullTab := u.Buttons["dragPass"]
		blueBanner := u.BackgroundImgs[1]
		imgs = append(imgs, pullTab)
		imgs = append(imgs, blueBanner)
		for _, d := range u.DropTargets {
			imgs = append(imgs, d)
			cards = append(cards, d.GetCardHere())
		}
		for i := 2; i < 7; i++ {
			text := u.BackgroundImgs[i]
			u.Eng.SetSubTex(text.GetNode(), text.GetAlt())
			text.SetDisplayingImage(false)
		}
		reposition.DragImgs(t, cards, imgs, u)
	} else if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
}

func endClickPass(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		if !dropCardOnTarget(u.CurCard, t, u) {
			// check to see if card was removed from a drop target
			removeCardFromTarget(u.CurCard, u)
			// add card back to hand
			reposition.ResetCardPosition(u.CurCard, u.Eng)
			reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
		}
		// check to see whether pull tab should be displayed
		readyToPass := true
		for _, d := range u.DropTargets {
			if d.GetCardHere() == nil {
				readyToPass = false
			}
		}
		pullTab := u.Buttons["dragPass"]
		if readyToPass {
			u.Eng.SetSubTex(pullTab.GetNode(), pullTab.GetImage())
			pullTab.SetDisplayingImage(true)
		} else {
			u.Eng.SetSubTex(pullTab.GetNode(), pullTab.GetAlt())
			pullTab.SetDisplayingImage(false)
		}
	} else if u.CurImg != nil && touchingStaticImg(t, u.Other[0], u) {
		ch := make(chan bool)
		success := passCards(ch, u.CurPlayerIndex, u)
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		go func() {
			onDone := func() {
				if !success {
					fmt.Println("Invalid pass")
				} else {
					view.LoadTakeView(u)
				}
			}
			reposition.SwitchOnChan(ch, quit, onDone, u)
		}()
	}
	u.CurCard = nil
	u.CurImg = nil
}

func beginClickTake(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	if u.CurCard != nil {
		reposition.BringNodeToFront(u.CurCard.GetNode(), u)
		u.CurCard.GetNode().Arranger = nil
	}
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["table"] {
			view.LoadTableView(u)
		} else if b == u.Buttons["hand"] {
			view.LoadPassOrTakeOrPlay(u)
		}
	}
}

func moveClickTake(t touch.Event, u *uistate.UIState) {
	reposition.DragCard(t, u)
}

func endClickTake(t touch.Event, c *card.Card, u *uistate.UIState) {
	// check to see if card was removed from a drop target
	removeCardFromTarget(c, u)
	// add card back to hand
	reposition.ResetCardPosition(c, u.Eng)
	reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
	doneTaking := true
	for _, d := range u.DropTargets {
		if d.GetCardHere() != nil {
			doneTaking = false
		}
	}
	if doneTaking {
		ch := make(chan bool)
		success := takeCards(ch, u.CurPlayerIndex, u)
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		go func() {
			onDone := func() {
				if !success {
					fmt.Println("Invalid take")
				} else {
					view.LoadPlayView(u)
				}
			}
			reposition.SwitchOnChan(ch, quit, onDone, u)
		}()
	}
}

func beginClickPlay(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	if u.CurCard != nil {
		reposition.BringNodeToFront(u.CurCard.GetNode(), u)
	}
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["toggleSplit"] && !u.SwitchingViews {
			view.LoadSplitView(false, u)
		} else if b == u.Buttons["table"] {
			view.LoadTableView(u)
		} else if b == u.Buttons["hand"] {
			view.LoadPassOrTakeOrPlay(u)
		}
	}
}

func moveClickPlay(t touch.Event, u *uistate.UIState) {
	reposition.DragCard(t, u)
}

func endClickPlay(t touch.Event, c *card.Card, u *uistate.UIState) {
	if dropCardOnTarget(c, t, u) {
		ch := make(chan bool)
		if err := playCard(ch, u.CurPlayerIndex, u); err != "" {
			view.ChangePlayMessage(err, u)
			removeCardFromTarget(c, u)
			// add card back to hand
			reposition.ResetCardPosition(c, u.Eng)
			reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
		}
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		go func() {
			onDone := func() { view.LoadPlayView(u) }
			reposition.SwitchOnChan(ch, quit, onDone, u)
		}()
	} else {
		// check to see if card was removed from a drop target
		removeCardFromTarget(c, u)
		// add card back to hand
		reposition.ResetCardPosition(c, u.Eng)
		reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
	}
}

func beginClickSplit(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	if u.CurCard != nil {
		reposition.BringNodeToFront(u.CurCard.GetNode(), u)
	}
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["toggleSplit"] && !u.SwitchingViews {
			ch := make(chan bool)
			u.SwitchingViews = true
			reposition.AnimateOutSplit(ch, u)
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			go func() {
				onDone := func() {
					u.SwitchingViews = false
					view.LoadPlayView(u)
				}
				reposition.SwitchOnChan(ch, quit, onDone, u)
			}()
		} else if b == u.Buttons["table"] {
			view.LoadTableView(u)
		} else if b == u.Buttons["hand"] {
			view.LoadPassOrTakeOrPlay(u)
		}
	}
}

func moveClickSplit(t touch.Event, u *uistate.UIState) {
	reposition.DragCard(t, u)
}

func endClickSplit(t touch.Event, c *card.Card, u *uistate.UIState) {
	if dropCardHere(c, u.DropTargets[0], t, u) {
		ch := make(chan bool)
		if err := playCard(ch, u.CurPlayerIndex, u); err != "" {
			view.ChangePlayMessage(err, u)
			removeCardFromTarget(c, u)
			// add card back to hand
			reposition.ResetCardPosition(c, u.Eng)
		}
	} else {
		// add card back to hand
		reposition.ResetCardPosition(c, u.Eng)
	}
}

func beginClickScore(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		pressButton(b, u)
	}
}

func moveClickScore(t touch.Event, u *uistate.UIState) {
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickScore(t touch.Event, u *uistate.UIState) {
	pressed := unpressButtons(u)
	if len(pressed) > 0 {
		success := sync.LogReady(u)
		for !success {
			sync.LogReady(u)
		}
		view.LoadWaitingView(u)
	}
}

// returns a card object if a card was clicked, or nil if no card was clicked
func findClickedCard(t touch.Event, u *uistate.UIState) *card.Card {
	// i goes from the end backwards so that it checks cards displayed on top of other cards first
	for i := len(u.Cards) - 1; i >= 0; i-- {
		c := u.Cards[i]
		if touchingCard(t, c, u) {
			return c
		}
	}
	return nil
}

// returns a button object if a button was clicked, or nil if no button was clicked
func findClickedButton(t touch.Event, u *uistate.UIState) []*staticimg.StaticImg {
	pressed := make([]*staticimg.StaticImg, 0)
	for _, b := range u.Buttons {
		if touchingStaticImg(t, b, u) {
			pressed = append(pressed, b)
		}
	}
	return pressed
}

// returns true if pass was successful
func passCards(ch chan bool, playerId int, u *uistate.UIState) bool {
	cardsPassed := make([]*card.Card, 0)
	dropsToReset := make([]*staticimg.StaticImg, 0)
	for _, d := range u.DropTargets {
		passCard := d.GetCardHere()
		if passCard != nil {
			cardsPassed = append(cardsPassed, passCard)
			dropsToReset = append(dropsToReset, d)
		}
	}
	// if the pass is not valid, don't pass any cards
	if !u.CurTable.ValidPass(cardsPassed) || u.CurTable.GetPlayers()[playerId].GetDonePassing() {
		return false
	}
	success := sync.LogPass(u, cardsPassed)
	for !success {
		success = sync.LogPass(u, cardsPassed)
	}
	// UI component
	pullTab := u.Buttons["dragPass"]
	blueBanner := u.BackgroundImgs[1]
	imgs := []*staticimg.StaticImg{pullTab, blueBanner}
	for _, d := range dropsToReset {
		imgs = append(imgs, d)
		d.SetCardHere(nil)
	}
	var blankTex sprite.SubTex
	for _, i := range imgs {
		u.Eng.SetSubTex(i.GetNode(), blankTex)
	}
	reposition.AnimateHandCardPass(ch, u.Other, cardsPassed, u)
	return true
}

func takeCards(ch chan bool, playerId int, u *uistate.UIState) bool {
	player := u.CurTable.GetPlayers()[playerId]
	passedCards := player.GetPassedTo()
	if len(passedCards) != 3 {
		return false
	}
	success := sync.LogTake(u)
	for !success {
		success = sync.LogTake(u)
	}
	reposition.AnimateHandCardTake(ch, u.Other, u)
	return true
}

func playCard(ch chan bool, playerId int, u *uistate.UIState) string {
	c := u.DropTargets[0].GetCardHere()
	if c == nil {
		return "No card has been played"
	}
	// checks to make sure that:
	// -player has not already played a card this round
	// -all players have passed cards
	// -the play is in the right order
	// -the play is valid given game logic
	if u.CurTable.GetPlayers()[playerId].GetDonePlaying() {
		return "You have already played a card in this trick"
	}
	if !u.CurTable.AllDonePassing() {
		return "Not all players have passed their cards"
	}
	if !u.CurTable.ValidPlayOrder(playerId) {
		return "It is not your turn"
	}
	if err := u.CurTable.ValidPlayLogic(c, playerId); err != "" {
		return err
	}
	u.DropTargets[0].SetCardHere(nil)
	success := sync.LogPlay(u, c)
	for !success {
		success = sync.LogPlay(u, c)
	}
	// no animation when in split view
	if u.CurView == uistate.Play {
		reposition.AnimateHandCardPlay(ch, c, u)
	}
	return ""
}

func pressButton(b *staticimg.StaticImg, u *uistate.UIState) {
	u.Eng.SetSubTex(b.GetNode(), b.GetAlt())
	b.SetDisplayingImage(false)
}

// returns buttons that were pressed
func unpressButtons(u *uistate.UIState) []*staticimg.StaticImg {
	pressed := make([]*staticimg.StaticImg, 0)
	for _, b := range u.Buttons {
		if b.GetDisplayingImage() == false {
			u.Eng.SetSubTex(b.GetNode(), b.GetImage())
			b.SetDisplayingImage(true)
			pressed = append(pressed, b)
		}
	}
	return pressed
}

// returns pressed buttons without unpressing them
func getPressed(u *uistate.UIState) []*staticimg.StaticImg {
	pressed := make([]*staticimg.StaticImg, 0)
	for _, b := range u.Buttons {
		if b.GetDisplayingImage() == false {
			pressed = append(pressed, b)
		}
	}
	return pressed
}

// checks all drop targets to see if a card was dropped there
func dropCardOnTarget(c *card.Card, t touch.Event, u *uistate.UIState) bool {
	for _, d := range u.DropTargets {
		// checking to see if card was dropped onto a drop target
		if touchingStaticImg(t, d, u) {
			lastDroppedCard := d.GetCardHere()
			if lastDroppedCard != nil {
				reposition.ResetCardPosition(lastDroppedCard, u.Eng)
				reposition.RealignSuit(lastDroppedCard.GetSuit(), lastDroppedCard.GetInitial().Y, u)
			}
			oldY := c.GetInitial().Y
			suit := c.GetSuit()
			u.CurCard.Move(d.GetCurrent(), c.GetDimensions(), u.Eng)
			d.SetCardHere(u.CurCard)
			// realign suit the card just left
			reposition.RealignSuit(suit, oldY, u)
			return true
		}
	}
	return false
}

// checks one specific drop target to see if a card was dropped there
func dropCardHere(c *card.Card, d *staticimg.StaticImg, t touch.Event, u *uistate.UIState) bool {
	if !touchingStaticImg(t, d, u) {
		return false
	}
	lastDroppedCard := d.GetCardHere()
	if lastDroppedCard != nil {
		reposition.ResetCardPosition(lastDroppedCard, u.Eng)
		reposition.RealignSuit(lastDroppedCard.GetSuit(), lastDroppedCard.GetInitial().Y, u)
	}
	oldY := c.GetInitial().Y
	suit := c.GetSuit()
	u.CurCard.Move(d.GetCurrent(), c.GetDimensions(), u.Eng)
	d.SetCardHere(u.CurCard)
	// realign suit the card just left
	reposition.RealignSuit(suit, oldY, u)
	return true
}

func removeCardFromTarget(c *card.Card, u *uistate.UIState) bool {
	for _, d := range u.DropTargets {
		if d.GetCardHere() == c {
			d.SetCardHere(nil)
			return true
		}
	}
	return false
}

func touchingCard(t touch.Event, c *card.Card, u *uistate.UIState) bool {
	withinXBounds := t.X/u.PixelsPerPt >= c.GetCurrent().X && t.X/u.PixelsPerPt <= c.GetDimensions().X+c.GetCurrent().X
	withinYBounds := t.Y/u.PixelsPerPt >= c.GetCurrent().Y && t.Y/u.PixelsPerPt <= c.GetDimensions().Y+c.GetCurrent().Y
	return withinXBounds && withinYBounds
}

func touchingStaticImg(t touch.Event, s *staticimg.StaticImg, u *uistate.UIState) bool {
	withinXBounds := t.X/u.PixelsPerPt >= s.GetCurrent().X && t.X/u.PixelsPerPt <= s.GetDimensions().X+s.GetCurrent().X
	withinYBounds := t.Y/u.PixelsPerPt >= s.GetCurrent().Y && t.Y/u.PixelsPerPt <= s.GetDimensions().Y+s.GetCurrent().Y
	return withinXBounds && withinYBounds
}

func updateViewFromTable(b *staticimg.StaticImg, u *uistate.UIState) {
	if b == u.Buttons["player0"] {
		u.CurPlayerIndex = 0
		view.LoadPassOrTakeOrPlay(u)
	} else if b == u.Buttons["player1"] {
		u.CurPlayerIndex = 1
		view.LoadPassOrTakeOrPlay(u)
	} else if b == u.Buttons["player2"] {
		u.CurPlayerIndex = 2
		view.LoadPassOrTakeOrPlay(u)
	} else if b == u.Buttons["player3"] {
		u.CurPlayerIndex = 3
		view.LoadPassOrTakeOrPlay(u)
	} else if b == u.Buttons["table"] {
		view.LoadTableView(u)
	} else if b == u.Buttons["hand"] {
		view.LoadPassOrTakeOrPlay(u)
	}
}
