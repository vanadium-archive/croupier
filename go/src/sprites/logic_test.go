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
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(3, "H"), 1)
	t.PlayCard(card.NewCard(7, "H"), 2)
	t.PlayCard(card.NewCard(12, "S"), 3)
	t.PlayCard(card.NewCard(4, "D"), 0)
	t.SendTrick()
	t.SetFirstPlayed(2)
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
	t.SetFirstPlayed(1)
	t.PlayCard(card.NewCard(8, "H"), 1)
	t.PlayCard(card.NewCard(12, "S"), 2)
	t.PlayCard(card.NewCard(13, "S"), 3)
	t.PlayCard(card.NewCard(8, "C"), 0)
	t.SendTrick()
	t.SetFirstPlayed(2)
	t.PlayCard(card.NewCard(5, "C"), 2)
	t.PlayCard(card.NewCard(2, "C"), 3)
	t.PlayCard(card.NewCard(13, "H"), 0)
	t.PlayCard(card.NewCard(11, "S"), 1)
	t.SendTrick()
	t.EndRound()
	t.SetFirstPlayed(3)
	t.PlayCard(card.NewCard(5, "S"), 3)
	t.PlayCard(card.NewCard(6, "S"), 0)
	t.PlayCard(card.NewCard(7, "S"), 1)
	t.PlayCard(card.NewCard(10, "H"), 2)
	t.SendTrick()
	t.SetFirstPlayed(1)
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

//Testing playing a card-- HasAllPoints()
func TestSeven(test *testing.T) {
	p1 := player.NewPlayer(0)
	p2 := player.NewPlayer(1)
	p1.AddToHand(card.NewCard(6, "H"))
	p1.AddToHand(card.NewCard(12, "S"))
	p2.AddToHand(card.NewCard(2, "D"))
	p2.AddToHand(card.NewCard(5, "H"))
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
	if t.ValidPlay(card.NewCard(8, "C"), 0) == true {
		test.Errorf("Expected invalid play for starting round with card other than 2 of Clubs")
	} else if t.ValidPlay(card.NewCard(2, "C"), 0) == false {
		test.Errorf("Expected valid play for starting round with 2 of Clubs")
	}
}

//Testing playing a card-- ValidPlay() testing first round points rule
func TestNine(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p1.AddToHand(card.NewCard(12, "S"))
	p1.AddToHand(card.NewCard(3, "D"))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, "C"), 0)
	if t.ValidPlay(card.NewCard(12, "S"), 1) == true {
		test.Errorf("Expected invalid play for points on the first round")
	}
}

//Testing playing a card-- ValidPlay() testing breaking Hearts rule
func TestTen(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p0.AddToHand(card.NewCard(5, "H"))
	p1.AddToHand(card.NewCard(2, "H"))
	p1.AddToHand(card.NewCard(3, "D"))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, "C"), 0)
	t.PlayCard(card.NewCard(3, "C"), 1)
	t.SendTrick()
	t.SetFirstPlayed(0)
	if t.ValidPlay(card.NewCard(5, "H"), 0) == false {
		test.Errorf("Expected valid play for opener rightfully breaking Hearts")
	}
	t.SetFirstPlayed(1)
	if t.ValidPlay(card.NewCard(2, "H"), 1) == true {
		test.Errorf("Expected invalid play for opener wrongfully breaking Hearts")
	}
	t.PlayCard(card.NewCard(3, "D"), 1)
	if t.ValidPlay(card.NewCard(5, "H"), 0) == false {
		test.Errorf("Expected valid play for follower rightfully breaking Hearts")
	}
	p0.AddToHand(card.NewCard(7, "D"))
	if t.ValidPlay(card.NewCard(5, "H"), 0) == true {
		test.Errorf("Expected invalid play for follower wrongfully breaking Hearts")
	}
}

//Testing playing a card-- ValidPlay() testing following suit rule
func TestEleven(test *testing.T) {
	p0 := player.NewPlayer(0)
	p1 := player.NewPlayer(1)
	p0.AddToHand(card.NewCard(2, "C"))
	p1.AddToHand(card.NewCard(3, "D"))
	players := []*player.Player{p0, p1}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(2, "C"), 0)
	if t.ValidPlay(card.NewCard(3, "D"), 1) == false {
		test.Errorf("Expected valid play for not following suit when player doesn't have suit")
	}
	p1.AddToHand(card.NewCard(5, "C"))
	if t.ValidPlay(card.NewCard(5, "C"), 1) == false {
		test.Errorf("Expected valid play for following suit")
	}
	if t.ValidPlay(card.NewCard(3, "D"), 1) == true {
		test.Errorf("Expected invalid play for not following suit when player has suit")
	}
}

//Testing win condition
func TestTwelve(test *testing.T) {
	p0 := player.NewPlayer(0)
	players := []*player.Player{p0}
	t := table.NewTable(players)
	t.SetFirstPlayed(0)
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	winner := t.EndRound()
	expect := -1
	if winner != expect {
		test.Errorf("Expected %d, got %d", expect, winner)
	}
	t.NewRound()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	t.PlayCard(card.NewCard(12, "S"), 0)
	t.SendTrick()
	winner = t.EndRound()
	expect = 0
	if winner != expect {
		test.Errorf("Expected %d, got %d", expect, winner)
	}
}
