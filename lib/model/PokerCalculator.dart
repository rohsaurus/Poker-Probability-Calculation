import 'dart:math';
import 'dart:isolate';
import 'Card.dart';
import 'HandEvaluator.dart';
import 'Settings.dart';

class HandProbability {
  final String handName;
  final bool isDraw;
  int count = 0;
  double probability = 0.0;
  double maxProbability = 0.0;
  double minProbability = 1.0;
  Map<int, int> playerSpecificCounts = {};

  HandProbability(this.handName, {this.isDraw = false});
}

class SimulationResult {
  final Map<String, HandProbability> playerHands;
  final Map<String, HandProbability> opponentHands;

  SimulationResult(this.playerHands, this.opponentHands);

  List<HandProbability> getTopPlayerHands(int count) {
    final hands = playerHands.values.toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
    return hands.take(count).toList();
  }

  List<HandProbability> getTopOpponentHands(int count) {
    final hands = opponentHands.values.toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));
    return hands.take(count).toList();
  }
}

class PokerCalculator {
  static Future<SimulationResult> calculateHandProbabilities({
    required List<Card> playerCards,
    required int activePlayers,
    required List<Card> communityCards,
  }) async {
    final startTime = DateTime.now();
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _runSimulations,
      _SimulationParams(
        playerCards: playerCards,
        activePlayers: activePlayers,
        communityCards: communityCards,
        simulationCount: settings.simulationCount,
        sendPort: receivePort.sendPort,
      ),
    );

    final result = await receivePort.first as SimulationResult;
    settings.lastSimulationDuration = DateTime.now().difference(startTime);
    return result;
  }

  static void _runSimulations(_SimulationParams params) {
    final playerHands = <String, HandProbability>{};
    final opponentHands = <String, HandProbability>{};

    for (int i = 0; i < params.simulationCount; i++) {
      final deck = Deck();
      deck.removeCards([...params.playerCards, ...params.communityCards]);
      
      final List<List<Card>> simulatedOpponentHands = [];
      for (int j = 0; j < params.activePlayers - 1; j++) {
        simulatedOpponentHands.add([deck.drawCard(), deck.drawCard()]);
      }
      
      final remainingCommunityCards = 5 - params.communityCards.length;
      final List<Card> simulatedCommunityCards = [
        ...params.communityCards,
        for (int j = 0; j < remainingCommunityCards; j++) deck.drawCard(),
      ];
      
      // Track player hand
      final playerHandRank = HandEvaluator.evaluateHand(params.playerCards, simulatedCommunityCards);
      playerHands.putIfAbsent(playerHandRank.name, 
        () => HandProbability(playerHandRank.name, isDraw: playerHandRank.isDraw));
      playerHands[playerHandRank.name]!.count++;
      
      // Track opponent hands with player-specific counts
      for (int j = 0; j < simulatedOpponentHands.length; j++) {
        final opponentHand = simulatedOpponentHands[j];
        final opponentHandRank = HandEvaluator.evaluateHand(opponentHand, simulatedCommunityCards);
        opponentHands.putIfAbsent(opponentHandRank.name, 
          () => HandProbability(opponentHandRank.name, isDraw: opponentHandRank.isDraw));
        opponentHands[opponentHandRank.name]!.count++;
        
        // Track per-player counts
        var handProb = opponentHands[opponentHandRank.name]!;
        handProb.playerSpecificCounts.update(j, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    // Calculate probabilities
    for (var hand in playerHands.values) {
      hand.probability = hand.count / params.simulationCount;
    }
    
    for (var hand in opponentHands.values) {
      // Calculate average probability
      hand.probability = hand.count / (params.simulationCount * (params.activePlayers - 1));
      
      // Calculate min/max probabilities per opponent
      for (var entry in hand.playerSpecificCounts.entries) {
        double playerProb = entry.value / params.simulationCount;
        hand.maxProbability = max(hand.maxProbability, playerProb);
        hand.minProbability = min(hand.minProbability, playerProb);
      }
    }

    params.sendPort.send(SimulationResult(playerHands, opponentHands));
  }
}

class _SimulationParams {
  final List<Card> playerCards;
  final int activePlayers;
  final List<Card> communityCards;
  final int simulationCount;
  final SendPort sendPort;

  _SimulationParams({
    required this.playerCards,
    required this.activePlayers,
    required this.communityCards,
    required this.simulationCount,
    required this.sendPort,
  });
}