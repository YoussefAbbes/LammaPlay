import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/widgets/timer_bar.dart';
import 'package:lamaplay/services/round_controller.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/games/emoji_telepathy/emoji_telepathy_screen.dart';
import 'package:lamaplay/games/speed_categories/speed_categories_screen.dart';
import 'package:lamaplay/games/odd_one_out/odd_one_out_screen.dart';
import 'package:lamaplay/games/bluff_trivia/bluff_trivia_screen.dart';

/// Game Shell screen: hosts individual mini-games.
class GameShellScreen extends StatelessWidget {
  const GameShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final roomId = args?['roomId'];
    final roundId = args?['roundId'];
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Game Shell')),
        body: roomId == null || roundId == null
            ? const Center(child: Text('No round'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirestoreRefs.roundDoc(roomId, roundId).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!.data();
                  if (data == null)
                    return const Center(child: Text('Round missing'));
                  final state = data['state'] as String? ?? 'intro';
                  if (state == 'intro') {
                    // route back to intro
                    Future.microtask(
                      () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.roundIntro,
                        (r) => false,
                        arguments: args,
                      ),
                    );
                  } else if (state == 'results') {
                    Future.microtask(
                      () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.results,
                        (r) => false,
                        arguments: args,
                      ),
                    );
                  }
                  DateTime? end;
                  final rawEnd = data['timerEnd'];
                  if (rawEnd is DateTime) {
                    end = rawEnd.toUtc();
                  } else if (rawEnd is Timestamp) {
                    end = rawEnd.toDate().toUtc();
                  }
                  final durationMs =
                      (data['durationMs'] as num?)?.toInt() ?? 60000;
                  final gameType = data['gameType'] as String?;
                  Widget gameBody;
                  if (gameType == 'emoji_telepathy') {
                    gameBody = EmojiTelepathyScreen(
                      roomId: roomId,
                      roundId: roundId,
                    );
                  } else if (gameType == 'speed_categories') {
                    gameBody = SpeedCategoriesScreen(
                      roomId: roomId,
                      roundId: roundId,
                    );
                  } else if (gameType == 'odd_one_out') {
                    gameBody = OddOneOutScreen(
                      roomId: roomId,
                      roundId: roundId,
                    );
                  } else if (gameType == 'bluff_trivia') {
                    gameBody = BluffTriviaScreen(
                      roomId: roomId,
                      roundId: roundId,
                    );
                  } else {
                    gameBody = Center(
                      child: Text('State: $state — game UI goes here'),
                    );
                  }
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TimerBar(end: end, durationMs: durationMs),
                      ),
                      Expanded(child: gameBody),
                      // Host-only lifecycle controls
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirestoreRefs.roomDoc(roomId).snapshots(),
                        builder: (context, rs) {
                          final uid = AuthService().uid;
                          final hostId = rs.data?.data()?['hostId'] as String?;
                          final isHost = uid != null && uid == hostId;
                          if (!isHost) return const SizedBox.shrink();
                          if (state == 'play') {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: () => RoundController().lockRound(
                                  roomId,
                                  roundId,
                                ),
                                child: const Text('Lock Submissions (Host)'),
                              ),
                            );
                          } else if (state == 'lock') {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: () => RoundController().openVoting(
                                  roomId,
                                  roundId,
                                ),
                                child: const Text('Open Voting (Host)'),
                              ),
                            );
                          } else if (state == 'vote') {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: () => RoundController().resolveRound(
                                  roomId,
                                  roundId,
                                ),
                                child: const Text('Resolve Round (Host)'),
                              ),
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
