// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// watch.go holds all code to handle updates to the syncbase gamelog.
// Update() is to be run as a goroutine, getting a watchstream from
// the syncgroup and updating the game state and UI display as a result
// of any changes that come along.

package sync

import (
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	"golang.org/x/mobile/exp/sprite"

	"hearts/img/direction"
	"hearts/img/reposition"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"hearts/sound"
	"hearts/util"

	"v.io/v23/syncbase"
)

func UpdateSettings(u *uistate.UIState) {
	scanner := ScanData(util.SettingsName, "users", u)
	for {
		if updateExists := scanner.Advance(); updateExists {
			key := scanner.Key()
			var value []byte
			if err := scanner.Value(&value); err != nil {
				fmt.Println("Value error:", err)
			}
			handleSettingsUpdate(key, value, u)
		} else {
			break
		}
	}
	stream, err := WatchData(util.SettingsName, "users", u)
	if err != nil {
		fmt.Println("WatchData error:", err)
	} else {
		for {
			if updateExists := stream.Advance(); updateExists {
				c := stream.Change()
				if c.ChangeType == syncbase.PutChange {
					key := c.Row
					var value []byte
					if err := c.Value(&value); err != nil {
						fmt.Println("Value error:", err)
					}
					handleSettingsUpdate(key, value, u)
				} else {
					fmt.Println("Unexpected ChangeType: ", c.ChangeType)
				}
			}
		}
	}
}

func handleSettingsUpdate(key string, value []byte, u *uistate.UIState) {
	var valueMap map[string]interface{}
	err := json.Unmarshal(value, &valueMap)
	if err != nil {
		fmt.Println("Unmarshal error:", err)
	}
	userID, _ := strconv.Atoi(strings.Split(key, "/")[1])
	u.UserData[userID] = valueMap
	for _, v := range u.PlayerData {
		if v == userID {
			view.ReloadView(u)
		}
	}
	if u.CurView == uistate.Discovery {
		view.LoadDiscoveryView(u)
	}
}

func UpdateGame(quit chan bool, u *uistate.UIState) {
	file, err := os.OpenFile("/sdcard/test.txt", os.O_RDWR|os.O_APPEND|os.O_CREATE, 0666)
	if err != nil {
		fmt.Println("err:", err)
	}
	fmt.Fprintf(file, fmt.Sprintf("\n***NEW GAME: %d\n", u.GameID))
	defer file.Close()
	scanner := ScanData(util.LogName, fmt.Sprintf("%d", u.GameID), u)
	m := make(map[string][]byte)
	keys := make([]string, 0)
	for scanner.Advance() {
		k := scanner.Key()
		var v []byte
		if err := scanner.Value(&v); err != nil {
			fmt.Println("Value error:", err)
		}
		id := strings.Split(k, "/")[0]
		if id == fmt.Sprintf("%d", u.GameID) {
			m[k] = v
			keys = append(keys, k)
		}
	}
	sort.Sort(scanSorter(keys))
	for _, key := range keys {
		select {
		case <-quit:
			return
		default:
			value := m[key]
			handleGameUpdate(file, key, value, u)
		}
	}
	stream, err2 := WatchData(util.LogName, fmt.Sprintf("%d", u.GameID), u)
	fmt.Println("STARTING WATCH FOR GAME", u.GameID)
	if err2 != nil {
		fmt.Println("WatchData error:", err2)
	}
	updateBlock := make([]syncbase.WatchChange, 0)
	for {
		if updateExists := stream.Advance(); updateExists {
			c := stream.Change()
			updateBlock = append(updateBlock, c)
			if !c.Continued {
				sort.Sort(updateSorter(updateBlock))
				for _, c := range updateBlock {
					select {
					case <-quit:
						return
					default:
						if c.ChangeType == syncbase.PutChange {
							key := c.Row
							var value []byte
							if err := c.Value(&value); err != nil {
								fmt.Println("Value error:", err)
							}
							handleGameUpdate(file, key, value, u)
						} else {
							fmt.Println("Unexpected ChangeType: ", c.ChangeType)
						}
					}
				}
				updateBlock = make([]syncbase.WatchChange, 0)
			}
		}
	}
}

