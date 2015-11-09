// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// touchhandler handles all touch events for the app

package touchhandler

import (
	"fmt"
	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/sprite"
	"hearts/img/coords"
	"hearts/img/reposition"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"hearts/syncbase/gamelog"
)

func OnTouch(t touch.Event, u *uistate.UIState) {
	switch u.CurView {
	case uistate.Opening:
		switch t.Type.String() {
		case "begin":
			beginClickOpening(t, u)
		}
	case uistate.Table:
		switch t.Type.String() {
		case "begin":
			beginClickTable(t, u)
		}
	case uistate.Pass:
		switch t.Type.String() {
		case "begin":
			beginClickPass(t, u)
		case "move":
			moveClickPass(t, u)
		case "end":
			endClickPass(t, u)
		}
	case uistate.Take:
		switch t.Type.String() {
		case "begin":
			beginClickTake(t, u)
		case "move":
			moveClickTake(t, u)
		case "end":
			endClickTake(t, u)
		}
	case uistate.Play:
		switch t.Type.String() {
		case "begin":
			beginClickPlay(t, u)
		case "move":
			moveClickPlay(t, u)
		case "end":
			endClickPlay(t, u)
		}
	case uistate.Score:
		switch t.Type.String() {
		case "begin":
			beginClickScore(t, u)
		}
	}
	u.LastMouseXY.X = t.X
	u.LastMouseXY.Y = t.Y
}

func beginClickOpening(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		if u.CurTable.GetPlayers()[0].GetHand() == nil {
			fmt.Println("Dealing")
			allHands := u.CurTable.Deal()
			gamelog.LogDeal(u, u.CurPlayerIndex, allHands)
		}
	}
}

func beginClickTable(t touch.Event, u *uistate.UIState) {
	if u.Debug {
		buttonList := findClickedButton(t, u)
		if len(buttonList) > 0 {
			if u.Buttons[0] == buttonList[0] {
				u.CurPlayerIndex = 0
				view.LoadPassOrTakeOrPlay(u)
			} else if u.Buttons[1] == buttonList[0] {
				u.CurPlayerIndex = 1
				view.LoadPassOrTakeOrPlay(u)
			} else if u.Buttons[2] == buttonList[0] {
				u.CurPlayerIndex = 2
				view.LoadPassOrTakeOrPlay(u)
			} else if u.Buttons[3] == buttonList[0] {
				u.CurPlayerIndex = 3
				view.LoadPassOrTakeOrPlay(u)
			} else if u.Buttons[4] == buttonList[0] {
				view.LoadTableView(u)
			} else if u.Buttons[5] == buttonList[0] {
				view.LoadPassOrTakeOrPlay(u)
			}
		}
	}
}

func beginClickPass(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		if u.Debug {
			if u.Buttons[0] == buttonList[0] {
				pullTab := u.Buttons[0]
				if pullTab.GetDisplayingImage() {
					u.CurImg = u.Buttons[0]
					for _, img := range u.Other {
						u.Eng.SetSubTex(img.GetNode(), img.GetAlt())
						img.SetDisplayingImage(false)
					}
					blueBanner := u.Other[0]
					if blueBanner.GetNode().Arranger == nil {
						finalX := blueBanner.GetInitial().X
						finalY := pullTab.GetInitial().Y + pullTab.GetDimensions().Y - blueBanner.GetDimensions().Y
						finalPos := coords.MakeVec(finalX, finalY)
						reposition.AnimateImageNoChannel(blueBanner, finalPos, blueBanner.GetDimensions())
					}
				}
			} else if u.Buttons[1] == buttonList[0] {
				view.LoadTableView(u)
			} else if u.Buttons[2] == buttonList[0] {
				view.LoadPassOrTakeOrPlay(u)
			}
		} else {
			pullTab := u.Buttons[0]
			if pullTab.GetDisplayingImage() {
				for _, img := range u.Other {
					u.Eng.SetSubTex(img.GetNode(), img.GetAlt())
					img.SetDisplayingImage(false)
				}
			}
		}
	}
}

func moveClickPass(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	} else if u.CurImg != nil {
		imgs := make([]*staticimg.StaticImg, 0)
		cards := make([]*card.Card, 0)
		pullTab := u.Buttons[0]
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
		pullTab := u.Buttons[0]
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
		go func() {
			<-ch
			if !success {
				fmt.Println("Invalid pass")
			} else {
				view.LoadTakeView(u)
			}
		}()
	}
	u.CurCard = nil
	u.CurImg = nil
}

func beginClickTake(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		if u.Debug {
			if u.Buttons[0] == buttonList[0] {
				view.LoadTableView(u)
			} else if u.Buttons[1] == buttonList[0] {
				view.LoadPassOrTakeOrPlay(u)
			}
		}
	}
}

func moveClickTake(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
}

func endClickTake(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		// check to see if card was removed from a drop target
		removeCardFromTarget(u.CurCard, u)
		// add card back to hand
		reposition.ResetCardPosition(u.CurCard, u.Eng)
		reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
		doneTaking := true
		for _, d := range u.DropTargets {
			if d.GetCardHere() != nil {
				doneTaking = false
			}
		}
		if doneTaking {
			ch := make(chan bool)
			success := takeCards(ch, u.CurPlayerIndex, u)
			go func() {
				<-ch
				if !success {
					fmt.Println("Invalid take")
				} else {
					view.LoadPlayView(u)
				}
			}()
		}
	}
	u.CurCard = nil
}

