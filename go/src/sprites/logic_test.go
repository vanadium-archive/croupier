package main

import (
	"sprites/card"
	"sprites/player"
	"sprites/table"
	"testing"
)

//Testing scoring
func TestOne(test *testing.T) {
	expect := 15
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
	t.ScoreRound()
	score := p2.GetScore()
	if score != expect {
		test.Errorf("Expected %d, got %d", expect, score)
	}
}

//Testing dealing to make sure no duplicates are dealt
func TestTwo(test *testing.T) {
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
