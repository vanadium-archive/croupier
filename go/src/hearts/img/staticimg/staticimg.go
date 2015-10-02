// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package staticimg

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"hearts/logic/card"
)

// Returns a new StaticImg object, with no variables set
func MakeStaticImg() *StaticImg {
	return &StaticImg{}
}

// Static Images may be buttons, drop targets, or any other image that is not a card object
type StaticImg struct {
	node  *sprite.Node
	image sprite.SubTex
	// alt may or may not be used
	// can be used as the 'pressed' image if the StaticImg instance is a button
	// also can be used as a 'blank' image if the StaticImg instance may disappear
	alt sprite.SubTex
	pos card.Position
	// cardHere is used if the StaticImg instance is a drop target
	cardHere *card.Card
}

// Returns the node of s
func (s *StaticImg) GetNode() *sprite.Node {
	return s.node
}

// Returns the image of s
func (s *StaticImg) GetImage() sprite.SubTex {
	return s.image
}

// Returns the alternate image of s
func (s *StaticImg) GetAlt() sprite.SubTex {
	return s.alt
}

// Returns a vector containing the current x- and y-coordinate of the upper left corner of s
func (s *StaticImg) GetCurrent() card.Vec {
	return s.pos.GetCurrent()
}

// Returns a vector containing the initial x- and y-coordinate of the upper left corner of s
func (s *StaticImg) GetInitial() card.Vec {
	return s.pos.GetInitial()
}

// Returns a vector containing the width and height of s
func (s *StaticImg) GetDimensions() card.Vec {
	return s.pos.GetDimensions()
}

// Returns the card currently pinned to s
func (s *StaticImg) GetCardHere() *card.Card {
	return s.cardHere
}

// Returns the node of s
func (s *StaticImg) SetNode(n *sprite.Node) {
	s.node = n
}

// Sets the image of s to t
func (s *StaticImg) SetImage(t sprite.SubTex) {
	s.image = t
}

// Sets the alternate image of s to t
func (s *StaticImg) SetAlt(t sprite.SubTex) {
	s.alt = t
}

// Moves s to a new position and size
func (s *StaticImg) Move(newXY, newDimensions card.Vec, eng sprite.Engine) {
	eng.SetTransform(s.node, f32.Affine{
		{newDimensions.X, 0, newXY.X},
		{0, newDimensions.Y, newXY.Y},
	})
	s.pos.SetCurrent(newXY)
	s.pos.SetDimensions(newDimensions)
}

// Sets the initial x and y coordinates of the upper left corner of s
func (s *StaticImg) SetInitialPos(newXY card.Vec) {
	s.pos.SetInitial(newXY)
}

// Pins card c to s
func (s *StaticImg) SetCardHere(c *card.Card) {
	s.cardHere = c
}
