import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enhanced player list widget with avatars and animations
class PlayerListWidget extends StatelessWidget {
  final String sessionId;

  const PlayerListWidget({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('players')
          .orderBy('joinedAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final players = snapshot.data!.docs;

        if (players.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for players to join...',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share the PIN with your friends!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Player count header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '${players.length} ${players.length == 1 ? "Player" : "Players"} Joined',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // Player list
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index].data() as Map<String, dynamic>;
                  final nickname = player['nickname'] as String? ?? 'Player';
                  final score = player['score'] as num? ?? 0;
                  final streak = player['streak'] as num? ?? 0;

                  return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getAvatarColor(index),
                            child: Text(
                              nickname[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            nickname,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text('$score points'),
                              if (streak > 0) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: Colors.orange.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text('$streak streak'),
                              ],
                            ],
                          ),
                          trailing: index == 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        size: 18,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '#1',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (index * 100).ms)
                      .slideX(begin: -0.2, end: 0, delay: (index * 100).ms);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];
    return colors[index % colors.length];
  }
}
