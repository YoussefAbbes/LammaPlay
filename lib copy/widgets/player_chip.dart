import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/colors.dart';

class PlayerChip extends StatelessWidget {
  final String nickname;
  final String avatarEmoji;
  final bool online;
  final bool host;
  final int? score;
  const PlayerChip({
    super.key,
    required this.nickname,
    required this.avatarEmoji,
    this.online = true,
    this.host = false,
    this.score,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: LmColors.secondary, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: online ? LmColors.success : LmColors.warning,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(nickname, style: Theme.of(context).textTheme.labelLarge),
                if (host) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: LmColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'HOST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (score != null)
              Text('${score!}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
