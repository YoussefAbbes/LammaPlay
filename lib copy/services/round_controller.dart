import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/firestore_refs.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/models/round.dart' as model;
import 'package:lamaplay/games/emoji_telepathy/emoji_telepathy_logic.dart';
import 'package:lamaplay/games/speed_categories/speed_categories_logic.dart';
import 'package:lamaplay/games/odd_one_out/odd_one_out_logic.dart';
import 'package:lamaplay/games/bluff_trivia/bluff_trivia_logic.dart';

/// RoundController: stream current round and provide host-only lifecycle methods.
class RoundController {
  final _auth = AuthService();

  Stream<model.Round?> currentRoundStream(String roomId) async* {
    final roomDoc = await FirestoreRefs.roomDoc(roomId).get();
    final index = (roomDoc.data()?['roundIndex'] as num?)?.toInt() ?? 0;
    final rounds = await FirestoreRefs.rounds(
      roomId,
    ).orderBy('createdAt').limit(index + 1).get();
    if (rounds.docs.isEmpty) {
      yield null;
      return;
    }
    final currentId = rounds.docs.last.id;
    yield* FirestoreRefs.roundDoc(roomId, currentId).snapshots().map(
      (s) => s.exists ? model.Round.fromJson(s.id, s.data()!) : null,
    );
  }

  Future<void> _ensureHost(String roomId) async {
    final room = await FirestoreRefs.roomDoc(roomId).get();
    if (room.data()?['hostId'] != _auth.uid) {
      throw StateError('Host-only operation');
    }
  }

