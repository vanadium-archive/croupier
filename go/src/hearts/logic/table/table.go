// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// table contains and manages the logic half of the game state

package table

import (
	"golang.org/x/mobile/exp/sprite"
	"hearts/img/direction"
	"hearts/logic/card"
	"hearts/logic/player"
	"math/rand"
	"sort"
)

// Returns a table instance with player set length numPlayers
func InitializeGame(numPlayers int, texs map[string]sprite.SubTex) *Table {
	players := make([]*player.Player, 0)
	for i := 0; i < numPlayers; i++ {
		players = append(players, player.NewPlayer(i))
	}
	t := makeTable(players)
	t.GenerateClassicCards()
	t.NewRound()
	return t
}

// Given a group of players, returns a table instance with that group as its player set
func makeTable(p []*player.Player) *Table {
	return &Table{
		players:      p,
		trick:        make([]*card.Card, len(p)),
		firstPlayer:  -1,
		allCards:     nil,
		heartsBroken: false,
		firstTrick:   true,
		winCondition: 100,
		dir:          direction.None,
	}
}

type Table struct {
	// players contains all players in the game, indexed by playerIndex
	players []*player.Player
	// trick contains all cards in the current trick, indexed by the playerIndex of the player who played them
	trick []*card.Card
	// firstPlayer is the index in trick of the card played first
	firstPlayer int
	// allCards contains all 52 cards in the deck. GenerateCards() populates this
	allCards []*card.Card
	// heartsBroken returns true if a heart has been played yet in the round, otherwise false
	heartsBroken bool
	// firstTrick returns true if the current trick is the first in the round, otherwise false
	firstTrick bool
	// winCondition is the number of points needed to win the game
	// traditionally 100, could set higher or lower for longer or shorter game
	winCondition int
	// dir is the current round's passing direction
	dir direction.Direction
}

// Returns the player set of t
func (t *Table) GetPlayers() []*player.Player {
	return t.players
}

// Returns the current trick of t
func (t *Table) GetTrick() []*card.Card {
	return t.trick
}

// Returns the index in t.players and t.trick of the designated first player in the current round
func (t *Table) GetFirstPlayer() int {
	return t.firstPlayer
}

// Returns the deck of all cards stored in t
func (t *Table) GetAllCards() []*card.Card {
	return t.allCards
}

func (t *Table) GetDir() direction.Direction {
	return t.dir
}

// Sets the firstplayer variable of t to index
func (t *Table) SetFirstPlayer(index int) {
	t.firstPlayer = index
}

// Returns the index of the player whose turn it is, -1 if this cannot be determined at this time
func (t *Table) WhoseTurn() int {
	allNil := true
	for i, c := range t.trick {
		nextPlayerIndex := (i + 1) % len(t.players)
		if c != nil {
			allNil = false
			if t.trick[nextPlayerIndex] == nil {
				return nextPlayerIndex
			}
		}
	}
	if allNil {
		return t.firstPlayer
	}
	return -1
}

// This function generates a traditional deck of 52 cards, with 13 in each of the four suits
// Each card has a suit (Club, Diamond, Spade, or Heart)
// Each card also has a face from Two to Ace (Aces are high in Hearts)
func (t *Table) GenerateClassicCards() {
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
	sort.Sort(card.CardSorter(t.allCards))
}

// Given a card and the index of its player, adds that card to the appropriate spot in the current trick
func (t *Table) SetPlayedCard(c *card.Card, playerIndex int) {
	t.trick[playerIndex] = c
	if c.GetSuit() == card.Heart && !t.heartsBroken {
		t.heartsBroken = true
	}
}

// Returns true if there are exactly three cards being passed (specified by Hearts logic)
func (t *Table) ValidPass(cardsPassed []*card.Card) bool {
	return len(cardsPassed) == 3
}

// Returns whether it is valid for the player at playerIndex to play a card
func (t *Table) ValidPlayOrder(playerIndex int) bool {
	return t.WhoseTurn() == playerIndex
}

// Given a card and the index of its player, returns "" if this move was valid based on game logic
// Otherwise returns a string explaining the error
func (t *Table) ValidPlayLogic(c *card.Card, playerIndex int) string {
	validPlay := ""
	player := t.players[playerIndex]
	if t.firstPlayer == playerIndex {
		if !t.firstTrick {
			if c.GetSuit() != card.Heart || t.heartsBroken {
				return validPlay
			} else {
				if player.HasOnlyHearts() {
					return validPlay
				} else {
					return "Hearts have not been broken"
				}
			}
		} else if c.GetSuit() == card.Club && c.GetFace() == card.Two {
			return validPlay
		} else {
			return "Must open with the Two of Clubs"
		}
	} else {
		firstPlayedSuit := t.trick[t.firstPlayer].GetSuit()
		if c.GetSuit() == firstPlayedSuit || !player.HasSuit(firstPlayedSuit) {
			if !t.firstTrick {
				return validPlay
			} else if !c.WorthPoints() {
				return validPlay
			} else if player.HasAllPoints() {
				return validPlay
			} else {
				return "Point cards not allowed in the first round"
			}
		} else {
			return "Must follow suit"
		}
	}
	return "Invalid play"
}

