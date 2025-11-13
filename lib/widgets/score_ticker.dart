import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/typography.dart';

class ScoreTicker extends ImplicitlyAnimatedWidget {
  final int score;
  final int? delta;
  const ScoreTicker({
    super.key,
    required this.score,
    this.delta,
    Duration duration = const Duration(milliseconds: 400),
  }) : super(duration: duration);

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() =>
      _ScoreTickerState();
}

class _ScoreTickerState extends AnimatedWidgetBaseState<ScoreTicker> {
  IntTween? _scoreTween;
  @override
  Widget build(BuildContext context) {
    final value = _scoreTween?.evaluate(animation) ?? widget.score;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: LmTypography.number(fontSize: 20)),
        if (widget.delta != null && widget.delta != 0) ...[
          const SizedBox(width: 6),
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (widget.delta! > 0 ? Colors.green : Colors.red)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.delta! > 0 ? '+${widget.delta}' : '${widget.delta}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _scoreTween =
        visitor(
              _scoreTween,
              widget.score,
              (value) => IntTween(begin: value as int),
            )
            as IntTween?;
  }
}
