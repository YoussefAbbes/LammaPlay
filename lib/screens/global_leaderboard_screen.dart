import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/services/global_leaderboard_service.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/sound_service.dart';

class GlobalLeaderboardScreen extends StatefulWidget {
  const GlobalLeaderboardScreen({super.key});

  @override
  State<GlobalLeaderboardScreen> createState() =>
      _GlobalLeaderboardScreenState();
}

class _GlobalLeaderboardScreenState extends State<GlobalLeaderboardScreen> {
  final _leaderboardService = GlobalLeaderboardService();
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        SoundService().play(SoundEffect.buttonTap);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 32)),
                              const SizedBox(width: 12),
                              Text(
                                'Global Leaderboard',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            'All-time champions across all quizzes',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder(
                    stream: _leaderboardService.getTopPlayers(limit: 100),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎯', style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 16),
                              Text(
                                'No players yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to join and dominate!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final players = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index].data();
                          final isCurrentUser = players[index].id == _auth.uid;
                          final rank = index + 1;
                          final isTopThree = rank <= 3;

                          final totalScore =
                              (player['totalScore'] as num?)?.toInt() ?? 0;
                          final correctAnswers =
                              (player['totalCorrectAnswers'] as num?)
                                  ?.toInt() ??
                              0;
                          final totalQuestions =
                              (player['totalQuestions'] as num?)?.toInt() ?? 0;
                          final quizzesPlayed =
                              (player['quizzesPlayed'] as num?)?.toInt() ?? 0;
                          final nickname =
                              player['nickname'] as String? ?? 'Player';
                          final accuracy = totalQuestions > 0
                              ? (correctAnswers / totalQuestions * 100)
                                    .toStringAsFixed(1)
                              : '0.0';

                          return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  gradient: isCurrentUser
                                      ? LinearGradient(
                                          colors: [
                                            Colors.purple[100]!,
                                            Colors.blue[100]!,
                                          ],
                                        )
                                      : isTopThree
                                      ? LinearGradient(
                                          colors: [
                                            Colors.amber[50]!,
                                            Colors.orange[50]!,
                                          ],
                                        )
                                      : null,
                                  color: isCurrentUser || isTopThree
                                      ? null
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrentUser
                                        ? Colors.purple[300]!
                                        : isTopThree
                                        ? Colors.amber[300]!
                                        : Colors.grey[200]!,
                                    width: isCurrentUser || isTopThree ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isCurrentUser
                                                  ? Colors.purple
                                                  : Colors.black)
                                              .withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: _getRankGradient(rank),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getRankColor(
                                            rank,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getRankEmoji(rank),
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          nickname,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isCurrentUser
                                                ? Colors.purple[900]
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isCurrentUser)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[700],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'YOU',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.emoji_events,
                                              size: 14,
                                              color: Colors.amber[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$totalScore pts',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.amber[900],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.check_circle,
                                              size: 14,
                                              color: Colors.green[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$correctAnswers/$totalQuestions ($accuracy%)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[900],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.quiz,
                                              size: 14,
                                              color: Colors.blue[700],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$quizzesPlayed quiz${quizzesPlayed != 1 ? 'zes' : ''} played',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                              .slideX(begin: -0.2, end: 0);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return LinearGradient(
          colors: [Colors.amber[400]!, Colors.yellow[600]!],
        );
      case 2:
        return LinearGradient(colors: [Colors.grey[400]!, Colors.grey[600]!]);
      case 3:
        return LinearGradient(
          colors: [Colors.orange[400]!, Colors.deepOrange[600]!],
        );
      default:
        return LinearGradient(colors: [Colors.blue[400]!, Colors.blue[700]!]);
    }
  }
}
