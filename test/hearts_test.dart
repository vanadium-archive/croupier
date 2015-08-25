import "package:test/test.dart";
import "../lib/logic/game.dart";

void main() {
  HeartsGame game = new HeartsGame(0);

  group("Card Manipulation", () {
    test("Dealing", () {
      // By virtue of creating the game, HeartsGame should have 4 collections with 13 cards and 8 collections with 0 cards each.

    });
    test("Passing", () {

    });
    test("Playing", () {

    });
  });
  group("Card Manipulation - Error Cases", () {
    test("Dealing - missing card", () {

    });
    test("Dealing - wrong number of cards", () {

    });
    test("Dealing - wrong phase", () {

    });
    test("Passing - missing card", () {

    });
    test("Passing - wrong number of cards", () {

    });
    test("Passing - wrong phase", () {

    });
    test("Playing - missing card", () {

    });
    test("Playing - invalid card (not 2 of clubs as first card)", () {

    });
    test("Playing - invalid card (no penalty on first round)", () {
      // NOTE: It is actually possible to be forced to play a penalty card on round 1.
      // But the odds are miniscule, so this rule will be enforced.
    });
    test("Playing - invalid card (suit mismatch)", () {

    });
    test("Playing - invalid card (hearts not broken yet)", () {

    });
    test("Playing - wrong turn", () {

    });
    test("Playing - wrong phase", () {

    });
  });
  group("Scoring", () {
    test("Count Points", () {
      // In this situation, what's the score?
    });
    test("Count Points 2", () {
      // In this alternative situation, what's the score?
    });
  });
  group("Game Over", () {
    test("Has the game ended? Yes", () {
      // Check if the game has ended. Should be yes.
    });
    test("Has the game ended? No", () {
      // Check if the game has ended. Should be no.
    });
  });
}