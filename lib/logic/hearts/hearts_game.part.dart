// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of hearts;

class HeartsGame extends Game {
  static const PLAYER_A = 0;
  static const PLAYER_B = 1;
  static const PLAYER_C = 2;
  static const PLAYER_D = 3;
  static const PLAYER_A_PLAY = 4;
  static const PLAYER_B_PLAY = 5;
  static const PLAYER_C_PLAY = 6;
  static const PLAYER_D_PLAY = 7;
  static const PLAYER_A_TRICK = 8;
  static const PLAYER_B_TRICK = 9;
  static const PLAYER_C_TRICK = 10;
  static const PLAYER_D_TRICK = 11;
  static const PLAYER_A_PASS = 12;
  static const PLAYER_B_PASS = 13;
  static const PLAYER_C_PASS = 14;
  static const PLAYER_D_PASS = 15;

  static const OFFSET_HAND = 0;
  static const OFFSET_PLAY = 4;
  static const OFFSET_TRICK = 8;
  static const OFFSET_PASS = 12;

  static const MAX_SCORE = 100; // Play until someone gets to 100.

  // Note: These cards are final because the "classic" deck has 52 cards.
  // It is up to the renderer to reskin those cards as needed.
  final Card TWO_OF_CLUBS = new Card("classic", "c2");
  final Card QUEEN_OF_SPADES = new Card("classic", "sq");

  @override
  String get gameTypeName => "Hearts";

  HeartsType viewType = HeartsType.Player;

  HeartsPhase _phase = HeartsPhase.StartGame;
  HeartsPhase get phase => _phase;
  void set phase(HeartsPhase other) {
    print('setting phase from ${_phase} to ${other}');
    _phase = other;
  }

  @override
  void set playerNumber(int other) {
    // The switch button requires us to change the current player.
    // Since the log writer has a notion of the associated user, we have to
    // change that too.
    super.playerNumber = other;
    HeartsLog hl = this.gamelog;
    hl.logWriter.associatedUser = other;
  }

  int roundNumber = 0;
  int lastTrickTaker;
  bool heartsBroken;
  int trickNumber;

  // Used by the score screen to track scores and see which players are ready to continue to the next round.
  List<int> scores = [0, 0, 0, 0];
  List<int> deltaScores = [0, 0, 0, 0];
  List<bool> ready;

  HeartsGame({int gameID, bool isCreator})
      : super.create(GameType.Hearts, new HeartsLog(), 16,
            gameID: gameID, isCreator: isCreator) {
    resetGame();
    unsetReady();
  }

  void resetGame() {
    this.resetCards();
    heartsBroken = false;
    lastTrickTaker = null;
    trickNumber = 0;
  }

  void dealCards() {
    deck.shuffle();

    // These things happen asynchronously, so we have to specify all cards now.
    List<Card> forA = this.deckPeek(13, 0);
    List<Card> forB = this.deckPeek(13, 13);
    List<Card> forC = this.deckPeek(13, 26);
    List<Card> forD = this.deckPeek(13, 39);

    deal(PLAYER_A, forA);
    deal(PLAYER_B, forB);
    deal(PLAYER_C, forC);
    deal(PLAYER_D, forD);
  }

  bool get isPlayer => this.playerNumber >= 0 && this.playerNumber < 4;

  int get passTarget {
    switch (roundNumber % 4) {
      // is a 4-cycle
      case 0:
        return (playerNumber - 1) % 4; // passLeft
      case 1:
        return (playerNumber + 1) % 4; // passRight
      case 2:
        return (playerNumber + 2) % 4; // passAcross
      case 3:
        return null; // no player to pass to
      default:
        assert(false);
        return null;
    }
  }

  int get takeTarget => getTakeTarget(playerNumber);
  int getTakeTarget(takerId) {
    switch (roundNumber % 4) {
      // is a 4-cycle
      case 0:
        return (takerId + 1) % 4; // takeRight
      case 1:
        return (takerId - 1) % 4; // takeLeft
      case 2:
        return (takerId + 2) % 4; // taleAcross
      case 3:
        return null; // no player to pass to
      default:
        assert(false);
        return null;
    }
  }

  // Please only call this in the Play phase. Otherwise, it's pretty useless.
  int get whoseTurn {
    if (phase != HeartsPhase.Play) {
      return null;
    }
    return (lastTrickTaker + this.numPlayed) % 4;
  }

