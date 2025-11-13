import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/widgets/game_scaffold.dart';

class OddOneOutScreen extends StatefulWidget {
  final String roomId;
  final String roundId;
  const OddOneOutScreen({
    super.key,
    required this.roomId,
    required this.roundId,
  });

  @override
  State<OddOneOutScreen> createState() => _OddOneOutScreenState();
}

class _OddOneOutScreenState extends State<OddOneOutScreen> {
  final _auth = AuthService();
  StreamSubscription? _roundSub;
  StreamSubscription? _secretsSub;
  StreamSubscription? _playersSub;
  StreamSubscription? _myVoteSub;

  String? _state;
  String? _spyId;
  String? _word; // from secrets (subject to rules)
  List<Map<String, String>> _players = [];
  String? _selectedTarget;
  String? _myVoteTarget;

  @override
  void initState() {
    super.initState();
    _roundSub = FirestoreRefs.roundDoc(widget.roomId, widget.roundId)
        .snapshots()
        .listen((s) {
          final d = s.data();
          if (d == null) return;
          setState(() {
            _state = d['state'] as String?;
            _spyId = d['payload']?['spyId'] as String?;
          });
        });
    _secretsSub =
        FirestoreRefs.roomSecretRoundDoc(
          widget.roomId,
          widget.roundId,
        ).snapshots().listen((s) {
          final d = s.data();
          if (d == null) return;
          setState(() {
            // We prefer 'word' if present (written during beginPlay)
            _word = (d['word'] as String?) ?? _word;
          });
        });
    _playersSub = FirestoreRefs.players(widget.roomId).snapshots().listen((
      snap,
    ) {
      setState(() {
        _players = snap.docs
            .map(
              (d) => {
                'id': d.id,
                'name':
                    (d.data()['nickname'] as String?) ?? d.id.substring(0, 6),
              },
            )
            .toList();
      });
    });
    final uid = _auth.uid!;
    _myVoteSub = FirestoreRefs.votes(widget.roomId, widget.roundId)
        .doc(uid)
        .snapshots()
        .listen((s) {
          final d = s.data();
          setState(() {
            _myVoteTarget = d == null ? null : (d['targetPlayerId'] as String?);
          });
        });
  }

  @override
  void dispose() {
    _roundSub?.cancel();
    _secretsSub?.cancel();
    _playersSub?.cancel();
    _myVoteSub?.cancel();
    super.dispose();
  }

  Future<void> _submitVote() async {
    if (_selectedTarget == null) return;
    final uid = _auth.uid!;
    // Prevent multiple votes by simply not allowing if already set
    if (_myVoteTarget != null) return;
    await FirestoreRefs.votes(widget.roomId, widget.roundId).doc(uid).set({
      'targetPlayerId': _selectedTarget,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.uid;
    final isSpy = uid != null && uid == _spyId;
    final headline = _state == 'play'
        ? (isSpy
              ? 'You are the SPY. Blend in!'
              : (_word != null ? 'Word: $_word' : 'Loading word...'))
        : 'Voting Phase';
    return GameScaffold(
      title: 'Odd One Out',
      subtitle: headline,
      heroImage: 'assets/images/game_spy.jpg',
      body: _buildBody(context, uid),
      bottomBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context, String? uid) {
    if (_state == 'vote') {
      final choices = _players.where((p) => p['id'] != uid).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((p) {
              final id = p['id'];
              final selected = id == _selectedTarget || id == _myVoteTarget;
              return GestureDetector(
                onTap: _myVoteTarget != null
                    ? null
                    : () => setState(() => _selectedTarget = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary.withOpacity(.15)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p['name'] ?? id!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (id == _myVoteTarget)
                        const Padding(
                          padding: EdgeInsets.only(left: 6.0),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_myVoteTarget != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                'You voted: '
                '${_players.firstWhere((p) => p['id'] == _myVoteTarget, orElse: () => {'id': _myVoteTarget!, 'name': _myVoteTarget!})['name']}',
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(BuildContext context) {
    if (_state == 'vote') {
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
                onPressed: (_myVoteTarget != null || _selectedTarget == null)
                    ? null
                    : _submitVote,
                child: Text(
                  _myVoteTarget != null ? 'Vote Locked' : 'Submit Vote',
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
