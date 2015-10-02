// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package resize

import (
	"golang.org/x/mobile/exp/sprite"
	"hearts/img/staticimg"
	"hearts/logic/card"
)

// Adjusts all images to accommodate a screen size change
// Takes as arguments:
// oldWindowWidth, oldWindowHeight = the dimensions of the window before it was resized
// cards, dropTargets, backgroundImgs, buttons, emptySuitImgs = the lists of image objects to be resized
// windowSize = an array containing the width and height of the app window
// eng = the engine running the app
func AdjustImgs(oldWindow card.Vec,
	cards []*card.Card,
	dropTargets,
	backgroundImgs,
	buttons,
	emptySuitImgs []*staticimg.StaticImg,
	windowSize card.Vec,
	eng sprite.Engine) {
	for _, c := range cards {
		oldDimensions := c.GetDimensions()
		oldXY := c.GetCurrent()
		oldInitialXY := c.GetInitial()
		oldPos := card.MakePosition(oldInitialXY, oldXY, oldDimensions)
		newXY, newInitialXY, newDimensions := AdjustScaleDimensions(oldPos, oldWindow, windowSize)
		c.Move(newXY, newDimensions, eng)
		c.SetInitialPos(newInitialXY)
	}
	AdjustImgArray(dropTargets, oldWindow, windowSize, eng)
	AdjustImgArray(backgroundImgs, oldWindow, windowSize, eng)
	AdjustImgArray(buttons, oldWindow, windowSize, eng)
	AdjustImgArray(emptySuitImgs, oldWindow, windowSize, eng)
}

// Returns coordinates for images with same width and height but in new positions proportional to the screen
func AdjustKeepDimensions(oldPos *card.Position, oldWindow, windowSize card.Vec) (card.Vec, card.Vec, card.Vec) {
	oldXY := oldPos.GetCurrent()
	oldInitialXY := oldPos.GetInitial()
	oldDimensions := oldPos.GetDimensions()
	newX := (oldXY.X+oldDimensions.X/2)/oldWindow.X*windowSize.X - oldDimensions.X/2
	newY := (oldXY.Y+oldDimensions.Y/2)/oldWindow.Y*windowSize.Y - oldDimensions.Y/2
	newInitialX := (oldInitialXY.X+oldDimensions.X/2)/oldWindow.X*windowSize.X - oldDimensions.X/2
	newInitialY := (oldInitialXY.Y+oldDimensions.Y/2)/oldWindow.Y*windowSize.Y - oldDimensions.Y/2
	newXY := card.MakeVec(newX, newY)
	newInitialXY := card.MakeVec(newInitialX, newInitialY)
	return newXY, newInitialXY, oldDimensions
}

// Returns coordinates for images with position, width and height scaled proportional to the screen
func AdjustScaleDimensions(oldPos *card.Position, oldWindow, windowSize card.Vec) (card.Vec, card.Vec, card.Vec) {
	return oldPos.Rescale(oldWindow, windowSize)
}

// Adjusts the positioning of an individual array of images
func AdjustImgArray(imgs []*staticimg.StaticImg, oldWindow, windowSize card.Vec, eng sprite.Engine) {
	for _, s := range imgs {
		oldDimensions := s.GetDimensions()
		oldXY := s.GetCurrent()
		oldInitial := s.GetInitial()
		oldPos := card.MakePosition(oldInitial, oldXY, oldDimensions)
		newXY, newInitialXY, newDimensions := AdjustScaleDimensions(oldPos, oldWindow, windowSize)
		s.Move(newXY, newDimensions, eng)
		s.SetInitialPos(newInitialXY)
	}
}

// Scales a float32 to a new window
func ScaleVar(curVar float32, oldWindow, newWindow card.Vec) float32 {
	return curVar*newWindow.X/oldWindow.X
}

// Scales a Vec to a new window
func ScaleVec(curVec, oldWindow, newWindow card.Vec) card.Vec {
	x := curVec.X*newWindow.X/oldWindow.X
	y := curVec.Y*newWindow.Y/oldWindow.Y
	newVec := card.MakeVec(x, y)
	return newVec
}
