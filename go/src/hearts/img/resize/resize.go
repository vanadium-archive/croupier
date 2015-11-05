// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// resize handles UI changes when the app changes size or dimensions

package resize

import (
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/exp/sprite"

	"hearts/img/coords"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/logic/card"
)

func UpdateImgPositions(sz size.Event, u *uistate.UIState) {
	// must copy u.WindowSize instead of creating a pointer to it
	oldWindow := coords.MakeVec(u.WindowSize.X, u.WindowSize.Y)
	updateWindowSize(sz, u)
	if windowExists(oldWindow) && windowExists(u.WindowSize) {
		u.Padding = scaleVar(u.Padding, oldWindow, u.WindowSize)
		u.CardDim = scaleVec(u.CardDim, oldWindow, u.WindowSize)
		u.TableCardDim = scaleVec(u.TableCardDim, oldWindow, u.WindowSize)
		AdjustImgs(oldWindow, u)
	}
}

func updateWindowSize(sz size.Event, u *uistate.UIState) {
	u.WindowSize.SetVec(float32(sz.WidthPt), float32(sz.HeightPt))
	u.PixelsPerPt = float32(sz.WidthPx) / u.WindowSize.X
}

// Adjusts all images to accommodate a screen size change
// Public for testing, but could be made private
func AdjustImgs(oldWindow *coords.Vec, u *uistate.UIState) {
	adjustCardArray(u.Cards, oldWindow, u.WindowSize, u.Eng)
	adjustCardArray(u.TableCards, oldWindow, u.WindowSize, u.Eng)
	adjustImgArray(u.DropTargets, oldWindow, u.WindowSize, u.Eng)
	adjustImgArray(u.BackgroundImgs, oldWindow, u.WindowSize, u.Eng)
	adjustImgArray(u.Buttons, oldWindow, u.WindowSize, u.Eng)
	adjustImgArray(u.EmptySuitImgs, oldWindow, u.WindowSize, u.Eng)
	adjustImgArray(u.Other, oldWindow, u.WindowSize, u.Eng)
}

// Returns coordinates for images with same width and height but in new positions proportional to the screen
// Public for testing, but could be made private
func AdjustKeepDimensions(oldPos *coords.Position, oldWindow, windowSize *coords.Vec) (*coords.Vec, *coords.Vec, *coords.Vec) {
	oldXY := oldPos.GetCurrent()
	oldInitialXY := oldPos.GetInitial()
	oldDimensions := oldPos.GetDimensions()
	newXY := oldXY.PlusVec(oldDimensions.DividedBy(2)).DividedByVec(oldWindow).TimesVec(windowSize).MinusVec(oldDimensions.DividedBy(2))
	newInitialXY := oldInitialXY.PlusVec(oldDimensions.DividedBy(2)).DividedByVec(oldWindow).TimesVec(windowSize).MinusVec(oldDimensions.DividedBy(2))
	return newXY, newInitialXY, oldDimensions
}

// Returns coordinates for images with position, width and height scaled proportional to the screen
// Public for testing, but could be made private
func AdjustScaleDimensions(oldPos *coords.Position, oldWindow, windowSize *coords.Vec) (*coords.Vec, *coords.Vec, *coords.Vec) {
	return oldPos.Rescale(oldWindow, windowSize)
}

// Adjusts the positioning of an individual array of images
func adjustImgArray(imgs []*staticimg.StaticImg, oldWindow, windowSize *coords.Vec, eng sprite.Engine) {
	for _, s := range imgs {
		oldDimensions := s.GetDimensions()
		oldXY := s.GetCurrent()
		oldInitial := s.GetInitial()
		oldPos := coords.MakePosition(oldInitial, oldXY, oldDimensions)
		newInitialXY, newXY, newDimensions := AdjustScaleDimensions(oldPos, oldWindow, windowSize)
		s.Move(newXY, newDimensions, eng)
		s.SetInitial(newInitialXY)
	}
}

// Adjusts the positioning of an individual array of cards
func adjustCardArray(cards []*card.Card, oldWindow, windowSize *coords.Vec, eng sprite.Engine) {
	for _, c := range cards {
		oldDimensions := c.GetDimensions()
		oldLocation := c.GetCurrent()
		oldInitial := c.GetInitial()
		oldPos := coords.MakePosition(oldInitial, oldLocation, oldDimensions)
		newInitial, newLocation, newDimensions := AdjustScaleDimensions(oldPos, oldWindow, windowSize)
		c.Move(newLocation, newDimensions, eng)
		c.SetInitial(newInitial)
	}
}

// Scales a float32 to a new window
func scaleVar(curVar float32, oldWindow, newWindow *coords.Vec) float32 {
	return curVar * newWindow.X / oldWindow.X
}

func scaleVec(vec, oldWindow, newWindow *coords.Vec) *coords.Vec {
	return vec.TimesVec(newWindow).DividedByVec(oldWindow)
}

func windowExists(window *coords.Vec) bool {
	return !(window.X < 0 || window.Y < 0)
}
