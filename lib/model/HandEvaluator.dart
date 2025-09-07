import 'Card.dart';

class HandRank {
  final int value;
  final String name;
  final List<Card> cards;
  final bool isDraw;

  HandRank(this.value, this.name, this.cards, {this.isDraw = false});
}

class HandEvaluator {
  static HandRank evaluateHand(List<Card> playerCards, List<Card> communityCards) {
    final allCards = [...playerCards, ...communityCards];
    allCards.sort((a, b) => b.rank.index.compareTo(a.rank.index));

    // Check for made hands first
    HandRank? handRank = _checkCompletedHands(allCards);
    if (handRank != null) return handRank;

    // If board is not complete, check for draws
    if (communityCards.length < 5) {
      HandRank? drawRank = _checkDraws(allCards);
      if (drawRank != null) return drawRank;
    }

    return _getHighCard(allCards);
  }

  static HandRank? _checkCompletedHands(List<Card> cards) {
    HandRank? handRank;
    
    handRank = _checkRoyalFlush(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkStraightFlush(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkFourOfAKind(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkFullHouse(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkFlush(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkStraight(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkThreeOfAKind(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkTwoPair(cards);
    if (handRank != null) return handRank;
    
    handRank = _checkOnePair(cards);
    if (handRank != null) return handRank;
    
    return null;
  }

  static HandRank? _checkDraws(List<Card> cards) {
    // Check flush draw (4 cards of same suit)
    for (var suit in Suit.values) {
      final sameSuitCards = cards.where((card) => card.suit == suit).toList();
      if (sameSuitCards.length == 4) {
        return HandRank(350, "Flush Draw", sameSuitCards, isDraw: true);
      }
    }

    // Check straight draws
    var distinctRanks = cards.map((c) => c.rank).toSet().toList();
    distinctRanks.sort((a, b) => b.index.compareTo(a.index));

    // Open-ended straight draw
    for (var i = 0; i < distinctRanks.length - 3; i++) {
      if (distinctRanks[i].index - distinctRanks[i + 3].index == 3) {
        final straightDrawCards = cards.where((c) => 
          distinctRanks.sublist(i, i + 4).contains(c.rank)
        ).toList();
        return HandRank(300, "Open-Ended Straight Draw", straightDrawCards, isDraw: true);
      }
    }

    // Gutshot straight draw
    for (var i = 0; i < distinctRanks.length - 3; i++) {
      if (distinctRanks[i].index - distinctRanks[i + 3].index == 4) {
        final straightDrawCards = cards.where((c) => 
          distinctRanks.sublist(i, i + 4).contains(c.rank)
        ).toList();
        return HandRank(250, "Gutshot Straight Draw", straightDrawCards, isDraw: true);
      }
    }

    return null;
  }

  static HandRank? _checkRoyalFlush(List<Card> cards) {
    // Check for A, K, Q, J, 10 of the same suit
    for (var suit in Suit.values) {
      final sameSuitCards = cards.where((card) => card.suit == suit).toList();
      if (sameSuitCards.length >= 5) {
        final royalCards = sameSuitCards.where((card) => 
          card.rank == Rank.ace || 
          card.rank == Rank.king || 
          card.rank == Rank.queen || 
          card.rank == Rank.jack || 
          card.rank == Rank.ten
        ).toList();
        
        if (royalCards.length == 5) {
          return HandRank(1000, 'Royal Flush', royalCards);
        }
      }
    }
    return null;
  }

  static HandRank? _checkStraightFlush(List<Card> cards) {
    for (var suit in Suit.values) {
      final sameSuitCards = cards.where((card) => card.suit == suit).toList();
      if (sameSuitCards.length >= 5) {
        final straightFlush = _findStraight(sameSuitCards);
        if (straightFlush != null) {
          return HandRank(900 + straightFlush.first.rank.index, 'Straight Flush', straightFlush);
        }
      }
    }
    return null;
  }

  static HandRank? _checkFourOfAKind(List<Card> cards) {
    for (var rank in Rank.values.reversed) {
      final sameRankCards = cards.where((card) => card.rank == rank).toList();
      if (sameRankCards.length == 4) {
        final kicker = cards.firstWhere((card) => card.rank != rank);
        return HandRank(800 + rank.index, 'Four of a Kind', [...sameRankCards, kicker]);
      }
    }
    return null;
  }

  static HandRank? _checkFullHouse(List<Card> cards) {
    var threeOfKind = _findNOfAKind(cards, 3);
    if (threeOfKind != null) {
      var remainingCards = cards.where((card) => !threeOfKind!.contains(card)).toList();
      var pair = _findNOfAKind(remainingCards, 2);
      if (pair != null) {
        return HandRank(
          700 + threeOfKind.first.rank.index * 13 + pair.first.rank.index,
          'Full House',
          [...threeOfKind, ...pair]
        );
      }
    }
    return null;
  }

  static HandRank? _checkFlush(List<Card> cards) {
    for (var suit in Suit.values) {
      final sameSuitCards = cards.where((card) => card.suit == suit).toList();
      if (sameSuitCards.length >= 5) {
        sameSuitCards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
        return HandRank(600 + sameSuitCards[0].rank.index, 'Flush', sameSuitCards.take(5).toList());
      }
    }
    return null;
  }

  static HandRank? _checkStraight(List<Card> cards) {
    final straight = _findStraight(cards);
    if (straight != null) {
      return HandRank(500 + straight.first.rank.index, 'Straight', straight);
    }
    return null;
  }

  static List<Card>? _findStraight(List<Card> cards) {
    if (cards.length < 5) return null;
    
    var distinctRanks = cards.map((c) => c.rank).toSet().toList();
    distinctRanks.sort((a, b) => b.index.compareTo(a.index));
    
    for (var i = 0; i <= distinctRanks.length - 5; i++) {
      if (distinctRanks[i].index - distinctRanks[i + 4].index == 4) {
        var straightCards = cards.where((c) => 
          distinctRanks.sublist(i, i + 5).contains(c.rank)
        ).toList();
        straightCards.sort((a, b) => b.rank.index.compareTo(a.rank.index));
        return straightCards.take(5).toList();
      }
    }
    
    // Check for Ace-low straight (A-5-4-3-2)
    if (distinctRanks.contains(Rank.ace) && 
        distinctRanks.contains(Rank.five) && 
        distinctRanks.contains(Rank.four) && 
        distinctRanks.contains(Rank.three) && 
        distinctRanks.contains(Rank.two)) {
      var straightCards = cards.where((c) => 
        c.rank == Rank.ace || 
        c.rank == Rank.five || 
        c.rank == Rank.four || 
        c.rank == Rank.three || 
        c.rank == Rank.two
      ).toList();
      return straightCards.take(5).toList();
    }
    
    return null;
  }

  static HandRank? _checkThreeOfAKind(List<Card> cards) {
    var threeOfKind = _findNOfAKind(cards, 3);
    if (threeOfKind != null) {
      var remainingCards = cards.where((card) => !threeOfKind!.contains(card))
          .take(2).toList();
      return HandRank(
        400 + threeOfKind.first.rank.index,
        'Three of a Kind',
        [...threeOfKind, ...remainingCards]
      );
    }
    return null;
  }

  static HandRank? _checkTwoPair(List<Card> cards) {
    var firstPair = _findNOfAKind(cards, 2);
    if (firstPair != null) {
      var remainingCards = cards.where((card) => !firstPair!.contains(card)).toList();
      var secondPair = _findNOfAKind(remainingCards, 2);
      if (secondPair != null) {
        var kicker = remainingCards.where((card) => !secondPair.contains(card))
            .take(1).toList();
        return HandRank(
          300 + firstPair.first.rank.index * 13 + secondPair.first.rank.index,
          'Two Pair',
          [...firstPair, ...secondPair, ...kicker]
        );
      }
    }
    return null;
  }

  static HandRank? _checkOnePair(List<Card> cards) {
    var pair = _findNOfAKind(cards, 2);
    if (pair != null) {
      var remainingCards = cards.where((card) => !pair!.contains(card))
          .take(3).toList();
      return HandRank(
        200 + pair.first.rank.index,
        'One Pair',
        [...pair, ...remainingCards]
      );
    }
    return null;
  }

  static HandRank _getHighCard(List<Card> cards) {
    var topCards = cards.take(5).toList();
    return HandRank(100 + topCards.first.rank.index, 'High Card', topCards);
  }

  static List<Card>? _findNOfAKind(List<Card> cards, int n) {
    for (var rank in Rank.values.reversed) {
      final sameRankCards = cards.where((card) => card.rank == rank).toList();
      if (sameRankCards.length == n) {
        return sameRankCards;
      }
    }
    return null;
  }

  bool get isDraw => isDraw;

}