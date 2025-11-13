import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/state/session_controller.dart';
import 'package:lamaplay/services/auth_service.dart';

class QuestionHostScreen extends StatelessWidget {
  final String sessionId;
  const QuestionHostScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    final quizRepo = QuizRepository();
    final controller = SessionController();
    final auth = AuthService();
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId);
    return StreamBuilder(
      stream: sessionRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Loading session')));
        }
        final data = snap.data!.data()!;
        final quizId = data['quizId'] as String;
        final qIndex = (data['currentQuestionIndex'] as num?)?.toInt() ?? -1;
        final state = data['questionState'] as String? ?? 'intro';
        final startAt = (data['questionStartAt'] as Timestamp?)?.toDate();
        final endAt = (data['questionEndAt'] as Timestamp?)?.toDate();
        final isHost = data['hostId'] == auth.uid;

        // Auto-navigate to podium when session ends
        if (state == 'ended') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushReplacementNamed('/podium', arguments: sessionId);
            }
          });
        }

        // Don't auto-navigate host to leaderboard - host needs to control progression
        // Players will auto-navigate via question_player_screen.dart

        return FutureBuilder(
          future: quizRepo.getQuestions(quizId),
          builder: (context, qsNap) {
            final questions = qsNap.data ?? const <dynamic>[];
            QuizQuestion? current;
            if (qIndex >= 0 && qIndex < questions.length) {
              current = questions[qIndex];
            }

            // Check if host is also a player
            return StreamBuilder(
              stream: sessionRef
                  .collection('players')
                  .doc(auth.uid)
                  .snapshots(),
              builder: (context, playerSnap) {
                final isHostPlayer =
                    playerSnap.hasData && playerSnap.data!.exists;

                return PopScope(
                  canPop: state == 'ended',
                  onPopInvoked: (didPop) async {
                    if (!didPop && context.mounted) {
                      // Show confirmation dialog
                      final shouldExit = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Leave Quiz?'),
                          content: const Text(
                            'The quiz is still in progress. Do you want to leave?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Leave'),
                            ),
                          ],
                        ),
                      );

                      if (shouldExit == true && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  child: Scaffold(
                    backgroundColor: Colors.grey[50],
                    appBar: AppBar(
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isHostPlayer
                                  ? Colors.deepPurple[700]
                                  : Colors.blue[700],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isHostPlayer
                                              ? Colors.deepPurple
                                              : Colors.blue)
                                          .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHostPlayer
                                      ? Icons.sports_esports
                                      : Icons.manage_accounts,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Q${qIndex + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHostPlayer ? 'Playing as Host' : 'Host Control',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      elevation: 0,
                      flexibleSpace: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isHostPlayer
                                ? [Colors.deepPurple[600]!, Colors.purple[500]!]
                                : [Colors.blue[600]!, Colors.cyan[500]!],
                          ),
                        ),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isHostPlayer &&
                              current != null &&
                              state == 'answering')
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple[100]!,
                                    Colors.purple[50]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purple[400]!,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[600],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.sports_esports,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'You are playing! Answer below',
                                    style: TextStyle(
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (current != null) ...[
                            Text(
                              current.text,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            if (current.media != null)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.asset(
                                  current.media!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Text('Image')),
                                ),
                              ),
                            const SizedBox(height: 12),
                            if (isHostPlayer && state == 'answering')
                              _HostAnswerInterface(
                                sessionId: sessionId,
                                question: current,
                                qIndex: qIndex,
                              )
                            else
                              _OptionsPreview(q: current),
                          ],
                          const Spacer(),
                          // Live answer count
                          if (current != null && state == 'answering')
                            _LiveAnswerCount(
                              sessionId: sessionId,
                              qIndex: qIndex,
                            ),
                          // Show answer statistics during reveal
                          if (current != null && state == 'reveal')
                            _AnswerStatistics(
                              sessionId: sessionId,
                              qIndex: qIndex,
                              question: current,
                            ),
                          const SizedBox(height: 8),
                          // Auto-progression info
                          if (state == 'answering')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.blue[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Waiting for players to answer...',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (state == 'reveal')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Click "Skip Wait" to continue',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text('State: $state'),
                          if (startAt != null && endAt != null)
                            _LiveTimer(
                              endAt: endAt,
                              sessionId: sessionId,
                              state: state,
                              controller: controller,
                              autoRevealEnabled: false, // Disabled auto-reveal
                            ),
                          const SizedBox(height: 12),
                          if (isHost)
                            _AutoNextHandler(
                              state: state,
                              sessionId: sessionId,
                              controller: controller,
                              qIndex: qIndex,
                              totalQuestions: questions.length,
                              autoNextEnabled: false, // Disabled auto-next
                            ),
                          if (isHost)
                            _HostButtons(
                              state: state,
                              sessionId: sessionId,
                              controller: controller,
                            ),
                        ],
                      ),
                    ),
                  ), // Scaffold
                ); // PopScope
              },
            );
          },
        );
      },
    );
  }
}

