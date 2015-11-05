// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// card.go contains the Suit and Face types, as well as the Card struct.
// Card contains basic card variables, including both logic and UI information.

package card

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"

	"hearts/img/coords"
)

type Suit int

const (
	Club Suit = iota
	Diamond
	Spade
	Heart
	UnknownSuit
)

// Converts a Suit type to string type
func (s Suit) String() string {
	switch s {
	case Heart:
		return "h"
	case Diamond:
		return "d"
	case Spade:
		return "s"
	case Club:
		return "c"
	default:
		return "?"
	}
}

// Converts a string type to Suit type
func ConvertToSuit(s string) Suit {
	switch s {
	case "h":
		return Heart
	case "d":
		return Diamond
	case "s":
		return Spade
	case "c":
		return Club
	default:
		return UnknownSuit
	}
}

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
	UnknownFace
)

// Converts a Face type to string type
func (f Face) String() string {
	switch f {
	case Ace:
		return "1"
	case Two:
		return "2"
	case Three:
		return "3"
	case Four:
		return "4"
	case Five:
		return "5"
	case Six:
		return "6"
	case Seven:
		return "7"
	case Eight:
		return "8"
	case Nine:
		return "9"
	case Ten:
		return "10"
	case Jack:
		return "j"
	case Queen:
		return "q"
	case King:
		return "k"
	default:
		return "?"
	}
}

// Converts a string type to Face type
func ConvertToFace(s string) Face {
	switch s {
	case "1":
		return Ace
	case "2":
		return Two
	case "3":
		return Three
	case "4":
		return Four
	case "5":
		return Five
	case "6":
		return Six
	case "7":
		return Seven
	case "8":
		return Eight
	case "9":
		return Nine
	case "10":
		return Ten
	case "j":
		return Jack
	case "q":
		return Queen
	case "k":
		return King
	default:
		return UnknownFace
	}
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
	pos   *coords.Position
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

func (c *Card) GetPosition() *coords.Position {
	return c.pos
}

// Returns a vector containing the current x- and y-coordinate of the upper left corner of c
func (c *Card) GetCurrent() *coords.Vec {
	return c.pos.GetCurrent()
}

// Returns a vector containing the initial x- and y-coordinate of the upper left corner of c
func (c *Card) GetInitial() *coords.Vec {
	return c.pos.GetInitial()
}

// Returns a vector containing the width and height of c
func (c *Card) GetDimensions() *coords.Vec {
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

// Sets the card back of c to s
func (c *Card) SetBack(s sprite.SubTex) {
	c.back = s
}

// Shows the front of c
func (c *Card) SetFrontDisplay(eng sprite.Engine) {
	eng.SetSubTex(c.node, c.image)
}

// Shows the back of c
func (c *Card) SetBackDisplay(eng sprite.Engine) {
	eng.SetSubTex(c.node, c.back)
}

// Moves c to a new position and size
func (c *Card) Move(newXY, newDimensions *coords.Vec, eng sprite.Engine) {
	eng.SetTransform(c.node, f32.Affine{
		{newDimensions.X, 0, newXY.X},
		{0, newDimensions.Y, newXY.Y},
	})
	pos := coords.MakePosition(c.GetInitial(), newXY, newDimensions)
	c.SetPos(pos)
}

// Sets the variables of c to a new position and size, but does not actually update the image on-screen
func (c *Card) SetPos(pos *coords.Position) {
	c.pos = pos
}

// Sets the initial x and y coordinates of c
func (c *Card) SetInitial(newInitial *coords.Vec) {
	c.pos.SetInitial(newInitial)
}

func (c *Card) InitializePosition() {
	zero := coords.MakeVec(0, 0)
	pos := coords.MakePosition(zero, zero, zero)
	c.SetPos(pos)
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
