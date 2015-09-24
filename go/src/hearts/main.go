// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"image"
	"log"
	"sort"
	"strconv"
	"time"

	_ "image/jpeg"
	_ "image/png"

	"hearts/img"
	"hearts/logic/card"
	"hearts/logic/player"
	"hearts/logic/table"

	"golang.org/x/mobile/app"
	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/event/paint"
	"golang.org/x/mobile/event/size"
	"golang.org/x/mobile/event/touch"
	"golang.org/x/mobile/exp/f32"
	"golang.org/x/mobile/exp/sprite"
	"golang.org/x/mobile/exp/sprite/clock"
	"golang.org/x/mobile/exp/sprite/glsprite"
	"golang.org/x/mobile/gl"
)

var (
	startTime      = time.Now()
	eng            = glsprite.Engine()
	scene          *sprite.Node
	cards          []*card.Card
	backgroundImgs []*img.StaticImg
	emptySuitImgs  []*img.StaticImg
	dropTargets    []*img.StaticImg
	buttons        []*img.StaticImg
	curCard        *card.Card
	numPlayers     = 4
	// lastMouseXY is in Px: divide by ppp to get Pt
	lastMouseXY = []float32{-1, -1}
	cardSize    = 35
	cardWidth   = float32(cardSize)
	cardHeight  = float32(cardSize)
	// windowSize is in Pt
	windowSize    = []float32{-1, -1}
	padding       = float32(5)
	topPadding    = float32(7)
	bottomPadding = float32(5)
	// ppp stands for pixels per pt
	ppp float32
	// to-do: test and fine-tune these thresholds
	swipeMoveThreshold = 70
	swipeTimeThreshold = .5
	swipeStart         time.Time
	animSpeedScaler    = .1
	animRotationScaler = .15
	d                  Direction
)

type Direction string

const (
	right  Direction = "R"
	across Direction = "A"
	left   Direction = "L"
)

func main() {
	app.Main(func(a app.App) {
		var sz size.Event
		d = right
		for e := range a.Events() {
			switch e := app.Filter(e).(type) {
			case size.Event:
				sz = e
				oldWidth := windowSize[0]
				oldHeight := windowSize[1]
				windowSize[0] = float32(sz.WidthPt)
				windowSize[1] = float32(sz.HeightPt)
				pixelsX := float32(sz.WidthPx)
				ppp = pixelsX / windowSize[0]
				adjustImgs(oldWidth, oldHeight)
			case touch.Event:
				onTouch(e, d)
			case paint.Event:
				onPaint(sz, d)
				a.EndPaint(e)
			}
		}
	})
}

