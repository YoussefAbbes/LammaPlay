import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class BluffTriviaLogic {
  static Future<List<Map<String, String>>> loadPack() async {
    final text = await rootBundle.loadString(
      'assets/games/bluff_trivia/trivia_pack.json',
    );
    final data = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
    return data
        .map((e) => {'q': e['q'] as String, 'a': e['a'] as String})
        .toList();
  }

  static String norm(String s) => s.trim();

  static bool isClean(String s) {
    final low = s.toLowerCase();
    const bad = ['fuck', 'shit', 'bitch', 'asshole', 'cunt'];
    return !bad.any((w) => low.contains(w));
  }

  // Build options: returns list of { id, text, authors[], isAnswer }
  static List<Map<String, dynamic>> buildOptions({
    required Map<String, String> bluffs, // playerId -> bluff
    required String trueAnswer,
    required int seed,
  }) {
    final Map<String, List<String>> byText = {};
    bluffs.forEach((pid, text) {
      final t = norm(text);
      if (t.isEmpty || !isClean(t)) return; // drop invalid
      byText.putIfAbsent(t, () => []).add(pid);
    });
    // Collapse identical bluffs
    final List<Map<String, dynamic>> options = [];
    byText.forEach((text, authors) {
      options.add({
        'id': 'b_${text.hashCode}',
        'text': text,
        'authors': authors,
        'isAnswer': false,
      });
    });
    // Add real answer option
    options.add({
      'id': 'a_${trueAnswer.hashCode}',
      'text': trueAnswer,
      'authors': const <String>[],
      'isAnswer': true,
    });
    // Shuffle deterministically by seed
    final rng = Random(seed);
    options.shuffle(rng);
    return options;
  }

  // Resolve votes: returns deltas and summary counts per option
  static Map<String, dynamic> resolveVotes({
    required Map<String, String> votes, // playerId -> optionId
    required List<Map<String, dynamic>> options,
  }) {
    final Map<String, int> deltas = {};
    final Map<String, int> counts = {};
    final Map<String, Map<String, dynamic>> byId = {
      for (final o in options) o['id'] as String: o,
    };
    votes.forEach((voterId, optionId) {
      final opt = byId[optionId];
      if (opt == null) return;
      counts[optionId] = (counts[optionId] ?? 0) + 1;
      final isAnswer = opt['isAnswer'] == true;
      if (isAnswer) {
        // Correct vote: +8
        deltas[voterId] = (deltas[voterId] ?? 0) + 8;
      } else {
        // Fooling: +5 per victim to the option's authors, but prevent self-vote counting
        final List authors = (opt['authors'] as List?) ?? const [];
        final isSelfVote = authors.contains(voterId);
        if (!isSelfVote) {
          for (final a in authors) {
            final id = a as String;
            deltas[id] = (deltas[id] ?? 0) + 5;
          }
        }
      }
    });
    // Cap fooling to +10 per author for this round
    deltas.updateAll((k, v) => v > 10 ? 10 : v);
    return {'deltas': deltas, 'counts': counts};
  }
}
/// Core logic helpers for Bluff Trivia mini-game.
 
