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
func AdjustImgs(oldWindowWidth,
	oldWindowHeight float32,
	cards []*card.Card,
	dropTargets,
	backgroundImgs,
	buttons,
	emptySuitImgs []*staticimg.StaticImg,
	windowSize []float32,
	eng sprite.Engine) {
	for _, c := range cards {
		oldCardWidth := c.GetWidth()
		oldCardHeight := c.GetHeight()
		oldX := c.GetX()
		oldInitialX := c.GetInitialX()
		oldY := c.GetY()
		oldInitialY := c.GetInitialY()
		oldPos := card.MakePosition(oldInitialX, oldInitialY, oldX, oldY, oldCardWidth, oldCardHeight)
		newX, newY, newInitialX, newInitialY, newCardWidth, newCardHeight := AdjustScaleDimensions(oldPos, oldWindowWidth, oldWindowHeight, windowSize)
		c.Move(newX, newY, newCardWidth, newCardHeight, eng)
		c.SetInitialPos(newInitialX, newInitialY)
	}
	AdjustImgArray(dropTargets, oldWindowWidth, oldWindowHeight, windowSize, eng)
	AdjustImgArray(backgroundImgs, oldWindowWidth, oldWindowHeight, windowSize, eng)
	AdjustImgArray(buttons, oldWindowWidth, oldWindowHeight, windowSize, eng)
	AdjustImgArray(emptySuitImgs, oldWindowWidth, oldWindowHeight, windowSize, eng)
}

// Returns coordinates for images with same width and height but in new positions proportional to the screen
func AdjustKeepDimensions(oldPos *card.Position, oldWindowWidth, oldWindowHeight float32, windowSize []float32) (float32, float32, float32, float32, float32, float32) {
	oldX := oldPos.GetCurrent().X
	oldY := oldPos.GetCurrent().Y
	oldInitialX := oldPos.GetInitial().X
	oldInitialY := oldPos.GetInitial().Y
	oldImgWidth := oldPos.GetDimensions().X
	oldImgHeight := oldPos.GetDimensions().Y
	newX := (oldX+oldImgWidth/2)/oldWindowWidth*windowSize[0] - oldImgWidth/2
	newY := (oldY+oldImgHeight/2)/oldWindowHeight*windowSize[1] - oldImgHeight/2
	newInitialX := (oldInitialX+oldImgWidth/2)/oldWindowWidth*windowSize[0] - oldImgWidth/2
	newInitialY := (oldInitialY+oldImgHeight/2)/oldWindowHeight*windowSize[1] - oldImgHeight/2
	return newX, newY, newInitialX, newInitialY, oldImgWidth, oldImgHeight
}

// Returns coordinates for images with position, width and height scaled proportional to the screen
func AdjustScaleDimensions(oldPos *card.Position, oldWindowWidth, oldWindowHeight float32, windowSize []float32) (float32, float32, float32, float32, float32, float32) {
	oldX := oldPos.GetCurrent().X
	oldY := oldPos.GetCurrent().Y
	oldInitialX := oldPos.GetInitial().X
	oldInitialY := oldPos.GetInitial().Y
	oldImgWidth := oldPos.GetDimensions().X
	oldImgHeight := oldPos.GetDimensions().Y
	newImgWidth := oldImgWidth / oldWindowWidth * windowSize[0]
	newImgHeight := oldImgHeight / oldWindowHeight * windowSize[1]
	newX := oldX / oldWindowWidth * windowSize[0]
	newY := oldY / oldWindowHeight * windowSize[1]
	newInitialX := oldInitialX / oldWindowWidth * windowSize[0]
	newInitialY := oldInitialY / oldWindowHeight * windowSize[1]
	return newX, newY, newInitialX, newInitialY, newImgWidth, newImgHeight
}

// Adjusts the positioning of an individual array of images
func AdjustImgArray(imgs []*staticimg.StaticImg, oldWindowWidth, oldWindowHeight float32, windowSize []float32, eng sprite.Engine) {
	for _, s := range imgs {
		oldImgWidth := s.GetWidth()
		oldImgHeight := s.GetHeight()
		oldX := s.GetX()
		oldY := s.GetY()
		oldInitialX := s.GetInitialX()
		oldInitialY := s.GetInitialY()
		oldPos := card.MakePosition(oldInitialX, oldInitialY, oldX, oldY, oldImgWidth, oldImgHeight)
		newX, newY, newInitialX, newInitialY, newImgWidth, newImgHeight := AdjustScaleDimensions(oldPos, oldWindowWidth, oldWindowHeight, windowSize)
		s.Move(newX, newY, newImgWidth, newImgHeight, eng)
		s.SetInitialPos(newInitialX, newInitialY)
	}
}
