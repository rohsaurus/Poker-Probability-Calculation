# Poker Probability Calculator

A Flutter application that calculates poker hand probabilities using Monte Carlo simulation.

## How to Use

### Card Input Format
- Use two-character format: [Rank][Suit]
- **Ranks**: 2-9, T (10), J (Jack), Q (Queen), K (King), A (Ace)
- **Suits**: H (Hearts), D (Diamonds), C (Clubs), S (Spades)
- Examples: 
  - AS = Ace of Spades
  - KH = King of Hearts
  - TD = Ten of Diamonds

### Features
1. **Player Cards**: Enter your two hole cards
2. **Number of Players**: Adjust the slider (2-9 players)
3. **Community Cards**: Enter known community cards (Flop, Turn, River)
4. **Results Show**:
   - Your top 3 most likely hands with probabilities
   - Opponents' top 3 most likely hands with probabilities

### Example
Input:
- Your Cards: AH, KH
- Players: 3
- Flop: QH, JH, 2C

The calculator will simulate thousands of possible outcomes to determine hand probabilities.