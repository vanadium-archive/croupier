// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import "package:test/test.dart";
import "../lib/logic/hearts/hearts.dart";
import "../lib/logic/card.dart";

import "dart:io";

void main() {
  group("Initialization", () {
    HeartsGame game = new HeartsGame()..playerNumber = 0;
    game.phase = HeartsPhase.deal;
    test("Dealing", () {
      game.dealCards(); // What the dealer actually runs to get cards to everybody.

      // By virtue of creating the game, HeartsGame should have 4 collections with 13 cards and 8 collections with 0 cards each.
      expect(
          game.cardCollections[HeartsGame.playerA + HeartsGame.offsetHand]
              .length,
          equals(13),
          reason: "Dealt 13 cards to A");
      expect(
          game.cardCollections[HeartsGame.playerB + HeartsGame.offsetHand]
              .length,
          equals(13),
          reason: "Dealt 13 cards to B");
      expect(
          game.cardCollections[HeartsGame.playerC + HeartsGame.offsetHand]
              .length,
          equals(13),
          reason: "Dealt 13 cards to C");
      expect(
          game.cardCollections[HeartsGame.playerD + HeartsGame.offsetHand]
              .length,
          equals(13),
          reason: "Dealt 13 cards to D");
      expect(
          game.cardCollections[HeartsGame.playerA + HeartsGame.offsetPlay]
              .length,
          equals(0),
          reason: "Not playing yet");
      expect(
          game.cardCollections[HeartsGame.playerB + HeartsGame.offsetPlay]
              .length,
          equals(0),
          reason: "Not playing yet");
      expect(
          game.cardCollections[HeartsGame.playerC + HeartsGame.offsetPlay]
              .length,
          equals(0),
          reason: "Not playing yet");
      expect(
          game.cardCollections[HeartsGame.playerD + HeartsGame.offsetPlay]
              .length,
          equals(0),
          reason: "Not playing yet");
      expect(
          game.cardCollections[HeartsGame.playerA + HeartsGame.offsetPass]
              .length,
          equals(0),
          reason: "Not passing yet");
      expect(
          game.cardCollections[HeartsGame.playerB + HeartsGame.offsetPass]
              .length,
          equals(0),
          reason: "Not passing yet");
      expect(
          game.cardCollections[HeartsGame.playerC + HeartsGame.offsetPass]
              .length,
          equals(0),
          reason: "Not passing yet");
      expect(
          game.cardCollections[HeartsGame.playerD + HeartsGame.offsetPass]
              .length,
          equals(0),
          reason: "Not passing yet");
      expect(
          game.cardCollections[HeartsGame.playerA + HeartsGame.offsetTrick]
              .length,
          equals(0),
          reason: "No tricks yet");
      expect(
          game.cardCollections[HeartsGame.playerB + HeartsGame.offsetTrick]
              .length,
          equals(0),
          reason: "No tricks yet");
      expect(
          game.cardCollections[HeartsGame.playerC + HeartsGame.offsetTrick]
              .length,
          equals(0),
          reason: "No tricks yet");
      expect(
          game.cardCollections[HeartsGame.playerD + HeartsGame.offsetTrick]
              .length,
          equals(0),
          reason: "No tricks yet");
    });
  });

  // For this test, the cards may end up being duplicate or inconsistent.
  group("Scoring", () {
    HeartsGame game = new HeartsGame()..playerNumber = 0;
    test("Compute/Prepare Score", () {
      // In this situation, what's the score?
      game.cardCollections[HeartsGame.playerTrickA] = <Card>[
        new Card("classic", "dq"),
        new Card("classic", "dk"),
        new Card("classic", "h1"),
        new Card("classic", "h2"),
        new Card("classic", "h3"),
        new Card("classic", "h4")
      ];

      expect(game.computeScore(HeartsGame.playerA), equals(4),
          reason: "Player A has 4 hearts");

      // In this alternative situation, what's the score?
      game.cardCollections[HeartsGame.playerTrickB] = <Card>[
        new Card("classic", "h6"),
        new Card("classic", "h7"),
        new Card("classic", "h8"),
        new Card("classic", "h9"),
        new Card("classic", "h10"),
        new Card("classic", "hj"),
        new Card("classic", "hq"),
        new Card("classic", "hk"),
        new Card("classic", "s1"),
        new Card("classic", "s2")
      ];

      expect(game.computeScore(HeartsGame.playerB), equals(8),
          reason: "Player B has 8 hearts.");

      // Should prepare C as well.
      game.cardCollections[HeartsGame.playerTrickC] = <Card>[
        new Card("classic", "h5"),
        new Card("classic", "sq")
      ];
      expect(game.computeScore(HeartsGame.playerC), equals(14),
          reason: "Player C has 1 heart and the queen of spades.");

      // Now, update the score, modifying game.scores.
      game.updateScore();
      expect(game.scores, equals([4, 8, 14, 0]));
      expect(game.deltaScores, equals([4, 8, 14, 0]));

      // Do it again.
      game.updateScore();
      expect(game.scores, equals([8, 16, 28, 0]));
      expect(game.deltaScores, equals([4, 8, 14, 0]));

      // Shoot the moon!
      game.cardCollections[HeartsGame.playerTrickA] = <Card>[];
      game.cardCollections[HeartsGame.playerTrickB] = <Card>[];
      game.cardCollections[HeartsGame.playerTrickC] = <Card>[];
      game.cardCollections[HeartsGame.playerTrickD] = Card.all;
      game.updateScore();
      expect(game.scores, equals([34, 42, 54, 0]));
      expect(game.deltaScores, equals([26, 26, 26, 0]));
    });
  });

  group("Game Over", () {
    HeartsGame game = new HeartsGame()..playerNumber = 0;

    test("Has the game ended? Yes", () {
      // Check if the game has ended. Should be yes.
      game.scores = <int>[HeartsGame.maxScore + 5, 40, 35, 0];
      expect(game.hasGameEnded, isTrue);
    });
    test("Has the game ended? No", () {
      // Check if the game has ended. Should be no.
      game.scores = <int>[HeartsGame.maxScore - 5, 40, 35, 0];
      expect(game.hasGameEnded, isFalse);
    });
  });

  // At this point, we should prepare the canonical game by setting up state and
  // performing a single action or set of actions.
  // Reads from a log, so we will go through logical game mechanics.
  group("Card Manipulation", () {
    HeartsGame game = new HeartsGame()..playerNumber = 0;

    // Note: This could have been a non-file (in-memory), but it's fine to use a file too.
    File file = new File("test/game_log_hearts_test.txt");
    List<String> commands = file.readAsStringSync().split("\n");
    int commandIndex = 0;

    void runCommand() {
      String c = commands[commandIndex];
      commandIndex++;
      if (c == "" || c[0] == "#") {
        // Essentially, this case allows empty lines and comments.
        runCommand();
      } else {
        game.gamelog.add(new HeartsCommand.fromCommand(c));
      }
    }

    test("Deal Phase", () {
      expect(game.phase, equals(HeartsPhase.deal));

      // Deal consists of 4 deal commands.
      runCommand();
      runCommand();
      runCommand();
      runCommand();

      // Confirm cards in hands.
      List<Card> expectedAHand =
          new List<Card>.from(Card.all.getRange(26, 26 + 5))
            ..addAll(Card.all.getRange(13 + 5, 26));
      List<Card> expectedBHand =
          new List<Card>.from(Card.all.getRange(13, 13 + 5))
            ..addAll(Card.all.getRange(39 + 5, 52));
      List<Card> expectedCHand =
          new List<Card>.from(Card.all.getRange(39, 39 + 5))
            ..addAll(Card.all.getRange(0 + 5, 13));
      List<Card> expectedDHand =
          new List<Card>.from(Card.all.getRange(0, 0 + 5))
            ..addAll(Card.all.getRange(26 + 5, 39));
      expect(game.cardCollections[HeartsGame.playerA], equals(expectedAHand));
      expect(game.cardCollections[HeartsGame.playerB], equals(expectedBHand));
      expect(game.cardCollections[HeartsGame.playerC], equals(expectedCHand));
      expect(game.cardCollections[HeartsGame.playerD], equals(expectedDHand));
    });
    test("Pass Phase", () {
      expect(game.phase, equals(HeartsPhase.pass));

      // Pass consists of 4 pass commands.
      runCommand();
      runCommand();
      runCommand();
      runCommand();

      // Confirm cards in hands and passes.
      List<Card> expectedAHand =
          new List<Card>.from(Card.all.getRange(26 + 3, 26 + 5))
            ..addAll(Card.all.getRange(13 + 5, 26));
      List<Card> expectedBHand =
          new List<Card>.from(Card.all.getRange(13 + 3, 13 + 5))
            ..addAll(Card.all.getRange(39 + 5, 52));
      List<Card> expectedCHand =
          new List<Card>.from(Card.all.getRange(39 + 3, 39 + 5))
            ..addAll(Card.all.getRange(0 + 5, 13));
      List<Card> expectedDHand =
          new List<Card>.from(Card.all.getRange(0 + 3, 0 + 5))
            ..addAll(Card.all.getRange(26 + 5, 39));
      List<Card> expectedAPass =
          new List<Card>.from(Card.all.getRange(26, 26 + 3));
      List<Card> expectedBPass =
          new List<Card>.from(Card.all.getRange(13, 13 + 3));
      List<Card> expectedCPass =
          new List<Card>.from(Card.all.getRange(39, 39 + 3));
      List<Card> expectedDPass =
          new List<Card>.from(Card.all.getRange(0, 0 + 3));
      expect(game.cardCollections[HeartsGame.playerA], equals(expectedAHand));
      expect(game.cardCollections[HeartsGame.playerB], equals(expectedBHand));
      expect(game.cardCollections[HeartsGame.playerC], equals(expectedCHand));
      expect(game.cardCollections[HeartsGame.playerD], equals(expectedDHand));
      expect(
          game.cardCollections[HeartsGame.playerPassA], equals(expectedAPass));
      expect(
          game.cardCollections[HeartsGame.playerPassB], equals(expectedBPass));
      expect(
          game.cardCollections[HeartsGame.playerPassC], equals(expectedCPass));
      expect(
          game.cardCollections[HeartsGame.playerPassD], equals(expectedDPass));
    });
    test("Take Phase", () {
      expect(game.phase, equals(HeartsPhase.take));

      // Take consists of 4 take commands.
      runCommand();
      runCommand();
      runCommand();
      runCommand();

      // Confirm cards in hands again.
      // Note: I will eventually want to do a sorted comparison or set comparison instead.
      List<Card> expectedAHand =
          new List<Card>.from(Card.all.getRange(26 + 3, 26 + 5))
            ..addAll(Card.all.getRange(13 + 5, 26))
            ..addAll(Card.all.getRange(13, 13 + 3));
      List<Card> expectedBHand =
          new List<Card>.from(Card.all.getRange(13 + 3, 13 + 5))
            ..addAll(Card.all.getRange(39 + 5, 52))
            ..addAll(Card.all.getRange(39, 39 + 3));
      List<Card> expectedCHand =
          new List<Card>.from(Card.all.getRange(39 + 3, 39 + 5))
            ..addAll(Card.all.getRange(0 + 5, 13))
            ..addAll(Card.all.getRange(0, 0 + 3));
      List<Card> expectedDHand =
          new List<Card>.from(Card.all.getRange(0 + 3, 0 + 5))
            ..addAll(Card.all.getRange(26 + 5, 39))
            ..addAll(Card.all.getRange(26, 26 + 3));
      expect(game.cardCollections[HeartsGame.playerA], equals(expectedAHand));
      expect(game.cardCollections[HeartsGame.playerB], equals(expectedBHand));
      expect(game.cardCollections[HeartsGame.playerC], equals(expectedCHand));
      expect(game.cardCollections[HeartsGame.playerD], equals(expectedDHand));
    });
    test("Play Phase - Trick 1", () {
      expect(game.phase, equals(HeartsPhase.play));

      // Play Trick 1 consists of 4 ask + 4 play + 1 take trick command.
      for (int i = 0; i < 8; i++) {
        runCommand();
      }

      // Confirm that everyone has played before taking the trick
      expect(game.allPlayed, isTrue);
      runCommand();

      // Confirm the winner of the round.
      expect(game.lastTrickTaker, equals(3),
          reason: "Player 3 played 4 of Clubs");
      expect(game.cardCollections[HeartsGame.playerTrickD].length, equals(4),
          reason: "Player 3 won 1 trick.");
    });
    test("Play Phase - Trick 2", () {
      expect(game.phase, equals(HeartsPhase.play));

      // Play Trick 2 consists of 4 ask + 4 play + 1 take trick command.
      for (int i = 0; i < 8; i++) {
        runCommand();
      }

      // Confirm that everyone has played before taking the trick
      expect(game.allPlayed, isTrue);
      runCommand();

      // Confirm the winner of the round.
      expect(game.lastTrickTaker, equals(2),
          reason: "Player 2 played Ace of Clubs");
      expect(game.cardCollections[HeartsGame.playerTrickC].length, equals(4),
          reason: "Player 2 won 1 trick.");
      expect(game.cardCollections[HeartsGame.playerTrickD].length, equals(4),
          reason: "Player 3 won 1 trick.");
    });
    test("Play Phase - Trick 13", () {
      expect(game.phase, equals(HeartsPhase.play));

      // Play Trick 13 consists of 44 ask + 44 play + 11 take trick command.
      // Read line by line until the game is "over".
      for (int i = 18; i < 117; i++) {
        runCommand();
      }

      // Assert that hands/plays/passes are empty.
      expect(
          game.cardCollections[HeartsGame.playerA + HeartsGame.offsetHand]
              .length,
          equals(0),
          reason: "Played all cards");
      expect(
          game.cardCollections[HeartsGame.playerB + HeartsGame.offsetHand]
              .length,
          equals(0),
          reason: "Played all cards");
      expect(
          game.cardCollections[HeartsGame.playerC + HeartsGame.offsetHand]
              .length,
          equals(0),
          reason: "Played all cards");
      expect(
          game.cardCollections[HeartsGame.playerD + HeartsGame.offsetHand]
              .length,
          equals(0),
          reason: "Played all cards");

      // Check that all 52 cards are in tricks.
      expect(game.lastTrickTaker, equals(0),
          reason: "Player 0 won the last trick.");
      expect(
          game.cardCollections[HeartsGame.playerTrickA].length, equals(4 * 8),
          reason: "Player 0 won 8 tricks.");
      expect(
          game.cardCollections[HeartsGame.playerTrickB].length, equals(4 * 2),
          reason: "Player 1 won 2 tricks.");
      expect(
          game.cardCollections[HeartsGame.playerTrickC].length, equals(4 * 2),
          reason: "Player 2 won 2 tricks.");
      expect(game.cardCollections[HeartsGame.playerTrickD].length, equals(4),
          reason: "Player 3 won 1 trick.");
    });
    test("Score Phase", () {
      expect(game.phase, equals(HeartsPhase.score));

      // Check score to ensure it matches the expectation.
      expect(game.scores, equals([21, 3, 2, 0]));
      expect(game.deltaScores, equals([21, 3, 2, 0]));

      // Score consists of 4 ready commands.
      runCommand();
      expect(game.allReady, isFalse);
      runCommand();
      expect(game.allReady, isFalse);
      runCommand();
      expect(game.allReady, isFalse);
      runCommand();

      // Back to the deal phase once everyone indicates that they are ready.
      expect(game.phase, equals(HeartsPhase.deal));
    });
    test("Score Phase - end of game", () {
      expect(game.hasGameEnded, isFalse);

      // 2nd Round: 4 deal, 4 pass, 4 take, 52 ask, 52 play, 13 take trick, 4 ready
      // Player A will shoot the moon for all remaining games (for simplicity).
      for (int i = 0; i < 133; i++) {
        runCommand();
      }
      expect(game.scores, equals([21 + 0, 3 + 26, 2 + 26, 0 + 26]));
      expect(game.hasGameEnded, isFalse);

      // 3rd Round: 4 deal, 4 pass, 4 take, 52 ask, 52 play, 13 take trick, 4 ready
      for (int i = 0; i < 133; i++) {
        runCommand();
      }
      expect(game.scores,
          equals([21 + 0 + 0, 3 + 26 + 26, 2 + 26 + 26, 0 + 26 + 26]));
      expect(game.hasGameEnded, isFalse);

      // 4th Round: 4 deal, 52 ask, 52 play, 13 take trick, 4 ready
      for (int i = 0; i < 125; i++) {
        runCommand();
      }
      expect(
          game.scores,
          equals([
            21 + 0 + 0 + 0,
            3 + 26 + 26 + 26,
            2 + 26 + 26 + 26,
            0 + 26 + 26 + 26
          ]));
      expect(game.deltaScores, equals([0, 26, 26, 26]));
      expect(game.hasGameEnded, isFalse);

      // 5th round: 4 deal, 4 pass, 4 take, 52 ask, 52 play, 13 take trick.
      // Game is over, so no ready phase.
      for (int i = 0; i < 129; i++) {
        runCommand();
      }
      expect(
          game.scores,
          equals([
            21 + 0 + 0 + 0 + 0,
            3 + 26 + 26 + 26 + 26,
            2 + 26 + 26 + 26 + 26,
            0 + 26 + 26 + 26 + 26
          ]));
      expect(game.deltaScores, equals([0, 26, 26, 26]));
      expect(game.hasGameEnded,
          isTrue); // assumes game ends after about 100 points.
    });
  });

  group("Card Manipulation - Error Cases", () {
    test("Dealing - wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.score;
      expect(() {
        game.gamelog.add(new HeartsCommand.deal(
            0, new List<Card>.from(Card.all.getRange(0, 13))));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Dealing - missing card", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      expect(() {
        game.gamelog.add(
            new HeartsCommand.deal(0, <Card>[new Card("fake", "not real")]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Dealing - too many cards dealt", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      expect(() {
        game.gamelog.add(new HeartsCommand.deal(
            0, new List<Card>.from(Card.all.getRange(0, 15))));
      }, throwsA(new isInstanceOf<StateError>()));

      game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      expect(() {
        game.gamelog.add(new HeartsCommand.deal(
            0, new List<Card>.from(Card.all.getRange(0, 5))));
        game.gamelog.add(new HeartsCommand.deal(
            0, new List<Card>.from(Card.all.getRange(5, 15))));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Passing - wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      expect(() {
        game.gamelog.add(new HeartsCommand.pass(
            0, new List<Card>.from(Card.all.getRange(0, 4))));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Passing - missing card", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.pass;
      expect(() {
        game.gamelog.add(new HeartsCommand.pass(
            0, new List<Card>.from(Card.all.getRange(13, 16))));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Passing - wrong number of cards", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.pass;
      expect(() {
        game.gamelog.add(new HeartsCommand.pass(
            0, new List<Card>.from(Card.all.getRange(0, 2))));
      }, throwsA(new isInstanceOf<StateError>()));

      game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.pass;
      expect(() {
        game.gamelog.add(new HeartsCommand.pass(
            0, new List<Card>.from(Card.all.getRange(0, 4))));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Taking - wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      expect(() {
        game.gamelog.add(new HeartsCommand.take(3));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Asking - wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      expect(() {
        game.gamelog.add(new HeartsCommand.ask());
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Asking - already asking", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.play;
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.ask());
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      expect(() {
        game.gamelog.add(new HeartsCommand.play(0, Card.all[0]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - not asking", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.play;
      expect(() {
        game.gamelog.add(new HeartsCommand.play(0, Card.all[0]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - missing card", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.play;
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.play(0, Card.all[13]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - invalid card (not 2 of clubs as first card)", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.play(0, Card.all[0]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - invalid card (no penalty on first round)", () {
      // NOTE: It is actually possible to be forced to play a penalty card on round 1.
      // But the odds are miniscule, so this rule will be enforced.
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(13, 26))));
      game.gamelog.add(new HeartsCommand.deal(
          2, new List<Card>.from(Card.all.getRange(26, 39))));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(0, Card.all[1]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(1, Card.all[13]));
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.play(2, Card.all[26]));
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - wrong turn", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 13))));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(13, 26))));
      game.gamelog.add(new HeartsCommand.deal(
          2, new List<Card>.from(Card.all.getRange(26, 39))));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.play(
            1, Card.all[13])); // player 0's turn, not player 1's.
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - invalid card (suit mismatch)", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 12))..add(Card.all[25])));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(12, 25))));
      game.gamelog.add(new HeartsCommand.deal(
          2, new List<Card>.from(Card.all.getRange(26, 39))));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(0, Card.all[1]));
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog
            .add(new HeartsCommand.play(0, Card.all[13])); // should play 12
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - invalid card (hearts not broken yet)", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 12))..add(Card.all[38])));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(13, 26))));
      game.gamelog.add(new HeartsCommand.deal(2,
          new List<Card>.from(Card.all.getRange(26, 38))..add(Card.all[12])));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(0, Card.all[1]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(1, Card.all[13]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(2, Card.all[12])); // 2 won!
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(3, Card.all[39]));
      game.gamelog.add(new HeartsCommand.takeTrick());
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.play(
            2, Card.all[26])); // But 2 can't lead with a hearts.
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Asking - trick not taken yet", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0,
          new List<Card>.from(Card.all.getRange(0, 11))
            ..add(Card.all[38])
            ..add(Card.all[37])));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(13, 26))));
      game.gamelog.add(new HeartsCommand.deal(
          2,
          new List<Card>.from(Card.all.getRange(26, 37))
            ..add(Card.all[12])
            ..add(Card.all[11])));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(0, Card.all[1]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(1, Card.all[13]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(2, Card.all[12])); // 2 won!
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(3, Card.all[39]));

      // Do not take trick. Ask instead.
      expect(() {
        game.gamelog.add(new HeartsCommand.ask());
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - take trick wrong phase", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      expect(() {
        game.gamelog.add(new HeartsCommand.takeTrick()); // bad phase
      }, throwsA(new isInstanceOf<StateError>()));
    });
    test("Playing - take trick too soon", () {
      HeartsGame game = new HeartsGame()..playerNumber = 0;
      game.phase = HeartsPhase.deal;
      game.gamelog.add(new HeartsCommand.deal(
          0, new List<Card>.from(Card.all.getRange(0, 12))..add(Card.all[38])));
      game.gamelog.add(new HeartsCommand.deal(
          1, new List<Card>.from(Card.all.getRange(13, 26))));
      game.gamelog.add(new HeartsCommand.deal(2,
          new List<Card>.from(Card.all.getRange(26, 38))..add(Card.all[12])));
      game.gamelog.add(new HeartsCommand.deal(
          3, new List<Card>.from(Card.all.getRange(39, 52))));
      game.phase = HeartsPhase.play;
      game.lastTrickTaker = 0;
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(0, Card.all[1]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(1, Card.all[13]));
      game.gamelog.add(new HeartsCommand.ask());
      game.gamelog.add(new HeartsCommand.play(2, Card.all[12]));
      game.gamelog.add(new HeartsCommand.ask());
      expect(() {
        game.gamelog.add(new HeartsCommand.takeTrick()); // too soon
      }, throwsA(new isInstanceOf<StateError>()));
    });
  });
}
