// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"hearts/img/coords"
	"hearts/img/reposition"
	"hearts/img/resize"
	"hearts/img/staticimg"
	"hearts/img/texture"
	"hearts/img/uistate"
	"hearts/logic/card"
	"testing"
)

var (
	subtex     sprite.SubTex
	windowSize = coords.MakeVec(90, 90)
	u          *uistate.UIState
)

// Testing AdjustScaleDimensions
func TestOne(test *testing.T) {
	imgXY := coords.MakeVec(5, 20)
	imgDimensions := coords.MakeVec(10, 10)
	oldWindow := coords.MakeVec(30, 60)
	pos := coords.MakePosition(imgXY, imgXY, imgDimensions)
	newXY, _, newDimensions := resize.AdjustScaleDimensions(pos, oldWindow, windowSize)
	widthExpect := imgDimensions.X * 3
	heightExpect := imgDimensions.Y * 3 / 2
	xExpect := float32(15)
	yExpect := float32(30)
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %f, got %f", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %f, got %f", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %f, got %f", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %f, got %f", yExpect, newXY.Y)
	}
}

// Testing AdjustKeepDimensions
func TestTwo(test *testing.T) {
	imgXY := coords.MakeVec(5, 20)
	imgDimensions := coords.MakeVec(10, 10)
	oldWindow := coords.MakeVec(30, 60)
	pos := coords.MakePosition(imgXY, imgXY, imgDimensions)
	newXY, _, newDimensions := resize.AdjustKeepDimensions(pos, oldWindow, windowSize)
	widthExpect := imgDimensions.X
	heightExpect := imgDimensions.Y
	xExpect := float32(25)
	yExpect := float32(32.5)
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %f, got %f", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %f, got %f", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %f, got %f", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %f, got %f", yExpect, newXY.Y)
	}
}

