import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/models/hrissa_card.dart';
import 'package:lamaplay/services/hrissa_card_service.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Multiplayer Hrissa Cards game - Host controls card flow, players vote and score
class HrissaCardsMultiplayerScreen extends StatefulWidget {
  final String sessionId;
  final bool isHost;

  const HrissaCardsMultiplayerScreen({
    super.key,
    required this.sessionId,
    required this.isHost,
  });

  @override
  State<HrissaCardsMultiplayerScreen> createState() =>
      _HrissaCardsMultiplayerScreenState();
}

class _HrissaCardsMultiplayerScreenState
    extends State<HrissaCardsMultiplayerScreen> {
  final HrissaCardService _cardService = HrissaCardService();
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  String? _error;
  String? _playerVote;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _cardService.loadCards();

      if (widget.isHost) {
        // Host: Initialize first card
        await _initializeFirstCard();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeFirstCard() async {
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId);

    final firstCard = _cardService.getNextCard();
    if (firstCard != null) {
      final category = _cardService.getCategoryById(firstCard.category);
      await sessionRef.update({
        'hrissaCard': {
          'cardIndex': 0,
          'question': firstCard.question,
          'category': firstCard.category,
          'categoryName': category?.name ?? '',
          'categoryIcon': category?.icon ?? '🌶️',
          'difficulty': firstCard.difficulty,
          'spicyLevel': firstCard.spicyLevel,
          'categoryColor': category?.color ?? '#FF5733',
          'categoryColorLight': category?.colorLight ?? '#FFA07A',
          'state': 'showing', // showing, revealing, scoring
          'votingTarget': null, // playerId being voted on
        },
      });
    }
  }

  Future<void> _nextCard() async {
    SoundService().play(SoundEffect.buttonTap);

    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId);

    // Clear votes
    await _clearVotes();

    // Get next card
    final nextCard = _cardService.getNextCard();
    if (nextCard == null) {
      // Deck finished, reshuffle
      _cardService.shuffleDeck();
      final card = _cardService.getNextCard();
      if (card != null) {
        await _updateSessionCard(sessionRef, card);
      }
    } else {
      await _updateSessionCard(sessionRef, nextCard);
    }
  }

  Future<void> _updateSessionCard(
    DocumentReference sessionRef,
    HrissaCard card,
  ) async {
    final category = _cardService.getCategoryById(card.category);
    await sessionRef.update({
      'hrissaCard': {
        'cardIndex': _cardService.currentIndex,
        'question': card.question,
        'category': card.category,
        'categoryName': category?.name ?? '',
        'categoryIcon': category?.icon ?? '🌶️',
        'difficulty': card.difficulty,
        'spicyLevel': card.spicyLevel,
        'categoryColor': category?.color ?? '#FF5733',
        'categoryColorLight': category?.colorLight ?? '#FFA07A',
        'state': 'showing',
        'votingTarget': null,
      },
    });

    setState(() {
      _hasVoted = false;
      _playerVote = null;
    });
  }

  Future<void> _clearVotes() async {
    final votesSnap = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('hrissaVotes')
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in votesSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _startVoting(String targetPlayerId) async {
    SoundService().play(SoundEffect.buttonTap);

    // Clear old votes from Firestore first
    await _clearVotes();

    // Reset vote state for new voting round
    setState(() {
      _hasVoted = false;
      _playerVote = null;
    });

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
          'hrissaCard.state': 'answered', // Player answers first
          'hrissaCard.votingTarget': targetPlayerId,
        });
  }

  Future<void> _startJudgment() async {
    SoundService().play(SoundEffect.buttonTap);

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .update({
          'hrissaCard.state': 'voting', // Now players judge
        });
  }

  Future<void> _submitVote(String vote) async {
    if (_hasVoted) return;

    SoundService().play(SoundEffect.buttonTap);

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('hrissaVotes')
        .doc(_auth.uid!)
        .set({
          'playerId': _auth.uid!,
          'vote': vote, // 'truth' or 'lie'
          'votedAt': FieldValue.serverTimestamp(),
        });

    setState(() {
      _hasVoted = true;
      _playerVote = vote;
    });
  }

  Future<void> _revealResults() async {
    try {
      SoundService().play(SoundEffect.buttonTap);

      final sessionRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId);

      final sessionSnap = await sessionRef.get();
      if (!sessionSnap.exists) {
        throw Exception('Session not found');
      }

      final cardData =
          sessionSnap.data()?['hrissaCard'] as Map<String, dynamic>?;
      if (cardData == null) {
        throw Exception('Card data not found');
      }

      final spicyLevel = cardData['spicyLevel'] as int? ?? 1;
      final targetPlayerId = cardData['votingTarget'] as String?;

      if (targetPlayerId != null) {
        // Get votes and count them
        final votesSnap = await sessionRef.collection('hrissaVotes').get();

        int truthVotes = 0; // Honest answer
        int lieVotes = 0; // Lie/dishonest

        for (final voteDoc in votesSnap.docs) {
          final vote = voteDoc.data()['vote'] as String?;
          if (vote == 'truth') truthVotes++;
          if (vote == 'lie') lieVotes++;
        }

        // Majority judgment
        final majorityVote = truthVotes > lieVotes ? 'truth' : 'lie';
        final totalVotes = truthVotes + lieVotes;

        // Hot seat player gets points if majority says truth
        if (majorityVote == 'truth') {
          final truthPoints = spicyLevel * 100; // 100-500 for honesty
          await sessionRef.collection('players').doc(targetPlayerId).update({
            'score': FieldValue.increment(truthPoints),
          });
        }

        // Voters get points for participating
        final participationBonus = spicyLevel * 20;
        final batch = FirebaseFirestore.instance.batch();
        for (final voteDoc in votesSnap.docs) {
          final voterId = voteDoc.data()['playerId'] as String;
          if (voterId != targetPlayerId) {
            final playerRef = sessionRef.collection('players').doc(voterId);
            batch.update(playerRef, {
              'score': FieldValue.increment(participationBonus),
            });
          }
        }
        await batch.commit();

        // Update state with voting results
        await sessionRef.update({
          'hrissaCard.state': 'scoring',
          'hrissaCard.majorityVote': majorityVote,
          'hrissaCard.truthVotes': truthVotes,
          'hrissaCard.lieVotes': lieVotes,
          'hrissaCard.totalVotes': totalVotes,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في عرض النتائج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                'جاري تحميل اللعبة...',
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
          child: Text(_error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a1a2e),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final sessionData = snap.data!.data() as Map<String, dynamic>?;
        final cardData = sessionData?['hrissaCard'] as Map<String, dynamic>?;

        if (cardData == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF1a1a2e),
            body: Center(
              child: Text(
                'في انتظار الكارت...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        return _buildGameScreen(cardData);
      },
    );
  }

  Widget _buildGameScreen(Map<String, dynamic> cardData) {
    final mainColor = _parseColor(
      cardData['categoryColor'] as String? ?? '#FF5733',
    );
    final lightColor = _parseColor(
      cardData['categoryColorLight'] as String? ?? '#FFA07A',
    );
    final state = cardData['state'] as String? ?? 'showing';
    final votingTarget = cardData['votingTarget'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header with scoreboard
            _buildHeader(),

            // Card display
            Expanded(
              child: Center(child: _buildCard(cardData, mainColor, lightColor)),
            ),

            // Action area based on state and role
            _buildActionArea(state, votingTarget, mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('players')
          .orderBy('score', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final players = snap.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      '🌶️ الهريسة 2 - جماعي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              // Top 3 players compact display
              if (players.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: players.take(3).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final nickname = data['nickname'] as String? ?? 'Player';
                    final score = data['score'] as int? ?? 0;
                    final index = players.indexOf(doc);
                    final medal = index == 0
                        ? '🥇'
                        : index == 1
                        ? '🥈'
                        : '🥉';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(medal, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${nickname.substring(0, nickname.length > 8 ? 8 : nickname.length)} $score',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard(
    Map<String, dynamic> cardData,
    Color mainColor,
    Color lightColor,
  ) {
    final question = cardData['question'] as String? ?? '';
    final categoryName = cardData['categoryName'] as String? ?? '';
    final categoryIcon = cardData['categoryIcon'] as String? ?? '🌶️';
    final difficulty = cardData['difficulty'] as String? ?? 'easy';
    final spicyLevel = cardData['spicyLevel'] as int? ?? 1;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
        maxWidth: MediaQuery.of(context).size.width - 48,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category badge
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            categoryIcon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Question
              Flexible(
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Difficulty and spicy level
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Spicy level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Icon(
                        Icons.local_fire_department,
                        color: index < spicyLevel
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Difficulty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getDifficultyText(difficulty),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildActionArea(String state, String? votingTarget, Color mainColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show voting results when in scoring state
            if (state == 'scoring') ...[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(widget.sessionId)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();

                  final cardData = snap.data!.data() as Map<String, dynamic>?;
                  final hrissaCard =
                      cardData?['hrissaCard'] as Map<String, dynamic>?;

                  if (hrissaCard == null) return const SizedBox.shrink();

                  final majorityVote = hrissaCard['majorityVote'] as String?;
                  final truthVotes = hrissaCard['truthVotes'] as int? ?? 0;
                  final lieVotes = hrissaCard['lieVotes'] as int? ?? 0;
                  final spicyLevel = hrissaCard['spicyLevel'] as int? ?? 1;

                  return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: majorityVote == 'truth'
                                ? [Colors.green, Colors.green.shade700]
                                : [Colors.red, Colors.red.shade700],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (majorityVote == 'truth'
                                          ? Colors.green
                                          : Colors.red)
                                      .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'نتيجة التصويت:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Flexible(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'صادق',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$truthVotes صوت',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 2,
                                  height: 60,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                Flexible(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'كذاب',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$lieVotes صوت',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                majorityVote == 'truth'
                                    ? '🎯 الأغلبية: صادق!'
                                    : '🎯 الأغلبية: كذاب!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              majorityVote == 'truth'
                                  ? 'النقاط: ${spicyLevel * 100} (للاعب) + ${spicyLevel * 20} (للمصوتين)'
                                  : 'النقاط: 0 (للاعب) + ${spicyLevel * 20} (للمصوتين)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.8, 0.8), duration: 500.ms);
                },
              ),
              const SizedBox(height: 20),
            ],

            // Host controls (always show if host)
            if (widget.isHost) ...[
              if (state == 'showing' || state == 'scoring') ...[
                // Select player for hot seat
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(widget.sessionId)
                      .collection('players')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();

                    final players = snap.data!.docs;

                    return Column(
                      children: [
                        const Text(
                          'اختار لاعب للكرسي الساخن:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: players.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nickname =
                                data['nickname'] as String? ?? 'Player';
                            final playerId = doc.id;

                            return ElevatedButton(
                              onPressed: () => _startVoting(playerId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                nickname,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _nextCard,
                          icon: const Icon(Icons.skip_next),
                          label: const Text('كارت جديد'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            minimumSize: const Size(double.infinity, 0),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],

            // Answered state - player has given answer
            if (state == 'answered') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.hearing, color: Colors.blue, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'اسمعوا الإجابة! 👂',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اللاعب في الكرسي الساخن باش يجاوب دابا',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (widget.isHost) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _startJudgment,
                  icon: const Icon(Icons.gavel),
                  label: const Text('ابدأ التصويت'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                ),
              ],
            ],

            // Voting section (for both host and players)
            if (state == 'voting') ...[
              if (votingTarget != _auth.uid) ...[
                // Not in hot seat - can vote
                if (!_hasVoted) ...[
                  Column(
                    children: [
                      const Text(
                        'هل الإجابة صادقة؟',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'صوّت بناء على إجابة اللاعب',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _submitVote('truth'),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('صادق'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _submitVote('lie'),
                          icon: const Icon(Icons.cancel),
                          label: const Text('كذاب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _playerVote == 'truth'
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _playerVote == 'truth'
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'صوّتت: ${_playerVote == "truth" ? "صادق" : "كذاب"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Host reveal button
                if (widget.isHost) ...[
                  const SizedBox(height: 16),
                  _buildVotingStatus(votingTarget),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _revealResults,
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض النتائج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ] else ...[
                // In hot seat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [mainColor, mainColor.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'أنت في الكرسي الساخن! 🔥',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Host reveal button even when in hot seat
                if (widget.isHost) ...[
                  const SizedBox(height: 16),
                  _buildVotingStatus(votingTarget),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _revealResults,
                    icon: const Icon(Icons.visibility),
                    label: const Text('عرض النتائج'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ],
              ],
            ],

            // Non-host waiting message
            if (!widget.isHost && (state == 'showing' || state == 'scoring'))
              const Text(
                'في انتظار المضيف...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingStatus(String? votingTarget) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .collection('hrissaVotes')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final votes = snap.data!.docs;
        final totalPlayers = votes.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'الأصوات:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalPlayers لاعب صوّت',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}
