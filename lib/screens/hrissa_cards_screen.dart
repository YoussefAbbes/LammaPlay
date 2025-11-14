import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/models/hrissa_card.dart';
import 'package:lamaplay/services/hrissa_card_service.dart';
import 'package:lamaplay/services/sound_service.dart';

/// Standalone Hrissa Cards game screen
class HrissaCardsScreen extends StatefulWidget {
  const HrissaCardsScreen({super.key});

  @override
  State<HrissaCardsScreen> createState() => _HrissaCardsScreenState();
}

class _HrissaCardsScreenState extends State<HrissaCardsScreen> {
  final HrissaCardService _cardService = HrissaCardService();
  HrissaCard? _currentCard;
  HrissaCategory? _currentCategory;
  bool _isLoading = true;
  String? _error;
  bool _showCategoryPicker = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      await _cardService.loadCards();
      final firstCard = _cardService.getNextCard();
      if (firstCard != null) {
        setState(() {
          _currentCard = firstCard;
          _currentCategory = _cardService.getCategoryById(firstCard.category);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No cards available';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextCard() {
    final nextCard = _cardService.getNextCard();
    if (nextCard == null) {
      // Deck finished, reshuffle
      _cardService.shuffleDeck();
      final card = _cardService.getNextCard();
      if (card != null) {
        setState(() {
          _currentCard = card;
          _currentCategory = _cardService.getCategoryById(card.category);
        });
      }
    } else {
      setState(() {
        _currentCard = nextCard;
        _currentCategory = _cardService.getCategoryById(nextCard.category);
      });
    }
    SoundService().play(SoundEffect.buttonTap);
  }

  void _previousCard() {
    final prevCard = _cardService.getPreviousCard();
    if (prevCard != null) {
      setState(() {
        _currentCard = prevCard;
        _currentCategory = _cardService.getCategoryById(prevCard.category);
      });
    }
    SoundService().play(SoundEffect.buttonTap);
  }

  void _shuffleDeck() {
    setState(() {
      _cardService.shuffleDeck();
      _currentCard = _cardService.getNextCard();
      _currentCategory = _cardService.getCategoryById(_currentCard!.category);
    });
    SoundService().play(SoundEffect.buttonTap);
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      if (categoryId == null) {
        _cardService.clearCategoryFilter();
      } else {
        _cardService.filterByCategory(categoryId);
      }
      _currentCard = _cardService.getNextCard();
      if (_currentCard != null) {
        _currentCategory = _cardService.getCategoryById(_currentCard!.category);
      }
      _showCategoryPicker = false;
    });
    SoundService().play(SoundEffect.buttonTap);
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return 'ساهل';
      case 'medium':
        return 'متوسط';
      case 'hard':
        return 'صعيب';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل الكروت...',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'خطأ في تحميل اللعبة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentCard == null || _currentCategory == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: const Center(
          child: Text(
            'ما فماش كروت',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      );
    }

    final mainColor = _parseColor(_currentCategory!.color);
    final lightColor = _parseColor(_currentCategory!.colorLight);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              '🌶️ الهريسة 2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'لعبة الكروت',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showCategoryPicker = !_showCategoryPicker;
                          });
                        },
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Card
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.velocity.pixelsPerSecond.dx > 300) {
                        // Swipe right - previous card
                        if (_cardService.canGoPrevious()) {
                          _previousCard();
                        }
                      } else if (details.velocity.pixelsPerSecond.dx < -300) {
                        // Swipe left - next card
                        if (_cardService.canGoNext()) {
                          _nextCard();
                        }
                      }
                    },
                    child: Center(
                      child:
                          Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [mainColor, lightColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mainColor.withOpacity(0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Category badge
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _currentCategory!.icon,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _currentCategory!.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Question
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            _currentCard!.question,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 32,
                                              fontWeight: FontWeight.w600,
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),

                                      // Difficulty and spicy level
                                      Column(
                                        children: [
                                          // Spicy level
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              5,
                                              (index) => Icon(
                                                Icons.local_fire_department,
                                                color:
                                                    index <
                                                        _currentCard!.spicyLevel
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                        0.3,
                                                      ),
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          // Difficulty badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.25,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getDifficultyText(
                                                _currentCard!.difficulty,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Previous button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _cardService.canGoPrevious()
                                  ? _previousCard
                                  : null,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('السابق'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[900],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shuffle button
                          ElevatedButton(
                            onPressed: _shuffleDeck,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Icon(Icons.shuffle, size: 24),
                          ),
                          const SizedBox(width: 12),
                          // Next button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _cardService.canGoNext()
                                  ? _nextCard
                                  : null,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('التالي'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[900],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress indicator
                      Text(
                        '${_cardService.currentIndex} / ${_cardService.totalCards} كروت',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Category picker overlay
            if (_showCategoryPicker)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showCategoryPicker = false;
                    });
                  },
                  child: Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2d2d44),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'اختار نوع الكروت',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // All categories option
                            _CategoryOption(
                              icon: '🎲',
                              name: 'كل الأنواع',
                              color: Colors.purple,
                              isSelected: _cardService.selectedCategory == null,
                              onTap: () => _selectCategory(null),
                            ),
                            const SizedBox(height: 12),
                            // Individual categories
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: _cardService.categories
                                      .map(
                                        (cat) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _CategoryOption(
                                            icon: cat.icon,
                                            name: cat.name,
                                            color: _parseColor(cat.color),
                                            isSelected:
                                                _cardService.selectedCategory ==
                                                cat.id,
                                            onTap: () =>
                                                _selectCategory(cat.id),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String icon;
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.icon,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
