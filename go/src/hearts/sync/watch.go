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
	"hearts/img/direction"
	"hearts/img/reposition"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"sort"
	"strconv"
	"strings"
	"time"
	"v.io/v23/syncbase/nosql"
)

func UpdateSettings(u *uistate.UIState) {
	scanner := ScanData(SettingsName, "users", u)
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
	stream, err := WatchData(SettingsName, "users", u)
	if err != nil {
		fmt.Println("WatchData error:", err)
	} else {
		for {
			if updateExists := stream.Advance(); updateExists {
				c := stream.Change()
				if c.ChangeType == nosql.PutChange {
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
			switch u.CurView {
			case uistate.Arrange:
				view.LoadArrangeView(u)
			case uistate.Table:
				view.LoadTableView(u)
			case uistate.Pass:
				view.LoadPassView(u)
			case uistate.Take:
				view.LoadTakeView(u)
			case uistate.Play:
				view.LoadPlayView(u)
			case uistate.Split:
				view.LoadSplitView(true, u)
			}
		}
	}
	if u.CurView == uistate.Discovery {
		view.LoadDiscoveryView(u)
	}
}

func UpdateGame(u *uistate.UIState) {
	stream, err := WatchData(LogName, fmt.Sprintf("%d", u.GameID), u)
	fmt.Println("STARTING WATCH FOR GAME", u.GameID)
	if err != nil {
		fmt.Println("WatchData error:", err)
	}
	updateBlock := make([]nosql.WatchChange, 0)
	for {
		if updateExists := stream.Advance(); updateExists {
			c := stream.Change()
			updateBlock = append(updateBlock, c)
			if !c.Continued {
				sort.Sort(updateSorter(updateBlock))
				handleGameUpdate(updateBlock, u)
				updateBlock = make([]nosql.WatchChange, 0)
			}
		}
	}
}

func handleGameUpdate(changes []nosql.WatchChange, u *uistate.UIState) {
	for _, c := range changes {
		if c.ChangeType == nosql.PutChange {
			key := c.Row
			var value []byte
			if err := c.Value(&value); err != nil {
				fmt.Println("Value error:", err)
			}
			valueStr := string(value)
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
		} else {
			fmt.Println("Unexpected ChangeType: ", c.ChangeType)
		}
	}
}

func onPlayerNum(key, value string, u *uistate.UIState) {
	userID, _ := strconv.Atoi(strings.Split(key, "/")[2])
	playerNum, _ := strconv.Atoi(value)
	u.PlayerData[playerNum] = userID
	if playerNum == u.CurPlayerIndex && userID != UserID {
		u.CurPlayerIndex = -1
	}
	if u.CurView == uistate.Arrange {
		view.LoadArrangeView(u)
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
		reposition.SetTableDropColors(u)
	} else if u.CurView == uistate.Take {
		if u.SequentialPhases {
			if u.CurTable.AllDonePassing() {
				view.LoadTakeView(u)
			}
		} else if u.CurPlayerIndex == receivingPlayer {
			view.LoadTakeView(u)
		}
	} else if u.CurView == uistate.Play && u.CurTable.AllDonePassing() {
		view.LoadPlayView(u)
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
				view.LoadPlayView(u)
			}
		}
	} else if p.HasTwoOfClubs() {
		u.CurTable.SetFirstPlayer(p.GetPlayerIndex())
		// UI
		if u.CurView == uistate.Play && u.CurPlayerIndex != playerInt {
			view.LoadPlayView(u)
		}
	}
	// UI
	if u.CurView == uistate.Table {
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardTake(passed, u.CurTable.GetPlayers()[playerInt], quit, u)
		reposition.SetTableDropColors(u)
	}
}

func onPlay(value string, u *uistate.UIState) {
	// logic
	playerInt, curCards := parsePlayerAndCards(value, u)
	playedCard := curCards[0]
	u.CurTable.GetPlayers()[playerInt].RemoveFromHand(playedCard)
	u.CurTable.SetPlayedCard(playedCard, playerInt)
	u.CurTable.GetPlayers()[playerInt].SetDonePlaying(true)
	trickOver := true
	trickCards := u.CurTable.GetTrick()
	for _, c := range trickCards {
		if c == nil {
			trickOver = false
		}
	}
	roundOver := false
	var recipient int
	if trickOver {
		roundOver, recipient = u.CurTable.SendTrick()
	}
	var roundScores []int
	var winners []int
	if roundOver {
		roundScores, winners = u.CurTable.EndRound()
	}
	// UI
	if u.CurView == uistate.Table {
		quit := make(chan bool)
		u.AnimChans = append(u.AnimChans, quit)
		reposition.AnimateTableCardPlay(playedCard, playerInt, quit, u)
		reposition.SetTableDropColors(u)
		if trickOver {
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
			view.SetNumTricksTable(u)
		}
	} else if u.CurView == uistate.Split {
		if roundOver {
			view.LoadScoreView(roundScores, winners, u)
		} else {
			if playerInt != u.CurPlayerIndex {
				quit := make(chan bool)
				u.AnimChans = append(u.AnimChans, quit)
				reposition.AnimateSplitCardPlay(playedCard, playerInt, quit, u)
			}
			reposition.SetSplitDropColors(u)
			if trickOver {
				var trickDir direction.Direction
				switch recipient {
				case u.CurPlayerIndex:
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
			}
			view.LoadSplitView(true, u)
		}
	} else if u.CurView == uistate.Play {
		if roundOver {
			view.LoadScoreView(roundScores, winners, u)
		} else if trickOver {
			if u.CurPlayerIndex != recipient {
				message := uistate.GetName(recipient, u) + "'s trick"
				view.ChangePlayMessage(message, u)
				<-time.After(2 * time.Second)
				view.LoadPlayView(u)
			} else {
				view.ChangePlayMessage("Your trick", u)
				<-time.After(2 * time.Second)
				view.LoadPlayView(u)
			}
		} else if u.CurPlayerIndex != playerInt {
			view.LoadPlayView(u)
		}
	}
	// logic
	if len(winners) > 0 {
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
type updateSorter []nosql.WatchChange

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
