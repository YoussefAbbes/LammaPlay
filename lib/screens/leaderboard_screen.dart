import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/firestore_refs.dart';

/// Leaderboard screen: displays cumulative scores.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roomId = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: roomId == null
          ? const Center(child: Text('No room'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreRefs.players(
                roomId,
              ).orderBy('score', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text('No players'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data();
                    return ListTile(
                      leading: Text('#${i + 1}'),
                      title: Text(d['nickname'] ?? 'Player'),
                      trailing: Text('${d['score'] ?? 0}'),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.home,
                (r) => false,
              ),
              child: const Text('Exit to Home'),
            ),
            const SizedBox(width: 12),
            if (roomId != null)
              ElevatedButton(
                onPressed: () async {
                  // Restart: navigate back to lobby
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.lobby,
                    (r) => false,
                    arguments: roomId,
                  );
                },
                child: const Text('Back to Lobby'),
              ),
          ],
        ),
      ),
    );
  }
}
