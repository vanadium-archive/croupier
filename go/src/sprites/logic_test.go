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
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(3, card.Heart), 1)
	t.PlayCard(card.NewCard(7, card.Heart), 2)
	t.PlayCard(card.NewCard(12, card.Spade), 3)
	t.PlayCard(card.NewCard(4, card.Diamond), 0)
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
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(3, card.Heart), 1)
	t.PlayCard(card.NewCard(7, card.Heart), 2)
	t.PlayCard(card.NewCard(12, card.Spade), 3)
	t.PlayCard(card.NewCard(4, card.Diamond), 0)
	t.SendTrick()
	t.SetFirstPlayed(2)
	t.PlayCard(card.NewCard(5, card.Diamond), 2)
	t.PlayCard(card.NewCard(2, card.Heart), 3)
	t.PlayCard(card.NewCard(13, card.Diamond), 0)
	t.PlayCard(card.NewCard(14, card.Spade), 1)
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
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(8, card.Heart), 1)
	t.PlayCard(card.NewCard(12, card.Spade), 2)
	t.PlayCard(card.NewCard(13, card.Spade), 3)
	t.PlayCard(card.NewCard(8, card.Club), 0)
	t.SendTrick()
	t.SetFirstPlayed(2)
	t.PlayCard(card.NewCard(5, card.Club), 2)
	t.PlayCard(card.NewCard(2, card.Club), 3)
	t.PlayCard(card.NewCard(13, card.Heart), 0)
	t.PlayCard(card.NewCard(11, card.Spade), 1)
	t.SendTrick()
	t.EndRound()
	t.SetFirstPlayed(3)
	t.PlayCard(card.NewCard(5, card.Spade), 3)
	t.PlayCard(card.NewCard(6, card.Spade), 0)
	t.PlayCard(card.NewCard(7, card.Spade), 1)
	t.PlayCard(card.NewCard(10, card.Heart), 2)
	t.SendTrick()
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(6, card.Diamond), 1)
	t.PlayCard(card.NewCard(2, card.Club), 2)
	t.PlayCard(card.NewCard(13, card.Heart), 3)
	t.PlayCard(card.NewCard(11, card.Heart), 0)
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
	p.AddToHand(card.NewCard(6, card.Diamond))
	p.AddToHand(card.NewCard(4, card.Spade))
	if p.HasSuit(card.Diamond) == false || p.HasSuit(card.Spade) == false {
		test.Errorf("False negative")
	}
	if p.HasSuit(card.Club) == true || p.HasSuit(card.Heart) == true {
		test.Errorf("False positive")
	}
}

//Testing playing a card-- HasAllPoints()
func TestSeven(test *testing.T) {
	p1 := player.NewPlayer(0)
	p2 := player.NewPlayer(1)
	p1.AddToHand(card.NewCard(6, card.Heart))
	p1.AddToHand(card.NewCard(12, card.Spade))
	p2.AddToHand(card.NewCard(2, card.Diamond))
	p2.AddToHand(card.NewCard(5, card.Heart))
	if p1.HasAllPoints() == false {
		test.Errorf("False negative")
	}
	if p2.HasAllPoints() == true {
		test.Errorf("False positive")
	}
}

//Testing playing a card-- ValidPlay() testing 2 of Clubs rule
func TestEight(test *testing.T) {
	p0 := player.NewPlayer(0)
	players := []*player.Player{p0}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	if t.ValidPlay(card.NewCard(8, card.Club), 0) == true {
		test.Errorf("Expected invalid play for starting round with card other than 2 of Clubs")
	} else if t.ValidPlay(card.NewCard(2, card.Club), 0) == false {
		test.Errorf("Expected valid play for starting round with 2 of Clubs")
	}
}

//Testing playing a card-- ValidPlay() testing first round points rule
func TestNine(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p1.AddToHand(card.NewCard(12, card.Spade))
	p1.AddToHand(card.NewCard(3, card.Diamond))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, card.Club), 0)
	if t.ValidPlay(card.NewCard(12, card.Spade), 1) == true {
		test.Errorf("Expected invalid play for points on the first round")
	}
}

//Testing playing a card-- ValidPlay() testing breaking Hearts rule
func TestTen(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p0.AddToHand(card.NewCard(5, card.Heart))
	p1.AddToHand(card.NewCard(2, card.Heart))
	p1.AddToHand(card.NewCard(3, card.Diamond))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, card.Club), 0)
	t.PlayCard(card.NewCard(3, card.Club), 1)
	t.SendTrick()
	t.SetFirstPlayed(0)
	if t.ValidPlay(card.NewCard(5, card.Heart), 0) == false {
		test.Errorf("Expected valid play for opener rightfully breaking Hearts")
	}
	t.SetFirstPlayed(1)
	if t.ValidPlay(card.NewCard(2, card.Heart), 1) == true {
		test.Errorf("Expected invalid play for opener wrongfully breaking Hearts")
	}
	t.PlayCard(card.NewCard(3, card.Diamond), 1)
	if t.ValidPlay(card.NewCard(5, card.Heart), 0) == false {
		test.Errorf("Expected valid play for follower rightfully breaking Hearts")
	}
	p0.AddToHand(card.NewCard(7, card.Diamond))
	if t.ValidPlay(card.NewCard(5, card.Heart), 0) == true {
		test.Errorf("Expected invalid play for follower wrongfully breaking Hearts")
	}
}

//Testing playing a card-- ValidPlay() testing following suit rule
func TestEleven(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p0.AddToHand(card.NewCard(2, card.Club))
	p1.AddToHand(card.NewCard(3, card.Diamond))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, card.Club), 0)
	if t.ValidPlay(card.NewCard(3, card.Diamond), 1) == false {
		test.Errorf("Expected valid play for not following suit when player doesn't have suit")
	}
	p1.AddToHand(card.NewCard(5, card.Club))
	if t.ValidPlay(card.NewCard(5, card.Club), 1) == false {
		test.Errorf("Expected valid play for following suit")
	}
	if t.ValidPlay(card.NewCard(3, card.Diamond), 1) == true {
		test.Errorf("Expected invalid play for not following suit when player has suit")
	}
}

//Testing win condition
func TestTwelve(test *testing.T) {
	p0 := player.NewPlayer(0)
	players := []*player.Player{p0}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	winner := t.EndRound()
	expect := -1
	if winner != expect {
		test.Errorf("Expected %d, got %d", expect, winner)
	}
	t.NewRound()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, card.Spade), 0)
	t.SendTrick()
	winner = t.EndRound()
	expect = 0
	if winner != expect {
		test.Errorf("Expected %d, got %d", expect, winner)
	}
}
