// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// texture handles creation of new images, as well as adding the UI element to card objects

package texture

import (
	"image"
	_ "image/jpeg"
	_ "image/png"
	"log"
	"strconv"
	"strings"

	"hearts/img/coords"
	"hearts/img/staticimg"
	"hearts/img/uistate"
	"hearts/logic/card"

	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/exp/sprite"
)

// Given a card object, populates it with its image
func PopulateCardImage(c *card.Card, u *uistate.UIState) {
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
	n := MakeNode(u)
	u.Eng.SetSubTex(n, u.Texs[texKey])
	c.SetNode(n)
	c.SetImage(u.Texs[texKey])
	c.SetBack(u.Texs["BakuSquare.png"])
}

// Returns array of textures which make up a string
func getStringImgs(input, color string, texs map[string]sprite.SubTex) []sprite.SubTex {
	imgs := make([]sprite.SubTex, 0)
	for _, char := range input {
		key := ""
		if char == 32 {
			key += "Space"
		} else if char == 33 {
			key += "Bang"
		} else if char == 39 {
			key += "Apostrophe"
		} else if char == 46 {
			key += "Period"
		} else if char == 58 {
			key += "Colon"
		} else if char >= 48 && char <= 57 {
			// if char is a number
			key += string(char)
		} else {
			// if char is a letter
			key += strings.ToUpper(string(char))
			if char > 90 {
				key += "-Lower"
			} else {
				key += "-Upper"
			}
		}
		if color != "" {
			key += "-" + color
		}
		key += ".png"
		img := texs[key]
		imgs = append(imgs, img)
	}
	return imgs
}

func MakeStringImgLeftAlign(input, color, altColor string,
	displayColor bool,
	start *coords.Vec,
	scaler, maxWidth float32,
	u *uistate.UIState) []*staticimg.StaticImg {
	textures := getStringImgs(input, color, u.Texs)
	var altTexs []sprite.SubTex
	if color != altColor {
		altTexs = getStringImgs(input, altColor, u.Texs)
	}
	// adjust scaler if string is too long
	totalWidth := float32(0)
	for _, img := range textures {
		totalWidth += float32(img.R.Max.X) / scaler
	}
	if totalWidth > maxWidth {
		scaler = totalWidth * scaler / maxWidth
	}
	allImgs := make([]*staticimg.StaticImg, 0)
	for i, img := range textures {
		subTexDims := coords.MakeVec(float32(img.R.Max.X), float32(img.R.Max.Y))
		dims := subTexDims.DividedBy(scaler)
		var textImg *staticimg.StaticImg
		if len(altTexs) == 0 {
			textImg = MakeImgWithoutAlt(img, start, dims, u)
		} else {
			textImg = MakeImgWithAlt(img, altTexs[i], start, dims, displayColor, u)
		}
		allImgs = append(allImgs, textImg)
		start = coords.MakeVec(start.X+dims.X, start.Y)
	}
	return allImgs
}

func MakeStringImgRightAlign(input, color, altColor string,
	displayColor bool,
	end *coords.Vec,
	scaler, maxWidth float32,
	u *uistate.UIState) []*staticimg.StaticImg {
	textures := getStringImgs(input, color, u.Texs)
	var altTexs []sprite.SubTex
	if color != altColor {
		altTexs = getStringImgs(input, altColor, u.Texs)
	}
	// adjust scaler if string is too long
	totalWidth := float32(0)
	for _, img := range textures {
		totalWidth += float32(img.R.Max.X) / scaler
	}
	if totalWidth > maxWidth {
		scaler = totalWidth * scaler / maxWidth
	}
	// reverse textures
	for i, j := 0, len(textures)-1; i < j; i, j = i+1, j-1 {
		textures[i], textures[j] = textures[j], textures[i]
	}
	allImgs := make([]*staticimg.StaticImg, 0)
	for i, img := range textures {
		subTexDims := coords.MakeVec(float32(img.R.Max.X), float32(img.R.Max.Y))
		dims := subTexDims.DividedBy(scaler)
		end = coords.MakeVec(end.X-dims.X, end.Y)
		var textImg *staticimg.StaticImg
		if len(altTexs) == 0 {
			textImg = MakeImgWithoutAlt(img, end, dims, u)
		} else {
			textImg = MakeImgWithAlt(img, altTexs[i], end, dims, displayColor, u)
		}
		allImgs = append(allImgs, textImg)
	}
	return allImgs
}

