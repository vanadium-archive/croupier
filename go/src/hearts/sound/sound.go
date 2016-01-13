// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// sound.go handles in-app sound effects

package sound

import (
	"fmt"
	"log"

	"hearts/img/uistate"

	"golang.org/x/mobile/asset"
	"golang.org/x/mobile/exp/audio"
)

func InitPlayers(u *uistate.UIState) {
	for i, _ := range u.Audio.Players {
		rc, err := asset.Open(u.Audio.Sounds[i])
		if err != nil {
			fmt.Println("FIRST ERR")
			log.Fatal(err)
		}
		u.Audio.Players[i], err = audio.NewPlayer(rc, 0, 0)
		if err != nil {
			fmt.Println("SECOND ERR")
			log.Fatal(err)
		}
	}
}

func ClosePlayers(u *uistate.UIState) {
	for _, p := range u.Audio.Players {
		p.Close()
	}
}

func PlaySound(index int, u *uistate.UIState) {
	fmt.Println("PLAYING SOUND")
	p := u.Audio.Players[index]
	p.Seek(0)
	p.Play()
}
