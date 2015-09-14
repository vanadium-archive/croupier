// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package table

import (
	"math/rand"
	"sprites/card"
	"sprites/player"
)

func NewTable(p []*player.Player) *Table {
	return &Table{
		players:      p,
		trick:        make([]*card.Card, len(p)),
		firstPlayed:  -1,
		allCards:     nil,
		heartsBroken: false,
		firstTrick:   true,
		winCondition: 100,
	}
}

type Table struct {
	//players contains all players in the game, indexed by playerIndex
	players []*player.Player
	//trick contains all cards in the current trick, indexed by the playerIndex of the player who played them
	trick []*card.Card
	//firstPlayed is the index in trick of the card played first
	firstPlayed int
	//allCards contains all 52 cards in the deck. GenerateCards() populates this
	allCards []*card.Card
	//heartsBroken returns true if a heart has been played yet in the round, otherwise false
	heartsBroken bool
	//firstTrick returns true if the current trick is the first in the round, otherwise false
	firstTrick bool
	//winCondition is the number of points needed to win the game
	//traditionally 100, could set higher or lower for longer or shorter game
	winCondition int
}

func (t *Table) GetPlayers() []*player.Player {
	return t.players
}

func (t *Table) SetFirstPlayed(index int) {
	t.firstPlayed = index
}

func (t *Table) GenerateCards() {
	t.allCards = make([]*card.Card, 0)
	for i := 0; i < 13; i++ {
		t.allCards = append(t.allCards, card.NewCard(i+2, card.Club))
		t.allCards = append(t.allCards, card.NewCard(i+2, card.Diamond))
		t.allCards = append(t.allCards, card.NewCard(i+2, card.Spade))
		t.allCards = append(t.allCards, card.NewCard(i+2, card.Heart))
	}
}

func (t *Table) PlayCard(c *card.Card, playerIndex int) {
	t.trick[playerIndex] = c
	if c.GetSuit() == card.Heart && t.heartsBroken == false {
		t.heartsBroken = true
	}
}

func (t *Table) ValidPlay(c *card.Card, playerIndex int) bool {
	player := t.players[playerIndex]
	if t.firstPlayed == playerIndex {
		if t.firstTrick == false {
			if c.GetSuit() != card.Heart || t.heartsBroken == true {
				return true
			} else {
				if player.HasSuit(card.Club) == false && player.HasSuit(card.Diamond) == false && player.HasSuit(card.Spade) == false {
					return true
				}
			}
		} else if c.GetSuit() == card.Club && c.GetNum() == 2 {
			return true
		}
	} else {
		firstPlayedSuit := t.trick[t.firstPlayed].GetSuit()
		if c.GetSuit() == firstPlayedSuit || player.HasSuit(firstPlayedSuit) == false {
			if t.firstTrick == false {
				return true
			} else if c.GetSuit() == card.Diamond || c.GetSuit() == card.Club || (c.GetSuit() == card.Spade && c.GetNum() != 12) {
				return true
			} else if player.HasAllPoints() == true {
				return true
			}
		}
	}
	return false
}

func (t *Table) SendTrick() {
	trickSuit := t.trick[t.firstPlayed].GetSuit()
	highest := -1
	highestIndex := -1
	for i := 0; i < len(t.trick); i++ {
		curCard := t.trick[i]
		if curCard.GetSuit() == trickSuit && curCard.GetNum() > highest {
			highest = curCard.GetNum()
			highestIndex = i
		}
	}
	//clear trick
	t.players[highestIndex].TakeTrick(t.trick)
	for i := 0; i < len(t.trick); i++ {
		t.trick[i] = nil
	}
	if t.firstTrick == true {
		t.firstTrick = false
	}
}

func (t *Table) ScoreRound() {
	roundScores := make([]int, len(t.players))
	shotMoon := false
	shooter := -1
	for i := 0; i < len(t.players); i++ {
		roundScores[i] = t.players[i].CalculateScore()
		if roundScores[i] == 26 {
			shotMoon = true
			shooter = i
		}
	}
	//if the moon was shot
	if shotMoon == true {
		for i := 0; i < len(t.players); i++ {
			if i == shooter {
				roundScores[i] = 0
			} else {
				roundScores[i] = 26
			}
		}
	}
	//sending scores to players
	for i := 0; i < len(t.players); i++ {
		t.players[i].UpdateScore(roundScores[i])
	}
}

func (t *Table) Deal() {
	numPlayers := len(t.players)
	if t.allCards == nil {
		t.GenerateCards()
	}
	shuffle := rand.Perm(52)
	for i := 0; i < len(t.allCards); i++ {
		t.players[i%numPlayers].AddToHand(t.allCards[shuffle[i]])
	}
}

//returns -1 if the game hasn't been won, playerIndex of the winner if it has
func (t *Table) EndRound() int {
	t.ScoreRound()
	for _, p := range t.players {
		p.ResetTricks()
		if p.GetScore() >= 100 {
			return p.GetPlayerIndex()
		}
	}
	return -1
}

func (t *Table) NewRound() {
	t.heartsBroken = false
	t.firstTrick = true
	t.Deal()
}