func MakeStringImgCenterAlign(input, color, altColor string,
	displayColor bool,
	center *coords.Vec,
	scaler, maxWidth float32,
	u *uistate.UIState) []*staticimg.StaticImg {
	textures := getStringImgs(input, color, u.Texs)
	totalWidth := float32(0)
	newScaler := scaler
	for _, img := range textures {
		totalWidth += float32(img.R.Max.X) / scaler
	}
	if totalWidth > maxWidth {
		newScaler = totalWidth * scaler / maxWidth
		totalWidth = maxWidth
	}
	startX := center.X - totalWidth/2
	startY := center.Y
	if len(textures) > 0 {
		startY = center.Y + (float32(textures[0].R.Max.Y)/scaler-float32(textures[0].R.Max.Y)/newScaler)/2
	}
	start := coords.MakeVec(startX, startY)
	return MakeStringImgLeftAlign(input, color, altColor, displayColor, start, newScaler, maxWidth, u)
}

// Returns a new StaticImg instance with desired image and dimensions
func MakeImgWithoutAlt(t sprite.SubTex, current, dim *coords.Vec, u *uistate.UIState) *staticimg.StaticImg {
	n := MakeNode(u)
	u.Eng.SetSubTex(n, t)
	s := staticimg.MakeStaticImg()
	s.SetNode(n)
	s.SetImage(t)
	s.SetInitial(current)
	s.Move(current, dim, u.Eng)
	return s
}

// Returns a new StaticImg instance with desired image and dimensions
// Also includes an alternate image. If displayImage is true, image will be displayed. Else, alt will be displayed.
func MakeImgWithAlt(t, alt sprite.SubTex, current, dim *coords.Vec, displayImage bool, u *uistate.UIState) *staticimg.StaticImg {
	s := MakeImgWithoutAlt(t, current, dim, u)
	s.SetAlt(alt)
	if !displayImage {
		u.Eng.SetSubTex(s.GetNode(), alt)
		s.SetDisplayingImage(false)
	} else {
		s.SetDisplayingImage(true)
	}
	return s
}

func RemoveImg(s *staticimg.StaticImg, u *uistate.UIState) {
	u.Eng.Unregister(s.GetNode())
}

