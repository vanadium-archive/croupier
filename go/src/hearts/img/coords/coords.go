// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// coords contains the Vec and Position structs

package coords

// Vec is comprised of an X and Y coordinate pair
// Vec is primarily used to indicate a 2-dimensional location
// Vec can also be used to group two related variables, eg. the width and height of an object
type Vec struct {
	X float32
	Y float32
}

// Returns a new vec
func MakeVec(x, y float32) *Vec {
	return &Vec{
		X: x,
		Y: y,
	}
}

// Sets the X and Y values of the Vec v
func (v *Vec) SetVec(x, y float32) {
	v.X = x
	v.Y = y
}

// Rescales Vec v relative to the window size
func (v *Vec) Rescale(oldWindow, newWindow *Vec) *Vec {
	newXY := v.DividedByVec(oldWindow).TimesVec(newWindow)
	return newXY
}

// The following functions define basic Vec math, on both float32 constants and other Vecs
func (v *Vec) PlusVec(v2 *Vec) *Vec {
	x := v.X + v2.X
	y := v.Y + v2.Y
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) MinusVec(v2 *Vec) *Vec {
	x := v.X - v2.X
	y := v.Y - v2.Y
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) TimesVec(v2 *Vec) *Vec {
	x := v.X * v2.X
	y := v.Y * v2.Y
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) DividedByVec(v2 *Vec) *Vec {
	x := v.X
	y := v.Y
	if v2.X != 0 {
		x = v.X / v2.X
	}
	if v2.Y != 0 {
		y = v.Y / v2.Y
	}
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) Plus(f float32) *Vec {
	x := v.X + f
	y := v.Y + f
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) Minus(f float32) *Vec {
	x := v.X - f
	y := v.Y - f
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) Times(f float32) *Vec {
	x := v.X * f
	y := v.Y * f
	newVec := MakeVec(x, y)
	return newVec
}

func (v *Vec) DividedBy(f float32) *Vec {
	x := v.X
	y := v.Y
	if f != 0 {
		x = v.X / f
	}
	if f != 0 {
		y = v.Y / f
	}
	newVec := MakeVec(x, y)
	return newVec
}

// Position is a tuple storing visual information about an image's on-screen location
// initial contains the XY coordinates of the initial placement of the image
// current contains the current XY coordinates of the image
// dimensions contains the current width and height of the image
// NOTE: This will be renamed in a future CL
type Position struct {
	initial    *Vec
	current    *Vec
	dimensions *Vec
}

// Returns a new position
func MakePosition(i, c, d *Vec) *Position {
	return &Position{
		initial:    i,
		current:    c,
		dimensions: d,
	}
}

// Returns the initial Vec of p
func (p *Position) GetInitial() *Vec {
	return p.initial
}

// Returns the current Vec of p
func (p *Position) GetCurrent() *Vec {
	return p.current
}

// Returns the dimensions Vec of p
func (p *Position) GetDimensions() *Vec {
	return p.dimensions
}

// Updates the initial Vec of p
func (p *Position) SetInitial(v *Vec) {
	p.initial = v
}

// Updates the current Vec of p
func (p *Position) SetCurrent(v *Vec) {
	p.current = v
}

// Updates the dimensions Vec of p
func (p *Position) SetDimensions(v *Vec) {
	p.dimensions = v
}

// Rescales Position p relative to the window size
func (p *Position) Rescale(oldWindow, newWindow *Vec) (*Vec, *Vec, *Vec) {
	i := p.initial.Rescale(oldWindow, newWindow)
	c := p.current.Rescale(oldWindow, newWindow)
	d := p.dimensions.Rescale(oldWindow, newWindow)
	return i, c, d
}
