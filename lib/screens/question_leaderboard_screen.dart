import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Shows leaderboard after each question with points gained
class QuestionLeaderboardScreen extends StatelessWidget {
  final String sessionId;
  final int qIndex;

  const QuestionLeaderboardScreen({
    super.key,
    required this.sessionId,
    required this.qIndex,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        // Auto-navigate back when state changes
        if (sessionSnapshot.hasData) {
          final sessionData = sessionSnapshot.data!.data();
          final currentState = sessionData?['questionState'] as String? ?? '';
          final currentIndex =
              (sessionData?['currentQuestionIndex'] as num?)?.toInt() ?? -1;

          // Auto-navigate back when state changes from reveal or question changes
          if (currentState != 'reveal' || currentIndex != qIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                // Check if session ended
                final status = sessionData?['status'] as String? ?? '';
                if (status == 'ended' || currentState == 'ended') {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/podium', arguments: sessionId);
                } else {
                  // Check if user is the host
                  final hostId = sessionData?['hostId'] as String?;
                  final isHost = hostId == auth.uid;

                  // Navigate to appropriate screen
                  if (isHost) {
                    Navigator.of(context).pushReplacementNamed(
                      '/questionHost',
                      arguments: sessionId,
                    );
                  } else {
                    Navigator.of(context).pushReplacementNamed(
                      '/questionPlayer',
                      arguments: sessionId,
                    );
                  }
                }
              }
            });
          }
        }

        // Always return the Scaffold UI
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.purple[100]!, Colors.purple[50]!, Colors.white],
              ),
            ),
            child: SafeArea(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(sessionId)
                    .collection('results')
                    .doc('q_$qIndex')
                    .snapshots(),
                builder: (context, resultsSnap) {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('sessions')
                        .doc(sessionId)
                        .collection('players')
                        .snapshots(),
                    builder: (context, playersSnap) {
                      if (!playersSnap.hasData || !resultsSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final players = playersSnap.data!.docs;
                      final resultsData = resultsSnap.data?.data();
                      final perPlayer =
                          (resultsData?['perPlayer']
                              as Map<dynamic, dynamic>?) ??
                          {};

                      // Build leaderboard data
                      final leaderboard = players.map((doc) {
                        final playerId = doc.id;
                        final playerData = doc.data();
                        final result =
                            perPlayer[playerId] as Map<dynamic, dynamic>?;

                        return {
                          'id': playerId,
                          'name': playerData['nickname'] ?? 'Player',
                          'totalScore':
                              (playerData['score'] as num?)?.toInt() ?? 0,
                          'pointsGained':
                              (result?['delta'] as num?)?.toInt() ?? 0,
                          'correct': result?['correct'] == true,
                          'streak':
                              (playerData['streak'] as num?)?.toInt() ?? 0,
                          'isUnique': result?['isUnique'] == true,
                          'timesSelected': (result?['timesSelected'] as num?)
                              ?.toInt(),
                        };
                      }).toList();

                      // Sort by total score
                      leaderboard.sort(
                        (a, b) => (b['totalScore'] as int).compareTo(
                          a['totalScore'] as int,
                        ),
                      );

                      return Column(
                        children: [
                          // Header
                          Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 32,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.purple[700]!,
                                      Colors.purple[500]!,
                                      Colors.deepPurple[400]!,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            '🏆',
                                            style: TextStyle(fontSize: 56),
                                          ),
                                        )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(reverse: true),
                                        )
                                        .scale(duration: 1000.ms),
                                    const SizedBox(height: 20),
                                    const Text(
                                          '⚡ RANKINGS ⚡',
                                          style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                          ),
                                        )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(),
                                        )
                                        .shimmer(duration: 2000.ms),
                                    const SizedBox(height: 8),
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
                                        'Question ${qIndex + 1} Results',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .slideY(begin: -0.5, end: 0, duration: 600.ms)
                              .shimmer(delay: 400.ms, duration: 1000.ms),

                          // Leaderboard list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: leaderboard.length,
                              itemBuilder: (context, index) {
                                final player = leaderboard[index];
                                final isTop3 = index < 3;
                                final pointsGained =
                                    player['pointsGained'] as int;
                                final isCorrect = player['correct'] as bool;

                                // Rank badges
                                final rankEmoji = index == 0
                                    ? '🥇'
                                    : index == 1
                                    ? '🥈'
                                    : index == 2
                                    ? '🥉'
                                    : '';

                                return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        gradient: isTop3
                                            ? LinearGradient(
                                                colors: index == 0
                                                    ? [
                                                        Colors.amber[100]!,
                                                        Colors.amber[50]!,
                                                      ]
                                                    : index == 1
                                                    ? [
                                                        Colors.grey[300]!,
                                                        Colors.grey[100]!,
                                                      ]
                                                    : [
                                                        Colors.orange[100]!,
                                                        Colors.orange[50]!,
                                                      ],
                                              )
                                            : null,
                                        color: isTop3 ? null : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isTop3
                                              ? index == 0
                                                    ? Colors.amber[600]!
                                                    : index == 1
                                                    ? Colors.grey[400]!
                                                    : Colors.orange[400]!
                                              : Colors.grey[300]!,
                                          width: isTop3 ? 3 : 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isTop3
                                                ? (index == 0
                                                          ? Colors.amber
                                                          : index == 1
                                                          ? Colors.grey
                                                          : Colors.orange)
                                                      .withOpacity(0.2)
                                                : Colors.black.withOpacity(
                                                    0.05,
                                                  ),
                                            blurRadius: isTop3 ? 12 : 8,
                                            offset: Offset(0, isTop3 ? 4 : 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                        leading: Stack(
                                          children: [
                                            Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: isTop3
                                                      ? index == 0
                                                            ? [
                                                                Colors
                                                                    .amber[400]!,
                                                                Colors
                                                                    .amber[700]!,
                                                              ]
                                                            : index == 1
                                                            ? [
                                                                Colors
                                                                    .grey[400]!,
                                                                Colors
                                                                    .grey[600]!,
                                                              ]
                                                            : [
                                                                Colors
                                                                    .orange[400]!,
                                                                Colors
                                                                    .orange[700]!,
                                                              ]
                                                      : [
                                                          Colors.purple[300]!,
                                                          Colors.purple[500]!,
                                                        ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        (isTop3
                                                                ? (index == 0
                                                                      ? Colors
                                                                            .amber
                                                                      : index ==
                                                                            1
                                                                      ? Colors
                                                                            .grey
                                                                      : Colors
                                                                            .orange)
                                                                : Colors.purple)
                                                            .withOpacity(0.4),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  rankEmoji.isNotEmpty
                                                      ? rankEmoji
                                                      : '#${index + 1}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        rankEmoji.isNotEmpty
                                                        ? 28
                                                        : 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                player['name'] as String,
                                                style: TextStyle(
                                                  fontWeight: isTop3
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  fontSize: isTop3 ? 19 : 17,
                                                ),
                                              ),
                                            ),
                                            if (isCorrect)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Text(
                                                  '✓',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (player['isUnique'] == true)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.purple[400]!,
                                                      Colors.deepPurple[600]!,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '🧠',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'UNIQUE!',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (player['timesSelected'] !=
                                                    null &&
                                                player['timesSelected'] as int >
                                                    1)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${player['timesSelected']}× picked',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            if (player['streak'] as int > 2)
                                              Text(
                                                '🔥 ${player['streak']} streak',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            if (pointsGained > 0)
                                              Text(
                                                '+$pointsGained pts',
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${player['totalScore']} pts',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: isTop3
                                                    ? Colors.amber[900]
                                                    : Colors.black87,
                                              ),
                                            ),
                                            if (index == 0)
                                              const Text(
                                                '👑 Leader',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.amber,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(
                                      delay: (index * 100).ms,
                                      duration: 400.ms,
                                    )
                                    .slideX(begin: 0.3, end: 0);
                              },
                            ),
                          ),

                          // Continue button (host only or auto-continue)
                          _ContinueButton(sessionId: sessionId),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final String sessionId;

  const _ContinueButton({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data!.data();
        final state = data?['questionState'] as String? ?? '';
        final hostId = data?['hostId'] as String?;
        final isHost = hostId == auth.uid;

        // Check if host is also a player
        return StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .doc(sessionId)
              .collection('players')
              .doc(auth.uid)
              .snapshots(),
          builder: (context, playerSnap) {
            final isHostPlayer = playerSnap.hasData && playerSnap.data!.exists;

            // Auto-dismiss when state changes from reveal
            if (state != 'reveal') {
              // Will auto-navigate via the session state listener
              return const SizedBox.shrink();
            }

            // If host is playing, show them Next Question button
            if (isHost && isHostPlayer) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    // Trigger next question via session controller
                    final currentIndex =
                        (data?['currentQuestionIndex'] as num?)?.toInt() ?? 0;
                    final quizId = data?['quizId'] as String? ?? '';

                    // Get total questions to check if this is the last one
                    final quizDoc = await FirebaseFirestore.instance
                        .collection('quizzes')
                        .doc(quizId)
                        .get();
                    final totalQuestions =
                        (quizDoc.data()?['totalQuestions'] as num?)?.toInt() ??
                        0;

                    if (currentIndex >= totalQuestions - 1) {
                      // End session
                      await FirebaseFirestore.instance
                          .collection('sessions')
                          .doc(sessionId)
                          .update({
                            'questionState': 'ended',
                            'status': 'ended',
                            'endedAt': FieldValue.serverTimestamp(),
                          });
                    } else {
                      // Next question
                      await FirebaseFirestore.instance
                          .collection('sessions')
                          .doc(sessionId)
                          .update({
                            'currentQuestionIndex': currentIndex + 1,
                            'questionState': 'answering',
                            'questionStartAt': FieldValue.serverTimestamp(),
                            'questionEndAt': Timestamp.fromDate(
                              DateTime.now().add(const Duration(seconds: 30)),
                            ),
                          });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_forward, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Next Question',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // For non-host players, show waiting message
            return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Waiting for host...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(Colors.purple[300]),
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms);
          },
        );
      },
    );
  }
}