func onTouch(t touch.Event, dir Direction) {
	switch t.Type.String() {
	case "begin":
		// i goes from the end backwards so that it checks cards displayed on top of other cards first
		for i := len(cards) - 1; i >= 0; i-- {
			curCard = cards[i]
			if t.X/ppp >= curCard.GetX() &&
				t.Y/ppp >= curCard.GetY() &&
				t.X/ppp <= curCard.GetWidth()+curCard.GetX() &&
				t.Y/ppp <= curCard.GetHeight()+curCard.GetY() {
				swipeStart = time.Now()
				node := curCard.GetNode()
				node.Arranger = nil
				lastMouseXY[0] = t.X
				lastMouseXY[1] = t.Y
				return
			} else {
				curCard = nil
			}
		}
		for _, b := range buttons {
			if t.X/ppp >= b.GetX() &&
				t.Y/ppp >= b.GetY() &&
				t.X/ppp <= b.GetWidth()+b.GetX() &&
				t.Y/ppp <= b.GetHeight()+b.GetY() {
				eng.SetSubTex(b.GetNode(), b.GetAlt())
				for _, d := range dropTargets {
					passCard := d.GetCardHere()
					if passCard != nil {
						animate(passCard, dir, t)
						d.SetCardHere(nil)
					}
				}
			}
		}
	case "move":
		if curCard != nil {
			newX := curCard.GetX() + (t.X-lastMouseXY[0])/ppp
			newY := curCard.GetY() + (t.Y-lastMouseXY[1])/ppp
			width := curCard.GetWidth()
			height := curCard.GetHeight()
			eng.SetTransform(curCard.GetNode(), f32.Affine{
				{width, 0, newX},
				{0, height, newY},
			})
			curCard.SetPos(newX, newY, width, height)
			lastMouseXY[0] = t.X
			lastMouseXY[1] = t.Y
		}
	case "end":
		if curCard != nil {
			successfulDrop := false
			for _, d := range dropTargets {
				// checking to see if card was dropped onto a drop target
				if t.X/ppp >= d.GetX() &&
					t.Y/ppp >= d.GetY() &&
					t.X/ppp <= d.GetWidth()+d.GetX() &&
					t.Y/ppp <= d.GetHeight()+d.GetY() {
					lastDroppedCard := d.GetCardHere()
					if lastDroppedCard != nil {
						resetCardPosition(lastDroppedCard)
					}
					oldY := curCard.GetInitialY()
					suit := curCard.GetSuit()
					newX := d.GetX()
					newY := d.GetY()
					width := curCard.GetWidth()
					height := curCard.GetHeight()
					eng.SetTransform(curCard.GetNode(), f32.Affine{
						{width, 0, newX},
						{0, height, newY},
					})
					curCard.SetPos(newX, newY, width, height)
					d.SetCardHere(curCard)
					successfulDrop = true
					// realign suit the card just left
					realignSuit(suit, oldY)
				} else {
					// checking to see if card was removed from a dop target
					if d.GetCardHere() == curCard {
						d.SetCardHere(nil)
					}
				}
			}
			if !successfulDrop {
				resetCardPosition(curCard)
			}
		}
		for _, b := range buttons {
			eng.SetSubTex(b.GetNode(), b.GetImage())
		}
		curCard = nil
	}
}

func resetCardPosition(c *card.Card) {
	newX := c.GetInitialX()
	newY := c.GetInitialY()
	eng.SetTransform(c.GetNode(), f32.Affine{
		{c.GetWidth(), 0, newX},
		{0, c.GetHeight(), newY},
	})
	c.SetPos(newX, newY, c.GetWidth(), c.GetHeight())
	realignSuit(c.GetSuit(), newY)
}

// returns coordinates for images with same width and height but in new positions proportional to the screen
func adjustKeepDimensions(oldX, oldY, oldInitialX, oldInitialY, oldImgWidth, oldImgHeight, oldWindowWidth, oldWindowHeight float32) (float32, float32, float32, float32, float32, float32) {
	newX := (oldX+oldImgWidth/2)/oldWindowWidth*windowSize[0] - oldImgWidth/2
	newY := (oldY+oldImgHeight/2)/oldWindowHeight*windowSize[1] - oldImgHeight/2
	newInitialX := (oldInitialX+oldImgWidth/2)/oldWindowWidth*windowSize[0] - oldImgWidth/2
	newInitialY := (oldInitialY+oldImgHeight/2)/oldWindowHeight*windowSize[1] - oldImgHeight/2
	return newX, newY, newInitialX, newInitialY, oldImgWidth, oldImgHeight
}

// returns coordinates for images with position, width and height scaled proportional to the screen
func adjustScaleDimensions(oldX, oldY, oldInitialX, oldInitialY, oldImgWidth, oldImgHeight, oldWindowWidth, oldWindowHeight float32) (float32, float32, float32, float32, float32, float32) {
	newImgWidth := oldImgWidth / oldWindowWidth * windowSize[0]
	newImgHeight := oldImgHeight / oldWindowHeight * windowSize[1]
	newX := oldX / oldWindowWidth * windowSize[0]
	newY := oldY / oldWindowHeight * windowSize[1]
	newInitialX := oldInitialX / oldWindowWidth * windowSize[0]
	newInitialY := oldInitialY / oldWindowHeight * windowSize[1]
	return newX, newY, newInitialX, newInitialY, newImgWidth, newImgHeight
}

