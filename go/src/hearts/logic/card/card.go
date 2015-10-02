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

func (v *Vec) SetVec(x, y float32) {
	v.X = x
	v.Y = y
}

func (v Vec) Rescale(oldWindow, newWindow Vec) Vec {
	newX := v.X/oldWindow.X*newWindow.X
	newY := v.Y/oldWindow.Y*newWindow.Y
	newXY := MakeVec(newX, newY)
	return newXY
}

type Position struct {
	initial    Vec
	current    Vec
	dimensions Vec
}

// Returns a new position
func MakePosition(i, c, d Vec) *Position {
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
func (p *Position) SetInitial(v Vec) {
	p.initial = v
}

// Updates the current Vec of p
func (p *Position) SetCurrent(v Vec) {
	p.current = v
}

// Updates the dimensions Vec of p
func (p *Position) SetDimensions(v Vec) {
	p.dimensions = v
}

func (p *Position) Rescale(oldWindow, newWindow Vec) (Vec, Vec, Vec){
	i := p.initial.Rescale(oldWindow, newWindow)
	c := p.current.Rescale(oldWindow, newWindow)
	d := p.dimensions.Rescale(oldWindow, newWindow)
	return i, c, d
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
	back  sprite.SubTex
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

// Returns the image of the back of c
func (c *Card) GetBack() sprite.SubTex {
	return c.back
}

// Returns a vector containing the current x- and y-coordinate of the upper left corner of c
func (c *Card) GetCurrent() Vec {
	return c.pos.GetCurrent()
}

// Returns a vector containing the initial x- and y-coordinate of the upper left corner of c
func (c *Card) GetInitial() Vec {
	return c.pos.GetInitial()
}

// Returns a vector containing the width and height of c
func (c *Card) GetDimensions() Vec {
	return c.pos.GetDimensions()
}

// Sets the node of c to n
func (c *Card) SetNode(n *sprite.Node) {
	c.node = n
}

// Sets the image of c to s
func (c *Card) SetImage(s sprite.SubTex) {
	c.image = s
}

func (c *Card) SetBack(s sprite.SubTex) {
	c.back = s
}

// Moves c to a new position and size
func (c *Card) Move(newXY, newDimensions Vec, eng sprite.Engine) {
	eng.SetTransform(c.node, f32.Affine{
		{newDimensions.X, 0, newXY.X},
		{0, newDimensions.Y, newXY.Y},
	})
	c.SetPos(newXY, newDimensions)
}

// Sets the variables of c to a new position and size, but does not actually update the image on-screen
func (c *Card) SetPos(newXY, newDimensions Vec) {
	c.pos.SetCurrent(newXY)
	c.pos.SetDimensions(newDimensions)
}

// Sets the initial x and y coordinates of c
func (c *Card) SetInitialPos(newInitialXY Vec) {
	c.pos.SetInitial(newInitialXY)
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