func handleGameUpdate(file *os.File, key string, value []byte, u *uistate.UIState) {
	curTime := time.Now().UnixNano() / 1000000
	valueStr := string(value)
	fmt.Fprintf(file, fmt.Sprintf("key: %s\n", key))
	fmt.Fprintf(file, fmt.Sprintf("value: %s\n", valueStr))
	fmt.Fprintf(file, fmt.Sprintf("time: %v\n", curTime))
	tmp := strings.Split(key, "/")
	if len(tmp) == 3 {
		keyTime, _ := strconv.ParseInt(strings.Split(tmp[2], "-")[0], 10, 64)
		if keyTime > u.LatestTimestamp {
			u.LatestTimestamp = keyTime
		}
		fmt.Fprintf(file, fmt.Sprintf("diff: %d milliseconds\n\n", curTime-keyTime))
	} else {
		fmt.Fprintf(file, "\n")
	}
	fmt.Println(key, valueStr)
	keyType := strings.Split(key, "/")[1]
	switch keyType {
	case "log":
		updateType := strings.Split(valueStr, "|")[0]
		switch updateType {
		case Deal:
			onDeal(valueStr, u)
		case Pass:
			onPass(valueStr, u)
		case Take:
			onTake(valueStr, u)
		case Play:
			onPlay(valueStr, u)
		case TakeTrick:
			onTakeTrick(valueStr, u)
		case Ready:
			onReady(valueStr, u)
		}
	case "players":
		switch strings.Split(key, "/")[3] {
		case "player_number":
			onPlayerNum(key, valueStr, u)
		case "settings_sg":
			onSettings(key, valueStr, u)
		}
	}
}

func onPlayerNum(key, value string, u *uistate.UIState) {
	userID, _ := strconv.Atoi(strings.Split(key, "/")[2])
	playerNum, _ := strconv.Atoi(value)
	if playerNum >= 0 && playerNum < 4 {
		u.PlayerData[playerNum] = userID
		u.CurTable.GetPlayers()[playerNum].SetDoneScoring(true)
	}
	if playerNum == u.CurPlayerIndex && userID != util.UserID {
		u.CurPlayerIndex = -1
	}
	if u.CurView == uistate.Arrange {
		view.LoadArrangeView(u)
		if u.CurTable.AllReadyForNewRound() && u.IsOwner {
			b := u.Buttons["start"]
			u.Eng.SetSubTex(b.GetNode(), b.GetImage())
			b.SetHidden(false)
			b.SetDisplayingImage(true)
			if u.SGChan != nil {
				u.SGChan <- true
				u.SGChan = nil
			}
		}
	}
}

func onSettings(key, value string, u *uistate.UIState) {
	JoinSettingsSyncgroup(value, u)
}

func onDeal(value string, u *uistate.UIState) {
	playerInt, curCards := parsePlayerAndCards(value, u)
	u.CurTable.GetPlayers()[playerInt].SetHand(curCards)
	if u.CurTable.AllDoneDealing() {
		u.CurTable.NewRound()
		if u.CurPlayerIndex >= 0 && u.CurPlayerIndex < u.NumPlayers {
			view.LoadPassOrTakeOrPlay(u)
		} else {
			view.LoadTableView(u)
		}
	}
}

func onPass(value string, u *uistate.UIState) {
	// logic
	playerInt, curCards := parsePlayerAndCards(value, u)
	var receivingPlayer int
	switch u.CurTable.GetDir() {
	case direction.Right:
		receivingPlayer = (playerInt + 3) % u.NumPlayers
	case direction.Left:
		receivingPlayer = (playerInt + 1) % u.NumPlayers
	case direction.Across:
		receivingPlayer = (playerInt + 2) % u.NumPlayers
	}
	for _, c := range curCards {
		u.CurTable.GetPlayers()[playerInt].RemoveFromHand(c)
	}
	u.CurTable.GetPlayers()[playerInt].SetPassedFrom(curCards)
	u.CurTable.GetPlayers()[receivingPlayer].SetPassedTo(curCards)
	u.CurTable.GetPlayers()[playerInt].SetDonePassing(true)
	// UI
	if u.CurView == uistate.Table {
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardPass(curCards, receivingPlayer, quit, u)
		view.LoadTableView(u)
	} else if u.CurView == uistate.Take {
		if u.SequentialPhases {
			if u.CurTable.AllDonePassing() {
				view.LoadTakeView(u)
			}
		} else if u.CurPlayerIndex == receivingPlayer {
			view.LoadTakeView(u)
		}
	} else if u.CurView == uistate.Play && u.CurTable.AllDonePassing() {
		view.LoadPlayView(true, u)
	}
}