func adjustImgArray(imgs []*img.StaticImg, oldWindowWidth, oldWindowHeight float32) {
	for _, s := range imgs {
		node := s.GetNode()
		oldImgWidth := s.GetWidth()
		oldImgHeight := s.GetHeight()
		oldX := s.GetX()
		oldY := s.GetY()
		oldInitialX := s.GetInitialX()
		oldInitialY := s.GetInitialY()
		newX, newY, newInitialX, newInitialY, newImgWidth, newImgHeight := adjustScaleDimensions(oldX, oldY,
			oldInitialX, oldInitialY, oldImgWidth, oldImgHeight, oldWindowWidth, oldWindowHeight)
		eng.SetTransform(node, f32.Affine{
			{newImgWidth, 0, newX},
			{0, newImgHeight, newY},
		})
		s.SetPos(newX, newY, newImgWidth, newImgHeight)
		s.SetInitialPos(newInitialX, newInitialY)
	}
}

func adjustImgs(oldWindowWidth, oldWindowHeight float32) {
	if windowSize[0] > -1 && oldWindowWidth > -1 {
		padding = padding * windowSize[0] / oldWindowWidth
	}
	for _, c := range cards {
		node := c.GetNode()
		oldCardWidth := c.GetWidth()
		oldCardHeight := c.GetHeight()
		oldX := c.GetX()
		oldInitialX := c.GetInitialX()
		oldY := c.GetY()
		oldInitialY := c.GetInitialY()
		newX, newY, newInitialX, newInitialY, newCardWidth, newCardHeight := adjustScaleDimensions(oldX, oldY,
			oldInitialX, oldInitialY, oldCardWidth, oldCardHeight, oldWindowWidth, oldWindowHeight)
		eng.SetTransform(node, f32.Affine{
			{newCardWidth, 0, newX},
			{0, newCardHeight, newY},
		})
		c.SetPos(newX, newY, newCardWidth, newCardHeight)
		c.SetInitialPos(newInitialX, newInitialY)
	}
	adjustImgArray(dropTargets, oldWindowWidth, oldWindowHeight)
	adjustImgArray(backgroundImgs, oldWindowWidth, oldWindowHeight)
	adjustImgArray(buttons, oldWindowWidth, oldWindowHeight)
	adjustImgArray(emptySuitImgs, oldWindowWidth, oldWindowHeight)
}

func animate(animCard *card.Card, dir Direction, touch touch.Event) {
	node := animCard.GetNode()
	startTime := -1
	node.Arranger = arrangerFunc(func(eng sprite.Engine, node *sprite.Node, t clock.Time) {
		if startTime == -1 {
			startTime = int(t)
		}
		moveSpeed := float32(int(t)-startTime) * float32(animSpeedScaler)
		x := animCard.GetX()
		y := animCard.GetY()
		width := animCard.GetWidth()
		height := animCard.GetHeight()
		switch dir {
		case right:
			x = x + moveSpeed
		case left:
			x = x - moveSpeed
		case across:
			y = y - moveSpeed
		}
		animCard.SetPos(x, y, width, height)
		position := f32.Affine{
			{width, 0, x + width/2},
			{0, height, y + height/2},
		}
		position.Rotate(&position, float32(t)*float32(animRotationScaler))
		position.Translate(&position, -.5, -.5)
		eng.SetTransform(node, position)
	})
}

func onPaint(sz size.Event, dir Direction) {
	if scene == nil {
		loadPassScreen(dir)
	}
	gl.ClearColor(1, 1, 1, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)
	now := clock.Time(time.Since(startTime) * 60 / time.Second)
	eng.Render(scene, now, sz)
}

func newNode() *sprite.Node {
	n := &sprite.Node{}
	eng.Register(n)
	scene.AppendChild(n)
	return n
}

func initializeGame() *table.Table {
	players := make([]*player.Player, 0)
	for i := 0; i < numPlayers; i++ {
		players = append(players, player.NewPlayer(i))
	}
	return table.NewTable(players)
}