  Future<String> startRound(String roomId, {int introMs = 3000}) async {
    await _ensureHost(roomId);
    final roomSnap = await FirestoreRefs.roomDoc(roomId).get();
    final data = roomSnap.data() ?? {};
    final List<dynamic> playlist = (data['playlist'] as List?) ?? [];
    final int index = (data['roundIndex'] as num?)?.toInt() ?? 0;
    if (index >= playlist.length) {
      throw StateError('No more games in playlist');
    }
    final String gameType = playlist[index] as String;

    final ref = FirestoreRefs.rounds(roomId).doc();
    await ref.set({
      'gameType': gameType,
      'state': 'intro',
      'payload': {
        'seed': DateTime.now().millisecondsSinceEpoch,
        'introMs': introMs,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await FirestoreRefs.roomDoc(
      roomId,
    ).update({'status': 'playing', 'updatedAt': FieldValue.serverTimestamp()});
    return ref.id;
  }

  Future<void> beginPlay(
    String roomId,
    String roundId, {
    int durationMs = 60000,
  }) async {
    await _ensureHost(roomId);
    final approxEnd = DateTime.now().toUtc().add(
      Duration(milliseconds: durationMs),
    );

    // If this is the emoji_telepathy game, seed a prompt deterministically.
    final roundSnap = await FirestoreRefs.roundDoc(roomId, roundId).get();
    final roundData = roundSnap.data() ?? {};
    final gameType = roundData['gameType'] as String?;
    Map<String, Object?> extra = {};
    if (gameType == 'emoji_telepathy') {
      try {
        final prompts = await EmojiTelepathyLogic.loadPrompts();
        final seed =
            (roundData['payload']?['seed'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final idx = prompts.isEmpty ? 0 : (seed % prompts.length).toInt();
        extra = {
          'payload.promptIndex': idx,
          'payload.prompt': prompts.isNotEmpty
              ? prompts[idx]
              : 'Make a choice!',
        };
      } catch (_) {
        // Swallow asset errors; proceed without prompt.
      }
    } else if (gameType == 'speed_categories') {
      try {
        final categories = await SpeedCategoriesLogic.loadCategories();
        final seed =
            (roundData['payload']?['seed'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final catIdx = categories.isEmpty
            ? 0
            : (seed % categories.length).toInt();
        final letter = SpeedCategoriesLogic.pickLetter(seed + 17);
        extra = {
          'payload.categoryIndex': catIdx,
          'payload.category': categories.isNotEmpty
              ? categories[catIdx]
              : 'Things',
          'payload.letter': letter,
        };
      } catch (_) {}
    } else if (gameType == 'odd_one_out') {
      try {
        // Determine spy and word; write spyId to round payload and word to secrets doc.
        final playersSnap = await FirestoreRefs.players(roomId).get();
        final playerIds = playersSnap.docs.map((d) => d.id).toList()..sort();
        final words = await OddOneOutLogic.loadWords();
        final seed =
            (roundData['payload']?['seed'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final spyId = OddOneOutLogic.pickSpyId(playerIds, seed);
        final wordIndex = OddOneOutLogic.pickWordIndex(words.length, seed + 31);
        final word = words.isNotEmpty ? words[wordIndex] : 'PIZZA';
        // Store the word in secrets path; payload only gets spyId.
        await FirestoreRefs.roomSecretRoundDoc(roomId, roundId).set({
          'word': word,
          'wordIndex': wordIndex,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        extra = {'payload.spyId': spyId, 'payload.wordIndex': wordIndex};
      } catch (_) {}
    } else if (gameType == 'bluff_trivia') {
      try {
        final pack = await BluffTriviaLogic.loadPack();
        final seed =
            (roundData['payload']?['seed'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final idx = pack.isEmpty ? 0 : (seed % pack.length).toInt();
        final q = pack.isNotEmpty ? pack[idx]['q']! : 'Placeholder question';
        final a = pack.isNotEmpty ? pack[idx]['a']! : 'Placeholder';
        // Store true answer in secrets; question in payload
        await FirestoreRefs.roomSecretRoundDoc(roomId, roundId).set({
          'trueAnswer': a,
          'qIndex': idx,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        extra = {'payload.question': q, 'payload.qIndex': idx};
      } catch (_) {}
    }

    await FirestoreRefs.roundDoc(roomId, roundId).update({
      'state': 'play',
      'startedAt': FieldValue.serverTimestamp(),
      'durationMs': durationMs,
      'timerEnd': approxEnd,
      'updatedAt': FieldValue.serverTimestamp(),
      ...extra,
    });
  }

  Future<void> lockRound(String roomId, String roundId) async {
    await _ensureHost(roomId);
    await FirestoreRefs.roundDoc(
      roomId,
      roundId,
    ).update({'state': 'lock', 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> openVoting(String roomId, String roundId) async {
    await _ensureHost(roomId);
    // For bluff_trivia: compile options from bluffs + true answer
    final roundSnap = await FirestoreRefs.roundDoc(roomId, roundId).get();
    final roundData = roundSnap.data() ?? {};
    if (roundData['gameType'] == 'bluff_trivia') {
      final subsSnap = await FirestoreRefs.submissions(roomId, roundId).get();
      final Map<String, String> bluffs = {
        for (final d in subsSnap.docs)
          d.id: (d.data()['bluff'] as String?) ?? '',
      };
      final secrets = await FirestoreRefs.roomSecretRoundDoc(
        roomId,
        roundId,
      ).get();
      final trueAnswer = (secrets.data()?['trueAnswer'] as String?) ?? '';
      final seed =
          (roundData['payload']?['seed'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch;
      final options = BluffTriviaLogic.buildOptions(
        bluffs: bluffs,
        trueAnswer: trueAnswer,
        seed: seed + 73,
      );
      await FirestoreRefs.roundDoc(
        roomId,
        roundId,
      ).update({'payload.options': options});
    }
    await FirestoreRefs.roundDoc(
      roomId,
      roundId,
    ).update({'state': 'vote', 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> resolveRound(String roomId, String roundId) async {
    await _ensureHost(roomId);
    final roundSnap = await FirestoreRefs.roundDoc(roomId, roundId).get();
    final roundData = roundSnap.data() ?? {};
    final gameType = roundData['gameType'] as String?;

    if (gameType == 'emoji_telepathy') {
      // Gather submissions and prior scores
      final subsSnap = await FirestoreRefs.submissions(roomId, roundId).get();
      final Map<String, String> submissions = {};
      for (final d in subsSnap.docs) {
        final choice = d.data()['choice'];
        if (choice is String && choice.isNotEmpty) {
          submissions[d.id] = choice;
        }
      }
      final playersSnap = await FirestoreRefs.players(roomId).get();
      final Map<String, int> priorScores = {
        for (final p in playersSnap.docs)
          p.id: ((p.data()['score'] as num?)?.toInt() ?? 0),
      };

      final result = EmojiTelepathyLogic.resolve(
        submissions: submissions,
        priorScores: priorScores,
      );
      final Map<String, int> deltas = (result['deltas'] as Map)
          .cast<String, int>();

      await FirestoreRefs.roundDoc(roomId, roundId).update({
        'state': 'results',
        'payload.results': {
          'deltas': deltas,
          'majorityChoices': result['majorityChoices'],
          'summary': result['summary'],
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Apply scores
      final batch = FirebaseFirestore.instance.batch();
      deltas.forEach((uid, delta) {
        final pRef = FirestoreRefs.playerDoc(roomId, uid);
        batch.update(pRef, {'score': FieldValue.increment(delta)});
      });
      await batch.commit();
    } else if (gameType == 'speed_categories') {
      // Gather submissions (word + createdAt) and prior scores
      final subsSnap = await FirestoreRefs.submissions(roomId, roundId).get();
      final Map<String, String> submissions = {};
      final Map<String, DateTime> created = {};
      for (final d in subsSnap.docs) {
        final data = d.data();
        final word = data['word'];
        if (word is String && word.isNotEmpty) {
          submissions[d.id] = word;
          final ts = data['createdAt'];
          if (ts is Timestamp) created[d.id] = ts.toDate();
        }
      }
      final playersSnap = await FirestoreRefs.players(roomId).get();
      final Map<String, int> priorScores = {
        for (final p in playersSnap.docs)
          p.id: ((p.data()['score'] as num?)?.toInt() ?? 0),
      };
      final letter = (roundData['payload']?['letter'] as String?) ?? 'A';
      final result = SpeedCategoriesLogic.resolve(
        submissions: submissions,
        letter: letter,
        priorScores: priorScores,
      );
      final Map<String, int> deltas = (result['deltas'] as Map)
          .cast<String, int>();

      // First valid by earliest createdAt timestamp among valid submissions
      String? firstValidPid;
      DateTime? earliest;
      submissions.forEach((pid, word) {
        final w = SpeedCategoriesLogic.norm(word);
        final isValid =
            w.isNotEmpty &&
            w[0].toLowerCase() == letter.toLowerCase() &&
            SpeedCategoriesLogic.isClean(w);
        final t = created[pid];
        if (isValid && t != null) {
          if (earliest == null || t.isBefore(earliest!)) {
            earliest = t;
            firstValidPid = pid;
          }
        }
      });
      if (firstValidPid != null) {
        deltas[firstValidPid!] = (deltas[firstValidPid!] ?? 0) + 2;
        // Reapply cap 20
        deltas.updateAll((_, v) => v > 20 ? 20 : v);
      }

      await FirestoreRefs.roundDoc(roomId, roundId).update({
        'state': 'results',
        'payload.results': {'deltas': deltas, 'summary': result['summary']},
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final batch = FirebaseFirestore.instance.batch();
      deltas.forEach((uid, delta) {
        final pRef = FirestoreRefs.playerDoc(roomId, uid);
        batch.update(pRef, {'score': FieldValue.increment(delta)});
      });
      await batch.commit();
    } else if (gameType == 'odd_one_out') {
      // Tally votes and score per Odd One Out rules
      final votesSnap = await FirestoreRefs.votes(roomId, roundId).get();
      final Map<String, String> votes = {};
      for (final d in votesSnap.docs) {
        final target = (d.data()['targetPlayerId'] as String?) ?? '';
        if (target.isNotEmpty) votes[d.id] = target;
      }
      final spyId = (roundData['payload']?['spyId'] as String?) ?? '';
      final tally = OddOneOutLogic.tally(votes);
      final eliminated = tally['eliminated'] as String?;
      final deltas = OddOneOutLogic.score(
        spyId: spyId,
        votes: votes,
        eliminated: eliminated,
      );

      await FirestoreRefs.roundDoc(roomId, roundId).update({
        'state': 'results',
        'payload.results': {
          'deltas': deltas,
          'eliminated': eliminated,
          'counts': tally['counts'],
          'spyId': spyId,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Apply scores
      final batch = FirebaseFirestore.instance.batch();
      deltas.forEach((uid, delta) {
        final pRef = FirestoreRefs.playerDoc(roomId, uid);
        batch.update(pRef, {'score': FieldValue.increment(delta)});
      });
      await batch.commit();
    } else if (gameType == 'bluff_trivia') {
      // Read votes and options; compute deltas per rules (correct +8; fooling +5 each victim, cap +10; self-vote = 0)
      final round = await FirestoreRefs.roundDoc(roomId, roundId).get();
      final optsRaw = round.data()?['payload']?['options'] as List? ?? const [];
      final options = optsRaw
          .cast<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      final votesSnap = await FirestoreRefs.votes(roomId, roundId).get();
      final Map<String, String> votes = {
        for (final d in votesSnap.docs)
          d.id: (d.data()['optionId'] as String?) ?? '',
      };
      final resolved = BluffTriviaLogic.resolveVotes(
        votes: votes,
        options: options,
      );
      final deltas = (resolved['deltas'] as Map).cast<String, int>();

      await FirestoreRefs.roundDoc(roomId, roundId).update({
        'state': 'results',
        'payload.results': {'deltas': deltas, 'voteCounts': resolved['counts']},
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final batch = FirebaseFirestore.instance.batch();
      deltas.forEach((uid, delta) {
        final pRef = FirestoreRefs.playerDoc(roomId, uid);
        batch.update(pRef, {'score': FieldValue.increment(delta)});
      });
      await batch.commit();
    } else {
      // Default vote-based resolution
      final votesSnap = await FirestoreRefs.votes(roomId, roundId).get();
      final Map<String, int> deltas = {};
      for (final d in votesSnap.docs) {
        final target = (d.data()['targetPlayerId'] as String?) ?? '';
        if (target.isEmpty) continue;
        deltas[target] = (deltas[target] ?? 0) + 10;
      }
      await FirestoreRefs.roundDoc(roomId, roundId).update({
        'state': 'results',
        'payload.results': {
          'deltas': deltas,
          'summary': {'voteCount': votesSnap.size},
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final batch = FirebaseFirestore.instance.batch();
      deltas.forEach((uid, delta) {
        final pRef = FirestoreRefs.playerDoc(roomId, uid);
        batch.update(pRef, {'score': FieldValue.increment(delta)});
      });
      await batch.commit();
    }
  }

  Future<void> nextRound(String roomId) async {
    await _ensureHost(roomId);
    final roomRef = FirestoreRefs.roomDoc(roomId);
    final roomSnap = await roomRef.get();
    final data = roomSnap.data() ?? {};
    final List<dynamic> playlist = (data['playlist'] as List?) ?? [];
    final int index = (data['roundIndex'] as num?)?.toInt() ?? 0;
    if (index + 1 < playlist.length) {
      await roomRef.update({
        'roundIndex': index + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await roomRef.update({
        'status': 'ended',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
