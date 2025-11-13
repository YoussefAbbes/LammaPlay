import 'package:flutter/material.dart';

class LmShadows {
  static const card = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const floating = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 24,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];
}
