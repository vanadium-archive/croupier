// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"hearts/img/newImg"
	"hearts/img/repositionImg"
	"hearts/img/screenResize"
	"hearts/img/staticImg"
	"hearts/logic/card"
	"testing"
)

var (
	eng           = glsprite.Engine()
	subtex        sprite.SubTex
	cardWidth     = float32(10)
	cardHeight    = float32(10)
	windowSize    = []float32{100, 100}
	padding       = float32(5)
	bottomPadding = float32(5)
	ppp           = float32(1)
	lastMouseXY   = []float32{0, 0}
	scene         = &sprite.Node{}
)

// Testing AdjustScaleDimensions
func TestOne(test *testing.T) {
	imgX := float32(5)
	imgY := float32(20)
	imgWidth := float32(10)
	imgHeight := float32(10)
	oldWindowWidth := float32(30)
	oldWindowHeight := float32(60)
	windowSize := []float32{90, 90}
	pos := card.MakePosition(imgX, imgY, imgX, imgY, imgWidth, imgHeight)
	newX, newY, _, _, newWidth, newHeight := resize.AdjustScaleDimensions(pos, oldWindowWidth, oldWindowHeight, windowSize)
	widthExpect := imgWidth * 3
	heightExpect := imgHeight * 3 / 2
	xExpect := float32(15)
	yExpect := float32(30)
	if newWidth != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newWidth)
	}
	if newHeight != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newHeight)
	}
	if newX != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newX)
	}
	if newY != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newY)
	}
}

// Testing AdjustKeepDimensions
func TestTwo(test *testing.T) {
	imgX := float32(5)
	imgY := float32(20)
	imgWidth := float32(10)
	imgHeight := float32(10)
	oldWindowWidth := float32(30)
	oldWindowHeight := float32(60)
	windowSize := []float32{90, 90}
	pos := card.MakePosition(imgX, imgY, imgX, imgY, imgWidth, imgHeight)
	newX, newY, _, _, newWidth, newHeight := resize.AdjustKeepDimensions(pos, oldWindowWidth, oldWindowHeight, windowSize)
	widthExpect := imgWidth
	heightExpect := imgHeight
	xExpect := float32(25)
	yExpect := float32(32.5)
	if newWidth != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newWidth)
	}
	if newHeight != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newHeight)
	}
	if newX != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newX)
	}
	if newY != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newY)
	}
}

// Testing full image adjustment after screen resizing (assumes adjustImgs is scaling dimensions)
func TestThree(test *testing.T) {
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	cards := make([]*card.Card, 0)
	dropTargets := make([]*staticimg.StaticImg, 0)
	buttons := make([]*staticimg.StaticImg, 0)
	buttonX := float32(5)
	buttonY := float32(20)
	buttonWidth := float32(10)
	buttonHeight := float32(10)
	buttonPos := card.MakePosition(buttonX, buttonY, buttonX, buttonY, buttonWidth, buttonHeight)
	newButton := texture.MakeImgWithoutAlt(subtex, buttonPos, eng, scene)
	buttons = append(buttons, newButton)
	backgroundImgs := make([]*staticimg.StaticImg, 0)
	emptySuitImgs := make([]*staticimg.StaticImg, 0)
	oldWidth := windowSize[0] / 2
	oldHeight := windowSize[1] / 2
	resize.AdjustImgs(oldWidth, oldHeight, cards, dropTargets, backgroundImgs, buttons, emptySuitImgs, windowSize, eng)
	newX := buttons[0].GetX()
	newY := buttons[0].GetY()
	newWidth := buttons[0].GetWidth()
	newHeight := buttons[0].GetHeight()
	widthExpect := buttonWidth * 2
	heightExpect := buttonHeight * 2
	xExpect := buttonX * 2
	yExpect := buttonY * 2
	if newWidth != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newWidth)
	}
	if newHeight != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newHeight)
	}
	if newX != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newX)
	}
	if newY != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newY)
	}
}