func realignSuit(suitName card.Suit, oldY float32) {
	cardsToAlign := make([]*card.Card, 0)
	for _, c := range cards {
		if c.GetSuit() == suitName && c.GetY() == oldY {
			cardsToAlign = append(cardsToAlign, c)
		}
	}
	var emptySuitImg *img.StaticImg
	switch suitName {
	case card.Club:
		emptySuitImg = emptySuitImgs[0]
	case card.Diamond:
		emptySuitImg = emptySuitImgs[1]
	case card.Spade:
		emptySuitImg = emptySuitImgs[2]
	case card.Heart:
		emptySuitImg = emptySuitImgs[3]
	}
	if len(cardsToAlign) == 0 {
		eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetImage())
	} else {
		eng.SetSubTex(emptySuitImg.GetNode(), emptySuitImg.GetAlt())
	}
	for i, c := range cardsToAlign {
		width := c.GetWidth()
		height := c.GetHeight()
		diff := float32(len(cardsToAlign))*(padding+width) - (windowSize[0] - padding)
		x := padding + float32(i)*(padding+width)
		if diff > 0 && i > 0 {
			x -= diff * float32(i) / float32(len(cardsToAlign)-1)
		}
		y := oldY
		c.SetPos(x, y, width, height)
		c.SetInitialPos(x, y)
		eng.SetTransform(c.GetNode(), f32.Affine{
			{width, 0, x},
			{0, height, y},
		})
	}
}

func addCard(c *card.Card, texs map[string]sprite.SubTex, numInSuit, clubCount, diamondCount, spadeCount, heartCount int) {
	var texKey string
	var suitCount float32
	var heightScaler float32
	switch c.GetSuit() {
	case card.Club:
		texKey = "Clubs-"
		suitCount = float32(clubCount)
		heightScaler = 4
	case card.Diamond:
		texKey = "Diamonds-"
		suitCount = float32(diamondCount)
		heightScaler = 3
	case card.Spade:
		texKey = "Spades-"
		suitCount = float32(spadeCount)
		heightScaler = 2
	case card.Heart:
		texKey = "Hearts-"
		suitCount = float32(heartCount)
		heightScaler = 1
	}
	log.Println(c.GetFace())
	log.Println(card.Two)
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
	log.Println(texKey)
	n := newNode()
	eng.SetSubTex(n, texs[texKey])
	c.SetNode(n)
	diff := suitCount*(padding+cardWidth) - (windowSize[0] - padding)
	x := padding + float32(numInSuit)*(padding+cardWidth)
	if diff > 0 && numInSuit > 0 {
		x -= diff * float32(numInSuit) / (suitCount - 1)
	}
	y := windowSize[1] - heightScaler*(cardHeight+padding) - bottomPadding
	width := cardWidth
	height := cardHeight
	c.SetPos(x, y, width, height)
	c.SetInitialPos(x, y)
	eng.SetTransform(c.GetNode(), f32.Affine{
		{width, 0, x},
		{0, height, y},
	})
}

func addImgWithoutAlt(t sprite.SubTex, x, y, width, height float32) *img.StaticImg {
	n := newNode()
	eng.SetSubTex(n, t)
	eng.SetTransform(n, f32.Affine{
		{width, 0, x},
		{0, height, y},
	})
	s := img.NewStaticImg()
	s.SetNode(n)
	s.SetImage(t)
	s.SetPos(x, y, width, height)
	s.SetInitialPos(x, y)
	return s
}

func addImgWithAlt(t sprite.SubTex, alt sprite.SubTex, x, y, width, height float32, displayImage bool) *img.StaticImg {
	n := newNode()
	if displayImage {
		eng.SetSubTex(n, t)
	}
	eng.SetTransform(n, f32.Affine{
		{width, 0, x},
		{0, height, y},
	})
	s := img.NewStaticImg()
	s.SetNode(n)
	s.SetImage(t)
	s.SetAlt(alt)
	s.SetPos(x, y, width, height)
	s.SetInitialPos(x, y)
	return s
}