func onTake(value string, u *uistate.UIState) {
	// logic
	playerInt, _ := parsePlayerAndCards(value, u)
	p := u.CurTable.GetPlayers()[playerInt]
	passed := p.GetPassedTo()
	for _, c := range passed {
		p.AddToHand(c)
	}
	u.CurTable.GetPlayers()[playerInt].SetDoneTaking(true)
	if u.SequentialPhases {
		if u.CurTable.AllDoneTaking() {
			for _, player := range u.CurTable.GetPlayers() {
				if player.HasTwoOfClubs() {
					u.CurTable.SetFirstPlayer(player.GetPlayerIndex())
				}
			}
			// UI
			if u.CurView == uistate.Play {
				view.LoadPlayView(true, u)
			}
		}
	} else if p.HasTwoOfClubs() {
		u.CurTable.SetFirstPlayer(p.GetPlayerIndex())
		// UI
		if u.CurView == uistate.Play && u.CurPlayerIndex != playerInt {
			view.LoadPlayView(true, u)
		}
	}
	// UI
	if u.CurView == uistate.Table {
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardTake(passed, u.CurTable.GetPlayers()[playerInt], quit, u)
		view.LoadTableView(u)
	}
}

func onPlay(value string, u *uistate.UIState) {
	// logic
	playerInt, curCards := parsePlayerAndCards(value, u)
	playedCard := curCards[0]
	u.CurTable.GetPlayers()[playerInt].RemoveFromHand(playedCard)
	u.CurTable.SetPlayedCard(playedCard, playerInt)
	u.CurTable.GetPlayers()[playerInt].SetDonePlaying(true)
	trickOver := u.CurTable.TrickOver()
	var recipient int
	if trickOver {
		recipient = u.CurTable.GetTrickRecipient()
	}
	// UI
	if u.CurView == uistate.Table {
		sound.PlaySound(0, u)
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardPlay(playedCard, playerInt, quit, u)
		reposition.SetTableDropColors(u)
		if trickOver {
			// display take trick button
			b := u.Buttons["takeTrick"]
			u.Eng.SetSubTex(b.GetNode(), b.GetImage())
			b.SetHidden(false)
		}
	} else if u.CurView == uistate.Split {
		if playerInt != u.CurPlayerIndex {
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			reposition.AnimateSplitCardPlay(playedCard, playerInt, quit, u)
		}
		reposition.SetSplitDropColors(u)
		view.LoadSplitView(true, u)
		if trickOver {
			if recipient == u.CurPlayerIndex {
				// display take trick button
				b := u.Buttons["takeTrick"]
				u.Eng.SetSubTex(b.GetNode(), b.GetImage())
				b.SetHidden(false)
			}
		} else if u.CardToPlay != nil && u.CurTable.WhoseTurn() == u.CurPlayerIndex {
			ch := make(chan bool)
			if err := PlayCard(ch, u.CurPlayerIndex, u); err != "" {
				view.ChangePlayMessage(err, u)
				RemoveCardFromTarget(u.CardToPlay, u)
				// add card back to hand
				reposition.ResetCardPosition(u.CardToPlay, u.Eng)
			}
			u.CardToPlay = nil
			u.BackgroundImgs[0].GetNode().Arranger = nil
			var emptyTex sprite.SubTex
			u.Eng.SetSubTex(u.BackgroundImgs[0].GetNode(), emptyTex)
			u.BackgroundImgs[0].SetHidden(true)
		}
	} else if u.CurView == uistate.Play && u.CurPlayerIndex != playerInt {
		view.LoadPlayView(true, u)
		if u.CardToPlay != nil && u.CurTable.WhoseTurn() == u.CurPlayerIndex {
			ch := make(chan bool)
			if err := PlayCard(ch, u.CurPlayerIndex, u); err != "" {
				view.ChangePlayMessage(err, u)
				RemoveCardFromTarget(u.CardToPlay, u)
				// add card back to hand
				reposition.ResetCardPosition(u.CardToPlay, u.Eng)
				reposition.RealignSuit(u.CardToPlay.GetSuit(), u.CardToPlay.GetInitial().Y, u)
			}
			u.CardToPlay = nil
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
		}
	}
}

