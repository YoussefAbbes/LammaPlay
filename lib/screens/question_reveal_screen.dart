import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';

class QuestionRevealScreen extends StatelessWidget {
  final String sessionId;
  const QuestionRevealScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final quizRepo = QuizRepository();
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    return StreamBuilder(
      stream: sessionRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Loading')));
        }
        final data = snap.data!.data()!;
        final quizId = data['quizId'] as String;
        final qIndex = (data['currentQuestionIndex'] as num?)?.toInt() ?? -1;
        final state = data['questionState'] as String? ?? 'reveal';

        // Auto-navigate to podium when session ends
        if (state == 'ended') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushReplacementNamed('/podium', arguments: sessionId);
            }
          });
        }

        return FutureBuilder(
          future: quizRepo.getQuestions(quizId),
          builder: (context, qsNap) {
            final list = qsNap.data ?? const <dynamic>[];
            QuizQuestion? q;
            if (qIndex >= 0 && qIndex < list.length) q = list[qIndex];
            return Scaffold(
              appBar: AppBar(title: const Text('Reveal')),
              body: q == null
                  ? const Center(child: Text('Waiting for host'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.text,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          if (q.type == QuestionType.numeric &&
                              q.numericAnswer != null)
                            Text('Correct answer: ${q.numericAnswer}')
                          else if (q.correctIndex != null &&
                              q.correctIndex! < q.options.length)
                            Text('Correct: ${q.options[q.correctIndex!]}'),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _Stats(sessionId: sessionId, qIndex: qIndex),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  final String sessionId;
  final int qIndex;
  const _Stats({required this.sessionId, required this.qIndex});

  @override
  Widget build(BuildContext context) {
    final resultsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('results')
        .doc('q_$qIndex');
    return StreamBuilder(
      stream: resultsRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Center(child: Text('Scoring...'));
        }
        final data = snap.data!.data()!;
        final perPlayer = (data['perPlayer'] as Map?) ?? {};
        final optionCounts = (data['optionCounts'] as Map?) ?? {};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Option counts:'),
            ...optionCounts.entries.map((e) => Text('${e.key}: ${e.value}')),
            const Divider(),
            Text('Player deltas:'),
            Expanded(
              child: ListView(
                children: perPlayer.entries.map((e) {
                  final delta = (e.value as Map)['delta'];
                  final total = (e.value as Map)['total'];
                  final correct = (e.value as Map)['correct'];
                  return ListTile(
                    title: Text(e.key),
                    subtitle: Text('Δ $delta • total $total'),
                    trailing: correct == true
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