// Testing NewImgWithoutAlt
func TestFour(test *testing.T) {
	x := float32(5)
	y := float32(10)
	width := float32(20)
	height := float32(10)
	pos := card.MakePosition(x, y, x, y, width, height)
	i := texture.MakeImgWithoutAlt(subtex, pos, eng, scene)
	if i.GetX() != x {
		test.Errorf("Expected x %d, got %d", x, i.GetX())
	}
	if i.GetY() != y {
		test.Errorf("Expected y %d, got %d", y, i.GetY())
	}
	if i.GetInitialX() != x {
		test.Errorf("Expected inital x %d, got %d", x, i.GetInitialX())
	}
	if i.GetInitialY() != y {
		test.Errorf("Expected initial y %d, got %d", y, i.GetInitialY())
	}
	if i.GetWidth() != width {
		test.Errorf("Expected width %d, got %d", width, i.GetWidth())
	}
	if i.GetHeight() != height {
		test.Errorf("Expected height %d, got %d", height, i.GetHeight())
	}
}

// Testing NewImgWithAlt
func TestFive(test *testing.T) {
	x := float32(5)
	y := float32(10)
	width := float32(20)
	height := float32(10)
	pos := card.MakePosition(x, y, x, y, width, height)
	i := texture.MakeImgWithAlt(subtex, subtex, pos, true, eng, scene)
	if i.GetX() != x {
		test.Errorf("Expected x %d, got %d", x, i.GetX())
	}
	if i.GetY() != y {
		test.Errorf("Expected y %d, got %d", y, i.GetY())
	}
	if i.GetInitialX() != x {
		test.Errorf("Expected inital x %d, got %d", x, i.GetInitialX())
	}
	if i.GetInitialY() != y {
		test.Errorf("Expected initial y %d, got %d", y, i.GetInitialY())
	}
	if i.GetWidth() != width {
		test.Errorf("Expected width %d, got %d", width, i.GetWidth())
	}
	if i.GetHeight() != height {
		test.Errorf("Expected height %d, got %d", height, i.GetHeight())
	}
}

// Testing resetting card position
func TestSix(test *testing.T) {
	emptySuitImgs := []*staticimg.StaticImg{staticimg.MakeStaticImg(), staticimg.MakeStaticImg(), staticimg.MakeStaticImg(), staticimg.MakeStaticImg()}
	n := texture.MakeNode(eng, scene)
	for _, e := range emptySuitImgs {
		e.SetImage(subtex)
		e.SetAlt(subtex)
		e.SetNode(n)
	}
	cards := make([]*card.Card, 0)
	c := card.NewCard(card.Two, card.Heart)
	c2 := card.NewCard(card.Four, card.Heart)
	n = texture.MakeNode(eng, scene)
	n2 := texture.MakeNode(eng, scene)
	initialX := float32(10)
	initialY := float32(10)
	curX := float32(100)
	curY := float32(30)
	width := float32(5)
	height := float32(5)
	c.SetNode(n)
	c2.SetNode(n2)
	c.SetInitialPos(initialX, initialY)
	c2.SetInitialPos(initialX, initialY)
	c.Move(curX, curY, width, height, eng)
	c2.Move(curX, curY, width, height, eng)
	cards = append(cards, c)
	cards = append(cards, c2)
	if c.GetX() != curX {
		test.Errorf("Expected x %d, got %d", curX, c.GetX())
	}
	if c.GetY() != curY {
		test.Errorf("Expected y %d, got %d", curY, c.GetY())
	}
	reposition.ResetCardPosition(c, cards, emptySuitImgs, padding, windowSize, eng)
	reposition.ResetCardPosition(c2, cards, emptySuitImgs, padding, windowSize, eng)
	if c.GetX() != padding {
		test.Errorf("Expected x %d, got %d", initialX, c.GetX())
	}
	if c.GetY() != initialY {
		test.Errorf("Expected y %d, got %d", initialY, c.GetY())
	}
	if c2.GetX() != padding+width+padding {
		test.Errorf("Expected x %d, got %d", padding+width+padding, c2.GetX())
	}
	if c2.GetY() != initialY {
		test.Errorf("Expected y %d, got %d", initialY, c2.GetY())
	}
}
