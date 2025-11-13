import 'dart:async';
import 'package:flutter/material.dart';

/// Visual countdown/progress bar with thresholds and subtle pulse under 10s.
class TimerBar extends StatefulWidget {
  final DateTime? end;
  final int durationMs;
  const TimerBar({super.key, required this.end, required this.durationMs});

  @override
  State<TimerBar> createState() => _TimerBarState();
}

class _TimerBarState extends State<TimerBar> {
  late Timer _timer;
  double _progress = 1;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
  }

  void _tick() {
    final end = widget.end;
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    double p = 0;
    if (end != null && widget.durationMs > 0) {
      final remaining = end.difference(now).inMilliseconds;
      p = (remaining / widget.durationMs).clamp(0.0, 1.0);
    }
    setState(() => _progress = p);
  }

  @override
  void didUpdateWidget(covariant TimerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tick();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _progress > 0.66
        ? Colors.green
        : _progress > 0.33
        ? Colors.orange
        : Colors.red;
    final critical =
        widget.end != null &&
        widget.durationMs > 0 &&
        (widget.end!.difference(DateTime.now().toUtc()).inSeconds <= 10);
    return AnimatedScale(
      duration: const Duration(milliseconds: 800),
      scale: critical ? 1.03 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: 10,
          color: color,
          backgroundColor: color.withOpacity(0.18),
        ),
      ),
    );
  }
}
