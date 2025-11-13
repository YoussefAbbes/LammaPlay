import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Core logic helpers for Emoji Telepathy mini-game.
class EmojiTelepathyLogic {
  // Loads prompts from bundled JSON.
  static Future<List<String>> loadPrompts() async {
    final text = await rootBundle.loadString(
      'assets/games/emoji_telepathy/emoji_prompts.json',
    );
    final data = jsonDecode(text) as List;
    return data.cast<String>();
  }

  // Compute scoring results given submissions and prior scores.
  // submissions: map of playerId -> chosen emoji (string)
  // priorScores: map of playerId -> existing score (int)
  // Returns: { deltas: Map<String,int>, majorityChoices: List<String>, summary: {...} }
  static Map<String, dynamic> resolve({
    required Map<String, String> submissions,
    required Map<String, int> priorScores,
  }) {
    // Edge cases
    if (submissions.isEmpty) {
      return {
        'deltas': <String, int>{},
        'majorityChoices': <String>[],
        'summary': {'counts': <String, int>{}, 'note': 'no submissions'},
      };
    }

    // Count choices
    final Map<String, int> counts = {};
    submissions.forEach((_, choice) {
      counts[choice] = (counts[choice] ?? 0) + 1;
    });

    // Determine top count and majority/near-majority
    final int top = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final List<String> topChoices = counts.entries
        .where((e) => e.value == top)
        .map((e) => e.key)
        .toList();

    // Perfect tie: every chosen emoji has same count and there are >1 distinct choices
    final bool perfectTie =
        counts.length > 1 && counts.values.toSet().length == 1;

    // Build deltas
    final Map<String, int> deltas = {
      for (final pid in submissions.keys) pid: 0,
    };

    if (perfectTie) {
      // All +8
      for (final pid in deltas.keys) {
        deltas[pid] = 8;
      }
    } else {
      // Majority +10; near-majority (within 1 of top) +6; unique +2
      // Unique means count == 1 and not near-top.
      submissions.forEach((pid, choice) {
        final c = counts[choice] ?? 0;
        if (c == top) {
          deltas[pid] = 10;
        } else if (top - c <= 1) {
          deltas[pid] = 6;
        } else if (c == 1) {
          deltas[pid] = 2;
        } else {
          deltas[pid] = 0;
        }
      });
    }

    // Catch-up: +2 if below median prior to round
    if (priorScores.isNotEmpty) {
      final scores = priorScores.values.toList()..sort();
      final median = scores.length.isOdd
          ? scores[scores.length ~/ 2]
          : ((scores[scores.length ~/ 2 - 1] + scores[scores.length ~/ 2]) / 2)
                .floor();
      for (final pid in deltas.keys) {
        final prior = priorScores[pid] ?? 0;
        if (prior < median) deltas[pid] = deltas[pid]! + 2;
      }
    }

    return {
      'deltas': deltas,
      'majorityChoices': topChoices,
      'summary': {
        'counts': counts,
        'top': top,
        'perfectTie': perfectTie,
        'distinctChoices': counts.length,
        'totalSubmissions': submissions.length,
      },
    };
  }
}
