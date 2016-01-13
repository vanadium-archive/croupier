// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// touchhandler handles all touch events for the app

package touchhandler

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/sprite"

	"hearts/img/reposition"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"hearts/sound"
	"hearts/sync"
)

var (
	numTaps            int
	beganTouchX        float32
	beganTouchY        float32
	timeStartedTapping = time.Now()
)

func OnTouch(t touch.Event, u *uistate.UIState) {
	if t.Type == touch.TypeBegin {
		u.ViewOnTouch = u.CurView
		beganTouchX = t.X
		beganTouchY = t.Y
	} else if u.CurView != u.ViewOnTouch {
		return
	}
	// tap 5 times to trigger debug mode
	if t.Type == touch.TypeEnd {
		if t.X == beganTouchX && t.Y == beganTouchY && time.Since(timeStartedTapping).Seconds() <= 5.0 {
			numTaps++
			if numTaps == 5 {
				fmt.Println("TOGGLING DEBUG")
				u.Debug = !u.Debug
				view.ReloadView(u)
				numTaps = 0
			}
		} else {
			numTaps = 0
			timeStartedTapping = time.Now()
		}
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
			beginClickTable(t, u)
		case touch.TypeMove:
			moveClickTable(t, u)
		case touch.TypeEnd:
			endClickTable(t, u)
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
			moveClickTake(t, u)
		case touch.TypeEnd:
			endClickTake(t, u)
		}
	case uistate.Play:
		switch t.Type {
		case touch.TypeBegin:
			beginClickPlay(t, u)
		case touch.TypeMove:
			moveClickPlay(t, u)
		case touch.TypeEnd:
			endClickPlay(t, u)
		}
	case uistate.Split:
		switch t.Type {
		case touch.TypeBegin:
			beginClickSplit(t, u)
		case touch.TypeMove:
			moveClickSplit(t, u)
		case touch.TypeEnd:
			endClickSplit(t, u)
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
			gameStartData, logName := sync.CreateLogSyncgroup(u)
			settingsName := sync.CreateSettingsSyncgroup(u)
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
					s := strings.Split(b.GetInfo(), "|")
					logAddr := s[0]
					creator, _ := strconv.ParseBool(s[1])
					fmt.Println("TRYING TO JOIN:", logAddr)
					success := sync.JoinLogSyncgroup(logAddr, creator, u)
					if success {
						sgName := sync.CreateSettingsSyncgroup(u)
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
		} else if u.CurPlayerIndex < 0 || u.Debug {
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
				if b == button && (u.CurPlayerIndex < 0 || u.Debug) {
					if key == "joinTable" {
						u.CurPlayerIndex = 4
						sync.LogPlayerNum(u)
					} else {
						playerNum := strings.Split(key, "-")[1]
						u.CurPlayerIndex, _ = strconv.Atoi(playerNum)
						sync.LogPlayerNum(u)
					}
				}
			}
		}
	}
}

func beginClickTable(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["takeTrick"] {
			pressButton(b, u)
		} else {
			handleDebugButtonClick(b, u)
		}
	}
}

func moveClickTable(t touch.Event, u *uistate.UIState) {
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickTable(t touch.Event, u *uistate.UIState) {
	pressed := unpressButtons(u)
	for _, b := range pressed {
		if b == u.Buttons["takeTrick"] {
			sync.LogTakeTrick(u)
		}
	}
}

func beginClickPass(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	if u.CurCard != nil {
		reposition.BringNodeToFront(u.CurCard.GetNode(), u)
	}
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["pass"] {
			pressButton(b, u)
		} else {
			handleDebugButtonClick(b, u)
		}
	}
}

