import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/widgets/timer_bar.dart';
import 'package:lamaplay/widgets/game_scaffold.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/core/theme/spacing.dart';

/// Emoji Telepathy screen.
class EmojiTelepathyScreen extends StatefulWidget {
  final String roomId;
  final String roundId;
  const EmojiTelepathyScreen({
    super.key,
    required this.roomId,
    required this.roundId,
  });

  @override
  State<EmojiTelepathyScreen> createState() => _EmojiTelepathyScreenState();
}

class _EmojiTelepathyScreenState extends State<EmojiTelepathyScreen> {
  final _auth = AuthService();
  String? _selected;
  bool _submitted = false;
  StreamSubscription? _roundSub;
  DateTime? _end;
  int _durationMs = 60000;
  String? _prompt;

  final List<String> _emoji = [
    '😀',
    '😂',
    '😍',
    '😎',
    '🤔',
    '😴',
    '😇',
    '🤯',
    '😅',
    '😭',
    '👍',
    '👎',
    '🙏',
    '👏',
    '🔥',
    '✨',
    '💥',
    '💤',
    '🍿',
    '🍕',
    '🍎',
    '🍩',
    '🍔',
    '🍣',
    '🍰',
    '☕',
    '🍵',
    '🍺',
    '🍷',
    '🥤',
    '⚽',
    '🏀',
    '🎮',
    '🎲',
    '🎵',
    '🎸',
    '🎧',
    '🎬',
    '📚',
    '💻',
    '🌞',
    '🌧️',
    '⛈️',
    '🌈',
    '❄️',
    '🌪️',
    '🌊',
    '🌴',
    '🌃',
    '🌆',
  ];

  @override
  void initState() {
    super.initState();
    _roundSub = FirestoreRefs.roundDoc(widget.roomId, widget.roundId)
        .snapshots()
        .listen((s) {
          final d = s.data();
          if (d == null) return;
          final rawEnd = d['timerEnd'];
          if (rawEnd is Timestamp) _end = rawEnd.toDate().toUtc();
          _durationMs = (d['durationMs'] as num?)?.toInt() ?? _durationMs;
          final payload = (d['payload'] as Map<String, dynamic>?) ?? {};
          setState(() {
            _prompt = payload['prompt'] as String? ?? _prompt;
          });
        });
  }

  @override
  void dispose() {
    _roundSub?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted || _selected == null) return;
    final uid = _auth.uid!;
    await FirestoreRefs.submissions(
      widget.roomId,
      widget.roundId,
    ).doc(uid).set({
      'choice': _selected,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final prompt = _prompt ?? 'Telepathic vibes loading...';
    return GameScaffold(
      title: 'Emoji Telepathy',
      subtitle: prompt,
      heroImage: 'assets/images/game_emoji.jpg',
      timer: _end == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TimerBar(end: _end, durationMs: _durationMs),
            ),
      body: _buildEmojiGrid(context),
      bottomBar: _buildBottomBar(context),
    );
  }

  Widget _buildEmojiGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount;
    if (width > 1100) {
      crossAxisCount = 10;
    } else if (width > 900) {
      crossAxisCount = 9;
    } else if (width > 700) {
      crossAxisCount = 8;
    } else if (width > 550) {
      crossAxisCount = 7;
    } else if (width > 450) {
      crossAxisCount = 6;
    } else {
      crossAxisCount = 5;
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: LmSpace.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _emoji.length,
      itemBuilder: (context, i) {
        final e = _emoji[i];
        final selected = e == _selected;
        return _EmojiTile(
          emoji: e,
          selected: selected,
          disabled: _submitted,
          onTap: () => setState(() => _selected = e),
          delay: (i * 12).ms,
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, -4),
            color: Colors.black.withOpacity(.15),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submitted || _selected == null ? null : _submit,
                child: Text(_submitted ? 'Locked In' : 'Lock In'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  final String emoji;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  final Duration delay;
  const _EmojiTile({
    required this.emoji,
    required this.selected,
    required this.disabled,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.primary;
    final bg = selected
        ? baseColor.withOpacity(.18)
        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final border = selected ? baseColor : Colors.transparent;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: baseColor.withOpacity(.35),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 26))
              .animate(delay: delay)
              .fadeIn(duration: 280.ms)
              .scaleXY(begin: 0.7, end: 1, curve: Curves.easeOutBack)
              .animate(target: selected ? 1 : 0)
              .scaleXY(
                end: selected ? 1.1 : 1,
                duration: 220.ms,
                curve: Curves.easeOut,
              ),
        ),
      ),
    );
  }
}
