// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// uistate contains the UIState struct that holds all variables relevant to creating and updating the app UI
// uistate also contains View, which defines different UI views

package uistate

import (
	"time"

	"hearts/img/coords"
	"hearts/img/staticimg"
	"hearts/logic/card"
	"hearts/logic/table"

	"golang.org/x/mobile/exp/gl/glutil"
	"golang.org/x/mobile/exp/sprite"

	"v.io/v23/context"
	"v.io/v23/syncbase"
)

type View string

const (
	None      View = "None"
	Arrange   View = "Arrange"
	Discovery View = "Discovery"
	Pass      View = "Pass"
	Take      View = "Take"
	Table     View = "Table"
	Play      View = "Play"
	Score     View = "Score"
	Split     View = "Split"
)

const (
	numPlayers    int     = 4
	numSuits      int     = 4
	cardSize      float32 = 35
	cardScaler    float32 = .5
	topPadding    float32 = 15
	bottomPadding float32 = 5
)

type UIState struct {
	StartTime time.Time
	Images    *glutil.Images
	Eng       sprite.Engine
	Scene     *sprite.Node
	// the following arrays keep track of all displayed images
	Cards          []*card.Card
	TableCards     []*card.Card
	BackgroundImgs []*staticimg.StaticImg
	EmptySuitImgs  []*staticimg.StaticImg
	DropTargets    []*staticimg.StaticImg
	Buttons        []*staticimg.StaticImg
	Other          []*staticimg.StaticImg
	CurCard        *card.Card           // the card that is currently clicked on
	CurImg         *staticimg.StaticImg // the image that is currently clicked on
	// lastMouseXY is in Px: divide by pixelsPerPt to get Pt
	LastMouseXY *coords.Vec // the position of the mouse in the most recent frame
	NumPlayers  int
	NumSuits    int
	// the following variables are used for sizing and positioning specifications
	CardSize       float32
	CardScaler     float32
	TopPadding     float32
	BottomPadding  float32
	WindowSize     *coords.Vec // windowSize is in Pt
	CardDim        *coords.Vec
	TableCardDim   *coords.Vec
	PlayerIconDim  *coords.Vec
	PixelsPerPt    float32
	Overlap        *coords.Vec
	Padding        float32
	CurView        View                     // the screen currently being shown to the user
	CurTable       *table.Table             // the table of the current game
	Done           bool                     // true if the app has been quit
	Texs           map[string]sprite.SubTex // map of all loaded images
	CurPlayerIndex int                      // the player number of this player
	Ctx            *context.T
	Service        syncbase.Service
	Debug          bool        // true if debugging, adds extra functionality to switch between players
	Shutdown       func()      // used to shut down a v23.Init()
	GameID         int         // used to differentiate between concurrent games
	IsOwner        bool        // true if this player is the game creator
	AnimChans      []chan bool // keeps track of all 'quit' channels in animations so their goroutines can be stopped
	SGChan         chan bool   // pass in a bool to stop advertising the syncgroup
	ScanChan       chan bool   // pass in a bool to stop scanning for syncgroups
}

func MakeUIState() *UIState {
	return &UIState{
		StartTime:      time.Now(),
		Cards:          make([]*card.Card, 0),
		TableCards:     make([]*card.Card, 0),
		BackgroundImgs: make([]*staticimg.StaticImg, 0),
		EmptySuitImgs:  make([]*staticimg.StaticImg, 0),
		DropTargets:    make([]*staticimg.StaticImg, 0),
		Buttons:        make([]*staticimg.StaticImg, 0),
		Other:          make([]*staticimg.StaticImg, 0),
		LastMouseXY:    coords.MakeVec(-1, -1),
		NumPlayers:     numPlayers,
		NumSuits:       numSuits,
		CardSize:       cardSize,
		CardScaler:     cardScaler,
		TopPadding:     topPadding,
		BottomPadding:  bottomPadding,
		WindowSize:     coords.MakeVec(-1, -1),
		CardDim:        coords.MakeVec(cardSize, cardSize),
		TableCardDim:   coords.MakeVec(cardSize*cardScaler, cardSize*cardScaler),
		PlayerIconDim:  coords.MakeVec(2*cardSize/3, 2*cardSize/3),
		Overlap:        coords.MakeVec(3*cardSize*cardScaler/4, 3*cardSize*cardScaler/4),
		Padding:        float32(5),
		CurView:        None,
		Done:           false,
		Debug:          false,
		AnimChans:      make([]chan bool, 0),
	}
}
