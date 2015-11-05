// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// direction is a struct used for anything which involves sending something to a variable edge of the screen (passing cards and taking tricks)

package direction

type Direction int

const (
	Right Direction = iota
	Left
	Across
	None
	Down
)
