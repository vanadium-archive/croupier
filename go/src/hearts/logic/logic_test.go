// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"golang.org/x/mobile/exp/sprite"
	"hearts/logic/card"
	"hearts/logic/player"
	"hearts/logic/table"
	"sort"
	"testing"
)

var (
	texs   map[string]sprite.SubTex
	subtex sprite.SubTex
)

// Testing scoring after 1 trick
func TestOne(test *testing.T) {
	numPlayers := 4
	p2Expect := 15
	otherExpect := 0
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	t.SetFirstPlayer(1)
	t.SetPlayedCard(card.NewCard(card.Three, card.Heart), 1)
	t.SetPlayedCard(card.NewCard(card.Seven, card.Heart), 2)
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 3)
	t.SetPlayedCard(card.NewCard(card.Four, card.Diamond), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.EndRound()
	score := players[0].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = players[1].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = players[2].GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = players[3].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

// Testing scoring after multiple tricks
func TestTwo(test *testing.T) {
	numPlayers := 4
	p0Expect := 1
	p2Expect := 15
	otherExpect := 0
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	t.SetFirstPlayer(1)
	t.SetPlayedCard(card.NewCard(card.Three, card.Heart), 1)
	t.SetPlayedCard(card.NewCard(card.Seven, card.Heart), 2)
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 3)
	t.SetPlayedCard(card.NewCard(card.Four, card.Diamond), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetFirstPlayer(2)
	t.SetPlayedCard(card.NewCard(card.Five, card.Diamond), 2)
	t.SetPlayedCard(card.NewCard(card.Two, card.Heart), 3)
	t.SetPlayedCard(card.NewCard(card.King, card.Diamond), 0)
	t.SetPlayedCard(card.NewCard(card.Ace, card.Spade), 1)
	t.SendTrick(t.GetTrickRecipient())
	t.EndRound()
	score := players[0].GetScore()
	if score != p0Expect {
		test.Errorf("Expected %d, got %d", p0Expect, score)
	}
	score = players[1].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = players[2].GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = players[3].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

// Testing scoring after multiple rounds
func TestThree(test *testing.T) {
	numPlayers := 4
	p1Expect := 17
	p2Expect := 1
	otherExpect := 0
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	t.SetFirstPlayer(1)
	t.SetPlayedCard(card.NewCard(card.Eight, card.Heart), 1)
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 2)
	t.SetPlayedCard(card.NewCard(card.King, card.Spade), 3)
	t.SetPlayedCard(card.NewCard(card.Eight, card.Club), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetFirstPlayer(2)
	t.SetPlayedCard(card.NewCard(card.Five, card.Club), 2)
	t.SetPlayedCard(card.NewCard(card.Two, card.Club), 3)
	t.SetPlayedCard(card.NewCard(card.King, card.Heart), 0)
	t.SetPlayedCard(card.NewCard(card.Jack, card.Spade), 1)
	t.SendTrick(t.GetTrickRecipient())
	t.EndRound()
	t.SetFirstPlayer(3)
	t.SetPlayedCard(card.NewCard(card.Five, card.Spade), 3)
	t.SetPlayedCard(card.NewCard(card.Six, card.Spade), 0)
	t.SetPlayedCard(card.NewCard(card.Seven, card.Spade), 1)
	t.SetPlayedCard(card.NewCard(card.Ten, card.Heart), 2)
	t.SendTrick(t.GetTrickRecipient())
	t.SetFirstPlayer(1)
	t.SetPlayedCard(card.NewCard(card.Six, card.Diamond), 1)
	t.SetPlayedCard(card.NewCard(card.Two, card.Club), 2)
	t.SetPlayedCard(card.NewCard(card.King, card.Heart), 3)
	t.SetPlayedCard(card.NewCard(card.Jack, card.Heart), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.EndRound()
	score := players[0].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = players[1].GetScore()
	if score != p1Expect {
		test.Errorf("Expected %d, got %d", p1Expect, score)
	}
	score = players[2].GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = players[3].GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

// Testing dealing to make sure no duplicates are dealt
func TestFour(test *testing.T) {
	numPlayers := 4
	t := table.InitializeGame(numPlayers, texs)
	hands := t.Deal()
	testMap := make(map[*card.Card]int)
	for i := 0; i < 13; i++ {
		if testMap[hands[0][i]] == 0 {
			testMap[hands[0][i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[hands[1][i]] == 0 {
			testMap[hands[1][i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[hands[2][i]] == 0 {
			testMap[hands[2][i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[hands[3][i]] == 0 {
			testMap[hands[3][i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
	}
}

// Testing dealing to make sure enough cards are dealt
func TestFive(test *testing.T) {
	numPlayers := 4
	expect := 13
	t := table.InitializeGame(numPlayers, texs)
	hands := t.Deal()
	for i, h := range hands {
		if len(h) != expect {
			test.Errorf("Expected %d cards in the hand of player %d, got %d cards", expect, i, len(h))
		}
	}
}

// Testing playing a card-- HasSuit()
func TestSix(test *testing.T) {
	p := player.NewPlayer(0)
	p.AddToHand(card.NewCard(card.Six, card.Diamond))
	p.AddToHand(card.NewCard(card.Four, card.Spade))
	if !p.HasSuit(card.Diamond) || !p.HasSuit(card.Spade) {
		test.Errorf("False negative")
	}
	if p.HasSuit(card.Club) || p.HasSuit(card.Heart) {
		test.Errorf("False positive")
	}
}

// Testing playing a card-- HasAllPoints()
func TestSeven(test *testing.T) {
	p1 := player.NewPlayer(0)
	p2 := player.NewPlayer(1)
	p1.AddToHand(card.NewCard(card.Six, card.Heart))
	p1.AddToHand(card.NewCard(card.Queen, card.Spade))
	p2.AddToHand(card.NewCard(card.Two, card.Diamond))
	p2.AddToHand(card.NewCard(card.Five, card.Heart))
	if !p1.HasAllPoints() {
		test.Errorf("False negative")
	}
	if p2.HasAllPoints() {
		test.Errorf("False positive")
	}
}

// Testing playing a card-- ValidPlay() testing 2 of Clubs rule
func TestEight(test *testing.T) {
	numPlayers := 1
	t := table.InitializeGame(numPlayers, texs)
	t.SetFirstPlayer(0)
	if t.ValidPlayLogic(card.NewCard(card.Eight, card.Club), 0) == "" {
		test.Errorf("Expected invalid play for starting round with card other than 2 of Clubs")
	} else if t.ValidPlayLogic(card.NewCard(card.Two, card.Club), 0) != "" {
		test.Errorf("Expected valid play for starting round with 2 of Clubs")
	}
}

// Testing playing a card-- ValidPlay() testing first round points rule
func TestNine(test *testing.T) {
	numPlayers := 4
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	players[1].AddToHand(card.NewCard(card.Queen, card.Spade))
	players[1].AddToHand(card.NewCard(card.Three, card.Diamond))
	t.SetFirstPlayer(0)
	t.SetPlayedCard(card.NewCard(card.Two, card.Club), 0)
	if t.ValidPlayLogic(card.NewCard(card.Queen, card.Spade), 1) == "" {
		test.Errorf("Expected invalid play for points on the first round")
	}
}

// Testing playing a card-- ValidPlay() testing breaking Hearts rule
func TestTen(test *testing.T) {
	numPlayers := 2
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	players[0].AddToHand(card.NewCard(card.Five, card.Heart))
	players[1].AddToHand(card.NewCard(card.Two, card.Heart))
	players[1].AddToHand(card.NewCard(card.Three, card.Diamond))
	t.SetFirstPlayer(0)
	t.SetPlayedCard(card.NewCard(card.Two, card.Club), 0)
	t.SetPlayedCard(card.NewCard(card.Three, card.Club), 1)
	t.SendTrick(t.GetTrickRecipient())
	t.SetFirstPlayer(0)
	if t.ValidPlayLogic(card.NewCard(card.Five, card.Heart), 0) != "" {
		test.Errorf("Expected valid play for opener rightfully breaking Hearts")
	}
	t.SetFirstPlayer(1)
	if t.ValidPlayLogic(card.NewCard(card.Two, card.Heart), 1) == "" {
		test.Errorf("Expected invalid play for opener wrongfully breaking Hearts")
	}
	t.SetPlayedCard(card.NewCard(card.Three, card.Diamond), 1)
	if t.ValidPlayLogic(card.NewCard(card.Five, card.Heart), 0) != "" {
		test.Errorf("Expected valid play for follower rightfully breaking Hearts")
	}
	players[0].AddToHand(card.NewCard(card.Seven, card.Diamond))
	if t.ValidPlayLogic(card.NewCard(card.Five, card.Heart), 0) == "" {
		test.Errorf("Expected invalid play for follower wrongfully breaking Hearts")
	}
}

// Testing playing a card-- ValidPlay() testing following suit rule
func TestEleven(test *testing.T) {
	numPlayers := 2
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	players[0].AddToHand(card.NewCard(card.Two, card.Club))
	players[1].AddToHand(card.NewCard(card.Three, card.Diamond))
	t.SetFirstPlayer(0)
	t.SetPlayedCard(card.NewCard(card.Two, card.Club), 0)
	if t.ValidPlayLogic(card.NewCard(card.Three, card.Diamond), 1) != "" {
		test.Errorf("Expected valid play for not following suit when player doesn't have suit")
	}
	players[1].AddToHand(card.NewCard(card.Five, card.Club))
	if t.ValidPlayLogic(card.NewCard(card.Five, card.Club), 1) != "" {
		test.Errorf("Expected valid play for following suit")
	}
	if t.ValidPlayLogic(card.NewCard(card.Three, card.Diamond), 1) == "" {
		test.Errorf("Expected invalid play for not following suit when player has suit")
	}
}

// Testing win condition
func TestTwelve(test *testing.T) {
	numPlayers := 1
	t := table.InitializeGame(numPlayers, texs)
	t.SetFirstPlayer(0)
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	_, winners := t.EndRound()
	expect := 0
	if len(winners) != expect {
		test.Errorf("Expected %d, got %d", expect, winners[0])
	}
	t.NewRound()
	t.SetFirstPlayer(0)
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	t.SetPlayedCard(card.NewCard(card.Queen, card.Spade), 0)
	t.SendTrick(t.GetTrickRecipient())
	_, winners = t.EndRound()
	expect = 0
	if winners[0] != expect {
		test.Errorf("Expected %d, got %d", expect, winners[0])
	}
}

// Testing WorthPoints()
func TestThirteen(test *testing.T) {
	c := card.NewCard(card.Queen, card.Spade)
	if !c.WorthPoints() {
		test.Errorf("Expected WorthPoints to be true on Queen of Spades, got false")
	}
	c = card.NewCard(card.King, card.Spade)
	if c.WorthPoints() {
		test.Errorf("Expected WorthPoints to be false on King of Spades, got true")
	}
	c = card.NewCard(card.Two, card.Heart)
	if !c.WorthPoints() {
		test.Errorf("Expected WorthPoints to be true on Two of Hearts, got false")
	}
}

// Testing card sorting
func TestFourteen(test *testing.T) {
	numPlayers := 1
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	t.Deal()
	hand := players[0].GetHand()
	sort.Sort(card.CardSorter(hand))
	for i, c := range hand {
		if i < len(hand)-1 {
			nextCard := hand[i+1]
			if c.GetSuit() == nextCard.GetSuit() {
				if nextCard.GetFace() < c.GetFace() {
					test.Errorf("Out of order within suit")
				}
			} else {
				switch c.GetSuit() {
				case card.Diamond:
					if nextCard.GetSuit() == card.Club {
						test.Errorf("Suits out of order")
					}
				case card.Spade:
					if nextCard.GetSuit() == card.Club || nextCard.GetSuit() == card.Diamond {
						test.Errorf("Suits out of order")
					}
				case card.Heart:
					test.Errorf("Suits out of order")
				}
			}
		}
	}
}

// Testing initializing game with illegal number of players
func TestFifteen(test *testing.T) {
	expect := 0
	numPlayers := -1
	t := table.InitializeGame(numPlayers, texs)
	players := t.GetPlayers()
	if len(players) != expect {
		test.Errorf("Expected %d, got %d", expect, len(players))
	}
}
