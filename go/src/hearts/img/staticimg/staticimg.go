// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// staticimg is where the StaticImg struct is defined.
// This struct contains image information for all images other than cards.

package staticimg

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"hearts/img/coords"
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
	// alt may or may not be set. It is a second SubTex in case the staticImg may alternate between two displays
	// can be used as the 'pressed' image if the StaticImg instance is a button
	// also can be used as a 'blank' image if the StaticImg instance may disappear
	alt sprite.SubTex
	// displayingImage is true is image is currently being displayed, and false if alt is currently being displayed
	displayingImage bool
	// XY coordinates of the initial placement of the image
	initial *coords.Vec
	// current XY coordinates of the image
	current *coords.Vec
	// current width and height of the image
	dimensions *coords.Vec
	// cardHere is used if the StaticImg instance is a drop target
	cardHere *card.Card
	// info contains any additional information contained in the image (eg. game syncgroup address, in a join game button)
	info []string
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

func (s *StaticImg) GetDisplayingImage() bool {
	return s.displayingImage
}

// Returns a vector containing the current x- and y-coordinate of the upper left corner of s
func (s *StaticImg) GetCurrent() *coords.Vec {
	return s.current
}

// Returns a vector containing the initial x- and y-coordinate of the upper left corner of s
func (s *StaticImg) GetInitial() *coords.Vec {
	return s.initial
}

// Returns a vector containing the width and height of s
func (s *StaticImg) GetDimensions() *coords.Vec {
	return s.dimensions
}

// Returns the card currently pinned to s
func (s *StaticImg) GetCardHere() *card.Card {
	return s.cardHere
}

// Returns the additional info associated with s
func (s *StaticImg) GetInfo() []string {
	return s.info
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

func (s *StaticImg) SetDisplayingImage(disp bool) {
	s.displayingImage = disp
}

// Moves s to a new position and size
func (s *StaticImg) Move(newXY, newDimensions *coords.Vec, eng sprite.Engine) {
	eng.SetTransform(s.node, f32.Affine{
		{newDimensions.X, 0, newXY.X},
		{0, newDimensions.Y, newXY.Y},
	})
	s.current = newXY
	s.dimensions = newDimensions
}

func (s *StaticImg) SetInitial(initial *coords.Vec) {
	s.initial = initial
}

// Pins card c to s
func (s *StaticImg) SetCardHere(c *card.Card) {
	s.cardHere = c
}

// Sets the additional info of s
func (s *StaticImg) SetInfo(i []string) {
	s.info = i
}
