// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// watch.go holds all code to handle updates to the syncbase gamelog.
// Update() is to be run as a goroutine, getting a watchstream from
// the syncgroup and updating the game state and UI display as a result
// of any changes that come along.

package watch

import (
	"fmt"
	"hearts/img/direction"
	"hearts/img/reposition"
	"hearts/img/uistate"
	"hearts/img/view"
	"hearts/logic/card"
	"hearts/syncbase/client"
	"hearts/syncbase/gamelog"
	"strconv"
	"strings"
	"time"
	"v.io/v23/syncbase/nosql"
)

func Update(u *uistate.UIState) {
	stream, err := client.WatchData(u)
	if err != nil {
		fmt.Println("WatchData error:", err)
	}
	for {
		if updateExists := stream.Advance(); updateExists {
			c := stream.Change()
			if c.ChangeType == nosql.PutChange {
				var value []byte
				if err := c.Value(&value); err != nil {
					fmt.Println("Value error:", err)
				}
				valueStr := string(value)
				fmt.Println(valueStr)
				updateType := strings.Split(valueStr, "|")[0]
				switch updateType {
				case gamelog.Deal:
					go onDeal(valueStr, u)
				case gamelog.Pass:
					go onPass(valueStr, u)
				case gamelog.Take:
					go onTake(valueStr, u)
				case gamelog.Play:
					go onPlay(valueStr, u)
				case gamelog.Ready:
					go onReady(valueStr, u)
				}
			} else {
				fmt.Println("Unexpected ChangeType: ", c.ChangeType)
			}
		}
		fmt.Println(stream.Err())
	}
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
	} else if u.CurView == uistate.Take && u.CurPlayerIndex == receivingPlayer {
		view.LoadTakeView(u)
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
	if p.HasTwoOfClubs() {
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
				message := u.CurTable.GetPlayers()[recipient].GetName() + "'s trick"
				view.ChangePlayMessage(message, u)
				<-time.After(1 * time.Second)
				view.LoadPlayView(u)
			} else {
				view.ChangePlayMessage("Your trick", u)
				<-time.After(1 * time.Second)
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
	if u.CurTable.AllReadyForNewRound() && u.IsOwner {
		newHands := u.CurTable.Deal()
		success := gamelog.LogDeal(u, u.CurPlayerIndex, newHands)
		for !success {
			success = gamelog.LogDeal(u, u.CurPlayerIndex, newHands)
		}
	}
	// UI
	if u.CurTable.AllReadyForNewRound() {
		if u.SGChan != nil {
			u.SGChan <- true
			u.SGChan = nil
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
