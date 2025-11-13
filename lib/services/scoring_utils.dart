import 'dart:math';

class ScoringUtils {
  static double speedMultiplier(int timeMs, int totalMs) {
    if (totalMs <= 0) return 0.3;
    final frac = 1 - (timeMs / totalMs.clamp(1, totalMs));
    final m = 0.3 + 0.7 * frac.clamp(0, 1);
    return m.clamp(0.3, 1.0);
  }

  static int mcqBase(bool correct, double speedMult) {
    if (!correct) return 0;
    final raw = (1000 * speedMult).round();
    return raw.clamp(300, 1000);
  }

  static int numericScore(num? guess, num? target) {
    if (guess == null || target == null) return 0;
    if (target == 0) {
      return (guess == 0) ? 1000 : 300;
    }
    final diffRatio = (guess - target).abs() / target.abs();
    if (diffRatio == 0) return 1000;
    if (diffRatio <= 0.02) return 900;
    if (diffRatio <= 0.05) return 700;
    if (diffRatio <= 0.10) return 500;
    return 300;
  }

  static int orderBase(List<dynamic>? submitted, List<dynamic>? solution) {
    if (submitted == null || solution == null || submitted.isEmpty) return 0;
    final len = min(submitted.length, solution.length);
    if (len == 0) return 0;
    int correctPos = 0;
    for (var i = 0; i < len; i++) {
      if (submitted[i] == solution[i]) correctPos++;
    }
    final similarity = correctPos / len;
    final base = (1000 * similarity).round();
    return similarity == 0 ? 0 : base.clamp(300, 1000);
  }

  static int streakBonus(int streak) {
    return streak >= 3 ? 200 : 0;
  }

  static int fastestBonus(bool isFastestCorrect) => isFastestCorrect ? 100 : 0;

  static int catchUpBonus(int preScore, int medianPreScore) =>
      preScore < medianPreScore ? 100 : 0;

  static int capTotal(int total) => total > 1400 ? 1400 : total;
}
