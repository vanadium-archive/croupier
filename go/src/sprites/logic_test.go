// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"sprites/card"
	"sprites/player"
	"sprites/table"
	"testing"
)

//Testing scoring after 1 trick
func TestOne(test *testing.T) {
	p2Expect := 15
	otherExpect := 0
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p2 := player.NewPlayer(2)
	p3 := player.NewPlayer(3)
	players := []*player.Player{p0, p1, p2, p3}
	t := table.NewTable(players)
	t.SetFirst(1)
	t.PlayCard(card.NewCard(3, "H"), 1)
	t.PlayCard(card.NewCard(7, "H"), 2)
	t.PlayCard(card.NewCard(12, "S"), 3)
	t.PlayCard(card.NewCard(4, "D"), 0)
	t.SendTrick()
	t.EndRound()
	score := p0.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = p1.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = p2.GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = p3.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

//Testing scoring after multiple tricks
func TestTwo(test *testing.T) {
	p0Expect := 1
	p2Expect := 15
	otherExpect := 0
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p2 := player.NewPlayer(2)
	p3 := player.NewPlayer(3)
	players := []*player.Player{p0, p1, p2, p3}
	t := table.NewTable(players)
	t.SetFirst(1)
	t.PlayCard(card.NewCard(3, "H"), 1)
	t.PlayCard(card.NewCard(7, "H"), 2)
	t.PlayCard(card.NewCard(12, "S"), 3)
	t.PlayCard(card.NewCard(4, "D"), 0)
	t.SendTrick()
	t.SetFirst(2)
	t.PlayCard(card.NewCard(5, "D"), 2)
	t.PlayCard(card.NewCard(2, "H"), 3)
	t.PlayCard(card.NewCard(13, "D"), 0)
	t.PlayCard(card.NewCard(14, "S"), 1)
	t.SendTrick()
	t.EndRound()
	score := p0.GetScore()
	if score != p0Expect {
		test.Errorf("Expected %d, got %d", p0Expect, score)
	}
	score = p1.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = p2.GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = p3.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

//Testing scoring after multiple rounds
func TestThree(test *testing.T) {
	p1Expect := 17
	p2Expect := 1
	otherExpect := 0
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p2 := player.NewPlayer(2)
	p3 := player.NewPlayer(3)
	players := []*player.Player{p0, p1, p2, p3}
	t := table.NewTable(players)
	t.SetFirst(1)
	t.PlayCard(card.NewCard(8, "H"), 1)
	t.PlayCard(card.NewCard(12, "S"), 2)
	t.PlayCard(card.NewCard(13, "S"), 3)
	t.PlayCard(card.NewCard(8, "C"), 0)
	t.SendTrick()
	t.SetFirst(2)
	t.PlayCard(card.NewCard(5, "C"), 2)
	t.PlayCard(card.NewCard(2, "C"), 3)
	t.PlayCard(card.NewCard(13, "H"), 0)
	t.PlayCard(card.NewCard(11, "S"), 1)
	t.SendTrick()
	t.EndRound()
	t.SetFirst(3)
	t.PlayCard(card.NewCard(5, "S"), 3)
	t.PlayCard(card.NewCard(6, "S"), 0)
	t.PlayCard(card.NewCard(7, "S"), 1)
	t.PlayCard(card.NewCard(10, "H"), 2)
	t.SendTrick()
	t.SetFirst(1)
	t.PlayCard(card.NewCard(6, "D"), 1)
	t.PlayCard(card.NewCard(2, "C"), 2)
	t.PlayCard(card.NewCard(13, "H"), 3)
	t.PlayCard(card.NewCard(11, "H"), 0)
	t.SendTrick()
	t.EndRound()
	score := p0.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
	score = p1.GetScore()
	if score != p1Expect {
		test.Errorf("Expected %d, got %d", p1Expect, score)
	}
	score = p2.GetScore()
	if score != p2Expect {
		test.Errorf("Expected %d, got %d", p2Expect, score)
	}
	score = p3.GetScore()
	if score != otherExpect {
		test.Errorf("Expected %d, got %d", otherExpect, score)
	}
}

//Testing dealing to make sure no duplicates are dealt
func TestFour(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p2 := player.NewPlayer(2)
	p3 := player.NewPlayer(3)
	players := []*player.Player{p0, p1, p2, p3}
	t := table.NewTable(players)
	t.GenerateCards()
	t.Deal()
	p0Hand := p0.GetHand()
	p1Hand := p1.GetHand()
	p2Hand := p2.GetHand()
	p3Hand := p3.GetHand()
	testMap := make(map[*card.Card]int)
	for i := 0; i < 13; i++ {
		if testMap[p0Hand[i]] == 0 {
			testMap[p0Hand[i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[p1Hand[i]] == 0 {
			testMap[p1Hand[i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[p2Hand[i]] == 0 {
			testMap[p2Hand[i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
		if testMap[p3Hand[i]] == 0 {
			testMap[p3Hand[i]] = 1
		} else {
			test.Errorf("Duplicate card")
		}
	}
}

//Testing dealing to make sure enough cards are dealt
func TestFive(test *testing.T) {
	expect := 13
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p2 := player.NewPlayer(2)
	p3 := player.NewPlayer(3)
	players := []*player.Player{p0, p1, p2, p3}
	t := table.NewTable(players)
	t.GenerateCards()
	t.Deal()
	for i := 0; i < 4; i++ {
		if len(players[i].GetHand()) != expect {
			test.Errorf("Expected %d cards in the hand of player %d, got %d cards", expect, i, len(players[i].GetHand()))
		}
	}
}

//Testing playing a card-- HasSuit()
func TestSix(test *testing.T) {
	p := player.NewPlayer(0)
	p.AddToHand(card.NewCard(6, "D"))
	p.AddToHand(card.NewCard(4, "S"))
	if p.HasSuit("D") == false || p.HasSuit("S") == false {
		test.Errorf("False negative")
	}
	if p.HasSuit("C") == true || p.HasSuit("H") == true {
		test.Errorf("False positive")
	}
}