// Returns true if all players have their initial dealt hands
func (t *Table) AllDoneDealing() bool {
	for _, p := range t.players {
		if len(p.GetHand()) == 0 {
			return false
		}
	}
	return true
}

// Returns true if all players have taken the cards passed to them
func (t *Table) AllDonePassing() bool {
	for _, p := range t.players {
		if !p.GetDonePassing() {
			return false
		}
	}
	return true
}

// Returns true if all players have finished looking at their scores
func (t *Table) AllReadyForNewRound() bool {
	for _, p := range t.players {
		if !p.GetDoneScoring() {
			return false
		}
	}
	return true
}

// Returns true if all players are out of cards, indicating the end of a round
func (t *Table) RoundOver() bool {
	for _, p := range t.players {
		if len(p.GetHand()) > 0 {
			return false
		}
	}
	return true
}

// Calculates who should take the cards in the current trick and sends them. Sets next first player accordingly. Returns true if the round is over
func (t *Table) SendTrick() (bool, int) {
	trickSuit := t.trick[t.firstPlayer].GetSuit()
	highestCardFace := card.Two
	highestIndex := -1
	for i := 0; i < len(t.trick); i++ {
		curCard := t.trick[i]
		if curCard.GetSuit() == trickSuit && curCard.GetFace() >= highestCardFace {
			highestCardFace = curCard.GetFace()
			highestIndex = i
		}
	}
	// resets all players' donePlaying bools
	for _, p := range t.players {
		p.SetDonePlaying(false)
	}
	// clear trick
	t.players[highestIndex].TakeTrick(t.trick)
	t.trick = make([]*card.Card, len(t.players))
	if t.firstTrick {
		t.firstTrick = false
	}
	if t.RoundOver() {
		return true, highestIndex
	}
	// set first player for next trick to whoever received the current trick
	t.SetFirstPlayer(highestIndex)
	return false, highestIndex
}

// Returns the score of the current round
// Accounts for a player possibly shooting the moon
func (t *Table) ScoreRound() []int {
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
	return roundScores
}

// Adds the scores of the current round to the players total scores
func (t *Table) UpdatePlayerScores(roundScores []int) {
	for i := 0; i < len(t.players); i++ {
		t.players[i].UpdateScore(roundScores[i])
	}
}

// Returns set of hands with random, even card distribution
func (t *Table) Deal() [][]*card.Card {
	numPlayers := len(t.players)
	allHands := make([][]*card.Card, numPlayers)
	shuffle := rand.Perm(len(t.allCards))
	for i := 0; i < len(t.allCards); i++ {
		allHands[i%numPlayers] = append(allHands[i%numPlayers], t.allCards[shuffle[i]])
	}
	return allHands
}

// Returns an array of the current round's scores, and an array of the game winners
// The winners array is empty if the game hasn't been won yet, contains all playerIndices of the winners if it has
func (t *Table) EndRound() ([]int, []int) {
	roundScores := t.ScoreRound()
	t.UpdatePlayerScores(roundScores)
	lowestScore := -1
	winningPlayers := make([]int, 0)
	winTriggered := false
	t.dir = (t.dir + 1) % 4
	for _, p := range t.players {
		p.ResetTricks()
		if p.GetScore() >= t.winCondition {
			winTriggered = true
		}
		if p.GetScore() < lowestScore || lowestScore == -1 {
			lowestScore = p.GetScore()
		}
	}
	if winTriggered {
		for _, p := range t.players {
			if p.GetScore() == lowestScore {
				winningPlayers = append(winningPlayers, p.GetPlayerIndex())
			}
		}
	}
	return roundScores, winningPlayers
}

// Resets stats for a new round of the game
func (t *Table) NewRound() {
	t.heartsBroken = false
	t.firstTrick = true
	players := t.GetPlayers()
	for _, p := range players {
		if t.dir != direction.None {
			p.SetDonePassing(false)
			p.SetDoneTaking(false)
			t.SetFirstPlayer(-1)
		} else {
			p.SetDonePassing(true)
			p.SetDoneTaking(true)
			if p.HasTwoOfClubs() {
				t.SetFirstPlayer(p.GetPlayerIndex())
			}
		}
		p.SetDoneScoring(false)
	}
}

// Resets table for start of new game
func (t *Table) NewGame() {
	for _, p := range t.players {
		p.ResetPassedTo()
		p.ResetPassedFrom()
		p.ResetTricks()
		p.ResetScore()
	}
	t.NewRound()
	t.dir = direction.Right
}
