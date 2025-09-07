import 'package:flutter/material.dart';
import 'model/Settings.dart';

import '/model/Card.dart' as card_model;
import '/model/PokerCalculator.dart';
import '/model/HandEvaluator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Probability Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PokerCalculatorScreen(),
    );
  }
}

class PokerCalculatorScreen extends StatefulWidget {
  const PokerCalculatorScreen({super.key});

  @override
  State<PokerCalculatorScreen> createState() => _PokerCalculatorScreenState();
}

class _PokerCalculatorScreenState extends State<PokerCalculatorScreen> {
  String playerCard1 = '';
  String playerCard2 = '';
  int activePlayers = 2;
  List<String> communityCards = ['', '', '', '', ''];
  SimulationResult? simulationResult;
  bool isCalculating = false;

  final TextEditingController _card1Controller = TextEditingController();
  final TextEditingController _card2Controller = TextEditingController();
  final List<TextEditingController> _communityCardControllers = 
    List.generate(5, (index) => TextEditingController());

  @override
  void dispose() {
    _card1Controller.dispose();
    _card2Controller.dispose();
    for (var controller in _communityCardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _calculateProbability() async {
    try {
      // Check for empty cards
      if (playerCard1.isEmpty || playerCard2.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both of your cards')),
        );
        return;
      }

      // Collect all non-empty cards
      final allCards = [
        playerCard1.toUpperCase(),
        playerCard2.toUpperCase(),
        ...communityCards.where((card) => card.isNotEmpty).map((card) => card.toUpperCase())
      ];

      // Check for duplicates
      final uniqueCards = allCards.toSet();
      if (uniqueCards.length != allCards.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate cards detected. Each card can only be used once.')),
        );
        return;
      }

      setState(() {
        isCalculating = true;
      });

      final playerCards = [
        card_model.Card.fromString(playerCard1.toUpperCase()),
        card_model.Card.fromString(playerCard2.toUpperCase()),
      ];

      final validCommunityCards = communityCards
          .where((card) => card.isNotEmpty)
          .map((card) => card_model.Card.fromString(card.toUpperCase()))
          .toList();

      final result = await PokerCalculator.calculateHandProbabilities(
        playerCards: playerCards,
        activePlayers: activePlayers,
        communityCards: validCommunityCards,
      );

      setState(() {
        simulationResult = result;
        isCalculating = false;
      });
    } catch (e) {
      setState(() {
        isCalculating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid card format. Use format like "AS" for Ace of Spades')),
      );
    }
  }

  void _resetInputs() {
    setState(() {
      playerCard1 = '';
      playerCard2 = '';
      activePlayers = 2;
      communityCards = ['', '', '', '', ''];
      simulationResult = null;
      
      _card1Controller.clear();
      _card2Controller.clear();
      for (var controller in _communityCardControllers) {
        controller.clear();
      }
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('How to Use'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Card Input Format:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Use two characters: [Rank][Suit]\n'),
                Text('Ranks:'),
                Text('• 2-9: Use the number'),
                Text('• T: Ten'),
                Text('• J: Jack'),
                Text('• Q: Queen'),
                Text('• K: King'),
                Text('• A: Ace\n'),
                Text('Suits:'),
                Text('• H: Hearts'),
                Text('• D: Diamonds'),
                Text('• C: Clubs'),
                Text('• S: Spades\n'),
                Text('Examples:'),
                Text('• AS = Ace of Spades'),
                Text('• KH = King of Hearts'),
                Text('• TD = Ten of Diamonds'),
                Text('\nNote that probabilities are estimates based on Monte Carlo simulations and may vary slightly with each calculation.'),
                Text('Also, note that it might state that you have a high chance of a pair, but that includes pairs in the community cards only as well.')
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailedStats() {
    if (simulationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calculate probabilities first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detailed Statistics'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Hand Statistics:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...simulationResult!.getTopPlayerHands(5).map((hand) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: hand.isDraw
                              ? const Icon(Icons.trending_up, color: Colors.orange, size: 16)
                              : null,
                          ),
                          Text(
                            hand.handName,
                            style: TextStyle(
                              fontSize: 16,
                              color: hand.isDraw ? Colors.orange : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Text('Probability: ${(hand.probability * 100).toStringAsFixed(1)}%'),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 32),
                const Text('Opponent Hand Statistics:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...simulationResult!.getTopOpponentHands(5).map((hand) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            child: hand.isDraw
                              ? const Icon(Icons.trending_up, color: Colors.orange, size: 16)
                              : null,
                          ),
                          Text(
                            hand.handName,
                            style: TextStyle(
                              fontSize: 16,
                              color: hand.isDraw ? Colors.orange : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Average: ${(hand.probability * 100).toStringAsFixed(1)}%'),
                            Text('Maximum: ${(hand.maxProbability * 100).toStringAsFixed(1)}%'),
                            Text('Minimum: ${(hand.minProbability * 100).toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monte Carlo Simulation Count:'),
                  Text(
                    settings.simulationCount.toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: settings.simulationCount.toDouble(),
                    min: 10000,
                    max: 1000000,
                    divisions: 99,
                    label: settings.simulationCount.toString(),
                    onChanged: (value) {
                      setState(() {
                        settings.simulationCount = value.round();
                      });
                    },
                  ),
                  if (settings.lastSimulationDuration != null)
                    Text(
                      'Last simulation took: ${settings.lastSimulationDuration!.inMilliseconds / 1000} seconds',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Note: Higher simulation counts increase accuracy but take more time. The more unknowns (community cards and opponent hands), the more simulations needed for reliable results. Start out with 30,000 and increase if needed.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Probability Calculator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: isCalculating ? null : _showSettingsDialog,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: isCalculating ? null : _showDetailedStats,
            tooltip: 'Detailed Stats',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _card1Controller,
                    enabled: !isCalculating,
                    decoration: const InputDecoration(
                      hintText: 'First Card (e.g., AS for Ace of Spades)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => playerCard1 = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _card2Controller,
                    enabled: !isCalculating,
                    decoration: const InputDecoration(
                      hintText: 'Second Card (e.g., KH for King of Hearts)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => playerCard2 = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Number of Active Players',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: activePlayers.toDouble(),
              min: 2,
              max: 9,
              divisions: 7,
              label: activePlayers.toString(),
              onChanged: isCalculating ? null : (value) => setState(() => activePlayers = value.round()),
            ),
            const SizedBox(height: 24),
            const Text(
              'Community Cards',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: List.generate(
                5,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TextField(
                      controller: _communityCardControllers[index],
                      enabled: !isCalculating,
                      decoration: InputDecoration(
                        hintText: index < 3 ? 'Flop ${index + 1}' : index == 3 ? 'Turn' : 'River',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => communityCards[index] = value),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (simulationResult != null) ...[
                      const Text(
                        'Your Possible Hands:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...simulationResult!.getTopPlayerHands(5).map((hand) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            if (hand.isDraw)
                              const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${hand.handName}: ${(hand.probability * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: hand.isDraw ? Colors.orange : Colors.black,
                                  fontWeight: hand.isDraw ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      const Text(
                        'Opponent\'s Possible Hands:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...simulationResult!.getTopOpponentHands(5).map((hand) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            if (hand.isDraw)
                              const Icon(Icons.trending_up, color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${hand.handName}: ${(hand.probability * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: hand.isDraw ? Colors.orange : Colors.black,
                                  fontWeight: hand.isDraw ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isCalculating ? null : _calculateProbability,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: isCalculating
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Calculating...'),
                              ],
                            )
                          : const Text('Calculate Probabilities'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isCalculating ? null : _resetInputs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
