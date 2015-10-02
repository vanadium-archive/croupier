// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package texture

import (
	"image"
	_ "image/jpeg"
	_ "image/png"
	"log"
	"strconv"

	"hearts/img/staticimg"
	"hearts/logic/card"

	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/exp/sprite"
)

// Given a card object, populates it with its image
func PopulateCardImage(c *card.Card, texs map[string]sprite.SubTex, eng sprite.Engine, scene *sprite.Node) {
	var texKey string
	switch c.GetSuit() {
	case card.Club:
		texKey = "Clubs-"
	case card.Diamond:
		texKey = "Diamonds-"
	case card.Spade:
		texKey = "Spades-"
	case card.Heart:
		texKey = "Hearts-"
	}
	switch c.GetFace() {
	case card.Jack:
		texKey += "Jack"
	case card.Queen:
		texKey += "Queen"
	case card.King:
		texKey += "King"
	case card.Ace:
		texKey += "Ace"
	default:
		texKey += strconv.Itoa(int(c.GetFace()))
	}
	texKey += ".png"
	n := MakeNode(eng, scene)
	eng.SetSubTex(n, texs[texKey])
	c.SetNode(n)
	c.SetImage(texs[texKey])
	c.SetBack(texs["BakuSquare.png"])
}

// Returns a new StaticImg instance with desired image and dimensions
func MakeImgWithoutAlt(t sprite.SubTex, pos *card.Position, eng sprite.Engine, scene *sprite.Node) *staticimg.StaticImg {
	currentVec := pos.GetCurrent()
	initialVec := pos.GetInitial()
	dimVec := pos.GetDimensions()
	n := MakeNode(eng, scene)
	eng.SetSubTex(n, t)
	s := staticimg.MakeStaticImg()
	s.SetNode(n)
	s.SetImage(t)
	s.Move(currentVec, dimVec, eng)
	s.SetInitialPos(initialVec)
	return s
}

// Returns a new StaticImg instance with desired image and dimensions
// Also includes an alternate image. If displayImage is true, image will be displayed. Else, alt will be displayed.
func MakeImgWithAlt(t sprite.SubTex, alt sprite.SubTex, pos *card.Position, displayImage bool, eng sprite.Engine, scene *sprite.Node) *staticimg.StaticImg {
	s := MakeImgWithoutAlt(t, pos, eng, scene)
	s.SetAlt(alt)
	if !displayImage {
		eng.SetSubTex(s.GetNode(), alt)
	}
	return s
}

// Loads all images for the app
func LoadTextures(eng sprite.Engine) map[string]sprite.SubTex {
	allTexs := make(map[string]sprite.SubTex)
	files := []string{"Clubs-2.png", "Clubs-3.png", "Clubs-4.png", "Clubs-5.png", "Clubs-6.png", "Clubs-7.png", "Clubs-8.png",
		"Clubs-9.png", "Clubs-10.png", "Clubs-Jack.png", "Clubs-Queen.png", "Clubs-King.png", "Clubs-Ace.png",
		"Diamonds-2.png", "Diamonds-3.png", "Diamonds-4.png", "Diamonds-5.png", "Diamonds-6.png", "Diamonds-7.png", "Diamonds-8.png",
		"Diamonds-9.png", "Diamonds-10.png", "Diamonds-Jack.png", "Diamonds-Queen.png", "Diamonds-King.png", "Diamonds-Ace.png",
		"Spades-2.png", "Spades-3.png", "Spades-4.png", "Spades-5.png", "Spades-6.png", "Spades-7.png", "Spades-8.png",
		"Spades-9.png", "Spades-10.png", "Spades-Jack.png", "Spades-Queen.png", "Spades-King.png", "Spades-Ace.png",
		"Hearts-2.png", "Hearts-3.png", "Hearts-4.png", "Hearts-5.png", "Hearts-6.png", "Hearts-7.png", "Hearts-8.png",
		"Hearts-9.png", "Hearts-10.png", "Hearts-Jack.png", "Hearts-Queen.png", "Hearts-King.png", "Hearts-Ace.png",
		"Club.png", "Diamond.png", "Spade.png", "Heart.png", "gray.jpeg", "blue.png", "white.png", "passPressed.png",
		"passUnpressed.png", "leftArrow.png", "rightArrow.png", "acrossArrow.png", "croupierName.png", "BakuSquare.png",
		"trickDrop.png", "player0.jpeg", "player1.jpeg", "player2.jpeg", "player3.jpeg", "laptopIcon.png", "watchIcon.png",
		"phoneIcon.png", "tabletIcon.png"}
	for _, f := range files {
		a, err := asset.Open(f)
		if err != nil {
			log.Fatal(err)
		}
		defer a.Close()

		img, _, err := image.Decode(a)
		if err != nil {
			log.Fatal(err)
		}
		t, err := eng.LoadTexture(img)
		if err != nil {
			log.Fatal(err)
		}
		imgWidth, imgHeight := t.Bounds()
		if f == "Club.png" || f == "Diamond.png" || f == "Spade.png" || f == "Heart.png" || f == "rightArrow.png" ||
			f == "leftArrow.png" || f == "acrossArrow.png" || f == "passUnpressed.png" || f == "passPressed.png" ||
			f == "croupierName.png" {
			allTexs[f] = sprite.SubTex{t, image.Rect(1, 1, imgWidth-1, imgHeight-1)}
		} else {
			allTexs[f] = sprite.SubTex{t, image.Rect(0, 0, imgWidth, imgHeight)}
		}

	}
	return allTexs
}

// Returns a new sprite node
// NOTE: Currently, this is a public method, as it is useful in testing. Eventually it should be made private.
func MakeNode(eng sprite.Engine, scene *sprite.Node) *sprite.Node {
	n := &sprite.Node{}
	eng.Register(n)
	scene.AppendChild(n)
	return n
}
