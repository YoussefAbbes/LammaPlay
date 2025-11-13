import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/games/bluff_trivia/bluff_trivia_logic.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/widgets/game_scaffold.dart';

class BluffTriviaScreen extends StatefulWidget {
  final String roomId;
  final String roundId;
  const BluffTriviaScreen({
    super.key,
    required this.roomId,
    required this.roundId,
  });

  @override
  State<BluffTriviaScreen> createState() => _BluffTriviaScreenState();
}

class _BluffTriviaScreenState extends State<BluffTriviaScreen> {
  final _auth = AuthService();
  final _ctrl = TextEditingController();
  StreamSubscription? _roundSub;
  StreamSubscription? _mySubSub;
  StreamSubscription? _myVoteSub;
  String? _state;
  String? _question;
  List<Map<String, dynamic>> _options = [];
  String? _myBluff;
  String? _myVote;

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
            _question = d['payload']?['question'] as String?;
            final opts = d['payload']?['options'];
            if (opts is List) {
              _options = opts
                  .cast<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
            }
          });
        });
    final uid = _auth.uid!;
    _mySubSub = FirestoreRefs.submissions(widget.roomId, widget.roundId)
        .doc(uid)
        .snapshots()
        .listen((s) {
          _myBluff = s.data()?['bluff'] as String?;
          if (_myBluff != null) _ctrl.text = _myBluff!;
          setState(() {});
        });
    _myVoteSub = FirestoreRefs.votes(widget.roomId, widget.roundId)
        .doc(uid)
        .snapshots()
        .listen((s) {
          _myVote = s.data()?['optionId'] as String?;
          setState(() {});
        });
  }

  @override
  void dispose() {
    _roundSub?.cancel();
    _mySubSub?.cancel();
    _myVoteSub?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submitBluff() async {
    final text = BluffTriviaLogic.norm(_ctrl.text);
    if (text.isEmpty || !BluffTriviaLogic.isClean(text)) return;
    final uid = _auth.uid!;
    await FirestoreRefs.submissions(
      widget.roomId,
      widget.roundId,
    ).doc(uid).set({
      'bluff': text,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _submitVote(String optionId) async {
    if (_myVote != null) return;
    final uid = _auth.uid!;
    await FirestoreRefs.votes(widget.roomId, widget.roundId).doc(uid).set({
      'optionId': optionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final question = _question ?? 'Loading trivia...';
    return GameScaffold(
      title: 'Bluff Trivia',
      subtitle: question,
      heroImage: 'assets/images/game_bluff.jpg',
      body: _buildBody(context),
      bottomBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_state == 'play') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            enabled: _myBluff == null,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _myBluff == null ? _submitBluff() : null,
            decoration: const InputDecoration(
              labelText: 'Your bluff',
              hintText: 'Invent a plausible answer',
            ),
          ),
          const SizedBox(height: 12),
          if (_myBluff != null)
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 6),
                Text('Bluff locked'),
              ],
            ),
        ],
      );
    }
    if (_state == 'vote') {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final opt = _options[i];
          final id = opt['id'] as String;
          final text = opt['text'] as String;
          final picked = _myVote == id;
          return GestureDetector(
            onTap: _myVote == null ? () => _submitVote(id) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: picked
                    ? Theme.of(context).colorScheme.primary.withOpacity(.15)
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: picked
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (picked)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(BuildContext context) {
    if (_state == 'play') {
      return _BottomBar(
        child: ElevatedButton(
          onPressed: _myBluff != null ? null : _submitBluff,
          child: Text(_myBluff != null ? 'Submitted' : 'Submit Bluff'),
        ),
      );
    }
    if (_state == 'vote') {
      return _BottomBar(
        child: Text(
          _myVote == null ? 'Pick the real answer' : 'Vote locked',
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});
  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(top: false, child: child),
    );
  }
}
