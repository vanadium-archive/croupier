// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package player

import (
	"hearts/logic/card"
)

// Returns a player instance with playerIndex equal to index
func NewPlayer(index int) *Player {
	return &Player{
		hand:        nil,
		tricks:      make([]*card.Card, 0),
		score:       0,
		playerIndex: index,
	}
}

type Player struct {
	hand        []*card.Card
	tricks      []*card.Card
	score       int
	playerIndex int
}

// Returns the hand of p
func (p *Player) GetHand() []*card.Card {
	return p.hand
}

// Returns the score of p
func (p *Player) GetScore() int {
	return p.score
}

// Returns the playerIndex of p
func (p *Player) GetPlayerIndex() int {
	return p.playerIndex
}

// Adds card to the hand of p
func (p *Player) AddToHand(card *card.Card) {
	p.hand = append(p.hand, card)
}

// Adds cards to the tricks deck of p
func (p *Player) TakeTrick(cards []*card.Card) {
	p.tricks = append(p.tricks, cards...)
}

// Adds points to the total score of p
func (p *Player) UpdateScore(points int) {
	p.score += points
}

// Calculates and returns the total point value of the cards in the tricks deck of p
func (p *Player) CalculateScore() int {
	score := 0
	for _, c := range p.tricks {
		if c.GetSuit() == card.Heart {
			score += 1
		} else if c.GetSuit() == card.Spade && c.GetFace() == card.Queen {
			score += 13
		}
	}
	return score
}

// Sets the tricks deck of p to a new empty list
func (p *Player) ResetTricks() {
	p.tricks = make([]*card.Card, 0)
}

// Given a suit, returns whether not there is at least one card of that suit in the hand of p
func (p *Player) HasSuit(suit card.Suit) bool {
	for _, c := range p.hand {
		if c.GetSuit() == suit {
			return true
		}
	}
	return false
}

// Returns true if p has at least one heart card in hand and no cards of any other suit
func (p *Player) HasOnlyHearts() bool {
	return !(p.HasSuit(card.Club) || p.HasSuit(card.Diamond) || p.HasSuit(card.Spade) || !p.HasSuit(card.Heart))
}

// Returns true if the hand of p doesn't contain any 0-point cards (all clubs and diamonds, and all spades aside from the queen)
func (p *Player) HasAllPoints() bool {
	for _, c := range p.hand {
		if !c.WorthPoints() {
			return false
		}
	}
	return true
}

// Returns true if p has the two of clubs in hand
func (p *Player) HasTwoOfClubs() bool {
	for _, c := range p.hand {
		if c.GetSuit() == card.Club && c.GetFace() == card.Two {
			return true
		}
	}
	return false
}
