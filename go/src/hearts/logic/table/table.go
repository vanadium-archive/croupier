// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package table

import (
	"hearts/logic/card"
	"hearts/logic/player"
	"math/rand"
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
	// players contains all players in the game, indexed by playerIndex
	players []*player.Player
	// trick contains all cards in the current trick, indexed by the playerIndex of the player who played them
	trick []*card.Card
	// firstPlayed is the index in trick of the card played first
	firstPlayed int
	// allCards contains all 52 cards in the deck. GenerateCards() populates this
	allCards []*card.Card
	// heartsBroken returns true if a heart has been played yet in the round, otherwise false
	heartsBroken bool
	// firstTrick returns true if the current trick is the first in the round, otherwise false
	firstTrick bool
	// winCondition is the number of points needed to win the game
	// traditionally 100, could set higher or lower for longer or shorter game
	winCondition int
}

func (t *Table) GetPlayers() []*player.Player {
	return t.players
}

func (t *Table) SetFirstPlayed(index int) {
	t.firstPlayed = index
}

// This function generates a traditional deck of 52 cards, with 13 in each of the four suits
// Each card has a suit (Club, Diamond, Spade, or Heart)
// Each card also has a number from 2-14, where 11 through 14 represent Jack, Queen, King and Ace, respectively
func (t *Table) GenerateCards() {
	cardsPerSuit := 13
	t.allCards = make([]*card.Card, 0)
	cardFaces := []card.Face{card.Two, card.Three, card.Four, card.Five, card.Six, card.Seven, card.Eight, card.Nine,
		card.Ten, card.Jack, card.Queen, card.King, card.Ace}
	for i := 0; i < cardsPerSuit; i++ {
		t.allCards = append(t.allCards, card.NewCard(cardFaces[i], card.Club))
		t.allCards = append(t.allCards, card.NewCard(cardFaces[i], card.Diamond))
		t.allCards = append(t.allCards, card.NewCard(cardFaces[i], card.Spade))
		t.allCards = append(t.allCards, card.NewCard(cardFaces[i], card.Heart))
	}
}

func (t *Table) PlayCard(c *card.Card, playerIndex int) {
	t.trick[playerIndex] = c
	if c.GetSuit() == card.Heart && !t.heartsBroken {
		t.heartsBroken = true
	}
}

func (t *Table) ValidPlay(c *card.Card, playerIndex int) bool {
	player := t.players[playerIndex]
	if t.firstPlayed == playerIndex {
		if !t.firstTrick {
			if c.GetSuit() != card.Heart || t.heartsBroken {
				return true
			} else {
				if player.HasOnlyHearts() {
					return true
				}
			}
		} else if c.GetSuit() == card.Club && c.GetFace() == card.Two {
			return true
		}
	} else {
		firstPlayedSuit := t.trick[t.firstPlayed].GetSuit()
		if c.GetSuit() == firstPlayedSuit || !player.HasSuit(firstPlayedSuit) {
			if !t.firstTrick {
				return true
			} else if !c.WorthPoints() {
				return true
			} else if player.HasAllPoints() {
				return true
			}
		}
	}
	return false
}

func (t *Table) SendTrick() {
	trickSuit := t.trick[t.firstPlayed].GetSuit()
	highestCardFace := card.Two
	highestIndex := -1
	for i := 0; i < len(t.trick); i++ {
		curCard := t.trick[i]
		if curCard.GetSuit() == trickSuit && curCard.GetFace() >= highestCardFace {
			highestCardFace = curCard.GetFace()
			highestIndex = i
		}
	}
	// clear trick
	t.players[highestIndex].TakeTrick(t.trick)
	t.trick = make([]*card.Card, len(t.players))
	if t.firstTrick {
		t.firstTrick = false
	}
}

func (t *Table) ScoreRound() {
	allPoints := 26
	roundScores := make([]int, len(t.players))
	shotMoon := false
	shooter := -1
	for i := 0; i < len(t.players); i++ {
		roundScores[i] = t.players[i].CalculateScore()
		if roundScores[i] == allPoints {
			shotMoon = true
			shooter = i
		}
	}
	if shotMoon {
		for i := 0; i < len(t.players); i++ {
			if i == shooter {
				roundScores[i] = 0
			} else {
				roundScores[i] = allPoints
			}
		}
	}
	// sending scores to players
	for i := 0; i < len(t.players); i++ {
		t.players[i].UpdateScore(roundScores[i])
	}
}

func (t *Table) Deal() {
	numPlayers := len(t.players)
	if t.allCards == nil {
		t.GenerateCards()
	}
	shuffle := rand.Perm(len(t.allCards))
	for i := 0; i < len(t.allCards); i++ {
		t.players[i%numPlayers].AddToHand(t.allCards[shuffle[i]])
	}
}

// returns -1 if the game hasn't been won, playerIndex of the winner if it has
// to-do: return a list of players in the event of a tie
func (t *Table) EndRound() int {
	t.ScoreRound()
	lowestScore := -1
	winningPlayer := -1
	winTriggered := false
	for _, p := range t.players {
		p.ResetTricks()
		if p.GetScore() >= t.winCondition {
			winTriggered = true
		}
		if p.GetScore() < lowestScore || lowestScore == -1 {
			lowestScore = p.GetScore()
			winningPlayer = p.GetPlayerIndex()
		}
	}
	if winTriggered {
		return winningPlayer
	}
	return -1
}

func (t *Table) NewRound() {
	t.heartsBroken = false
	t.firstTrick = true
	t.Deal()
}
