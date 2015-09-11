// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

import (
	"log"
	"sprites/player"
	"sprites/table"
)

var (
	t *table.Table
)

func main() {
	players := []*player.Player{player.NewPlayer(0), player.NewPlayer(1), player.NewPlayer(2), player.NewPlayer(3)}
	t := table.NewTable(players)
	t.Deal()
	hand := players[0].GetHand()
	log.Println(hand[0].GetNum(), hand[0].GetSuit())
	log.Println(hand[1].GetNum(), hand[1].GetSuit())
	log.Println(hand[2].GetNum(), hand[2].GetSuit())
	log.Println(hand[3].GetNum(), hand[3].GetSuit())
	log.Println(hand[4].GetNum(), hand[4].GetSuit())
	log.Println("-------------")
	t.Deal()
	hand = players[0].GetHand()
	log.Println(hand[0].GetNum(), hand[0].GetSuit())
	log.Println(hand[1].GetNum(), hand[1].GetSuit())
	log.Println(hand[2].GetNum(), hand[2].GetSuit())
	log.Println(hand[3].GetNum(), hand[3].GetSuit())
	log.Println(hand[4].GetNum(), hand[4].GetSuit())
}
