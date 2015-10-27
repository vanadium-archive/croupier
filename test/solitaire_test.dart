// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import "package:test/test.dart";
import "../lib/logic/solitaire/solitaire.dart";
import "../lib/logic/card.dart";

import "dart:io";

typedef bool KeepGoingCb();

KeepGoingCb makeCommandReader(SolitaireGame game, String filename) {
  File file = new File(filename);
  List<String> commands = file.readAsStringSync().split("\n");
  int commandIndex = 0;

  KeepGoingCb runCommand;

  runCommand = () {
    if (commandIndex >= commands.length) {
      return false;
    }
    String c = commands[commandIndex];
    commandIndex++;
    if (c == "" || c[0] == "#") {
      // Essentially, this case allows empty lines and comments.
      return runCommand();
    }
    game.gamelog.add(new SolitaireCommand.fromCommand(c));

    return commandIndex < commands.length;
  };

  return runCommand;
}

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
        expect(game.cardCollections[SolitaireGame.OFFSET_ACES + i].length,
            equals(0),
            reason: "Ace piles start empty");
      }
      expect(
          game.cardCollections[SolitaireGame.OFFSET_DISCARD].length, equals(0),
          reason: "Discard pile starts empty");
      expect(game.cardCollections[SolitaireGame.OFFSET_DRAW].length, equals(24),
          reason: "Draw pile gets the remaining 24 cards");

      for (int i = 0; i < 7; i++) {
        expect(game.cardCollections[SolitaireGame.OFFSET_DOWN + i].length,
            equals(i),
            reason: "Down pile ${i} starts with ${i} cards");
        expect(
            game.cardCollections[SolitaireGame.OFFSET_UP + i].length, equals(1),
            reason: "Up piles start with 1 card");
      }
    });
  });

  // We have a debug cheat button that lets you advance in the game.
  // After calling it once, it is forced to place cards up into the aces area.
  group("Cheat Command", () {
    SolitaireGame game = new SolitaireGame(0);
    game.dealCardsUI(); // Get the cards out there.

    test("Cheat Functionality", () {
      for (int cheatNum = 0; cheatNum < 13; cheatNum++) {
        game.cheatUI();
        for (int i = 0; i < 4; i++) {
          expect(game.cardCollections[SolitaireGame.OFFSET_ACES + i].length,
              equals(cheatNum + 1));
        }
      }

      expect(game.isGameWon, isTrue);

      game.cheatUI(); // Should not error
      expect(game.isGameWon, isTrue); // We still win.
    });
  });

  group("Check Endgame", () {
    SolitaireGame game = new SolitaireGame(0);

    test("Has not won pre-deal", () {
      expect(game.phase, equals(SolitairePhase.Deal));
      expect(game.isGameWon, isFalse);
    });

    test("Has not won immediately after deal", () {
      game.dealCardsUI(); // What we run when starting the game.
      expect(game.phase, equals(SolitairePhase.Play));
      expect(game.isGameWon, isFalse);
    });

    test("Wins with all cards placed - regardless of order", () {
      for (int i = 0; i < 13; i++) {
        game.cheatUI(); // What we run when cheating.
      }
      expect(game.phase, equals(SolitairePhase.Score));
      expect(game.isGameWon, isTrue);

      // Now check an alternative suit order.
      List<Card> aces0 =
          new List<Card>.from(game.cardCollections[SolitaireGame.OFFSET_ACES]);
      List<Card> aces1 = new List<Card>.from(
          game.cardCollections[SolitaireGame.OFFSET_ACES + 1]);

      game.cardCollections[SolitaireGame.OFFSET_ACES].clear();
      game.cardCollections[SolitaireGame.OFFSET_ACES + 1].clear();

      // This expectation can be removed if isGameWon becomes a parameter, as
      // opposed to a computed property. However, if that happens, this test
      // will need to be reworked too, to start with a fresh game.
      expect(game.isGameWon, isFalse);

      // Swap the piles
      game.cardCollections[SolitaireGame.OFFSET_ACES].addAll(aces1);
      game.cardCollections[SolitaireGame.OFFSET_ACES + 1].addAll(aces0);

      expect(game.isGameWon, isTrue);
    });
  });

  // Run through a canonical game of Solitaire where the player doesn't win.
  group("Solitaire - Loss", () {
    SolitaireGame game = new SolitaireGame(0);

    // Note: This could have been a non-file (in-memory), but it's fine to use a file too.
    KeepGoingCb runCommand =
        makeCommandReader(game, "test/game_log_solitaire_test_loss.txt");

    test("Solitaire Commands", () {
      bool keepGoing = true;
      for (int i = 0; keepGoing; i++) {
        if (i == 0) {
          expect(game.phase, equals(SolitairePhase.Deal));
        } else if (!game.isGameWon) {
          expect(game.phase, equals(SolitairePhase.Play));
        } else {
          expect(game.phase, equals(SolitairePhase.Score));
        }

        // Play the next step of the game until we run out.
        keepGoing = runCommand(); // Must not error.
      }
    });

    // Naturally, we should ensure that we haven't won the game.
    test("Solitaire Win == False", () {
      expect(game.isGameWon, isFalse);
      expect(game.phase, equals(SolitairePhase.Play));
    });
  });

  // Run through a canonical game of Solitaire where the player does win.
  group("Solitaire - Win", () {
    SolitaireGame game = new SolitaireGame(0);

    // Note: This could have been a non-file (in-memory), but it's fine to use a file too.
    KeepGoingCb runCommand =
        makeCommandReader(game, "test/game_log_solitaire_test_win.txt");

    test("Solitaire Commands", () {
      bool keepGoing = true;
      for (int i = 0; keepGoing; i++) {
        if (i == 0) {
          expect(game.phase, equals(SolitairePhase.Deal));
        } else if (!game.isGameWon) {
          expect(game.phase, equals(SolitairePhase.Play));
        } else {
          expect(game.phase, equals(SolitairePhase.Score));
        }

        // Play the next step of the game until we run out.
        keepGoing = runCommand(); // Must not error.
      }
    });

    // Check that we won the game.
    test("Solitaire Win == True", () {
      expect(game.isGameWon, isTrue);
      expect(game.phase, equals(SolitairePhase.Score));
    });
  });

  group("Card Manipulation - Error Cases", () {
    test("Dealing - wrong phase", () {
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.phase = SolitairePhase.Score;
        game.gamelog
            .add(new SolitaireCommand.deal(new List<Card>.from(Card.All)));
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

    // Set up an arbitrary game state (manually) that allows testing of many
    // error cases.
    test("Playing - cannot move", () {
      // The setup will be this:
      // s2 _ h2 _   d2 c11
      // _ c3 h3 d1 s13 d3 d12

      Card c3 = Card.All[0 + 2];
      Card c11 = Card.All[0 + 10];
      Card d1 = Card.All[13 + 0];
      Card d2 = Card.All[13 + 1];
      Card d3 = Card.All[13 + 2];
      Card h2 = Card.All[26 + 1];
      Card h3 = Card.All[26 + 2];
      Card d12 = Card.All[13 + 11];
      Card s2 = Card.All[39 + 1];
      Card s13 = Card.All[39 + 12];

      SolitaireGame _makeArbitrarySolitaireGame() {
        SolitaireGame g = new SolitaireGame(0);

        // Top row
        g.cardCollections[SolitaireGame.OFFSET_ACES].add(s2);
        g.cardCollections[SolitaireGame.OFFSET_ACES + 2].add(h2);
        g.cardCollections[SolitaireGame.OFFSET_DISCARD].add(d2);
        g.cardCollections[SolitaireGame.OFFSET_DRAW].add(c11);

        // Bottom row
        g.cardCollections[SolitaireGame.OFFSET_UP + 1].add(c3);
        g.cardCollections[SolitaireGame.OFFSET_UP + 2].add(h3);
        g.cardCollections[SolitaireGame.OFFSET_UP + 3].add(d1);
        g.cardCollections[SolitaireGame.OFFSET_UP + 4].add(s13);
        g.cardCollections[SolitaireGame.OFFSET_UP + 5].add(d3);
        g.cardCollections[SolitaireGame.OFFSET_UP + 6].add(d12);

        g.phase = SolitairePhase.Play;

        return g;
      }

      // Cannot move d1 up to empty ACES slot if not in Play phase.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.phase = SolitairePhase.Deal;
        game.gamelog
            .add(new SolitaireCommand.move(d1, SolitaireGame.OFFSET_ACES + 1));
      }, throwsA(new isInstanceOf<StateError>()));

      // Cannot move d1 to nonexistent slot.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog.add(new SolitaireCommand.move(d1, -1));
      }, throwsA(new isInstanceOf<StateError>()));

      // Cannot move d1 to ACES slot that is used.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(d1, SolitaireGame.OFFSET_ACES + 2));
      }, throwsA(new isInstanceOf<StateError>()));

      // However, we can move d1 to the unused ACES slot in the Play phase.
      // see the end.

      // We cannot move c11 to d12 because it's in the DRAW pile still.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(c11, SolitaireGame.OFFSET_UP + 6));
      }, throwsA(new isInstanceOf<StateError>()));

      // We cannot move d2 (discard) to the DRAW pile.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(d2, SolitaireGame.OFFSET_DRAW));
      }, throwsA(new isInstanceOf<StateError>()));

      // We cannot move d1 (up) to the DISCARD pile either.
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(d1, SolitaireGame.OFFSET_DISCARD));
      }, throwsA(new isInstanceOf<StateError>()));

      // There are restrictions on what can be played on ACES piles.
      // First, suit mismatch: (h3 to spade ACE)
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(h3, SolitaireGame.OFFSET_ACES));
      }, throwsA(new isInstanceOf<StateError>()));

      // Next, non-ace on empty ACES slot. (c3 to empty ACE)
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(c3, SolitaireGame.OFFSET_ACES + 3));
      }, throwsA(new isInstanceOf<StateError>()));

      // Below, we'll show that moving to ACES works for various cases.

      // There are restrictions on what can be played on UP piles.
      // First, color that matches. (h2 to d3)
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(h2, SolitaireGame.OFFSET_ACES + 5));
      }, throwsA(new isInstanceOf<StateError>()));

      // Next, number that isn't 1 lower. (c3 to h3)
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(c3, SolitaireGame.OFFSET_ACES + 2));
      }, throwsA(new isInstanceOf<StateError>()));

      // Last, an empty that doesn't receive a king. (c3 to empty UP)
      expect(() {
        SolitaireGame game = _makeArbitrarySolitaireGame();
        game.gamelog
            .add(new SolitaireCommand.move(c3, SolitaireGame.OFFSET_ACES));
      }, throwsA(new isInstanceOf<StateError>()));

      // Below, we'll show that moving to UP works for various cases.

      // Success cases:
      // Going to ACES (empty) with an ace. (d1 to empty)
      // Going to ACES with a suit match. (h3 to h2, d2 to d1)
      // Going to UP with the color mismatch + 1 number lower. (d12 to s13, s2 to d3, d2 to c3)
      // Going to UP (empty) with a king. (s13 to empty)
      SolitaireGame game = _makeArbitrarySolitaireGame();
      game.gamelog
          .add(new SolitaireCommand.move(d1, SolitaireGame.OFFSET_ACES + 1));
      game.gamelog
          .add(new SolitaireCommand.move(h3, SolitaireGame.OFFSET_ACES + 2));
      game.gamelog
          .add(new SolitaireCommand.move(d2, SolitaireGame.OFFSET_ACES + 1));
      game.gamelog
          .add(new SolitaireCommand.move(d12, SolitaireGame.OFFSET_UP + 4));
      game.gamelog
          .add(new SolitaireCommand.move(s2, SolitaireGame.OFFSET_UP + 5));
      game.gamelog
          .add(new SolitaireCommand.move(d2, SolitaireGame.OFFSET_UP + 1));
      game.gamelog
          .add(new SolitaireCommand.move(s13, SolitaireGame.OFFSET_UP + 0));
    });

    // Consider various situations in which you cannot flip.
    test("Playing - cannot flip", () {
      // Wrong phase.
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.gamelog.add(new SolitaireCommand.flip(3));
      }, throwsA(new isInstanceOf<StateError>()));

      // Bad index (low)
      expect(() {
        SolitaireGame game = new SolitaireGame(0);

        // Deal first.
        game.dealCardsUI();

        // Remove some cards...
        game.cardCollections[SolitaireGame.OFFSET_UP + 1].clear();

        // Try to flip a pile that doesn't exist.
        game.gamelog.add(new SolitaireCommand.flip(-1));
      }, throwsA(new isInstanceOf<StateError>()));

      // Bad index (high)
      expect(() {
        SolitaireGame game = new SolitaireGame(0);

        // Deal first.
        game.dealCardsUI();

        // Remove some cards...
        game.cardCollections[SolitaireGame.OFFSET_UP + 1].clear();

        // Try to flip a pile that doesn't exist.
        game.gamelog.add(new SolitaireCommand.flip(7));
      }, throwsA(new isInstanceOf<StateError>()));

      // No down card to flip.
      expect(() {
        SolitaireGame game = new SolitaireGame(0);

        // Deal first.
        game.dealCardsUI();

        // Remove some cards...
        game.cardCollections[SolitaireGame.OFFSET_UP + 1].clear();
        game.cardCollections[SolitaireGame.OFFSET_DOWN + 1].clear();

        // Try to flip a pile that doesn't exist.
        game.gamelog.add(new SolitaireCommand.flip(1));
      }, throwsA(new isInstanceOf<StateError>()));

      // Up card is in the way.
      expect(() {
        SolitaireGame game = new SolitaireGame(0);

        // Deal first.
        game.dealCardsUI();

        // Do not clear out the area for pile 1.

        game.gamelog.add(new SolitaireCommand.flip(1));
      }, throwsA(new isInstanceOf<StateError>()));

      // This scenario should work though.
      SolitaireGame game = new SolitaireGame(0);

      // Deal. Clear away pile 1. Flip pile 1.
      game.dealCardsUI();
      game.cardCollections[SolitaireGame.OFFSET_UP + 1].clear();
      game.gamelog.add(new SolitaireCommand.flip(1));
    });

    // Consider various situations in which you cannot draw.
    test("Playing - cannot draw", () {
      // Wrong phase.
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.gamelog.add(new SolitaireCommand.draw());
      }, throwsA(new isInstanceOf<StateError>()));

      // No draw cards remain.
      expect(() {
        SolitaireGame game = new SolitaireGame(0);
        game.dealCardsUI();

        // Remove all draw cards.
        game.cardCollections[SolitaireGame.OFFSET_DRAW].clear();

        game.gamelog.add(new SolitaireCommand.draw());
      }, throwsA(new isInstanceOf<StateError>()));

      // But it should be fine to draw just after dealing.
      SolitaireGame game = new SolitaireGame(0);

      // Deal first.
      game.dealCardsUI();
      game.gamelog.add(new SolitaireCommand.draw());
    });
  });
}