func onTakeTrick(value string, u *uistate.UIState) {
	trickCards := u.CurTable.GetTrick()
	recipient := u.CurTable.GetTrickRecipient()
	roundOver := u.CurTable.SendTrick(recipient)
	if roundOver {
		u.RoundScores, u.Winners = u.CurTable.EndRound()
	}
	// UI
	if u.CurView == uistate.Table {
		sound.PlaySound(1, u)
		var emptyTex sprite.SubTex
		u.Eng.SetSubTex(u.Buttons["takeTrick"].GetNode(), emptyTex)
		u.Buttons["takeTrick"].SetHidden(true)
		var trickDir direction.Direction
		switch recipient {
		case 0:
			trickDir = direction.Down
		case 1:
			trickDir = direction.Left
		case 2:
			trickDir = direction.Across
		case 3:
			trickDir = direction.Right
		}
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardTakeTrick(trickCards, trickDir, quit, u)
		reposition.SetTableDropColors(u)
		view.SetNumTricksTable(u)
	} else if u.CurView == uistate.Split {
		var emptyTex sprite.SubTex
		u.Eng.SetSubTex(u.Buttons["takeTrick"].GetNode(), emptyTex)
		u.Buttons["takeTrick"].SetHidden(true)
		if roundOver {
			view.LoadScoreView(u)
		} else {
			var trickDir direction.Direction
			switch recipient {
			case u.CurPlayerIndex:
				sound.PlaySound(0, u)
				trickDir = direction.Down
			case (u.CurPlayerIndex + 1) % u.NumPlayers:
				trickDir = direction.Left
			case (u.CurPlayerIndex + 2) % u.NumPlayers:
				trickDir = direction.Across
			case (u.CurPlayerIndex + 3) % u.NumPlayers:
				trickDir = direction.Right
			}
			quit := make(chan bool)
			u.AnimChans = append(u.AnimChans, quit)
			reposition.AnimateTableCardTakeTrick(trickCards, trickDir, quit, u)
			view.LoadSplitView(true, u)
		}
	} else if u.CurView == uistate.Play {
		if roundOver {
			view.LoadScoreView(u)
		} else {
			if recipient == u.CurPlayerIndex {
				sound.PlaySound(0, u)
			}
			view.LoadPlayView(true, u)
		}
	}
	// logic
	if len(u.Winners) > 0 {
		u.CurTable.NewGame()
	}
}

func onReady(value string, u *uistate.UIState) {
	// logic
	playerInt, _ := parsePlayerAndCards(value, u)
	u.CurTable.GetPlayers()[playerInt].SetDoneScoring(true)
	// UI
	if u.CurTable.AllReadyForNewRound() && u.IsOwner {
		if u.CurView == uistate.Arrange {
			b := u.Buttons["start"]
			u.Eng.SetSubTex(b.GetNode(), b.GetImage())
			b.SetHidden(false)
			b.SetDisplayingImage(true)
			if u.SGChan != nil {
				u.SGChan <- true
				u.SGChan = nil
			}
		} else if u.CurView == uistate.Score {
			newHands := u.CurTable.Deal()
			successDeal := LogDeal(u, u.CurPlayerIndex, newHands)
			for !successDeal {
				successDeal = LogDeal(u, u.CurPlayerIndex, newHands)
			}
		}
	}
}

func parsePlayerAndCards(value string, u *uistate.UIState) (int, []*card.Card) {
	updateContents := strings.Split(value, "|")[1]
	playerIntPlusCards := strings.Split(updateContents, ":")
	playerInt, _ := strconv.Atoi(playerIntPlusCards[0])
	cardList := u.CurTable.GetAllCards()
	curCards := make([]*card.Card, 0)
	for i := 1; i < len(playerIntPlusCards)-1; i++ {
		cardInfo := playerIntPlusCards[i]
		cardSuitFace := strings.Split(cardInfo, " ")[1]
		cardSuit := card.ConvertToSuit(string(cardSuitFace[0]))
		cardFace := card.ConvertToFace(string(cardSuitFace[1:]))
		cardIndex := int(cardSuit*13) + int(cardFace) - 2
		curCards = append(curCards, cardList[cardIndex])
	}
	return playerInt, curCards
}

// Used to sort an array of watch changes
type updateSorter []syncbase.WatchChange

// Returns the length of the array
func (us updateSorter) Len() int {
	return len(us)
}

// Swaps the positions of two changes in the array
func (us updateSorter) Swap(i, j int) {
	us[i], us[j] = us[j], us[i]
}

// Compares two changes-- one card is less than another if it has an earlier timestamp
func (us updateSorter) Less(i, j int) bool {
	iKey := us[i].Row
	jKey := us[j].Row
	return iKey < jKey
}

type scanSorter []string

func (ss scanSorter) Len() int {
	return len(ss)
}

// Swaps the positions of two changes in the array
func (ss scanSorter) Swap(i, j int) {
	ss[i], ss[j] = ss[j], ss[i]
}

// Compares two changes-- one card is less than another if it has an earlier timestamp
func (ss scanSorter) Less(i, j int) bool {
	iKey := ss[i]
	jKey := ss[j]
	return iKey < jKey
}

func PlayCard(ch chan bool, playerId int, u *uistate.UIState) string {
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
	sound.PlaySound(1, u)
	success := LogPlay(u, c)
	for !success {
		success = LogPlay(u, c)
	}
	// no animation when in split view
	if u.CurView == uistate.Play {
		reposition.AnimateHandCardPlay(ch, c, u)
	}
	return ""
}

func RemoveCardFromTarget(c *card.Card, u *uistate.UIState) bool {
	for _, d := range u.DropTargets {
		if d.GetCardHere() == c {
			d.SetCardHere(nil)
			return true
		}
	}
	return false
}
