import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/widgets/answer_feedback.dart';

class PodiumScreen extends StatelessWidget {
  final String sessionId;
  const PodiumScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
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
                      },
                    )
                    .toList()
                  ..sort((a, b) => (b['score'] as int) - (a['score'] as int));

            final hasPerfectScore =
                players.isNotEmpty && (players[0]['score'] as int) > 0;

            return Scaffold(
              backgroundColor: Colors.grey[50],
              appBar: AppBar(
                title: const Row(
                  children: [
                    Text('🏆 '),
                    Text(
                      'Final Results',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                elevation: 0,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple[600]!,
                        Colors.purple[400]!,
                        Colors.deepPurple[400]!,
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
                              // Quiz name
                              Center(
                                    child: Text(
                                      'Quiz Complete!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 600.ms)
                                  .slideY(begin: -0.3, end: 0),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  '${players.length} player${players.length != 1 ? 's' : ''} competed',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ).animate().fadeIn(
                                delay: 200.ms,
                                duration: 600.ms,
                              ),
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
                                                  subtitle:
                                                      p['streak'] as int > 2
                                                      ? Text(
                                                          '🔥 ${p['streak']} streak',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .orange,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        )
                                                      : null,
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

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.home),
                                      label: const Text('Exit'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Navigate back to lobby with same quiz
                                        Navigator.of(
                                          context,
                                        ).popUntil((route) => route.isFirst);
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Play Again'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
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
