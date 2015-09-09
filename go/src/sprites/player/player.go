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

func (p *Player) SetHand(cards []*card.Card) {
	p.hand = cards
}

func (p *Player) TakeTrick(cards []*card.Card) {
	p.tricks = append(p.tricks, cards...)
}

func (p *Player) UpdateScore(score int) {
	p.score += score
}

func (p *Player) CalculateScore() int {
	score := 0
	for i := 0; i < len(p.tricks); i++ {
		curCard := p.tricks[i]
		if curCard.GetSuit() == "H" {
			score += 1
		} else if curCard.GetSuit() == "S" && curCard.GetNum() == 12 {
			score += 13
		}
	}
	return score
}
