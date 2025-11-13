import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Core logic helpers for Odd One Out mini-game.
class OddOneOutLogic {
  static Future<List<String>> loadWords() async {
    final text = await rootBundle.loadString(
      'assets/games/odd_one_out/spy_words.json',
    );
    final data = jsonDecode(text) as List;
    return data.cast<String>();
  }

  // Deterministic selection based on seed
  static String pickSpyId(List<String> playerIds, int seed) {
    if (playerIds.isEmpty) return '';
    final idx = seed % playerIds.length;
    return playerIds[idx];
  }

  static int pickWordIndex(int wordCount, int seed) {
    if (wordCount <= 0) return 0;
    return seed % wordCount;
  }

  // Tally votes and return eliminated player id using deterministic tie-break (lexicographically smallest uid)
  static Map<String, dynamic> tally(Map<String, String> votes) {
    final Map<String, int> counts = {};
    votes.forEach((voter, target) {
      if (target.isEmpty) return;
      counts[target] = (counts[target] ?? 0) + 1;
    });
    if (counts.isEmpty) return {'eliminated': null, 'counts': counts};
    int top = 0;
    for (final c in counts.values) {
      if (c > top) top = c;
    }
    final topTargets =
        counts.entries.where((e) => e.value == top).map((e) => e.key).toList()
          ..sort();
    final eliminated = topTargets.first; // smallest uid
    return {'eliminated': eliminated, 'counts': counts};
  }

  // Compute deltas
  // If spy caught (eliminated == spyId): each voter who voted spy +10
  // Else: spy +12 (optional bonus +3 not implemented here)
  static Map<String, int> score({
    required String spyId,
    required Map<String, String> votes,
    required String? eliminated,
  }) {
    final Map<String, int> deltas = {};
    if (eliminated != null && eliminated == spyId) {
      votes.forEach((voter, target) {
        if (target == spyId) {
          deltas[voter] = (deltas[voter] ?? 0) + 10;
        }
      });
    } else {
      if (spyId.isNotEmpty) {
        deltas[spyId] = (deltas[spyId] ?? 0) + 12;
      }
    }
    return deltas;
  }
}
