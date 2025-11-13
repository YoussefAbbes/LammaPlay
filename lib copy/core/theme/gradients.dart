import 'package:flutter/material.dart';
import 'colors.dart';

class LmGradients {
  static const _angle45 = Alignment(0.7, -0.7);
  static const _angle45Opp = Alignment(-0.7, 0.7);

  static const banner = LinearGradient(
    begin: _angle45Opp,
    end: _angle45,
    colors: [LmColors.primary, LmColors.secondary],
  );

  static const tileWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
  );

  static const tileCool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  );

  static const win = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );
}
