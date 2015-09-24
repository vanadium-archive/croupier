// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package img

import (
	"golang.org/x/mobile/exp/sprite"
	"hearts/logic/card"
)

func NewStaticImg() *StaticImg {
	return &StaticImg{}
}

// Static Images may be buttons, drop targets, or any other image that is not a card object
type StaticImg struct {
	node  *sprite.Node
	image sprite.SubTex
	// alt may or may not be used
	// can be used as the 'pressed' image if the StaticImg instance is a button
	// also can be used as a 'blank' image if the StaticImg instance may disappear
	alt      sprite.SubTex
	x        float32
	y        float32
	initialX float32
	initialY float32
	width    float32
	height   float32
	// cardHere is used if the StaticImg instance is a drop target
	cardHere *card.Card
}

func (s *StaticImg) GetNode() *sprite.Node {
	return s.node
}

func (s *StaticImg) GetImage() sprite.SubTex {
	return s.image
}

func (s *StaticImg) GetAlt() sprite.SubTex {
	return s.alt
}

func (s *StaticImg) GetX() float32 {
	return s.x
}

func (s *StaticImg) GetY() float32 {
	return s.y
}

func (s *StaticImg) GetInitialX() float32 {
	return s.initialX
}

func (s *StaticImg) GetInitialY() float32 {
	return s.initialY
}

func (s *StaticImg) GetWidth() float32 {
	return s.width
}

func (s *StaticImg) GetHeight() float32 {
	return s.height
}

func (s *StaticImg) GetCardHere() *card.Card {
	return s.cardHere
}

func (s *StaticImg) SetNode(n *sprite.Node) {
	s.node = n
}

func (s *StaticImg) SetImage(t sprite.SubTex) {
	s.image = t
}

func (s *StaticImg) SetAlt(t sprite.SubTex) {
	s.alt = t
}

func (s *StaticImg) SetPos(newX float32, newY float32, newWidth float32, newHeight float32) {
	s.x = newX
	s.y = newY
	s.width = newWidth
	s.height = newHeight
}

func (s *StaticImg) SetInitialPos(newX float32, newY float32) {
	s.initialX = newX
	s.initialY = newY
}

func (s *StaticImg) SetCardHere(c *card.Card) {
	s.cardHere = c
}