  int getCardValue(Card c) {
    String remainder = c.identifier.substring(1);
    switch (remainder) {
      case "1": // ace
        return 14;
      case "k":
        return 13;
      case "q":
        return 12;
      case "j":
        return 11;
      default:
        return int.parse(remainder);
    }
  }

  String getCardSuit(Card c) {
    return c.identifier[0];
  }

  bool isHeartsCard(Card c) {
    return getCardSuit(c) == 'h' && c.deck == 'classic';
  }

  bool isQSCard(Card c) {
    return c == QUEEN_OF_SPADES;
  }

  bool isFirstCard(Card c) {
    return c == TWO_OF_CLUBS;
  }

  bool isPenaltyCard(Card c) {
    return isQSCard(c) || isHeartsCard(c);
  }

  bool hasSuit(int player, String suit) {
    Card matchesSuit = this.cardCollections[player + OFFSET_HAND].firstWhere(
        (Card element) => (getCardSuit(element) == suit),
        orElse: () => null);
    return matchesSuit != null;
  }

  Card get leadingCard {
    if (this.numPlayed >= 1) {
      return cardCollections[this.lastTrickTaker + OFFSET_PLAY][0];
    }
    return null;
  }

  int get numPlayed {
    int count = 0;
    for (int i = 0; i < 4; i++) {
      if (cardCollections[i + OFFSET_PLAY].length == 1) {
        count++;
      }
    }
    return count;
  }

  bool get hasGameEnded => this.scores.reduce(math.max) >= HeartsGame.MAX_SCORE;

  bool get allDealt => cardCollections[PLAYER_A].length == 13 &&
      cardCollections[PLAYER_B].length == 13 &&
      cardCollections[PLAYER_C].length == 13 &&
      cardCollections[PLAYER_D].length == 13;

  bool get allPassed => cardCollections[PLAYER_A_PASS].length == 3 &&
      cardCollections[PLAYER_B_PASS].length == 3 &&
      cardCollections[PLAYER_C_PASS].length == 3 &&
      cardCollections[PLAYER_D_PASS].length == 3;
  bool get allTaken => cardCollections[PLAYER_A_PASS].length == 0 &&
      cardCollections[PLAYER_B_PASS].length == 0 &&
      cardCollections[PLAYER_C_PASS].length == 0 &&
      cardCollections[PLAYER_D_PASS].length == 0;
  bool get allPlayed => this.numPlayed == 4;

  bool get allReady => ready[0] && ready[1] && ready[2] && ready[3];
  void setReady(int playerId) {
    ready[playerId] = true;
  }

  void unsetReady() {
    ready = <bool>[false, false, false, false];
  }

  void deal(int playerId, List<Card> cards) {
    gamelog.add(new HeartsCommand.deal(playerId, cards));
  }

  // Note that this will be called by the UI.
  // It won't be possible to pass for other players, except via the GameLog.
  void passCards(List<Card> cards) {
    assert(phase == HeartsPhase.Pass);
    assert(this.passTarget != null);
    if (cards.length != 3) {
      throw new StateError('3 cards expected, but got: ${cards.toString()}');
    }
    gamelog.add(new HeartsCommand.pass(playerNumber, cards));
  }

  // Note that this will be called by the UI.
  // It won't be possible to take cards for other players, except via the GameLog.
  void takeCards() {
    assert(phase == HeartsPhase.Take);
    assert(this.takeTarget != null);
    List<Card> cards = this.cardCollections[takeTarget + OFFSET_PASS];
    assert(cards.length == 3);

    gamelog.add(new HeartsCommand.take(playerNumber));
  }

  // Note that this will be called by the UI.
  // It won't be possible to set the readiness for other players, except via the GameLog.
  void setReadyUI() {
    assert(phase == HeartsPhase.Score || phase == HeartsPhase.StartGame);
    if (this.debugMode) {
      // Debug Mode should pretend this device is all players.
      for (int i = 0; i < 4; i++) {
        gamelog.add(new HeartsCommand.ready(i));
      }
    } else if (this.isPlayer) {
      gamelog.add(new HeartsCommand.ready(playerNumber));
    }
  }

  static final GameArrangeData _arrangeData =
      new GameArrangeData(true, new Set.from([0, 1, 2, 3]));
  GameArrangeData get gameArrangeData => _arrangeData;

