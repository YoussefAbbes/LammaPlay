import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/widgets/answer_feedback.dart';
import 'package:lamaplay/services/global_leaderboard_service.dart';

class PodiumScreen extends StatefulWidget {
  final String sessionId;
  const PodiumScreen({super.key, required this.sessionId});

  @override
  State<PodiumScreen> createState() => _PodiumScreenState();
}

class _PodiumScreenState extends State<PodiumScreen> {
  final _globalLeaderboard = GlobalLeaderboardService();
  bool _globalStatsUpdated = false;

  @override
  void initState() {
    super.initState();
    _updateGlobalStats();
  }

  Future<void> _updateGlobalStats() async {
    if (_globalStatsUpdated) return;

    try {
      final sessionRef = FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId);
      final playersSnap = await sessionRef.collection('players').get();

      for (final playerDoc in playersSnap.docs) {
        final data = playerDoc.data();
        await _globalLeaderboard.updateGlobalStats(
          playerId: playerDoc.id,
          nickname: data['nickname'] ?? 'Player',
          sessionScore: (data['score'] as num?)?.toInt() ?? 0,
          correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
          totalAnswers: (data['totalAnswers'] as num?)?.toInt() ?? 0,
        );
      }

      _globalStatsUpdated = true;
    } catch (e) {
      print('Error updating global stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId);
    final playersRef = sessionRef.collection('players');

    return StreamBuilder(
      stream: sessionRef.snapshots(),
      builder: (context, sessionSnap) {
        return StreamBuilder(
          stream: playersRef.snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];

            final players =
                docs
                    .map(
                      (d) => {
                        'id': d.id,
                        'name': d.data()['nickname'] ?? d.id.substring(0, 6),
                        'score': (d.data()['score'] as num? ?? 0).toInt(),
                        'streak': (d.data()['streak'] as num? ?? 0).toInt(),
                        'correctAnswers':
                            (d.data()['correctAnswers'] as num? ?? 0).toInt(),
                        'totalAnswers': (d.data()['totalAnswers'] as num? ?? 0)
                            .toInt(),
                      },
                    )
                    .toList()
                  ..sort((a, b) => (b['score'] as int) - (a['score'] as int));

            final hasPerfectScore =
                players.isNotEmpty && (players[0]['score'] as int) > 0;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                title:
                    Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '🎉',
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Victory!',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .shimmer(duration: 2000.ms),
                elevation: 0,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFFD93D),
                        Color(0xFF6BCB77),
                        Color(0xFF4D96FF),
                      ],
                    ),
                  ),
                ),
                foregroundColor: Colors.white,
              ),
              body: Stack(
                children: [
                  // Show confetti for winner
                  if (hasPerfectScore) const ConfettiOverlay(),

                  // Main content
                  players.isEmpty
                      ? const Center(child: Text('No players'))
                      : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Quiz complete banner
                              Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.shade400,
                                          Colors.orange.shade400,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          '✨ GAME OVER ✨',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${players.length} epic player${players.length != 1 ? 's' : ''} battled! 🔥',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white.withOpacity(
                                              0.95,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: -0.3, end: 0)
                                  .shimmer(delay: 600.ms, duration: 1500.ms),
                              const SizedBox(height: 24),

                              // Top 3 podium
                              _TopThree(players: players.take(3).toList())
                                  .animate()
                                  .fadeIn(delay: 400.ms, duration: 800.ms)
                                  .slideY(begin: 0.3, end: 0),
                              const SizedBox(height: 24),

                              // Full rankings
                              Expanded(
                                child: Card(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'Final Rankings',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: players.length,
                                          itemBuilder: (context, i) {
                                            final p = players[i];
                                            final isTop3 = i < 3;
                                            return ListTile(
                                                  tileColor: isTop3
                                                      ? Colors.amber[50]
                                                      : null,
                                                  leading: Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: isTop3
                                                          ? Colors.amber
                                                          : Colors.grey[300],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        '#${i + 1}',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: isTop3
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    p['name'] as String,
                                                    style: TextStyle(
                                                      fontWeight: isTop3
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                  subtitle: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '✅ ${p['correctAnswers']}/${p['totalAnswers']} correct',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.green[700],
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      if (p['streak'] as int >
                                                          2)
                                                        Text(
                                                          '🔥 ${p['streak']} streak',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .orange,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                  trailing: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (i == 0)
                                                        const Text(
                                                          '🥇 ',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                          ),
                                                        ),
                                                      if (i == 1)
                                                        const Text(
                                                          '🥈 ',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                          ),
                                                        ),
                                                      if (i == 2)
                                                        const Text(
                                                          '🥉 ',
                                                          style: TextStyle(
                                                            fontSize: 24,
                                                          ),
                                                        ),
                                                      Text(
                                                        '${p['score']} pts',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: isTop3
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                    .normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                                .animate()
                                                .fadeIn(
                                                  delay: (600 + (i * 100)).ms,
                                                  duration: 400.ms,
                                                )
                                                .slideX(begin: -0.2, end: 0);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                              ),

                              const SizedBox(height: 16),

                              // Action button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    // Clean up session before leaving
                                    try {
                                      await sessionRef.update({
                                        'status': 'completed',
                                        'completedAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                    } catch (e) {
                                      // Ignore cleanup errors
                                    }

                                    if (context.mounted) {
                                      // Navigate to home and remove all previous routes
                                      Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        '/',
                                        (route) => false,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.home),
                                  label: const Text('Exit to Home'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopThree extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  const _TopThree({required this.players});
  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    final trophies = ['🥇', '🥈', '🥉'];
    final heights = [120.0, 100.0, 90.0];
    final colors = [Colors.amber[100], Colors.grey[300], Colors.brown[100]];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(players.length.clamp(0, 3), (i) {
        final p = players[i];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                // Trophy emoji
                Text(trophies[i], style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                // Player name
                Text(
                  p['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Score
                Text(
                  '${p['score']} pts',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                // Podium platform
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors[i]!, colors[i]!.withOpacity(0.6)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: i == 0 ? Colors.amber : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
