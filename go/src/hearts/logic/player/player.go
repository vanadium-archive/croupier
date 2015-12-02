// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// player keeps track of all player-specific variables, as well as some basic logic functions to support more complex table logic

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
		donePassing: false,
		doneTaking:  false,
		doneScoring: false,
	}
}

type Player struct {
	hand        []*card.Card
	passedFrom  []*card.Card
	passedTo    []*card.Card
	tricks      []*card.Card
	score       int
	playerIndex int
	donePassing bool
	doneTaking  bool
	donePlaying bool
	doneScoring bool
}

// Returns the hand of p
func (p *Player) GetHand() []*card.Card {
	return p.hand
}

// Returns the cards that have been passed to p
func (p *Player) GetPassedTo() []*card.Card {
	return p.passedTo
}

// Returns the cards that p passed
func (p *Player) GetPassedFrom() []*card.Card {
	return p.passedFrom
}

// Returns the number of tricks p has taken
// Assumes each trick is 4 cards
func (p *Player) GetNumTricks() int {
	return len(p.tricks) / 4
}

// Returns the score of p
func (p *Player) GetScore() int {
	return p.score
}

// Returns the playerIndex of p
func (p *Player) GetPlayerIndex() int {
	return p.playerIndex
}

// Returns true if p has finished the pass phase of the current round
func (p *Player) GetDonePassing() bool {
	return p.donePassing
}

// Returns true if p has finished the take phase of the current round
func (p *Player) GetDoneTaking() bool {
	return p.doneTaking
}

// Returns true if p has finished the play phase of the current trick
func (p *Player) GetDonePlaying() bool {
	return p.donePlaying
}

// Returns true if p has finished the score phase of the current round
func (p *Player) GetDoneScoring() bool {
	return p.doneScoring
}

// Adds card to the hand of p
func (p *Player) AddToHand(card *card.Card) {
	p.hand = append(p.hand, card)
}

// Removes card from the hand of p, every time it appears
func (p *Player) RemoveFromHand(card *card.Card) {
	for i, c := range p.hand {
		if c == card {
			p.hand = append(p.hand[:i], p.hand[i+1:]...)
		}
	}
}

// Sets hand of p in one chunk of cards
func (p *Player) SetHand(cards []*card.Card) {
	p.hand = cards
}

// Sets passedTo of p to cards
func (p *Player) SetPassedTo(cards []*card.Card) {
	p.passedTo = cards
}

// Sets passedFrom of p to cards
func (p *Player) SetPassedFrom(cards []*card.Card) {
	p.passedFrom = cards
}

// Sets p.donePassing to isDone
func (p *Player) SetDonePassing(isDone bool) {
	p.donePassing = isDone
}

// Sets p.doneTaking to isDone
func (p *Player) SetDoneTaking(isDone bool) {
	p.doneTaking = isDone
}

// Sets p.donePlaying to isDone
func (p *Player) SetDonePlaying(isDone bool) {
	p.donePlaying = isDone
}

// Sets p.doneScoring to isDone
func (p *Player) SetDoneScoring(isDone bool) {
	p.doneScoring = isDone
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

// Sets the passedTo deck of p to a new empty list
func (p *Player) ResetPassedTo() {
	p.passedTo = make([]*card.Card, 0)
}

// Sets the passedFrom deck of p to a new empty list
func (p *Player) ResetPassedFrom() {
	p.passedFrom = make([]*card.Card, 0)
}

// Sets the tricks deck of p to a new empty list
func (p *Player) ResetTricks() {
	p.tricks = make([]*card.Card, 0)
}

// Resets the score of p to 0 for a new game
func (p *Player) ResetScore() {
	p.score = 0
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
