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
	oldWindowSize := coords.MakeVec(u.WindowSize.X, u.WindowSize.Y)
	updateWindowSize(sz, u)
	if windowExists(oldWindowSize) && windowExists(u.WindowSize) {
		u.Padding = scaleVar(u.Padding, oldWindowSize, u.WindowSize)
		AdjustImgs(oldWindowSize, u)
	}
}

func updateWindowSize(sz size.Event, u *uistate.UIState) {
	u.WindowSize.SetVec(float32(sz.WidthPt), float32(sz.HeightPt))
	u.PixelsPerPt = float32(sz.WidthPx) / u.WindowSize.X
}

// Adjusts all images to accommodate a screen size change
// Public for testing, but could be made private
func AdjustImgs(oldWindowSize *coords.Vec, u *uistate.UIState) {
	adjustCardArray(u.Cards, oldWindowSize, u.WindowSize, u.Eng)
	adjustCardArray(u.TableCards, oldWindowSize, u.WindowSize, u.Eng)
	adjustImgArray(u.DropTargets, oldWindowSize, u.WindowSize, u.Eng)
	adjustImgArray(u.BackgroundImgs, oldWindowSize, u.WindowSize, u.Eng)
	adjustImgArray(u.EmptySuitImgs, oldWindowSize, u.WindowSize, u.Eng)
	adjustImgArray(u.Other, oldWindowSize, u.WindowSize, u.Eng)
	adjustImgArray(u.ModText, oldWindowSize, u.WindowSize, u.Eng)
	buttons := make([]*staticimg.StaticImg, 0)
	for _, b := range u.Buttons {
		buttons = append(buttons, b)
	}
	adjustImgArray(buttons, oldWindowSize, u.WindowSize, u.Eng)
}

// Returns coordinates for images with same width and height but in new positions proportional to the screen
// Public for testing, but could be made private
func AdjustKeepDimensions(oldInitial, oldPos, oldDimensions, oldWindowSize, newWindowSize *coords.Vec) (*coords.Vec, *coords.Vec, *coords.Vec) {
	newPos := oldPos.PlusVec(oldDimensions.DividedBy(2)).DividedByVec(oldWindowSize).TimesVec(newWindowSize).MinusVec(oldDimensions.DividedBy(2))
	newInitial := oldInitial.PlusVec(oldDimensions.DividedBy(2)).DividedByVec(oldWindowSize).TimesVec(newWindowSize).MinusVec(oldDimensions.DividedBy(2))
	return newInitial, newPos, oldDimensions
}

// Returns coordinates for images with position, width and height scaled proportional to the screen
// Public for testing, but could be made private
func AdjustScaleDimensions(oldInitial, oldPos, oldDimensions, oldWindowSize, newWindowSize *coords.Vec) (*coords.Vec, *coords.Vec, *coords.Vec) {
	return oldInitial.Rescale(oldWindowSize, newWindowSize),
		oldPos.Rescale(oldWindowSize, newWindowSize),
		oldDimensions.Rescale(oldWindowSize, newWindowSize)
}

// Adjusts the positioning of an individual array of images
func adjustImgArray(imgs []*staticimg.StaticImg, oldWindowSize, newWindowSize *coords.Vec, eng sprite.Engine) {
	for _, s := range imgs {
		newInitial, newPos, newDimensions := AdjustScaleDimensions(
			s.GetInitial(), s.GetCurrent(), s.GetDimensions(), oldWindowSize, newWindowSize)
		s.Move(newPos, newDimensions, eng)
		s.SetInitial(newInitial)
	}
}

// Adjusts the positioning of an individual array of cards
func adjustCardArray(cards []*card.Card, oldWindowSize, newWindowSize *coords.Vec, eng sprite.Engine) {
	for _, c := range cards {
		newInitial, newPos, newDimensions := AdjustScaleDimensions(
			c.GetInitial(), c.GetCurrent(), c.GetDimensions(), oldWindowSize, newWindowSize)
		c.Move(newPos, newDimensions, eng)
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
