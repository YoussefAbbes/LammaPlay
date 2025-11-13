import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Core logic helpers for Speed Categories mini-game.
class SpeedCategoriesLogic {
  static Future<List<String>> loadCategories() async {
    final text = await rootBundle.loadString(
      'assets/games/speed_categories/categories.json',
    );
    final data = jsonDecode(text) as List;
    return data.cast<String>();
  }

  // Weighted letter picker: rare letters have very low weight; A/E/I/O/U/S/T/N/R/L common.
  static String pickLetter(int seed) {
    // weights roughly based on English letter frequency
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final weights = <int>[
      8, // A
      2, // B
      3, // C
      4, // D
      13, // E
      2, // F
      2, // G
      6, // H
      7, // I
      1, // J
      1, // K
      4, // L
      2, // M
      7, // N
      8, // O
      2, // P
      0, // Q (extremely rare)
      6, // R
      6, // S
      9, // T
      3, // U
      1, // V
      2, // W
      0, // X (skip)
      2, // Y
      0, // Z (skip)
    ];
    final total = weights.reduce((a, b) => a + b);
    int r = (seed % total).toInt();
    for (int i = 0; i < letters.length; i++) {
      r -= weights[i];
      if (r < 0) return letters[i];
    }
    return 'A';
  }

  // Normalize: lowercase, remove accents/diacritics, trim
  static String norm(String s) {
    final lower = s.trim().toLowerCase();
    // Basic ascii fold for common Latin accents
    const from =
        'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœæśšžđł·/_,:;'
        'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝŒÆŚŠŽĐŁ';
    const to =
        'aaaaaaceeeeiiiinooooouuuuyyoeasszdl------'
        'AAAAAACEEEEIIIINOOOOOUUUUYOEASSZDL';
    var out = lower;
    for (int i = 0; i < from.length && i < to.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  // Very basic profanity list (placeholder, non-exhaustive)
  static final Set<String> _banned = {'badword', 'offensive', 'curse'};
  static bool isClean(String s) => !_banned.contains(norm(s));

  // Resolve scoring
  // inputs: submissions map playerId->word, letter char, priorScores map
  // Returns: { deltas: Map<String,int>, summary: {...} }
  static Map<String, dynamic> resolve({
    required Map<String, String> submissions,
    required String letter,
    required Map<String, int> priorScores,
  }) {
    final L = letter.toLowerCase();
    // Validate entries
    final Map<String, bool> valid = {};
    final Map<String, String> cleaned = {};
    submissions.forEach((pid, word) {
      final w = norm(word);
      cleaned[pid] = w;
      valid[pid] = w.isNotEmpty && w[0] == L && isClean(w);
    });

    // First valid (by created order is not known client-only). We’ll approximate using lexical order of cleaned word + pid as deterministic tiebreaker.
    final validPids =
        submissions.keys.where((pid) => valid[pid] == true).toList()
          ..sort((a, b) {
            final ca = cleaned[a]!;
            final cb = cleaned[b]!;
            final cmp = ca.compareTo(cb);
            if (cmp != 0) return cmp;
            return a.compareTo(b);
          });
    final String? firstValidPid = validPids.isEmpty ? null : validPids.first;

    // Unique detection across normalized form (case/accents normalized)
    final Map<String, int> counts = {};
    submissions.forEach((pid, _) {
      final w = cleaned[pid] ?? '';
      if (w.isEmpty) return;
      counts[w] = (counts[w] ?? 0) + 1;
    });

    // Base scoring
    final Map<String, int> deltas = {
      for (final pid in submissions.keys) pid: 0,
    };
    submissions.forEach((pid, _) {
      if (valid[pid] != true) {
        deltas[pid] = 0; // invalid
        return;
      }
      final w = cleaned[pid]!;
      final frequency = counts[w] ?? 0;
      if (frequency == 1) {
        deltas[pid] = 10; // unique valid
      } else {
        deltas[pid] = 5; // non-unique valid
      }
      if (firstValidPid != null && pid == firstValidPid) {
        deltas[pid] = deltas[pid]! + 2; // first valid bonus
      }
    });

    // Cap per player score to ~20
    deltas.updateAll((_, v) => v > 20 ? 20 : v);

    return {
      'deltas': deltas,
      'summary': {
        'letter': letter,
        'counts': counts,
        'firstValid': firstValidPid,
        'validCount': valid.values.where((v) => v).length,
        'total': submissions.length,
      },
    };
  }
}
