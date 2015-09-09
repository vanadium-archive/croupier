package card

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
)

func NewCard(n int, s string) *Card {
	return &Card{
		suit:   s,
		num:    n,
		node:   nil,
		x:      0.0,
		y:      0.0,
		width:  0.0,
		height: 0.0,
	}
}

type Card struct {
	suit string
	//num ranges from 2-14; jack is 11, queen is 12, king is 13, ace is 14
	num    int
	node   *sprite.Node
	x      float32
	y      float32
	width  float32
	height float32
}

func (c *Card) GetSuit() string {
	return c.suit
}

func (c *Card) GetNum() int {
	return c.num
}

func (c *Card) Move(eng sprite.Engine, newX float32, newY float32) {
	eng.SetTransform(c.node, f32.Affine{
		{c.width, 0, newX},
		{0, c.height, newY},
	})
	c.x = newX
	c.y = newY
}
