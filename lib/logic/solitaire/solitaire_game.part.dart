// Copyright 2015 The Vanadium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

part of solitaire;

enum SolitairePileType { aces, discard, draw, down, up }

class SolitaireGame extends Game {
  // Constants for the index-based offsets of the Solitaire Game's card collection.
  // There are 20 piles to track (4 aces, 1 discard, 1 draw, 7 down, 7 up).
  static const numPiles = 20;
  static const offsetAces = 0;
  static const offsetDiscard = 4;
  static const offsetDraw = 5;
  static const offsetDown = 6;
  static const offsetUp = 13;

  SolitaireGame({int gameID, bool isCreator})
      : super.create(GameType.solitaire, new SolitaireLog(), numPiles,
            gameID: gameID, isCreator: isCreator) {
    resetGame();
  }

  @override
  String get gameTypeName => "Solitaire";

  static final GameArrangeData _arrangeData =
      new GameArrangeData(false, new Set());
  @override
  GameArrangeData get gameArrangeData => _arrangeData;

  SolitairePhase _phase = SolitairePhase.deal;
  SolitairePhase get phase => _phase;
  void set phase(SolitairePhase other) {
    print('setting phase from $_phase to $other');
    _phase = other;
  }

  void resetGame() {
    this.resetCards();
  }