func moveClickPass(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickPass(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		if !dropCardOnTarget(u.CurCard, t, u) {
			// check to see if card was removed from a drop target
			sync.RemoveCardFromTarget(u.CurCard, u)
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
		passButton := u.Buttons["pass"]
		if readyToPass {
			if passButton.GetDisplayingImage() {
				u.Eng.SetSubTex(passButton.GetNode(), passButton.GetImage())
				passButton.SetHidden(false)
				passButton.SetDisplayingImage(true)
			}
			for _, img := range u.Other {
				if img.GetDisplayingImage() {
					u.Eng.SetSubTex(img.GetNode(), img.GetAlt())
					img.SetHidden(false)
					img.SetDisplayingImage(false)
				}
			}
		} else {
			var emptyTex sprite.SubTex
			u.Eng.SetSubTex(passButton.GetNode(), emptyTex)
			passButton.SetHidden(true)
			passButton.SetDisplayingImage(true)
			for _, img := range u.Other {
				if !img.GetDisplayingImage() {
					u.Eng.SetSubTex(img.GetNode(), img.GetImage())
					img.SetHidden(false)
					img.SetDisplayingImage(true)
				}
			}
		}
	}
	pressed := unpressButtons(u)
	for _, p := range pressed {
		if p == u.Buttons["pass"] {
			ch := make(chan bool)
			success := passCards(ch, u.CurPlayerIndex, u)
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			go func() {
				onDone := func() {
					if !success {
						fmt.Println("Invalid pass")
					} else if u.CurView == uistate.Pass {
						view.LoadTakeView(u)
					}
				}
				reposition.SwitchOnChan(ch, quit, onDone, u)
			}()
		}
	}
	u.CurCard = nil
}

func beginClickTake(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	for _, b := range buttonList {
		if b == u.Buttons["take"] {
			pressButton(b, u)
		} else {
			handleDebugButtonClick(b, u)
		}
	}
}

func moveClickTake(t touch.Event, u *uistate.UIState) {
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickTake(t touch.Event, u *uistate.UIState) {
	pressed := unpressButtons(u)
	for _, b := range pressed {
		if b == u.Buttons["take"] {
			cards := make([]*card.Card, 0)
			for _, d := range u.DropTargets {
				c := d.GetCardHere()
				if c != nil {
					cards = append(cards, c)
				}
			}
			for _, c := range cards {
				sync.RemoveCardFromTarget(c, u)
				// add card back to hand
				reposition.ResetCardPosition(c, u.Eng)
				reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
			}
			ch := make(chan bool)
			success := takeCards(ch, u.CurPlayerIndex, u)
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			go func() {
				onDone := func() {
					if !success {
						fmt.Println("Invalid take")
					} else {
						if u.CurView == uistate.Take {
							view.LoadPlayView(false, u)
						}
					}
				}
				reposition.SwitchOnChan(ch, quit, onDone, u)
			}()
		}
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
		} else if b == u.Buttons["takeTrick"] {
			pressButton(b, u)
		} else {
			handleDebugButtonClick(b, u)
		}
	}
}

func moveClickPlay(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpressButtons(u)
	}
}

func endClickPlay(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		if u.CurTable.GetTrick()[u.CurPlayerIndex] == nil {
			if dropCardOnTarget(u.CurCard, t, u) {
				if u.CurTable.WhoseTurn() == u.CurPlayerIndex {
					ch := make(chan bool)
					if err := sync.PlayCard(ch, u.CurPlayerIndex, u); err != "" {
						view.ChangePlayMessage(err, u)
						sync.RemoveCardFromTarget(u.CurCard, u)
						u.CardToPlay = nil
						// add card back to hand
						reposition.ResetCardPosition(u.CurCard, u.Eng)
						reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
					}
					quit := make(chan bool)
					u.AnimChans = append(u.AnimChans, quit)
					go func() {
						onDone := func() {
							if u.CurView == uistate.Play {
								view.LoadPlayView(true, u)
							}
						}
						reposition.SwitchOnChan(ch, quit, onDone, u)
					}()
				} else {
					u.CardToPlay = u.CurCard
				}
			} else {
				// add card back to hand
				if sync.RemoveCardFromTarget(u.CurCard, u) {
					u.CardToPlay = nil
				}
				reposition.ResetCardPosition(u.CurCard, u.Eng)
				reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
			}
		} else {
			// add card back to hand
			reposition.ResetCardPosition(u.CurCard, u.Eng)
			reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
		}
	}
	pressed := unpressButtons(u)
	for _, b := range pressed {
		if b == u.Buttons["takeTrick"] {
			var emptyTex sprite.SubTex
			u.Eng.SetSubTex(b.GetNode(), emptyTex)
			b.SetHidden(true)
			u.Buttons["takeTrick"] = nil
			for _, takenCard := range u.TableCards {
				sync.RemoveCardFromTarget(takenCard, u)
				reposition.BringNodeToFront(takenCard.GetNode(), u)
			}
			ch := make(chan bool)
			reposition.AnimateHandCardTakeTrick(ch, u.TableCards, u)
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			go func() {
				onDone := func() {
					sync.LogTakeTrick(u)
				}
				reposition.SwitchOnChan(ch, quit, onDone, u)
			}()
		}
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
					if u.CurView == uistate.Split {
						view.LoadPlayView(false, u)
					}
				}
				reposition.SwitchOnChan(ch, quit, onDone, u)
			}()
		} else if b == u.Buttons["takeTrick"] {
			pressButton(b, u)
		} else {
			handleDebugButtonClick(b, u)
		}
	}
}

func moveClickSplit(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
	curPressed := findClickedButton(t, u)
	alreadyPressed := getPressed(u)
	if len(alreadyPressed) > 0 && len(curPressed) == 0 {
		unpress := true
		for _, b := range alreadyPressed {
			if b == u.Buttons["toggleSplit"] {
				unpress = false
			}
		}
		if unpress {
			unpressButtons(u)
		}
	}
}

