// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"hearts/img/reposition"
	"hearts/img/resize"
	"hearts/img/staticimg"
	"hearts/img/texture"
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
	imgXY := card.MakeVec(5, 20)
	imgDimensions := card.MakeVec(10, 10)
	oldWindowWidth := float32(30)
	oldWindowHeight := float32(60)
	windowSize := []float32{90, 90}
	pos := card.MakePosition(imgXY, imgXY, imgDimensions)
	newXY, _, newDimensions := resize.AdjustScaleDimensions(pos, oldWindowWidth, oldWindowHeight, windowSize)
	widthExpect := imgDimensions.X * 3
	heightExpect := imgDimensions.Y * 3 / 2
	xExpect := float32(15)
	yExpect := float32(30)
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newXY.Y)
	}
}

// Testing AdjustKeepDimensions
func TestTwo(test *testing.T) {
	imgXY := card.MakeVec(5, 20)
	imgDimensions := card.MakeVec(10, 10)
	oldWindowWidth := float32(30)
	oldWindowHeight := float32(60)
	windowSize := []float32{90, 90}
	pos := card.MakePosition(imgXY, imgXY, imgDimensions)
	newXY, _, newDimensions := resize.AdjustKeepDimensions(pos, oldWindowWidth, oldWindowHeight, windowSize)
	widthExpect := imgDimensions.X
	heightExpect := imgDimensions.Y
	xExpect := float32(25)
	yExpect := float32(32.5)
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newXY.Y)
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
	imgXY := card.MakeVec(5, 20)
	imgDimensions := card.MakeVec(10, 10)
	buttonPos := card.MakePosition(imgXY, imgXY, imgDimensions)
	newButton := texture.MakeImgWithoutAlt(subtex, buttonPos, eng, scene)
	buttons = append(buttons, newButton)
	backgroundImgs := make([]*staticimg.StaticImg, 0)
	emptySuitImgs := make([]*staticimg.StaticImg, 0)
	oldWidth := windowSize[0] / 2
	oldHeight := windowSize[1] / 2
	resize.AdjustImgs(oldWidth, oldHeight, cards, dropTargets, backgroundImgs, buttons, emptySuitImgs, windowSize, eng)
	newXY := buttons[0].GetCurrent()
	newDimensions := buttons[0].GetDimensions()
	widthExpect := imgDimensions.X * 2
	heightExpect := imgDimensions.Y * 2
	xExpect := imgXY.X * 2
	yExpect := imgXY.Y * 2
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %d, got %d", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %d, got %d", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %d, got %d", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %d, got %d", yExpect, newXY.Y)
	}
}

// Testing NewImgWithoutAlt
func TestFour(test *testing.T) {
	xy := card.MakeVec(5, 10)
	dimensions := card.MakeVec(20, 10)
	pos := card.MakePosition(xy, xy, dimensions)
	i := texture.MakeImgWithoutAlt(subtex, pos, eng, scene)
	if i.GetCurrent().X != xy.X {
		test.Errorf("Expected x %d, got %d", xy.X, i.GetCurrent().X)
	}
	if i.GetCurrent().Y != xy.Y {
		test.Errorf("Expected y %d, got %d", xy.Y, i.GetCurrent().Y)
	}
	if i.GetInitial().X != xy.X {
		test.Errorf("Expected inital x %d, got %d", xy.X, i.GetInitial().X)
	}
	if i.GetInitial().Y != xy.Y {
		test.Errorf("Expected initial y %d, got %d", xy.Y, i.GetInitial().Y)
	}
	if i.GetDimensions().X != dimensions.X {
		test.Errorf("Expected width %d, got %d", dimensions.X, i.GetDimensions().X)
	}
	if i.GetDimensions().Y != dimensions.Y {
		test.Errorf("Expected height %d, got %d", dimensions.Y, i.GetDimensions().Y)
	}
}

// Testing NewImgWithAlt
func TestFive(test *testing.T) {
	xy := card.MakeVec(5, 10)
	dimensions := card.MakeVec(20, 10)
	pos := card.MakePosition(xy, xy, dimensions)
	i := texture.MakeImgWithAlt(subtex, subtex, pos, true, eng, scene)
	if i.GetCurrent().X != xy.X {
		test.Errorf("Expected x %d, got %d", xy.X, i.GetCurrent().X)
	}
	if i.GetCurrent().Y != xy.Y {
		test.Errorf("Expected y %d, got %d", xy.Y, i.GetCurrent().Y)
	}
	if i.GetInitial().X != xy.X {
		test.Errorf("Expected inital x %d, got %d", xy.X, i.GetInitial().X)
	}
	if i.GetInitial().Y != xy.Y {
		test.Errorf("Expected initial y %d, got %d", xy.Y, i.GetInitial().Y)
	}
	if i.GetDimensions().X != dimensions.X {
		test.Errorf("Expected width %d, got %d", dimensions.X, i.GetDimensions().X)
	}
	if i.GetDimensions().Y != dimensions.Y {
		test.Errorf("Expected height %d, got %d", dimensions.Y, i.GetDimensions().Y)
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
	initialXY := card.MakeVec(10, 10)
	curXY := card.MakeVec(100, 30)
	dimensions := card.MakeVec(5, 5)
	c.SetNode(n)
	c2.SetNode(n2)
	c.SetInitialPos(initialXY)
	c2.SetInitialPos(initialXY)
	c.Move(curXY, dimensions, eng)
	c2.Move(curXY, dimensions, eng)
	cards = append(cards, c)
	cards = append(cards, c2)
	if c.GetCurrent().X != curXY.X {
		test.Errorf("Expected x %d, got %d", curXY.X, c.GetCurrent().X)
	}
	if c.GetCurrent().Y != curXY.Y {
		test.Errorf("Expected y %d, got %d", curXY.Y, c.GetCurrent().Y)
	}
	reposition.ResetCardPosition(c, eng)
	reposition.ResetCardPosition(c2, eng)
	reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, cards, emptySuitImgs, padding, windowSize, eng)
	if c.GetCurrent().X != padding {
		test.Errorf("Expected x %d, got %d", initialXY.X, c.GetCurrent().X)
	}
	if c.GetCurrent().Y != initialXY.Y {
		test.Errorf("Expected y %d, got %d", initialXY.Y, c.GetCurrent().Y)
	}
	if c2.GetCurrent().X != padding+dimensions.X+padding {
		test.Errorf("Expected x %d, got %d", padding+dimensions.X+padding, c2.GetCurrent().X)
	}
	if c2.GetCurrent().Y != initialXY.Y {
		test.Errorf("Expected y %d, got %d", initialXY.Y, c2.GetCurrent().Y)
	}
}