func loadPassScreen(dir Direction) {
	texs := loadTextures()
	scene = &sprite.Node{}
	eng.Register(scene)
	eng.SetTransform(scene, f32.Affine{
		{1, 0, 0},
		{0, 1, 0},
	})
	t := initializeGame()
	t.Deal()
	cards = t.GetPlayers()[1].GetHand()
	dropTargets = make([]*img.StaticImg, 0)
	backgroundImgs = make([]*img.StaticImg, 0)
	emptySuitImgs = make([]*img.StaticImg, 0)
	buttons = make([]*img.StaticImg, 0)
	sort.Sort(cardSorter(cards))
	clubCount := 0
	diamondCount := 0
	spadeCount := 0
	heartCount := 0
	for i := 0; i < len(cards); i++ {
		switch cards[i].GetSuit() {
		case card.Club:
			clubCount++
		case card.Diamond:
			diamondCount++
		case card.Spade:
			spadeCount++
		case card.Heart:
			heartCount++
		}
	}
	suitCounts := []int{clubCount, diamondCount, spadeCount, heartCount}
	numSuits := 4
	numDropTargets := 3
	// adding blue banner for croupier header
	image := texs["blue.png"]
	headerX := float32(0)
	headerY := float32(0)
	headerWidth := windowSize[0]
	var headerHeight float32
	if 2*cardHeight < headerWidth/4 {
		headerHeight = 2 * cardHeight
	} else {
		headerHeight = headerWidth / 4
	}
	header := addImgWithoutAlt(image, headerX, headerY, headerWidth, headerHeight)
	backgroundImgs = append(backgroundImgs, header)
	// adding croupier name on top of banner
	image = texs["croupierName.png"]
	var width float32
	var height float32
	if headerHeight-topPadding > headerWidth/6 {
		width = headerWidth / 2
		height = width / 3
	} else {
		height = 2 * headerHeight / 3
		width = height * 3
	}
	x := headerX + (headerWidth-width)/2
	y := headerY + (headerHeight-height+topPadding)/2
	headerText := addImgWithoutAlt(image, x, y, width, height)
	backgroundImgs = append(backgroundImgs, headerText)
	// adding blue background banner for drop targets
	topOfHand := windowSize[1] - 5*(cardHeight+padding) - (2 * padding / 5) - bottomPadding
	image = texs["blue.png"]
	x = float32(0)
	passBannerY := topOfHand - (2 * padding)
	width = windowSize[0]
	height = cardHeight + (4 * padding / 5)
	newImg := addImgWithoutAlt(image, x, passBannerY, width, height)
	backgroundImgs = append(backgroundImgs, newImg)
	// adding drop targets
	for i := 0; i < numDropTargets; i++ {
		image := texs["white.png"]
		width := cardWidth
		height := cardHeight
		x := windowSize[0]/2 - (width+float32(numDropTargets)*(padding+width))/2 + float32(i)*(padding+width)
		y := passBannerY + (2 * padding / 5)
		newTarget := addImgWithoutAlt(image, x, y, width, height)
		dropTargets = append(dropTargets, newTarget)
	}
	// adding pass button
	pressedImg := texs["passPressed.png"]
	unpressedImg := texs["passUnpressed.png"]
	width = cardWidth
	height = cardHeight / 2
	x = windowSize[0]/2 + (float32(numDropTargets)*(padding+width)-width)/2
	passY := passBannerY + (2 * padding / 5)
	newButton := addImgWithAlt(unpressedImg, pressedImg, x, passY, width, height, true)
	buttons = append(buttons, newButton)
	// adding arrow below pass button
	var a *img.StaticImg
	if dir == right {
		image := texs["rightArrow.png"]
		width := cardWidth
		height := cardHeight / 2
		x := windowSize[0]/2 + (float32(numDropTargets)*(padding+cardWidth)-width)/2
		y := passY + cardHeight/2
		a = addImgWithoutAlt(image, x, y, width, height)
	} else if dir == left {
		image := texs["leftArrow.png"]
		width := cardWidth
		height := cardHeight / 2
		x := windowSize[0]/2 + (float32(numDropTargets)*(padding+cardWidth)-width)/2
		y := passY + cardHeight/2
		a = addImgWithoutAlt(image, x, y, width, height)
	} else {
		image := texs["acrossArrow.png"]
		width := cardWidth / 4
		height := cardHeight / 2
		x := windowSize[0]/2 + (float32(numDropTargets)*(padding+cardWidth)-width)/2
		y := passY + cardHeight/2
		a = addImgWithoutAlt(image, x, y, width, height)
	}
	backgroundImgs = append(backgroundImgs, a)
	// adding gray background banners for each suit
	for i := 0; i < numSuits; i++ {
		image := texs["gray.jpeg"]
		x := float32(0)
		y := windowSize[1] - float32(i+1)*(cardHeight+padding) - (2 * padding / 5) - bottomPadding
		width := windowSize[0]
		height := cardHeight + (4 * padding / 5)
		newImg := addImgWithoutAlt(image, x, y, width, height)
		backgroundImgs = append(backgroundImgs, newImg)
	}
	// adding suit image to any empty suit in hand
	for i, c := range suitCounts {
		var texKey string
		switch i {
		case 0:
			texKey = "Club.png"
		case 1:
			texKey = "Diamond.png"
		case 2:
			texKey = "Spade.png"
		case 3:
			texKey = "Heart.png"
		}
		image := texs[texKey]
		alt := texs["gray.png"]
		x := windowSize[0]/2 - cardWidth/3
		y := windowSize[1] - float32(4-i)*(cardHeight+padding) + cardHeight/6 - bottomPadding
		width := 2 * cardWidth / 3
		height := 2 * cardHeight / 3
		display := c == 0
		newSuitImg := addImgWithAlt(image, alt, x, y, width, height, display)
		emptySuitImgs = append(emptySuitImgs, newSuitImg)
	}
	// adding clubs
	for i := 0; i < clubCount; i++ {
		addCard(cards[i], texs, i, clubCount, diamondCount, spadeCount, heartCount)
	}
	// adding diamonds
	for i := clubCount; i < clubCount+diamondCount; i++ {
		addCard(cards[i], texs, i-clubCount, clubCount, diamondCount, spadeCount, heartCount)
	}
	// adding spades
	for i := clubCount + diamondCount; i < clubCount+diamondCount+spadeCount; i++ {
		addCard(cards[i], texs, i-clubCount-diamondCount, clubCount, diamondCount, spadeCount, heartCount)
	}
	// adding hearts
	for i := clubCount + diamondCount + spadeCount; i < clubCount+diamondCount+spadeCount+heartCount; i++ {
		addCard(cards[i], texs, i-clubCount-diamondCount-spadeCount, clubCount, diamondCount, spadeCount, heartCount)
	}
}

func loadTextures() map[string]sprite.SubTex {
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
		"passUnpressed.png", "leftArrow.png", "rightArrow.png", "acrossArrow.png", "croupierName.png"}
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

type arrangerFunc func(e sprite.Engine, n *sprite.Node, t clock.Time)

func (a arrangerFunc) Arrange(e sprite.Engine, n *sprite.Node, t clock.Time) { a(e, n, t) }

type cardSorter []*card.Card

func (cs cardSorter) Len() int {
	return len(cs)
}

func (cs cardSorter) Swap(i, j int) {
	cs[i], cs[j] = cs[j], cs[i]
}

func (cs cardSorter) Less(i, j int) bool {
	if cs[i].GetSuit() == cs[j].GetSuit() {
		return cs[i].GetFace() < cs[j].GetFace()
	} else {
		switch cs[i].GetSuit() {
		case card.Club:
			return true
		case card.Diamond:
			return cs[j].GetSuit() != card.Club
		case card.Spade:
			return cs[j].GetSuit() == card.Heart
		case card.Heart:
			return false
		}
	}
	return true
}
