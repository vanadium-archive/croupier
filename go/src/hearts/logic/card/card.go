// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package card

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
)

type Suit int

const (
	Club Suit = iota
	Diamond
	Spade
	Heart
)

type Face int

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

type Vec struct {
	X float32
	Y float32
}

// Returns a new vec
func MakeVec(x, y float32) Vec {
	return Vec{
		X: x,
		Y: y,
	}
}

type Position struct {
	initial    Vec
	current    Vec
	dimensions Vec
}

// Returns a new position
func MakePosition(initialX, initialY, currentX, currentY, width, height float32) *Position {
	i := MakeVec(initialX, initialY)
	c := MakeVec(currentX, currentY)
	d := MakeVec(width, height)
	return &Position{
		initial:    i,
		current:    c,
		dimensions: d,
	}
}

// Returns the initial Vec of p
func (p *Position) GetInitial() Vec {
	return p.initial
}

// Returns the current Vec of p
func (p *Position) GetCurrent() Vec {
	return p.current
}

// Returns the dimensions Vec of p
func (p *Position) GetDimensions() Vec {
	return p.dimensions
}

// Updates the initial Vec of p
func (p *Position) SetInitial(x float32, y float32) {
	p.initial.X = x
	p.initial.Y = y
}

// Updates the current Vec of p
func (p *Position) SetCurrent(x float32, y float32) {
	p.current.X = x
	p.current.Y = y
}

// Updates the dimensions Vec of p
func (p *Position) SetDimensions(width float32, height float32) {
	p.dimensions.X = width
	p.dimensions.Y = height
}

// Returns a new card with suit and face variables set
// Does not set any properties of the card image
func NewCard(face Face, suit Suit) *Card {
	return &Card{
		s: suit,
		f: face,
	}
}

type Card struct {
	s     Suit
	f     Face
	node  *sprite.Node
	image sprite.SubTex
	pos   Position
}

// Returns the suit of c
func (c *Card) GetSuit() Suit {
	return c.s
}

// Returns the face of c
func (c *Card) GetFace() Face {
	return c.f
}

// Returns the node of c
func (c *Card) GetNode() *sprite.Node {
	return c.node
}

// Returns the image of c
func (c *Card) GetImage() sprite.SubTex {
	return c.image
}

// Returns the x-coordinate of the upper left corner of c
func (c *Card) GetX() float32 {
	return c.pos.GetCurrent().X
}

// Returns the y-coordinate of the upper left corner of c
func (c *Card) GetY() float32 {
	return c.pos.GetCurrent().Y
}

// Returns the x-coordinate of the upper left corner of c in its initial placement
func (c *Card) GetInitialX() float32 {
	return c.pos.GetInitial().X
}

// Returns the y-coordinate of the upper left corner of c in its initial placement
func (c *Card) GetInitialY() float32 {
	return c.pos.GetInitial().Y
}

// Returns the width of c
func (c *Card) GetWidth() float32 {
	return c.pos.GetDimensions().X
}

// Returns the height of c
func (c *Card) GetHeight() float32 {
	return c.pos.GetDimensions().Y
}

// Sets the node of c to n
func (c *Card) SetNode(n *sprite.Node) {
	c.node = n
}

// Sets the image of c to s
func (c *Card) SetImage(s sprite.SubTex) {
	c.image = s
}

// Moves c to a new position and size
func (c *Card) Move(newX float32, newY float32, newWidth float32, newHeight float32, eng sprite.Engine) {
	eng.SetTransform(c.node, f32.Affine{
		{newWidth, 0, newX},
		{0, newHeight, newY},
	})
	c.SetPos(newX, newY, newWidth, newHeight)
}

// Sets the variables of c to a new position and size, but does not actually update the image on-screen
func (c *Card) SetPos(newX float32, newY float32, newWidth float32, newHeight float32) {
	c.pos.SetCurrent(newX, newY)
	c.pos.SetDimensions(newWidth, newHeight)
}

// Sets the initial x and y coordinates of c
func (c *Card) SetInitialPos(newX float32, newY float32) {
	c.pos.SetInitial(newX, newY)
}

// Returns true if c is worth any points (all Hearts cards, and the Queen of Spades)
func (c *Card) WorthPoints() bool {
	return c.s == Heart || (c.s == Spade && c.f == Queen)
}

// Used to sort an array of cards
type CardSorter []*Card

// Returns the length of the array of cards
func (cs CardSorter) Len() int {
	return len(cs)
}

// Swaps the positions of two cards in the array
func (cs CardSorter) Swap(i, j int) {
	cs[i], cs[j] = cs[j], cs[i]
}

// Compares two cards-- one card is less than another if it has a lower suit, or if it has the same suit and a lower face
func (cs CardSorter) Less(i, j int) bool {
	if cs[i].GetSuit() == cs[j].GetSuit() {
		return cs[i].GetFace() < cs[j].GetFace()
	}
	return cs[i].GetSuit() < cs[j].GetSuit()
}
