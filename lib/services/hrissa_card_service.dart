import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:lamaplay/models/hrissa_card.dart';

/// Service for loading and managing Hrissa Cards
class HrissaCardService {
  List<HrissaCard> _allCards = [];
  List<HrissaCategory> _categories = [];
  List<HrissaCard> _currentDeck = [];
  int _currentIndex = 0;
  String? _selectedCategory;

  List<HrissaCard> get allCards => _allCards;
  List<HrissaCategory> get categories => _categories;
  int get currentIndex => _currentIndex;
  int get totalCards => _currentDeck.length;
  bool get hasMoreCards => _currentIndex < _currentDeck.length;
  String? get selectedCategory => _selectedCategory;

  /// Load cards from JSON asset
  Future<void> loadCards() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/quizzes/hrissa_cards.json',
      );
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Load categories
      final categoriesJson = data['categories'] as List<dynamic>;
      _categories = categoriesJson
          .map((cat) => HrissaCategory.fromJson(cat as Map<String, dynamic>))
          .toList();

      // Load cards
      final cardsJson = data['cards'] as List<dynamic>;
      _allCards = cardsJson
          .map((card) => HrissaCard.fromJson(card as Map<String, dynamic>))
          .toList();

      // Initialize deck with all cards shuffled
      shuffleDeck();
    } catch (e) {
      throw Exception('Failed to load Hrissa cards: $e');
    }
  }

  /// Shuffle the entire deck
  void shuffleDeck() {
    _currentDeck = List.from(_allCards)..shuffle(Random());
    _currentIndex = 0;
    _selectedCategory = null;
  }

  /// Get next card from deck
  HrissaCard? getNextCard() {
    if (_currentIndex < _currentDeck.length) {
      return _currentDeck[_currentIndex++];
    }
    return null;
  }

  /// Get previous card (if available)
  HrissaCard? getPreviousCard() {
    if (_currentIndex > 1) {
      _currentIndex -=
          2; // Go back 2 positions (current was already incremented)
      return getNextCard();
    }
    return null;
  }

  /// Get current card without advancing
  HrissaCard? getCurrentCard() {
    if (_currentIndex > 0 && _currentIndex <= _currentDeck.length) {
      return _currentDeck[_currentIndex - 1];
    }
    return null;
  }

  /// Filter deck by category
  void filterByCategory(String categoryId) {
    _selectedCategory = categoryId;
    _currentDeck =
        _allCards.where((card) => card.category == categoryId).toList()
          ..shuffle(Random());
    _currentIndex = 0;
  }

  /// Clear category filter and show all cards
  void clearCategoryFilter() {
    shuffleDeck();
  }

  /// Get a random card from entire collection
  HrissaCard getRandomCard() {
    return _allCards[Random().nextInt(_allCards.length)];
  }

  /// Get category info by ID
  HrissaCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get cards count by category
  Map<String, int> getCardCountsByCategory() {
    final counts = <String, int>{};
    for (final card in _allCards) {
      counts[card.category] = (counts[card.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Restart deck from beginning
  void restart() {
    _currentIndex = 0;
  }

  /// Check if there are more cards
  bool canGoNext() {
    return _currentIndex < _currentDeck.length;
  }

  /// Check if can go to previous card
  bool canGoPrevious() {
    return _currentIndex > 1;
  }
}