func endClickSplit(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		if u.CurTable.GetTrick()[u.CurPlayerIndex] == nil {
			if dropCardHere(u.CurCard, u.DropTargets[0], t, u) {
				if u.CurTable.WhoseTurn() == u.CurPlayerIndex {
					ch := make(chan bool)
					if err := sync.PlayCard(ch, u.CurPlayerIndex, u); err != "" {
						view.ChangePlayMessage(err, u)
						if sync.RemoveCardFromTarget(u.CurCard, u) {
							u.CardToPlay = nil
							u.BackgroundImgs[0].GetNode().Arranger = nil
							var emptyTex sprite.SubTex
							u.Eng.SetSubTex(u.BackgroundImgs[0].GetNode(), emptyTex)
							u.BackgroundImgs[0].SetHidden(true)
						}
						// add card back to hand
						reposition.ResetCardPosition(u.CurCard, u.Eng)
					}
				} else {
					u.CardToPlay = u.CurCard
					reposition.AlternateImgs(u.BackgroundImgs[0], u)
				}
			} else {
				// add card back to hand
				if sync.RemoveCardFromTarget(u.CurCard, u) {
					u.CardToPlay = nil
					u.BackgroundImgs[0].GetNode().Arranger = nil
					var emptyTex sprite.SubTex
					u.Eng.SetSubTex(u.BackgroundImgs[0].GetNode(), emptyTex)
					u.BackgroundImgs[0].SetHidden(true)
				}
				reposition.ResetCardPosition(u.CurCard, u.Eng)
				reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
			}
		} else {
			// add card back to hand
			reposition.ResetCardPosition(u.CurCard, u.Eng)
			reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
		}
	}
	pressed := getPressed(u)
	unpress := true
	for _, b := range pressed {
		if b == u.Buttons["takeTrick"] {
			sync.LogTakeTrick(u)
		} else if b == u.Buttons["toggleSplit"] {
			unpress = false
		}
	}
	if unpress {
		unpressButtons(u)
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

// returns a card object if a card was clicked, or nil if no card was clicked
func findClickedTableCard(t touch.Event, u *uistate.UIState) *card.Card {
	// i goes from the end backwards so that it checks cards displayed on top of other cards first
	for i := len(u.TableCards) - 1; i >= 0; i-- {
		c := u.TableCards[i]
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
		if b != nil {
			if touchingStaticImg(t, b, u) {
				pressed = append(pressed, b)
			}
		}
	}
	return pressed
}

// returns true if pass was successful
func passCards(ch chan bool, playerId int, u *uistate.UIState) bool {
	cardsPassed := make([]*card.Card, 0)
	for _, d := range u.DropTargets {
		passCard := d.GetCardHere()
		if passCard != nil {
			cardsPassed = append(cardsPassed, passCard)
		}
	}
	// if the pass is not valid, don't pass any cards
	if !u.CurTable.ValidPass(cardsPassed) || u.CurTable.GetPlayers()[playerId].GetDonePassing() {
		return false
	}
	sound.PlaySound(1, u)
	success := sync.LogPass(u, cardsPassed)
	for !success {
		success = sync.LogPass(u, cardsPassed)
	}
	imgs := append(u.Other, u.DropTargets...)
	imgs = append(imgs, u.Buttons["pass"])
	reposition.AnimateHandCardPass(ch, imgs, u)
	return true
}

func takeCards(ch chan bool, playerId int, u *uistate.UIState) bool {
	player := u.CurTable.GetPlayers()[playerId]
	passedCards := player.GetPassedTo()
	if len(passedCards) != 3 {
		return false
	}
	sound.PlaySound(0, u)
	success := sync.LogTake(u)
	for !success {
		success = sync.LogTake(u)
	}
	imgs := append(u.Other, u.Buttons["take"])
	reposition.AnimateHandCardTake(ch, imgs, u)
	return true
}

func pressButton(b *staticimg.StaticImg, u *uistate.UIState) {
	if !b.GetHidden() {
		u.Eng.SetSubTex(b.GetNode(), b.GetAlt())
		b.SetHidden(false)
		b.SetDisplayingImage(false)
	}
}

// returns buttons that were pressed
func unpressButtons(u *uistate.UIState) []*staticimg.StaticImg {
	pressed := make([]*staticimg.StaticImg, 0)
	for _, b := range u.Buttons {
		if b != nil && !b.GetDisplayingImage() && !b.GetHidden() {
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
		if b != nil && !b.GetDisplayingImage() && !b.GetHidden() {
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
			c.Move(d.GetCurrent(), c.GetDimensions(), u.Eng)
			d.SetCardHere(c)
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

func handleDebugButtonClick(b *staticimg.StaticImg, u *uistate.UIState) {
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
	} else if b == u.Buttons["restart"] {
		sync.ResetGame(u.LogSG, u.IsOwner, u)
	}
}
