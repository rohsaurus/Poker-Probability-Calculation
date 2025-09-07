import 'dart:math';

enum Suit { hearts, diamonds, clubs, spades }
enum Rank { two, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace }

class Card {
  final Rank rank;
  final Suit suit;

  Card(this.rank, this.suit);

  factory Card.fromString(String card) {
    if (card.length != 2) throw FormatException('Invalid card format');
    
    final rankChar = card[0].toUpperCase();
    final suitChar = card[1].toUpperCase();
    
    final rank = switch (rankChar) {
      '2' => Rank.two,
      '3' => Rank.three,
      '4' => Rank.four,
      '5' => Rank.five,
      '6' => Rank.six,
      '7' => Rank.seven,
      '8' => Rank.eight,
      '9' => Rank.nine,
      'T' => Rank.ten,
      'J' => Rank.jack,
      'Q' => Rank.queen,
      'K' => Rank.king,
      'A' => Rank.ace,
      _ => throw FormatException('Invalid rank'),
    };

    final suit = switch (suitChar) {
      'H' => Suit.hearts,
      'D' => Suit.diamonds,
      'C' => Suit.clubs,
      'S' => Suit.spades,
      _ => throw FormatException('Invalid suit'),
    };

    return Card(rank, suit);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card && runtimeType == other.runtimeType && rank == other.rank && suit == other.suit;

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;

  @override
  String toString() => '${rank.name}-${suit.name}';
}

class Deck {
  final List<Card> cards = [];
  final random = Random();

  Deck() {
    for (var suit in Suit.values) {
      for (var rank in Rank.values) {
        cards.add(Card(rank, suit));
      }
    }
  }

  void removeCards(List<Card> cardsToRemove) {
    for (var card in cardsToRemove) {
      cards.removeWhere((c) => c == card);
    }
  }

  Card drawCard() {
    if (cards.isEmpty) throw StateError('No cards left in deck');
    final index = random.nextInt(cards.length);
    return cards.removeAt(index);
  }
}
