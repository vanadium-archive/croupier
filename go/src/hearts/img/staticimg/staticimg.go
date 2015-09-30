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

// Returns the x-coordinate of the upper left corner of s
func (s *StaticImg) GetX() float32 {
	return s.pos.GetCurrent().X
}

// Returns the y-coordinate of the upper left corner of s
func (s *StaticImg) GetY() float32 {
	return s.pos.GetCurrent().Y
}

// Returns the x-coordinate of the upper left corner of s in its initial placement
func (s *StaticImg) GetInitialX() float32 {
	return s.pos.GetInitial().X
}

// Returns the y-coordinate of the upper left corner of s in its initial placement
func (s *StaticImg) GetInitialY() float32 {
	return s.pos.GetInitial().Y
}

// Returns the width of s
func (s *StaticImg) GetWidth() float32 {
	return s.pos.GetDimensions().X
}

// Returns the height of s
func (s *StaticImg) GetHeight() float32 {
	return s.pos.GetDimensions().Y
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
func (s *StaticImg) Move(newX float32, newY float32, newWidth float32, newHeight float32, eng sprite.Engine) {
	eng.SetTransform(s.node, f32.Affine{
		{newWidth, 0, newX},
		{0, newHeight, newY},
	})
	s.pos.SetCurrent(newX, newY)
	s.pos.SetDimensions(newWidth, newHeight)
}

// Sets the initial x and y coordinates of the upper left corner of s
func (s *StaticImg) SetInitialPos(newX float32, newY float32) {
	s.pos.SetInitial(newX, newY)
}

// Pins card c to s
func (s *StaticImg) SetCardHere(c *card.Card) {
	s.cardHere = c
}