  int getCardValue(Card c) {
    String remainder = c.identifier.substring(1);
    switch (remainder) {
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

  bool isAce(Card c) {
    return getCardValue(c) == 1;
  }

  bool isKing(Card c) {
    return getCardValue(c) == 13;
  }

  bool isRed(Card c) {
    return getCardSuit(c) == 'h' || getCardSuit(c) == 'd';
  }

  bool isBlack(Card c) {
    return getCardSuit(c) == 's' || getCardSuit(c) == 'c';
  }

  bool get canDrawCard =>
      cardCollections[offsetDiscard].length +
          cardCollections[offsetDraw].length >
      0;

  bool get isGameWon {
    for (int i = 0; i < 4; i++) {
      if (this.cardCollections[i].length != 13) {
        return false;
      }
    }
    return true;
  }

  // UI Callback: Deal
  void dealCardsUI() {
    deck.shuffle();

    gamelog.add(new SolitaireCommand.deal(this.deckPeek(52, 0)));
  }

  // UI Callback: Move
  @override
  void move(Card card, List<Card> dest) {
    int targetPile = cardCollections.indexOf(dest);
    gamelog.add(new SolitaireCommand.move(card, targetPile));
  }

  // UI Callback: Draw
  void drawCardUI() {
    gamelog.add(new SolitaireCommand.draw());
  }

  // UI Callback: Flip
  void flipCardUI(int index) {
    gamelog.add(new SolitaireCommand.flip(index));
  }

  // UI Callback: Cheat UI
  void cheatUI() {
    if (this.isGameWon) {
      return;
    }

    // First, determine the suits present on the ACES pile.
    // Try to preserve this order.
    // Further, we need to know the next index (minLen) we're cheating with.
    List<String> suits = new List<String>(4);
    Set<String> remainingSuits =
        new Set<String>.from(<String>['c', 'd', 'h', 's']);
    int minLen;
    for (int i = 0; i < 4; i++) {
      int len = cardCollections[offsetAces + i].length;

      if (minLen == null || len < minLen) {
        minLen = len;
      }

      if (len > 0) {
        suits[i] = getCardSuit(cardCollections[offsetAces + i][0]);
        remainingSuits.remove(suits[i]);
      }
    }

    if (remainingSuits.length != 0) {
      for (int i = 0; i < 4; i++) {
        if (suits[i] == null) {
          suits[i] = remainingSuits.first;
          remainingSuits.remove(suits[i]);
        }
      }
    }

    // With all suits assigned, and the minLen known, we know which cards to pull.
    for (int i = 0; i < 4; i++) {
      List<Card> cards = cardCollections[offsetAces + i];

      if (cards.length == minLen) {
        // Let us pull a card from either the down cards, up cards, or deck.
        // Note: If we pull from up cards, the game may not be in a valid state,
        // but this is okay since we are cheating.

        int indexOffset;
        switch (suits[i]) {
          case 'c':
            indexOffset = 0;
            break;
          case 'd':
            indexOffset = 13;
            break;
          case 'h':
            indexOffset = 26;
            break;
          case 's':
            indexOffset = 39;
            break;
          default:
            print('the suit was ${suits[i]}');
            assert(false);
        }
        Card c = Card.all[indexOffset + minLen];
        int pileIndex = findCard(c);

        cardCollections[pileIndex].remove(c);
        cards.add(c);
      }
    }

    // After cheating, trigger events.
    triggerEvents();
  }

  // Overridden from Game for Solitaire-specific logic:
  // Allows you to immediately show the Score phase after noticing that the
  // player has won.
  @override
  void triggerEvents() {
    switch (this.phase) {
      case SolitairePhase.deal:
        if (this.deck.length == 0) {
          phase = SolitairePhase.play;
        }
        return;
      case SolitairePhase.play:
        if (this.isGameWon) {
          phase = SolitairePhase.score;
        }
        return;
      case SolitairePhase.score:
        return;
      default:
        assert(false);
    }
  }

  SolitairePileType pileType(int index) {
    if (index >= offsetAces && index < offsetDiscard) {
      return SolitairePileType.aces;
    } else if (index == offsetDiscard) {
      return SolitairePileType.discard;
    } else if (index == offsetDraw) {
      return SolitairePileType.draw;
    } else if (index >= offsetDown && index < offsetUp) {
      return SolitairePileType.down;
    } else if (index >= offsetUp && index < 20) {
      return SolitairePileType.up;
    } else {
      assert(false);
      return null;
    }
  }

  bool _cardCompatibleUp(Card top, Card bot) {
    if (isBlack(top) && isBlack(bot)) {
      return false;
    } else if (isRed(top) && isRed(bot)) {
      return false;
    } else if (getCardValue(top) - 1 != getCardValue(bot)) {
      return false;
    }
    return true;
  }

  bool _cardCompatibleAces(Card top, Card bot) {
    return getCardSuit(top) == getCardSuit(bot) &&
        getCardValue(top) + 1 == getCardValue(bot);
  }

  bool _isTopCard(Card c, int source) {
    List<Card> sourcePile = cardCollections[source];
    return sourcePile[sourcePile.length - 1] == c;
  }

  // The card in question must be the top card of the source (if it is from the aces or discard pile).
  // If the destination has no cards, you can play any king.
  // Otherwise, you have to be an opposite color AND 1 lower in value.
  String _checkUpDestination(
      Card c, int source, int destination, bool isAcesOrDiscard) {
    if (isAcesOrDiscard && !_isTopCard(c, source)) {
      return "Tried to move ${c.toString()}, but it is not the top card.";
    }

    List<Card> destPile = cardCollections[destination];
    if (destPile.length == 0) {
      if (!isKing(c)) {
        return "Destination is empty, but card is not a King.";
      }
      return null;
    }
    Card topCard = destPile[destPile.length - 1];
    if (!_cardCompatibleUp(topCard, c)) {
      return "${c.toString()} cannot be played on top of ${topCard.toString()}";
    }
    return null;
  }

  // The card in question must be the top card of the source.
  // If the destination has no cards, you can play any ace.
  // Otherwise, it has to be the same suit AND be 1 higher in value.
  String _checkAcesDestination(Card c, int source, int destination) {
    if (!_isTopCard(c, source)) {
      return "Tried to move ${c.toString()}, but it is not the top card.";
    }

    List<Card> destPile = cardCollections[destination];
    if (destPile.length == 0) {
      if (!isAce(c)) {
        return "Destination is empty, but card is not an Ace.";
      }
      return null;
    }
    Card topCard = destPile[destPile.length - 1];
    if (!_cardCompatibleAces(topCard, c)) {
      return "${c.toString()} cannot be played on top of ${topCard.toString()}";
    }
    return null;
  }

  // Returns null or the reason that the player cannot play the card.
  String canPlay(Card c, List<Card> dest) {
    int destination = cardCollections.indexOf(dest);
    int source = findCard(c);
    print("Can play? $c, $source $destination");

    if (phase != SolitairePhase.play) {
      return "It is not the Play phase of Solitaire.";
    }
    if (source == -1) {
      return "Unknown card: (${c.toString()})";
    }
    if (dest == -1) {
      return "Unknown destination: $dest";
    }
    if (source == destination) {
      return "Source Pile is same as Destination Pile";
    }
    SolitairePileType sType = pileType(source);
    SolitairePileType dType = pileType(destination);
    switch (sType) {
      case SolitairePileType.aces:
        if (dType != SolitairePileType.up) {
          return "Destination Pile for ACES pile should be an UP pile.";
        }
        return _checkUpDestination(c, source, destination, true);
      case SolitairePileType.discard:
        if (dType == SolitairePileType.up) {
          return _checkUpDestination(c, source, destination, true);
        } else if (dType == SolitairePileType.aces) {
          return _checkAcesDestination(c, source, destination);
        }
        return "Destination Pile for DISCARD should be an UP or ACES pile.";
      case SolitairePileType.draw:
        return "Source Pile should not be a DRAW pile.";
      case SolitairePileType.down:
        return "Source Pile should not be a DOWN pile.";
      case SolitairePileType.up:
        if (dType == SolitairePileType.up) {
          return _checkUpDestination(c, source, destination, false);
        } else if (dType == SolitairePileType.aces) {
          return _checkAcesDestination(c, source, destination);
        }
        return "Destination Pile for UP should be an UP or ACES pile.";
      default:
        assert(false);
    }

    return null;
  }

  // TODO(alexfandrianto): Maybe wanted for debug; if not, remove.
  void jumpToScorePhaseDebug() {}

  @override
  void startGameSignal() {
    if (this.isCreator) {
      this.dealCardsUI();
    }
  }
}
