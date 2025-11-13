import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/round_controller.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Results screen: shows round results/summary.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final roomId = args?['roomId'];
    final roundId = args?['roundId'];
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: roomId == null || roundId == null
            ? const Center(child: Text('No round'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirestoreRefs.roundDoc(roomId, roundId).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final round = snap.data!.data();
                  if (round == null)
                    return const Center(child: Text('Round missing'));
                  final payload = (round['payload'] as Map<String, dynamic>?);
                  final results = payload?['results'] as Map<String, dynamic>?;
                  final deltas =
                      (results?['deltas'] as Map?)?.cast<String, num>() ?? {};
                  final voteCount =
                      (results?['summary']?['voteCount'] as num?)?.toInt() ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Votes counted: $voteCount'),
                      ),
                      Expanded(
                        child:
                            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirestoreRefs.players(roomId).snapshots(),
                              builder: (context, ps) {
                                final players = ps.data?.docs ?? [];
                                if (players.isEmpty)
                                  return const Center(
                                    child: Text('No players'),
                                  );
                                return ListView(
                                  children: players.map((p) {
                                    final name =
                                        p.data()['nickname'] ??
                                        p.id.substring(0, 6);
                                    final delta = (deltas[p.id] ?? 0).toInt();
                                    return ListTile(
                                      title: Text(name),
                                      trailing: Text(
                                        delta >= 0 ? '+$delta' : '$delta',
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                      ),
                      // Footer: host-only Next button and guest auto-follow
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirestoreRefs.roomDoc(roomId).snapshots(),
                        builder: (context, rs) {
                          final hostId = rs.data?.data()?['hostId'] as String?;
                          final status = rs.data?.data()?['status'] as String?;
                          final uid = AuthService().uid;
                          final isHost = uid != null && uid == hostId;
                          if (isHost) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      await RoundController().nextRound(roomId);
                                      if (!context.mounted) return;
                                      final room = await FirestoreRefs.roomDoc(
                                        roomId,
                                      ).get();
                                      final s =
                                          room.data()?['status'] as String?;
                                      if (s == 'ended') {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AppRouter.leaderboard,
                                          (r) => false,
                                          arguments: roomId,
                                        );
                                      } else {
                                        final nextId = await RoundController()
                                            .startRound(roomId);
                                        if (!context.mounted) return;
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          AppRouter.roundIntro,
                                          (r) => false,
                                          arguments: {
                                            'roomId': roomId,
                                            'roundId': nextId,
                                          },
                                        );
                                      }
                                    },
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                            );
                          }
                          // Guests: auto-follow host's decision
                          if (status == 'ended') {
                            Future.microtask(() {
                              if (!context.mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                AppRouter.leaderboard,
                                (r) => false,
                                arguments: roomId,
                              );
                            });
                          } else {
                            // If a new round got created after results, navigate to its intro
                            return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>
                            >(
                              stream: FirestoreRefs.rounds(
                                roomId,
                              ).orderBy('createdAt').snapshots(),
                              builder: (context, rds) {
                                final docs = rds.data?.docs ?? [];
                                if (docs.isNotEmpty) {
                                  final last = docs.last;
                                  if (last.id != roundId) {
                                    Future.microtask(() {
                                      if (!context.mounted) return;
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRouter.roundIntro,
                                        (r) => false,
                                        arguments: {
                                          'roomId': roomId,
                                          'roundId': last.id,
                                        },
                                      );
                                    });
                                  }
                                }
                                return const SizedBox.shrink();
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
