// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package player

import (
	"sprites/card"
)

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

func (p *Player) GetHand() []*card.Card {
	return p.hand
}

func (p *Player) GetScore() int {
	return p.score
}

func (p *Player) GetPlayerIndex() int {
	return p.playerIndex
}

func (p *Player) AddToHand(card *card.Card) {
	p.hand = append(p.hand, card)
}

func (p *Player) TakeTrick(cards []*card.Card) {
	p.tricks = append(p.tricks, cards...)
}

func (p *Player) UpdateScore(score int) {
	p.score += score
}

func (p *Player) CalculateScore() int {
	score := 0
	for _, c := range p.tricks {
		if c.GetSuit() == card.Heart {
			score += 1
		} else if c.GetSuit() == card.Spade && c.GetNum() == 12 {
			score += 13
		}
	}
	return score
}

func (p *Player) ResetTricks() {
	p.tricks = nil
}

func (p *Player) HasSuit(suit card.Suit) bool {
	for _, c := range p.hand {
		if c.GetSuit() == suit {
			return true
		}
	}
	return false
}

func (p *Player) HasAllPoints() bool {
	for _, c := range p.hand {
		if c.GetSuit() == card.Diamond || c.GetSuit() == card.Club {
			return false
		} else if c.GetSuit() == card.Spade && c.GetNum() != 12 {
			return false
		}
	}
	return true
}
