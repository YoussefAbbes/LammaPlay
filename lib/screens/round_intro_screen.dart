import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/services/round_controller.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/firestore_refs.dart';

/// Round Intro screen: explains the upcoming round.
class RoundIntroScreen extends StatelessWidget {
  const RoundIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    final roomId = args?['roomId'];
    final roundId = args?['roundId'];
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Round Intro')),
        body: roomId == null || roundId == null
            ? const Center(child: Text('No round'))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirestoreRefs.roundDoc(roomId, roundId).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!.data();
                  if (data == null) {
                    return const Center(child: Text('Round missing'));
                  }
                  final state = data['state'] as String? ?? 'intro';
                  // If state advanced, route accordingly
                  if (state != 'intro') {
                    Future.microtask(() {
                      if (!context.mounted) return;
                      final route = state == 'results'
                          ? AppRouter.results
                          : AppRouter.gameShell;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        route,
                        (r) => false,
                        arguments: args,
                      );
                    });
                  }
                  final uid = AuthService().uid;
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirestoreRefs.roomDoc(roomId).snapshots(),
                    builder: (context, rs) {
                      final hostId = rs.data?.data()?['hostId'] as String?;
                      final isHost = uid != null && hostId == uid;
                      return Center(
                        child: isHost
                            ? ElevatedButton(
                                onPressed: () async {
                                  await RoundController().beginPlay(
                                    roomId,
                                    roundId,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRouter.gameShell,
                                    (r) => false,
                                    arguments: args,
                                  );
                                },
                                child: const Text('Start Round'),
                              )
                            : const Text('Waiting for host to start…'),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
