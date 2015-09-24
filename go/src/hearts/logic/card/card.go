// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package card

import (
	"golang.org/x/mobile/exp/sprite"
)

type Suit string
type Face int

const (
	Heart   Suit = "H"
	Diamond Suit = "D"
	Spade   Suit = "S"
	Club    Suit = "C"
)

const (
	Two Face = iota + 2
	Three
	Four
	Five
	Six
	Seven
	Eight
	Nine
	Ten
	Jack
	Queen
	King
	// note: in Hearts, Aces are high
	Ace
)

func NewCard(f Face, suit Suit) *Card {
	return &Card{
		s:    suit,
		face: f,
	}
}

type Card struct {
	s        Suit
	face     Face
	node     *sprite.Node
	x        float32
	y        float32
	initialX float32
	initialY float32
	width    float32
	height   float32
}

func (c *Card) GetSuit() Suit {
	return c.s
}

func (c *Card) GetFace() Face {
	return c.face
}

func (c *Card) GetNode() *sprite.Node {
	return c.node
}

func (c *Card) GetX() float32 {
	return c.x
}

func (c *Card) GetY() float32 {
	return c.y
}

func (c *Card) GetInitialX() float32 {
	return c.initialX
}

func (c *Card) GetInitialY() float32 {
	return c.initialY
}

func (c *Card) GetWidth() float32 {
	return c.width
}

func (c *Card) GetHeight() float32 {
	return c.height
}

func (c *Card) SetNode(n *sprite.Node) {
	c.node = n
}

func (c *Card) SetPos(newX float32, newY float32, newWidth float32, newHeight float32) {
	c.x = newX
	c.y = newY
	c.width = newWidth
	c.height = newHeight
}

func (c *Card) SetInitialPos(newX float32, newY float32) {
	c.initialX = newX
	c.initialY = newY
}

func (c *Card) WorthPoints() bool {
	worthPoints := false
	if c.s == Heart || (c.s == Spade && c.face == Queen) {
		worthPoints = true
	}
	return worthPoints
}
