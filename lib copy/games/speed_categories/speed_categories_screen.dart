import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/widgets/timer_bar.dart';
import 'package:lamaplay/widgets/game_scaffold.dart';

/// Speed Categories screen UI with category+letter, input field, and submit; prevent double-submit.
class SpeedCategoriesScreen extends StatefulWidget {
  final String roomId;
  final String roundId;
  const SpeedCategoriesScreen({
    super.key,
    required this.roomId,
    required this.roundId,
  });

  @override
  State<SpeedCategoriesScreen> createState() => _SpeedCategoriesScreenState();
}

class _SpeedCategoriesScreenState extends State<SpeedCategoriesScreen> {
  final _auth = AuthService();
  final _controller = TextEditingController();
  bool _submitted = false;
  DateTime? _end;
  int _durationMs = 60000;
  String? _category;
  String? _letter;
  StreamSubscription? _roundSub;

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
            _category = payload['category'] as String? ?? _category;
            _letter = payload['letter'] as String? ?? _letter;
          });
        });
  }

  @override
  void dispose() {
    _roundSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = _auth.uid!;
    await FirestoreRefs.submissions(
      widget.roomId,
      widget.roundId,
    ).doc(uid).set({
      'word': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final header = (_category != null && _letter != null)
        ? '${_category!} — Letter: ${_letter!}'
        : 'Get Ready…';
    return GameScaffold(
      title: 'Speed Categories',
      subtitle: header,
      heroImage: 'assets/images/game_speed.jpg',
      timer: _end == null
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: TimerBar(end: _end, durationMs: _durationMs),
            ),
      body: _buildBody(context),
      bottomBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !_submitted,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitted ? null : _submit(),
          decoration: const InputDecoration(
            labelText: 'Your word',
            hintText: 'Type fast…',
          ),
        ),
        const SizedBox(height: 12),
        if (_submitted)
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('Locked in'),
            ],
          ),
      ],
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
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _submitted ? null : _submit,
              child: Text(_submitted ? 'Submitted' : 'Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