// Loads all images for the app
func LoadTextures(eng sprite.Engine) map[string]sprite.SubTex {
	allTexs := make(map[string]sprite.SubTex)
	boundedImgs := []string{"Clubs-2.png", "Clubs-3.png", "Clubs-4.png", "Clubs-5.png", "Clubs-6.png", "Clubs-7.png", "Clubs-8.png",
		"Clubs-9.png", "Clubs-10.png", "Clubs-Jack.png", "Clubs-Queen.png", "Clubs-King.png", "Clubs-Ace.png",
		"Diamonds-2.png", "Diamonds-3.png", "Diamonds-4.png", "Diamonds-5.png", "Diamonds-6.png", "Diamonds-7.png", "Diamonds-8.png",
		"Diamonds-9.png", "Diamonds-10.png", "Diamonds-Jack.png", "Diamonds-Queen.png", "Diamonds-King.png", "Diamonds-Ace.png",
		"Spades-2.png", "Spades-3.png", "Spades-4.png", "Spades-5.png", "Spades-6.png", "Spades-7.png", "Spades-8.png",
		"Spades-9.png", "Spades-10.png", "Spades-Jack.png", "Spades-Queen.png", "Spades-King.png", "Spades-Ace.png",
		"Hearts-2.png", "Hearts-3.png", "Hearts-4.png", "Hearts-5.png", "Hearts-6.png", "Hearts-7.png", "Hearts-8.png",
		"Hearts-9.png", "Hearts-10.png", "Hearts-Jack.png", "Hearts-Queen.png", "Hearts-King.png", "Hearts-Ace.png", "BakuSquare.png",
	}
	unboundedImgs := []string{"Club.png", "Diamond.png", "Spade.png", "Heart.png", "gray.jpeg", "blue.png", "trickDrop.png",
		"trickDropBlue.png", "player0.jpeg", "player1.jpeg", "player2.jpeg", "player3.jpeg", "laptopIcon.png", "watchIcon.png",
		"phoneIcon.png", "tabletIcon.png", "A-Upper.png", "B-Upper.png", "C-Upper.png", "D-Upper.png", "E-Upper.png", "F-Upper.png",
		"G-Upper.png", "H-Upper.png", "I-Upper.png", "J-Upper.png", "K-Upper.png", "L-Upper.png", "M-Upper.png", "N-Upper.png",
		"O-Upper.png", "P-Upper.png", "Q-Upper.png", "R-Upper.png", "S-Upper.png", "T-Upper.png", "U-Upper.png", "V-Upper.png",
		"W-Upper.png", "X-Upper.png", "Y-Upper.png", "Z-Upper.png", "A-Lower.png", "B-Lower.png", "C-Lower.png", "D-Lower.png",
		"E-Lower.png", "F-Lower.png", "G-Lower.png", "H-Lower.png", "I-Lower.png", "J-Lower.png", "K-Lower.png", "L-Lower.png",
		"M-Lower.png", "N-Lower.png", "O-Lower.png", "P-Lower.png", "Q-Lower.png", "R-Lower.png", "S-Lower.png", "T-Lower.png",
		"U-Lower.png", "V-Lower.png", "W-Lower.png", "X-Lower.png", "Y-Lower.png", "Z-Lower.png", "Space.png", "Colon.png", "Bang.png",
		"1.png", "2.png", "3.png", "4.png", "5.png", "6.png", "7.png", "8.png", "9.png", "0.png", "1-Red.png", "2-Red.png", "3-Red.png",
		"4-Red.png", "5-Red.png", "6-Red.png", "7-Red.png", "8-Red.png", "9-Red.png", "0-Red.png", "1-DBlue.png", "2-DBlue.png",
		"3-DBlue.png", "4-DBlue.png", "5-DBlue.png", "6-DBlue.png", "7-DBlue.png", "8-DBlue.png", "9-DBlue.png", "0-DBlue.png",
		"A-Upper-DBlue.png", "B-Upper-DBlue.png",
		"C-Upper-DBlue.png", "D-Upper-DBlue.png", "E-Upper-DBlue.png", "F-Upper-DBlue.png", "G-Upper-DBlue.png", "H-Upper-DBlue.png",
		"I-Upper-DBlue.png", "J-Upper-DBlue.png", "K-Upper-DBlue.png", "L-Upper-DBlue.png", "M-Upper-DBlue.png", "N-Upper-DBlue.png",
		"O-Upper-DBlue.png", "P-Upper-DBlue.png", "Q-Upper-DBlue.png", "R-Upper-DBlue.png", "S-Upper-DBlue.png", "T-Upper-DBlue.png",
		"U-Upper-DBlue.png", "V-Upper-DBlue.png", "W-Upper-DBlue.png", "X-Upper-DBlue.png", "Y-Upper-DBlue.png", "Z-Upper-DBlue.png",
		"A-Lower-DBlue.png", "B-Lower-DBlue.png", "C-Lower-DBlue.png", "D-Lower-DBlue.png", "E-Lower-DBlue.png", "F-Lower-DBlue.png",
		"G-Lower-DBlue.png", "H-Lower-DBlue.png", "I-Lower-DBlue.png", "J-Lower-DBlue.png", "K-Lower-DBlue.png", "L-Lower-DBlue.png",
		"M-Lower-DBlue.png", "N-Lower-DBlue.png", "O-Lower-DBlue.png", "P-Lower-DBlue.png", "Q-Lower-DBlue.png", "R-Lower-DBlue.png",
		"S-Lower-DBlue.png", "T-Lower-DBlue.png", "U-Lower-DBlue.png", "V-Lower-DBlue.png", "W-Lower-DBlue.png", "X-Lower-DBlue.png",
		"Y-Lower-DBlue.png", "Z-Lower-DBlue.png", "Apostrophe-DBlue.png", "Space-DBlue.png", "A-Upper-LBlue.png", "B-Upper-LBlue.png",
		"C-Upper-LBlue.png", "D-Upper-LBlue.png", "E-Upper-LBlue.png", "F-Upper-LBlue.png", "G-Upper-LBlue.png", "H-Upper-LBlue.png",
		"I-Upper-LBlue.png", "J-Upper-LBlue.png", "K-Upper-LBlue.png", "L-Upper-LBlue.png", "M-Upper-LBlue.png", "N-Upper-LBlue.png",
		"O-Upper-LBlue.png", "P-Upper-LBlue.png", "Q-Upper-LBlue.png", "R-Upper-LBlue.png", "S-Upper-LBlue.png", "T-Upper-LBlue.png",
		"U-Upper-LBlue.png", "V-Upper-LBlue.png", "W-Upper-LBlue.png", "X-Upper-LBlue.png", "Y-Upper-LBlue.png", "Z-Upper-LBlue.png",
		"A-Lower-LBlue.png", "B-Lower-LBlue.png", "C-Lower-LBlue.png", "D-Lower-LBlue.png", "E-Lower-LBlue.png", "F-Lower-LBlue.png",
		"G-Lower-LBlue.png", "H-Lower-LBlue.png", "I-Lower-LBlue.png", "J-Lower-LBlue.png", "K-Lower-LBlue.png", "L-Lower-LBlue.png",
		"M-Lower-LBlue.png", "N-Lower-LBlue.png", "O-Lower-LBlue.png", "P-Lower-LBlue.png", "Q-Lower-LBlue.png", "R-Lower-LBlue.png",
		"S-Lower-LBlue.png", "T-Lower-LBlue.png", "U-Lower-LBlue.png", "V-Lower-LBlue.png", "W-Lower-LBlue.png", "X-Lower-LBlue.png",
		"Y-Lower-LBlue.png", "Z-Lower-LBlue.png", "A-Upper-Gray.png", "B-Upper-Gray.png", "C-Upper-Gray.png", "D-Upper-Gray.png",
		"E-Upper-Gray.png", "F-Upper-Gray.png", "G-Upper-Gray.png", "H-Upper-Gray.png", "I-Upper-Gray.png", "J-Upper-Gray.png",
		"K-Upper-Gray.png", "L-Upper-Gray.png", "M-Upper-Gray.png", "N-Upper-Gray.png", "O-Upper-Gray.png", "P-Upper-Gray.png",
		"Q-Upper-Gray.png", "R-Upper-Gray.png", "S-Upper-Gray.png", "T-Upper-Gray.png", "U-Upper-Gray.png", "V-Upper-Gray.png",
		"W-Upper-Gray.png", "X-Upper-Gray.png", "Y-Upper-Gray.png", "Z-Upper-Gray.png", "A-Lower-Gray.png", "B-Lower-Gray.png",
		"C-Lower-Gray.png", "D-Lower-Gray.png", "E-Lower-Gray.png", "F-Lower-Gray.png", "G-Lower-Gray.png", "H-Lower-Gray.png",
		"I-Lower-Gray.png", "J-Lower-Gray.png", "K-Lower-Gray.png", "L-Lower-Gray.png", "M-Lower-Gray.png", "N-Lower-Gray.png",
		"O-Lower-Gray.png", "P-Lower-Gray.png", "Q-Lower-Gray.png", "R-Lower-Gray.png", "S-Lower-Gray.png", "T-Lower-Gray.png",
		"U-Lower-Gray.png", "V-Lower-Gray.png", "W-Lower-Gray.png", "X-Lower-Gray.png", "Y-Lower-Gray.png", "Z-Lower-Gray.png",
		"Space-Gray.png", "RoundedRectangle-DBlue.png", "RoundedRectangle-LBlue.png", "RoundedRectangle-Gray.png", "Rectangle-LBlue.png",
		"Rectangle-DBlue.png", "HorizontalPullTab.png", "VerticalPullTab.png", "NewGame.png", "NewRound.png", "JoinGame.png", "Period.png",
		"SitSpot.png", "WatchSpot.png", "StartBlue.png", "StartGray.png", "Restart.png", "Visibility.png", "VisibilityOff.png",
	}
	for _, f := range boundedImgs {
		a, err := asset.Open(f)
		if err != nil {
			log.Fatal(err)
		}

		img, _, err := image.Decode(a)
		if err != nil {
			log.Fatal(err)
		}
		t, err := eng.LoadTexture(img)
		if err != nil {
			log.Fatal(err)
		}
		imgWidth, imgHeight := t.Bounds()
		allTexs[f] = sprite.SubTex{t, image.Rect(0, 0, imgWidth, imgHeight)}
		a.Close()
	}
	for _, f := range unboundedImgs {
		a, err := asset.Open(f)
		if err != nil {
			log.Fatal(err)
		}

		img, _, err := image.Decode(a)
		if err != nil {
			log.Fatal(err)
		}
		t, err := eng.LoadTexture(img)
		if err != nil {
			log.Fatal(err)
		}
		imgWidth, imgHeight := t.Bounds()
		allTexs[f] = sprite.SubTex{t, image.Rect(1, 1, imgWidth-1, imgHeight-1)}
		a.Close()
	}
	return allTexs
}

// Returns a new sprite node
// NOTE: Currently, this is a public method, as it is useful in testing. Eventually it should be made private.
func MakeNode(u *uistate.UIState) *sprite.Node {
	n := &sprite.Node{}
	u.Eng.Register(n)
	u.Scene.AppendChild(n)
	return n
}