/// Auto-Next Handler - automatically progresses to next question after reveal
class _AutoNextHandler extends StatefulWidget {
  final String state;
  final String sessionId;
  final SessionController controller;
  final int qIndex;
  final int totalQuestions;
  final bool autoNextEnabled;

  const _AutoNextHandler({
    required this.state,
    required this.sessionId,
    required this.controller,
    required this.qIndex,
    required this.totalQuestions,
    this.autoNextEnabled = true,
  });

  @override
  State<_AutoNextHandler> createState() => _AutoNextHandlerState();
}

class _AutoNextHandlerState extends State<_AutoNextHandler> {
  bool _autoNextTriggered = false;
  int? _lastRevealedQuestion;

  @override
  void didUpdateWidget(_AutoNextHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset trigger when question changes
    if (oldWidget.qIndex != widget.qIndex) {
      _autoNextTriggered = false;
      _lastRevealedQuestion = null;
    }
  }

  void _triggerAutoNext() async {
    if (!widget.autoNextEnabled) return; // Don't auto-advance if disabled
    if (_autoNextTriggered || _lastRevealedQuestion == widget.qIndex) return;
    _autoNextTriggered = true;
    _lastRevealedQuestion = widget.qIndex;

    // Wait for leaderboard to be shown (6 seconds)
    await Future.delayed(const Duration(seconds: 6));

    if (mounted && widget.state == 'reveal') {
      await widget.controller.nextQuestion(sessionId: widget.sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger auto-next when in reveal state
    if (widget.state == 'reveal' &&
        !_autoNextTriggered &&
        _lastRevealedQuestion != widget.qIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAutoNext();
      });
    }

    // Show countdown during reveal
    if (widget.state == 'reveal' && _autoNextTriggered) {
      return FutureBuilder(
        future: Future.delayed(const Duration(seconds: 6)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final isLastQuestion = widget.qIndex >= widget.totalQuestions - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                isLastQuestion
                    ? 'Going to final results...'
                    : 'Next question loading...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _HostButtons extends StatelessWidget {
  final String state;
  final String sessionId;
  final SessionController controller;
  const _HostButtons({
    required this.state,
    required this.sessionId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (state == 'answering')
          ElevatedButton.icon(
            onPressed: () => controller.reveal(sessionId: sessionId),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('Reveal Answers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        if (state == 'reveal')
          ElevatedButton.icon(
            onPressed: () => controller.nextQuestion(sessionId: sessionId),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Next Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

class _OptionsPreview extends StatelessWidget {
  final QuizQuestion q;
  const _OptionsPreview({required this.q});

  @override
  Widget build(BuildContext context) {
    if (q.type == QuestionType.numeric || q.type == QuestionType.poll) {
      return Text('${q.options.length} options');
    }
    if (q.options.isEmpty) return const Text('No options');

    // For image questions, show images
    if (q.type == QuestionType.image) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(q.options.length, (i) {
            final opt = q.options[i];
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Option ${String.fromCharCode(65 + i)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: Image.network(
                      opt.toString(),
                      height: 80,
                      width: 120,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 80,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // For text-based questions
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(q.options.length, (i) {
          final opt = q.options[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('${i + 1}. $opt'),
          );
        }),
      ],
    );
  }
}

class _LiveAnswerCount extends StatelessWidget {
  final String sessionId;
  final int qIndex;
  const _LiveAnswerCount({required this.sessionId, required this.qIndex});

  @override
  Widget build(BuildContext context) {
    // Watch both players and answers collections
    final playersStream = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('players')
        .snapshots();

    final answersStream = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .where('questionIndex', isEqualTo: qIndex)
        .snapshots();

    return StreamBuilder(
      stream: playersStream,
      builder: (context, playersSnap) {
        return StreamBuilder(
          stream: answersStream,
          builder: (context, answersSnap) {
            final totalPlayers = playersSnap.data?.docs.length ?? 0;
            final answeredCount = answersSnap.data?.docs.length ?? 0;

            final percentage = totalPlayers > 0
                ? (answeredCount / totalPlayers * 100).toInt()
                : 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$answeredCount/$totalPlayers players answered',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '($percentage%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LiveTimer extends StatefulWidget {
  final DateTime endAt;
  final String sessionId;
  final String state;
  final SessionController controller;
  final bool autoRevealEnabled;

  const _LiveTimer({
    required this.endAt,
    required this.sessionId,
    required this.state,
    required this.controller,
    this.autoRevealEnabled = true,
  });

  @override
  State<_LiveTimer> createState() => _LiveTimerState();
}

class _LiveTimerState extends State<_LiveTimer> {
  late Stream<int> _timerStream;
  bool _autoRevealTriggered = false;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(milliseconds: 100), (_) {
      final remaining = widget.endAt.difference(DateTime.now().toUtc());
      return remaining.inSeconds.clamp(0, double.infinity).toInt();
    });
  }

  @override
  void didUpdateWidget(_LiveTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset trigger when question changes
    if (oldWidget.endAt != widget.endAt) {
      _autoRevealTriggered = false;
    }
  }

  void _triggerAutoReveal() async {
    if (!widget.autoRevealEnabled) return; // Don't auto-reveal if disabled
    if (_autoRevealTriggered) return;
    _autoRevealTriggered = true;

    // Wait 3 seconds after timer expires to give players time to submit
    await Future.delayed(const Duration(seconds: 3));

    if (mounted && widget.state == 'answering') {
      await widget.controller.reveal(sessionId: widget.sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final seconds = snapshot.data ?? 0;
        final isLow = seconds <= 5 && seconds > 0;

        // Auto-reveal when timer expires (only trigger once when it hits exactly 0)
        if (seconds <= 0 &&
            widget.state == 'answering' &&
            !_autoRevealTriggered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerAutoReveal();
          });
        }

        return Row(
          children: [
            Icon(
              Icons.timer,
              color: isLow
                  ? Colors.red
                  : seconds <= 0
                  ? Colors.orange
                  : Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              seconds <= 0
                  ? _autoRevealTriggered
                        ? 'Revealing answers...'
                        : 'Time up! Get your answers in!'
                  : 'Time left: ${seconds}s',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isLow
                    ? Colors.red
                    : seconds <= 0
                    ? Colors.orange
                    : Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Host Answer Interface - allows host to answer while controlling the game
class _HostAnswerInterface extends StatefulWidget {
  final String sessionId;
  final QuizQuestion question;
  final int qIndex;

  const _HostAnswerInterface({
    required this.sessionId,
    required this.question,
    required this.qIndex,
  });

  @override
  State<_HostAnswerInterface> createState() => _HostAnswerInterfaceState();
}

class _HostAnswerInterfaceState extends State<_HostAnswerInterface> {
  dynamic _selectedAnswer;
  bool _submitted = false;
  List<String>? _currentOrder; // For order questions

  @override
  void didUpdateWidget(_HostAnswerInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset when question changes
    if (oldWidget.qIndex != widget.qIndex) {
      setState(() {
        _selectedAnswer = null;
        _submitted = false;
        _currentOrder = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize order for order questions
    if (widget.question.type == QuestionType.order) {
      _currentOrder = List<String>.from(widget.question.options)..shuffle();
    }
  }

  Future<void> _submitAnswer(dynamic value) async {
    if (_submitted) return;

    setState(() {
      _selectedAnswer = value;
      _submitted = true;
    });

    // Submit answer to Firestore
    final auth = AuthService();
    final startAt =
        (await FirebaseFirestore.instance
                    .collection('sessions')
                    .doc(widget.sessionId)
                    .get())
                .data()?['questionStartAt']
            as Timestamp?;

    final timeMsFromStart = startAt != null
        ? DateTime.now().toUtc().difference(startAt.toDate()).inMilliseconds
        : 0;

    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .collection('answers')
        .add({
          'playerId': auth.uid,
          'questionIndex': widget.qIndex,
          'qIndex': widget.qIndex,
          'value': value,
          'answeredAt': FieldValue.serverTimestamp(),
          'timeMsFromStart': timeMsFromStart,
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _submitted ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _submitted ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _submitted ? Icons.check_circle : Icons.touch_app,
                color: _submitted ? Colors.green : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(
                _submitted ? 'Answer Submitted!' : 'Your Answer:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _submitted ? Colors.green[700] : Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.question.type == QuestionType.mcq ||
              widget.question.type == QuestionType.tf ||
              widget.question.type == QuestionType.image ||
              widget.question.type == QuestionType.poll)
            widget.question.type == QuestionType.image
                ? Column(
                    children: List.generate(widget.question.options.length, (
                      i,
                    ) {
                      final option = widget.question.options[i];
                      final isSelected = _selectedAnswer == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: _submitted ? null : () => _submitAnswer(i),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Colors.purple[400]!
                                    : Colors.grey[300]!,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: isSelected
                                  ? Colors.purple[50]
                                  : Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.purple[400]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        String.fromCharCode(
                                          65 + i,
                                        ), // A, B, C, D
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.purple,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    option.toString(),
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 150,
                                            alignment: Alignment.center,
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Image failed to load',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(widget.question.options.length, (
                      i,
                    ) {
                      final option = widget.question.options[i];
                      final isSelected = _selectedAnswer == i;
                      return ChoiceChip(
                        label: Text(option.toString()),
                        selected: isSelected,
                        onSelected: _submitted
                            ? null
                            : (selected) {
                                if (selected) _submitAnswer(i);
                              },
                        selectedColor: Colors.purple[300],
                      );
                    }).toList(),
                  ),
          if (widget.question.type == QuestionType.numeric)
            TextField(
              enabled: !_submitted,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter number',
                filled: true,
                fillColor: _submitted ? Colors.grey[200] : Colors.white,
              ),
              onSubmitted: _submitted
                  ? null
                  : (value) {
                      final num = double.tryParse(value);
                      if (num != null) _submitAnswer(num);
                    },
            ),
          if (widget.question.type == QuestionType.order)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentOrder != null && !_submitted)
                  ...List.generate(_currentOrder!.length, (i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '${i + 1}.',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(_currentOrder![i]),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              if (i > 0)
                                IconButton(
                                  icon: const Icon(Icons.arrow_upward),
                                  onPressed: () {
                                    setState(() {
                                      final temp = _currentOrder![i];
                                      _currentOrder![i] = _currentOrder![i - 1];
                                      _currentOrder![i - 1] = temp;
                                    });
                                  },
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              if (i < _currentOrder!.length - 1)
                                IconButton(
                                  icon: const Icon(Icons.arrow_downward),
                                  onPressed: () {
                                    setState(() {
                                      final temp = _currentOrder![i];
                                      _currentOrder![i] = _currentOrder![i + 1];
                                      _currentOrder![i + 1] = temp;
                                    });
                                  },
                                  iconSize: 20,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                if (!_submitted) const SizedBox(height: 8),
                if (!_submitted)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Convert current order to indices
                      final indices = _currentOrder!
                          .map((item) => widget.question.options.indexOf(item))
                          .join(',');
                      _submitAnswer(indices);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Submit Order'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_submitted)
                  Text(
                    'Order submitted: ${_selectedAnswer}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Answer Statistics - shows how players answered during reveal
class _AnswerStatistics extends StatelessWidget {
  final String sessionId;
  final int qIndex;
  final QuizQuestion question;

  const _AnswerStatistics({
    required this.sessionId,
    required this.qIndex,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final resultsRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('results')
        .doc('q_$qIndex');

    return StreamBuilder(
      stream: resultsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Calculating results...'),
              ],
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final optionCounts = (data['optionCounts'] as Map?) ?? {};
        final perPlayer = (data['perPlayer'] as Map?) ?? {};

        final totalAnswers = perPlayer.length;
        final correctCount = perPlayer.values
            .where((v) => (v as Map)['correct'] == true)
            .length;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Answer Statistics',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$correctCount / $totalAnswers correct (${totalAnswers > 0 ? ((correctCount / totalAnswers * 100).toStringAsFixed(0)) : '0'}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (optionCounts.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 4),
                ...optionCounts.entries.map((entry) {
                  final optionIndex = int.tryParse(entry.key.toString());
                  final count = entry.value as int;
                  final percentage = totalAnswers > 0
                      ? (count / totalAnswers * 100).toStringAsFixed(0)
                      : '0';

                  final optionText =
                      optionIndex != null &&
                          optionIndex < question.options.length
                      ? question.options[optionIndex].toString()
                      : entry.key.toString();

                  final isCorrect = optionIndex == question.correctIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        if (isCorrect)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        if (isCorrect) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontWeight: isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCorrect ? Colors.green[700] : null,
                            ),
                          ),
                        ),
                        Text(
                          '$count ($percentage%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCorrect
                                ? Colors.green[700]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}