  @override
  void startGameSignal() {
    if (this.debugMode && this.playerNumber < 0) {
      this.playerNumber = 0;
    }
    if (!this.isPlayer) {
      this.viewType = HeartsType.Board;
    }
    // Only the creator should deal the cards once everyone is ready.
    if (this.isCreator) {
      this.dealCards();
    }
  }

  // Note that this will be called by the UI.
  // TODO: Does this really need to be overridden? That seems like bad structure in GameComponent.
  // Overrides Game's move method with the "move" logic for Hearts. Used for drag-drop.
  // Note that this can only be called in the Play Phase of your turn.
  // The UI will handle the drag-drop of the Pass Phase with its own state.
  // The UI will initiate pass separately.
  @override
  void move(Card card, List<Card> dest) {
    assert(phase == HeartsPhase.Play);
    assert(whoseTurn == playerNumber);

    int i = findCard(card);
    if (i == -1) {
      throw new StateError(
          'card does not exist or was not dealt: ${card.toString()}');
    }
    int destId = cardCollections.indexOf(dest);
    if (destId == -1) {
      throw new StateError(
          'destination list does not exist: ${dest.toString()}');
    }
    if (destId != playerNumber + OFFSET_PLAY) {
      throw new StateError(
          'player ${playerNumber} is not playing to the correct list: ${destId}');
    }

    gamelog.add(new HeartsCommand.play(playerNumber, card));

    debugString = 'Play ${i} ${card.toString()}';
    print(debugString);
  }

  // Overridden from Game for Hearts-specific logic:
  // Switch from Pass to Take phase when all 4 players are passing.
  // Switch from Take to Play phase when all 4 players have taken.
  // During Play, if all 4 players play a card, move the tricks around.
  // During Play, once all cards are gone and last trick is taken, go to Score phase (compute score and possibly end game).
  // Switch from Score to Deal phase when all 4 players indicate they are ready.
  @override
  void triggerEvents() {
    switch (this.phase) {
      case HeartsPhase.StartGame:
        if (this.allReady) {
          phase = HeartsPhase.Deal;
          this.resetGame();

          print('we are all ready. ${isCreator}');
        }
        return;
      case HeartsPhase.Deal:
        if (this.allDealt) {
          if (this.passTarget != null) {
            phase = HeartsPhase.Pass;
          } else {
            // All cards are dealt. The person who "won" the last trick goes first.
            // In this case, we'll just pretend it's the person with the 2 of clubs.
            this.lastTrickTaker = this.findCard(TWO_OF_CLUBS);
            phase = HeartsPhase.Play;
          }
        }
        return;
      case HeartsPhase.Pass:
        if (this.allPassed) {
          phase = HeartsPhase.Take;
        }
        return;
      case HeartsPhase.Take:
        if (this.allTaken) {
          // All cards are dealt. The person who "won" the last trick goes first.
          // In this case, we'll just pretend it's the person with the 2 of clubs.
          this.lastTrickTaker = this.findCard(TWO_OF_CLUBS);
          phase = HeartsPhase.Play;
        }
        return;
      case HeartsPhase.Play:
        if (this.allPlayed) {
          // Determine who won this trick.
          int winner = this.determineTrickWinner();

          // Move the cards to their trick list. Also check if hearts was broken.
          // Note: Some variants of Hearts allows the QUEEN_OF_SPADES to break hearts too.
          for (int i = 0; i < 4; i++) {
            List<Card> play = this.cardCollections[i + OFFSET_PLAY];
            if (!heartsBroken && isHeartsCard(play[0])) {
              heartsBroken = true;
            }
            this.cardCollections[winner + OFFSET_TRICK]
                .addAll(play); // or add(play[0])
            play.clear();
          }

          // Set them as the next person to go.
          this.lastTrickTaker = winner;
          this.trickNumber++;

          // Additionally, if that was the last trick, move onto the score phase.
          if (this.trickNumber == 13) {
            phase = HeartsPhase.Score;
            this.prepareScore();
          }
        }
        return;
      case HeartsPhase.Score:
        if (!this.hasGameEnded && this.allReady) {
          this.roundNumber++;
          phase = HeartsPhase.Deal;
          this.resetGame();

          // Only the creator should deal the cards once everyone is ready.
          if (this.isCreator) {
            this.dealCards();
          }
        }
        return;
      default:
        assert(false);
    }
  }