func beginClickPlay(t touch.Event, u *uistate.UIState) {
	u.CurCard = findClickedCard(t, u)
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		if u.Debug {
			if u.Buttons[0] == buttonList[0] {
				u.CurImg = u.Buttons[0]
			} else if u.Buttons[1] == buttonList[0] {
				view.LoadTableView(u)
			} else if u.Buttons[2] == buttonList[0] {
				view.LoadPassOrTakeOrPlay(u)
			}
		}
	}
}

func moveClickPlay(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		reposition.DragCard(t, u)
	}
}

func endClickPlay(t touch.Event, u *uistate.UIState) {
	if u.CurCard != nil {
		if !dropCardOnTarget(u.CurCard, t, u) {
			// check to see if card was removed from a drop target
			removeCardFromTarget(u.CurCard, u)
			// add card back to hand
			reposition.ResetCardPosition(u.CurCard, u.Eng)
			reposition.RealignSuit(u.CurCard.GetSuit(), u.CurCard.GetInitial().Y, u)
		} else {
			ch := make(chan bool)
			err := playCard(ch, u.CurPlayerIndex, u)
			go func() {
				<-ch
				if err != "" {
					fmt.Println(err)
				} else {
					view.LoadPlayView(u)
				}
			}()
		}
	}
	u.CurCard = nil
}

func beginClickScore(t touch.Event, u *uistate.UIState) {
	buttonList := findClickedButton(t, u)
	if len(buttonList) > 0 {
		success := gamelog.LogReady(u)
		for !success {
			gamelog.LogReady(u)
		}
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
	if u.CurTable.ValidPass(cardsPassed) && !u.CurTable.GetPlayers()[playerId].GetDonePassing() {
		success := gamelog.LogPass(u, cardsPassed)
		for !success {
			success = gamelog.LogPass(u, cardsPassed)
		}
		// UI component
		pullTab := u.Buttons[0]
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
	return false
}

func takeCards(ch chan bool, playerId int, u *uistate.UIState) bool {
	player := u.CurTable.GetPlayers()[playerId]
	passedCards := player.GetPassedTo()
	if len(passedCards) == 3 {
		success := gamelog.LogTake(u)
		for !success {
			success = gamelog.LogTake(u)
		}
		reposition.AnimateHandCardTake(ch, u.Other, u)
		return true
	}
	return false
}

func playCard(ch chan bool, playerId int, u *uistate.UIState) string {
	c := u.DropTargets[0].GetCardHere()
	if c != nil {
		// checks to make sure that:
		// -player has not already played a card this round
		// -all players have passed cards
		// -the play is in the right order
		// -the play is valid given game logic
		if u.CurTable.GetPlayers()[playerId].GetDonePlaying() {
			return "Invalid play: The current player has already played a card in this trick"
		}
		if !u.CurTable.AllDonePassing() {
			return "Invalid play: Not all players have passed their cards"
		}
		if !u.CurTable.ValidPlayOrder(playerId) {
			return "Invalid play: It is not the current player's turn"
		}
		if !u.CurTable.ValidPlayLogic(c, playerId) {
			return "Invalid play: This card does not follow game logic"
		}
		u.DropTargets[0].SetCardHere(nil)
		success := gamelog.LogPlay(u, c)
		for !success {
			success = gamelog.LogPlay(u, c)
		}
		reposition.AnimateHandCardPlay(ch, c, u)
		return ""
	}
	return "Invalid play: No card has been played"
}

func pressButton(b *staticimg.StaticImg, u *uistate.UIState) {
	u.Eng.SetSubTex(b.GetNode(), b.GetAlt())
	b.SetDisplayingImage(false)
}

func unpressButtons(u *uistate.UIState) {
	for _, b := range u.Buttons {
		u.Eng.SetSubTex(b.GetNode(), b.GetImage())
		b.SetDisplayingImage(true)
	}
}

func dropCardOnTarget(c *card.Card, t touch.Event, u *uistate.UIState) bool {
	for _, d := range u.DropTargets {
		// checking to see if card was dropped onto a drop target
		if touchingStaticImg(t, d, u) {
			lastDroppedCard := d.GetCardHere()
			if lastDroppedCard != nil {
				reposition.ResetCardPosition(lastDroppedCard, u.Eng)
				if u.CurView == uistate.Pass || u.CurView == uistate.Play {
					reposition.RealignSuit(lastDroppedCard.GetSuit(), lastDroppedCard.GetInitial().Y, u)
				} else if u.CurView == uistate.Table {
					u.Eng.SetSubTex(lastDroppedCard.GetNode(), lastDroppedCard.GetBack())
					lastDroppedCard.Move(lastDroppedCard.GetCurrent(), u.TableCardDim, u.Eng)
				}
			}
			oldY := c.GetInitial().Y
			suit := c.GetSuit()
			u.CurCard.Move(d.GetCurrent(), c.GetDimensions(), u.Eng)
			d.SetCardHere(u.CurCard)
			// realign suit the card just left
			if u.CurView == uistate.Pass || u.CurView == uistate.Play {
				reposition.RealignSuit(suit, oldY, u)
			}
			return true
		}
	}
	return false
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