// Testing full image adjustment after screen resizing (assumes adjustImgs is scaling dimensions)
func TestThree(test *testing.T) {
	u = uistate.MakeUIState()
	u.Scene = &sprite.Node{}
	u.Eng = glsprite.Engine(nil)
	u.Eng.Register(u.Scene)
	u.Eng.SetTransform(u.Scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	imgXY := coords.MakeVec(5, 20)
	imgDimensions := coords.MakeVec(10, 10)
	buttonPos := coords.MakePosition(imgXY, imgXY, imgDimensions)
	newButton := texture.MakeImgWithoutAlt(subtex, buttonPos, u.Eng, u.Scene)
	u.Buttons = append(u.Buttons, newButton)
	oldWindow := coords.MakeVec(u.WindowSize.X/2, u.WindowSize.Y/2)
	resize.AdjustImgs(oldWindow, u)
	newXY := u.Buttons[0].GetCurrent()
	newDimensions := u.Buttons[0].GetDimensions()
	widthExpect := imgDimensions.X * 2
	heightExpect := imgDimensions.Y * 2
	xExpect := imgXY.X * 2
	yExpect := imgXY.Y * 2
	if newDimensions.X != widthExpect {
		test.Errorf("Expected width %f, got %f", widthExpect, newDimensions.X)
	}
	if newDimensions.Y != heightExpect {
		test.Errorf("Expected height %f, got %f", heightExpect, newDimensions.Y)
	}
	if newXY.X != xExpect {
		test.Errorf("Expected x %f, got %f", xExpect, newXY.X)
	}
	if newXY.Y != yExpect {
		test.Errorf("Expected y %f, got %f", yExpect, newXY.Y)
	}
}

// Testing NewImgWithoutAlt
func TestFour(test *testing.T) {
	scene := &sprite.Node{}
	eng := glsprite.Engine(nil)
	xy := coords.MakeVec(5, 10)
	dimensions := coords.MakeVec(20, 10)
	pos := coords.MakePosition(xy, xy, dimensions)
	i := texture.MakeImgWithoutAlt(subtex, pos, eng, scene)
	if i.GetCurrent().X != xy.X {
		test.Errorf("Expected x %f, got %f", xy.X, i.GetCurrent().X)
	}
	if i.GetCurrent().Y != xy.Y {
		test.Errorf("Expected y %f, got %f", xy.Y, i.GetCurrent().Y)
	}
	if i.GetInitial().X != xy.X {
		test.Errorf("Expected inital x %f, got %f", xy.X, i.GetInitial().X)
	}
	if i.GetInitial().Y != xy.Y {
		test.Errorf("Expected initial y %f, got %f", xy.Y, i.GetInitial().Y)
	}
	if i.GetDimensions().X != dimensions.X {
		test.Errorf("Expected width %f, got %f", dimensions.X, i.GetDimensions().X)
	}
	if i.GetDimensions().Y != dimensions.Y {
		test.Errorf("Expected height %f, got %f", dimensions.Y, i.GetDimensions().Y)
	}
}

// Testing NewImgWithAlt
func TestFive(test *testing.T) {
	scene := &sprite.Node{}
	eng := glsprite.Engine(nil)
	xy := coords.MakeVec(5, 10)
	dimensions := coords.MakeVec(20, 10)
	pos := coords.MakePosition(xy, xy, dimensions)
	i := texture.MakeImgWithAlt(subtex, subtex, pos, true, eng, scene)
	if i.GetCurrent().X != xy.X {
		test.Errorf("Expected x %f, got %f", xy.X, i.GetCurrent().X)
	}
	if i.GetCurrent().Y != xy.Y {
		test.Errorf("Expected y %f, got %f", xy.Y, i.GetCurrent().Y)
	}
	if i.GetInitial().X != xy.X {
		test.Errorf("Expected inital x %f, got %f", xy.X, i.GetInitial().X)
	}
	if i.GetInitial().Y != xy.Y {
		test.Errorf("Expected initial y %f, got %f", xy.Y, i.GetInitial().Y)
	}
	if i.GetDimensions().X != dimensions.X {
		test.Errorf("Expected width %f, got %f", dimensions.X, i.GetDimensions().X)
	}
	if i.GetDimensions().Y != dimensions.Y {
		test.Errorf("Expected height %f, got %f", dimensions.Y, i.GetDimensions().Y)
	}
}

// Testing resetting card position
func TestSix(test *testing.T) {
	u = uistate.MakeUIState()
	u.Scene = &sprite.Node{}
	u.Eng = glsprite.Engine(nil)
	u.Eng.Register(u.Scene)
	u.Eng.SetTransform(u.Scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	u.EmptySuitImgs = []*staticimg.StaticImg{staticimg.MakeStaticImg(), staticimg.MakeStaticImg(), staticimg.MakeStaticImg(), staticimg.MakeStaticImg()}
	u.WindowSize = windowSize
	n := texture.MakeNode(u.Eng, u.Scene)
	for _, e := range u.EmptySuitImgs {
		e.SetImage(subtex)
		e.SetAlt(subtex)
		e.SetNode(n)
	}
	c := card.NewCard(card.Two, card.Heart)
	c2 := card.NewCard(card.Four, card.Heart)
	n = texture.MakeNode(u.Eng, u.Scene)
	n2 := texture.MakeNode(u.Eng, u.Scene)
	initialXY := coords.MakeVec(10, 10)
	curXY := coords.MakeVec(100, 30)
	dimensions := coords.MakeVec(5, 5)
	c.SetNode(n)
	c2.SetNode(n2)
	c.InitializePosition()
	c2.InitializePosition()
	c.SetInitial(initialXY)
	c2.SetInitial(initialXY)
	c.Move(curXY, dimensions, u.Eng)
	c2.Move(curXY, dimensions, u.Eng)
	u.Cards = append(u.Cards, c)
	u.Cards = append(u.Cards, c2)
	if c.GetCurrent().X != curXY.X {
		test.Errorf("Expected x %f, got %f", curXY.X, c.GetCurrent().X)
	}
	if c.GetCurrent().Y != curXY.Y {
		test.Errorf("Expected y %f, got %f", curXY.Y, c.GetCurrent().Y)
	}
	reposition.ResetCardPosition(c, u.Eng)
	reposition.ResetCardPosition(c2, u.Eng)
	reposition.RealignSuit(c.GetSuit(), c.GetInitial().Y, u)
	if c.GetCurrent().X != u.Padding {
		test.Errorf("Expected x %f, got %f", initialXY.X, c.GetCurrent().X)
	}
	if c.GetCurrent().Y != initialXY.Y {
		test.Errorf("Expected y %f, got %f", initialXY.Y, c.GetCurrent().Y)
	}
	if c2.GetCurrent().X != u.Padding+dimensions.X+u.Padding {
		test.Errorf("Expected x %f, got %f", u.Padding+dimensions.X+u.Padding, c2.GetCurrent().X)
	}
	if c2.GetCurrent().Y != initialXY.Y {
		test.Errorf("Expected y %f, got %f", initialXY.Y, c2.GetCurrent().Y)
	}
}
