import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/screens/hrissa_cards_multiplayer_screen.dart';

/// Host lobby for Hrissa Cards multiplayer - waiting for players to join
class HrissaCardsHostLobbyScreen extends StatefulWidget {
  final String sessionId;
  final String pin;

  const HrissaCardsHostLobbyScreen({
    super.key,
    required this.sessionId,
    required this.pin,
  });

  @override
  State<HrissaCardsHostLobbyScreen> createState() =>
      _HrissaCardsHostLobbyScreenState();
}

class _HrissaCardsHostLobbyScreenState
    extends State<HrissaCardsHostLobbyScreen> {
  bool _isStarting = false;

  Future<void> _startGame() async {
    if (_isStarting) return;

    setState(() => _isStarting = true);

    try {
      SoundService().play(SoundEffect.buttonTap);

      // Update session status to started
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .update({
            'status': 'in_progress',
            'startedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      // Navigate to game screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HrissaCardsMultiplayerScreen(
            sessionId: widget.sessionId,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isStarting = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في بدء اللعبة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('sessions')
                      .doc(widget.sessionId)
                      .collection('players')
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    final players = snap.data!.docs;

                    return Column(
                      children: [
                        _buildPinDisplay(),
                        const SizedBox(height: 32),
                        _buildPlayersList(players),
                        const SizedBox(height: 24),
                        _buildStartButton(players.length),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Column(
      children: [
        Text(
          'رمز الجلسة',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
        ),
        const SizedBox(height: 12),
        GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: widget.pin));
                SoundService().play(SoundEffect.buttonTap);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ الرمز'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5733), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5733).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.pin,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.copy, color: Colors.white, size: 24),
                  ],
                ),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
      ],
    );
  }

  Widget _buildPlayersList(List<QueryDocumentSnapshot> players) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'اللاعبون (${players.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (players.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 64,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'في انتظار اللاعبين...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player =
                        players[index].data() as Map<String, dynamic>;
                    final nickname = player['nickname'] as String? ?? 'Player';
                    final score = player['score'] as int? ?? 0;

                    return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF5733),
                                      Color(0xFFFF8C42),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '$score نقطة',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: (index * 100).ms)
                        .slideX(
                          begin: -0.2,
                          duration: 300.ms,
                          delay: (index * 100).ms,
                        );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(int playerCount) {
    final canStart = playerCount >= 2 && !_isStarting;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (playerCount < 2)
            Text(
              'يحتاج 2 لاعبين على الأقل',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canStart ? _startGame : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canStart
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: canStart ? 8 : 0,
                  ),
                  child: _isStarting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ابدأ اللعبة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )
              .animate(
                onPlay: (controller) => canStart ? controller.repeat() : null,
              )
              .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
        ],
      ),
    );
  }
}
