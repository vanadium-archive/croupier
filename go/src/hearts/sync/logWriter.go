// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// gamelog handles creating the appropriately formatted key and value strings to write to the game log in syncbase
// a description of the log syntax can be found here: https://docs.google.com/document/d/1uZc9EQ2-F6CjJjGkj7VWvJNFklKGsFGQSVHtpEiJUlQ

package sync

import (
	"fmt"
	"strconv"
	"time"

	"hearts/img/uistate"
	"hearts/logic/card"

	"v.io/v23/context"
	"v.io/v23/syncbase"
)

var (
	cardType = "classic"
)

const (
	Deal      string = "Deal"
	Pass      string = "Pass"
	Take      string = "Take"
	Play      string = "Play"
	Ready     string = "Ready"
	TakeTrick string = "TakeTrick"
	Bar       string = "|"
	Space     string = " "
	Colon     string = ":"
	Dash      string = "-"
	End       string = "END"
)

// Formats deal command and sends to Syncbase
func LogDeal(u *uistate.UIState, playerIndex int, hands [][]*card.Card) bool {
	for i, h := range hands {
		key := getKey(playerIndex, u)
		value := Deal + Bar
		value += strconv.Itoa(i) + Colon
		for _, c := range h {
			value += cardType + Space + c.GetSuit().String() + c.GetFace().String() + Colon
		}
		value += End
		success := logKeyValue(u.Service, u.Ctx, key, value)
		if !success {
			return false
		}
	}
	return true
}

// Formats pass command and sends to Syncbase
func LogPass(u *uistate.UIState, cards []*card.Card) bool {
	key := getKey(u.CurPlayerIndex, u)
	value := Pass + Bar + strconv.Itoa(u.CurPlayerIndex) + Colon
	for _, c := range cards {
		value += cardType + Space + c.GetSuit().String() + c.GetFace().String() + Colon
	}
	value += End
	return logKeyValue(u.Service, u.Ctx, key, value)
}

// Formats take command and sends to Syncbase
func LogTake(u *uistate.UIState) bool {
	key := getKey(u.CurPlayerIndex, u)
	value := Take + Bar + strconv.Itoa(u.CurPlayerIndex) + Colon + End
	return logKeyValue(u.Service, u.Ctx, key, value)
}

// Formats play command and sends to Syncbase
func LogPlay(u *uistate.UIState, c *card.Card) bool {
	key := getKey(u.CurPlayerIndex, u)
	value := Play + Bar + strconv.Itoa(u.CurPlayerIndex) + Colon
	value += cardType + Space + c.GetSuit().String() + c.GetFace().String() + Colon + End
	return logKeyValue(u.Service, u.Ctx, key, value)
}

// Formats ready command and sends to Syncbase
func LogReady(u *uistate.UIState) bool {
	key := getKey(u.CurPlayerIndex, u)
	value := Ready + Bar + strconv.Itoa(u.CurPlayerIndex) + Colon + End
	return logKeyValue(u.Service, u.Ctx, key, value)
}

func LogTakeTrick(u *uistate.UIState) bool {
	key := getKey(u.CurPlayerIndex, u)
	value := TakeTrick + Bar + End
	return logKeyValue(u.Service, u.Ctx, key, value)
}

func LogPlayerNum(u *uistate.UIState) bool {
	key := fmt.Sprintf("%d/players/%d/player_number", u.GameID, UserID)
	value := strconv.Itoa(u.CurPlayerIndex)
	return logKeyValue(u.Service, u.Ctx, key, value)
}

func LogSettingsName(name string, u *uistate.UIState) bool {
	key := fmt.Sprintf("%d/players/%d/settings_sg", u.GameID, UserID)
	return logKeyValue(u.Service, u.Ctx, key, name)
}

func LogGameStart(u *uistate.UIState) bool {
	key := fmt.Sprintf("%d/status", u.GameID)
	value := "RUNNING"
	return logKeyValue(u.Service, u.Ctx, key, value)
}

// Note: The syntax replicates the way Croupier in Dart/Flutter writes keys.
func getKey(playerId int, u *uistate.UIState) string {
	t := time.Now().UnixNano() / 1000000
	key := fmt.Sprintf("%d/log/%d%s%d", u.GameID, t, Dash, playerId)
	return key
}

func logKeyValue(service syncbase.Service, ctx *context.T, key, value string) bool {
	return AddKeyValue(service, ctx, key, value)
}
