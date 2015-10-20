// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import "package:test/test.dart";
import "../lib/logic/solitaire/solitaire.dart";
import "../lib/logic/card.dart";

import "dart:io";

void main() {
  group("Initialization", () {
    SolitaireGame game = new SolitaireGame(0);
    test("Dealing", () {
      game.dealCardsUI(); // What we run when starting the game.

      // By virtue of creating the game, SolitaireGame should have:
      // 0 in each Ace pile
      // 0 in the discard and 24 in the draw pile
      // 0 to 6 in each down pile
      // 1 in each up pile
      for (int i = 0; i < 4; i++) {
        expect(
          game.cardCollections[SolitaireGame.OFFSET_ACES + i].length,
          equals(0),
          reason: "Ace piles start empty");
      }
      expect(
        game.cardCollections[SolitaireGame.OFFSET_DISCARD].length,
        equals(0),
        reason: "Discard pile starts empty");
      expect(
        game.cardCollections[SolitaireGame.OFFSET_DRAW].length,
        equals(24),
        reason: "Draw pile gets the remaining 24 cards");

      for (int i = 0; i < 7; i++) {
        expect(
          game.cardCollections[SolitaireGame.OFFSET_DOWN + i].length,
          equals(i),
          reason: "Down pile ${i} starts with ${i} cards");
        expect(
          game.cardCollections[SolitaireGame.OFFSET_UP + i].length,
          equals(1),
          reason: "Up piles start with 1 card");
      }
    });
  });

  // TODO(alexfandrianto): Test if Solitaire can detect the end of the game.

  // At this point, we should prepare the canonical game by setting up state and
  // performing a single action or set of actions.
  // Reads from a log, so we will go through logical game mechanics.
  group("Card Manipulation", () {
    SolitaireGame game = new SolitaireGame(0);

    // Note: This could have been a non-file (in-memory), but it's fine to use a file too.
    File file = new File("test/game_log_solitaire_test.txt");
    List<String> commands = file.readAsStringSync().split("\n");
    int commandIndex = 0;

    void runCommand() {
      String c = commands[commandIndex];
      commandIndex++;
      if (c == "" || c[0] == "#") {
        // Essentially, this case allows empty lines and comments.
        runCommand();
      } else {
        game.gamelog.add(new SolitaireCommand.fromCommand(c));
      }
    }

    test("Deal Phase", () {
      expect(game.phase, equals(SolitairePhase.Deal));

      // Deal consists of 1 deal command.
      runCommand();

      // TODO(alexfandrianto): Test that the correct cards appeared.
    });

    // TODO(alexfandrianto): Play the rest of the game!
  });

  group("Card Manipulation - Error Cases", () {
    test("Dealing - wrong phase", () {
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.phase = SolitairePhase.Score;
        game.gamelog.add(new SolitaireCommand.deal(
            new List<Card>.from(Card.All)));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Dealing - fake cards", () {
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.gamelog.add(
            new SolitaireCommand.deal(<Card>[new Card("fake", "not real")]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Dealing - wrong number of cards dealt", () {
      // 2x as many cards
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.gamelog.add(new SolitaireCommand.deal(
            new List<Card>.from(Card.All)..addAll(Card.All)));
      }, throwsA(new isInstanceOf<StateError>()));
      // missing cards
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.gamelog.add(new SolitaireCommand.deal(
            new List<Card>.from(Card.All.getRange(0, 40))));
      }, throwsA(new isInstanceOf<StateError>()));
    });

    // TODO(alexfandrianto): Lots of play phase mistakes can be made in canPlay.
  });
}