  // Returns null or the reason that the player cannot play the card.
  String canPlay(int player, Card c) {
    if (phase != HeartsPhase.Play) {
      return "It is not the Play phase of Hearts.";
    }
    if (!cardCollections[player].contains(c)) {
      return "Player ${player} does not have the card (${c.toString()})";
    }
    if (this.whoseTurn != player) {
      return "It is not Player ${player}'s turn.";
    }
    if (trickNumber == 0 && this.numPlayed == 0 && c != TWO_OF_CLUBS) {
      return "Player ${player} must play the two of clubs.";
    }
    if (trickNumber == 0 && isPenaltyCard(c)) {
      return "Cannot play a penalty card on the first round of Hearts.";
    }
    if (this.numPlayed == 0 && isHeartsCard(c) && !heartsBroken) {
      return "Cannot lead with a heart when the suit has not been broken yet.";
    }
    if (this.leadingCard != null) {
      String leadingSuit = getCardSuit(this.leadingCard);
      String otherSuit = getCardSuit(c);
      if (this.numPlayed >= 1 &&
          leadingSuit != otherSuit &&
          hasSuit(player, leadingSuit)) {
        return "Must follow with a ${leadingSuit}.";
      }
    }
    return null;
  }

  int determineTrickWinner() {
    String leadingSuit = this.getCardSuit(this.leadingCard);
    int highestIndex;
    int highestValue; // oh no, aces are highest.
    for (int i = 0; i < 4; i++) {
      Card c = cardCollections[i + OFFSET_PLAY][0];
      int value = this.getCardValue(c);
      String suit = this.getCardSuit(c);
      if (suit == leadingSuit &&
          (highestIndex == null || highestValue < value)) {
        highestIndex = i;
        highestValue = value;
      }
    }

    return highestIndex;
  }

  void prepareScore() {
    this.unsetReady();
    this.updateScore();

    // At this point, it's up to the UI to determine what to do if the game is 'over'.
    // Check this.hasGameEnded to determine if that is the case. Logically, there is nothing for this game to do.
  }

  void updateScore() {
    // Clear out delta scores.
    deltaScores = [0, 0, 0, 0];

    // Count up points and check if someone shot the moon.
    int shotMoon = null;
    for (int i = 0; i < 4; i++) {
      int delta = computeScore(i);
      this.deltaScores[i] = delta;
      if (delta == 26) {
        // Shot the moon!
        shotMoon = i;
      }
    }

    // If someone shot the moon, apply the proper score adjustments here.
    if (shotMoon != null) {
      for (int i = 0; i < 4; i++) {
        if (shotMoon == i) {
          this.deltaScores[i] -= 26;
        } else {
          this.deltaScores[i] += 26;
        }
      }
    }

    // Finally, apply deltaScores to scores. Preserve deltaScores for the UI.
    for (int i = 0; i < 4; i++) {
      this.scores[i] += this.deltaScores[i];
    }
  }

  int computeScore(int player) {
    int total = 0;
    List<Card> trickCards = this.cardCollections[player + OFFSET_TRICK];
    for (int i = 0; i < trickCards.length; i++) {
      Card c = trickCards[i];
      if (isHeartsCard(c)) {
        total++;
      }
      if (isQSCard(c)) {
        total += 13;
      }
    }
    return total;
  }

  // TODO(alexfandrianto): Remove. This is just for testing the UI without having
  // to play through the whole game.
  void jumpToScorePhaseDebug() {
    for (int i = 0; i < 4; i++) {
      // Move the hand cards, pass cards, etc. to the tricks for each player.
      // If you're in the deal phase, this will probably do nothing.
      List<Card> trick = cardCollections[i + OFFSET_TRICK];
      trick.addAll(cardCollections[i + OFFSET_HAND]);
      cardCollections[i + OFFSET_HAND].clear();
      trick.addAll(cardCollections[i + OFFSET_PLAY]);
      cardCollections[i + OFFSET_PLAY].clear();
      trick.addAll(cardCollections[i + OFFSET_PASS]);
      cardCollections[i + OFFSET_PASS].clear();
    }

    phase = HeartsPhase.Score;
    this.prepareScore();
  }
}
