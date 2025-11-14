import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/state/answer_controller.dart';
import 'package:lamaplay/services/sound_service.dart';

class QuestionPlayerScreen extends StatefulWidget {
  final String sessionId;
  const QuestionPlayerScreen({super.key, required this.sessionId});

  @override
  State<QuestionPlayerScreen> createState() => _QuestionPlayerScreenState();
}

class _QuestionPlayerScreenState extends State<QuestionPlayerScreen> {
  final _quizRepo = QuizRepository();
  final _answerCtrl = AnswerController();
  dynamic _submittedValue;
  int _lastQuestionIndex = -1; // Track the current question index

  @override
  Widget build(BuildContext context) {
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId);
    return StreamBuilder(
      stream: sessionRef.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(body: Center(child: Text('Loading session')));
        }
        final data = snap.data!.data()!;
        final quizId = data['quizId'] as String;
        final index = (data['currentQuestionIndex'] as num?)?.toInt() ?? -1;
        final state = data['questionState'] as String? ?? 'intro';
        final endAt = (data['questionEndAt'] as Timestamp?)?.toDate();

        // Auto-navigate to podium when session ends
        if (state == 'ended') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(
                context,
              ).pushReplacementNamed('/podium', arguments: widget.sessionId);
            }
          });
        }

        // Reset submitted value when question changes
        if (index != _lastQuestionIndex) {
          _submittedValue = null;
          _lastQuestionIndex = index;
        }

        return FutureBuilder(
          future: Future.wait([
            _quizRepo.getQuestions(quizId),
            _quizRepo.getQuiz(quizId),
          ]),
          builder: (context, qsNap) {
            final questions =
                (qsNap.data?[0] as List<dynamic>?) ?? const <dynamic>[];
            final quiz = qsNap.data?[1] as QuizMeta?;
            final gameMode = quiz?.gameMode ?? 'standard';
            QuizQuestion? q;
            if (index >= 0 && index < questions.length) q = questions[index];

            // Build the main question UI
            final questionUI = PopScope(
              canPop: state == 'ended',
              onPopInvoked: (didPop) async {
                if (!didPop && context.mounted) {
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
                backgroundColor: const Color(0xFFF5F7FA),
                appBar: AppBar(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400]!,
                              Colors.deepPurple[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.quiz,
                              size: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                    ),
                  ),
                ),
                body: q == null
                    ? Center(
                        child:
                            Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 20,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 3,
                                              ),
                                        )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(),
                                        )
                                        .shimmer(duration: 1500.ms),
                                    const SizedBox(height: 32),
                                    Text(
                                      '⏳ Waiting for host...',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'The quiz will begin shortly',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .scale(begin: const Offset(0.8, 0.8)),
                      )
                    : Column(
                        children: [
                          // Live timer at top
                          if (state == 'answering' && endAt != null)
                            Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange[600]!,
                                        Colors.red[500]!,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _PlayerLiveTimer(endAt: endAt),
                                )
                                .animate()
                                .slideY(begin: -1, duration: 400.ms)
                                .fadeIn(),
                          Expanded(
                            child: _buildQuestion(context, q, state, gameMode),
                          ),
                        ],
                      ),
              ), // Scaffold
            ); // PopScope

            // Navigate to leaderboard when in reveal state
            if (state == 'reveal' && index >= 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed(
                    '/questionLeaderboard',
                    arguments: {'sessionId': widget.sessionId, 'qIndex': index},
                  );
                }
              });
            }

            return questionUI;
          },
        );
      },
    );
  }

  Widget _buildQuestion(
    BuildContext context,
    QuizQuestion q,
    String state,
    String gameMode,
  ) {
    final answering = state == 'answering';
    final revealing = state == 'reveal';

    switch (q.type) {
      case QuestionType.mcq:
      case QuestionType.tf:
      case QuestionType.image:
      case QuestionType.poll:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Show game mode indicator
            if (gameMode != 'standard')
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getGameModeColors(gameMode),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getGameModeColors(gameMode)[0].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getGameModeIcon(gameMode),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getGameModeName(gameMode),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (gameMode == 'uniqueAnswer') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Think Unique!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.5, end: 0),

            // Show result summary during reveal
            if (revealing && q.correctIndex != null)
              Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: (_submittedValue == q.correctIndex)
                            ? [Colors.green[400]!, Colors.green[600]!]
                            : [Colors.red[500]!, Colors.red[700]!],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              ((_submittedValue == q.correctIndex)
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                (_submittedValue == q.correctIndex)
                                    ? Icons.emoji_events
                                    : Icons.highlight_off,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                (_submittedValue == q.correctIndex)
                                    ? '🎉 Correct!'
                                    : '❌ Wrong Answer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_submittedValue != q.correctIndex) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[600],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Correct Answer:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.green[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    q.options[q.correctIndex!].toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(
                    begin: -0.3,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  )
                  .scale(begin: const Offset(0.9, 0.9)),

            // Question text card with enhanced styling
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Colors.purple[50]!.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purple[100]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.deepPurple[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      q.text,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        height: 1.4,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

            // Options
            ...List.generate(q.options.length, (i) {
              final opt = q.options[i];
              final selected = _submittedValue == i;
              final isCorrect = q.correctIndex == i;
              final showCorrect = revealing && isCorrect;
              final showWrong = revealing && selected && !isCorrect;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: selected ? 1.02 : 1.0,
                  child:
                      ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              backgroundColor: showCorrect
                                  ? Colors.green[500]
                                  : showWrong
                                  ? Colors.red[500]
                                  : selected
                                  ? Colors.purple[500]
                                  : Colors.white,
                              foregroundColor:
                                  (showCorrect || showWrong || selected)
                                  ? Colors.white
                                  : Colors.grey[800],
                              elevation: selected ? 12 : 3,
                              shadowColor: showCorrect
                                  ? Colors.green.withOpacity(0.5)
                                  : showWrong
                                  ? Colors.red.withOpacity(0.5)
                                  : selected
                                  ? Colors.purple.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: showCorrect
                                      ? Colors.green[700]!
                                      : showWrong
                                      ? Colors.red[700]!
                                      : selected
                                      ? Colors.purple[700]!
                                      : Colors.grey[300]!,
                                  width: 3,
                                ),
                              ),
                            ),
                            onPressed: (!answering || _submittedValue != null)
                                ? null
                                : () async {
                                    SoundService().play(SoundEffect.buttonTap);
                                    setState(() => _submittedValue = i);
                                    await _answerCtrl.submitAnswer(
                                      sessionId: widget.sessionId,
                                      qIndex: q.index,
                                      value: i,
                                    );
                                    SoundService().play(SoundEffect.success);
                                  },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: showCorrect
                                        ? Colors.white.withOpacity(0.3)
                                        : showWrong
                                        ? Colors.white.withOpacity(0.3)
                                        : selected
                                        ? Colors.white.withOpacity(0.25)
                                        : Colors.purple[100],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          (showCorrect || showWrong || selected)
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.purple[200]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: showCorrect
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : showWrong
                                        ? const Icon(
                                            Icons.cancel,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : Text(
                                            String.fromCharCode(65 + i),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: selected
                                                  ? Colors.white
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child:
                                      q.type == QuestionType.image &&
                                          opt.toString().startsWith('http')
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            opt.toString(),
                                            height: 120,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                height: 120,
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
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    height: 120,
                                                    alignment: Alignment.center,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.broken_image,
                                                          color:
                                                              Colors.grey[400],
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Image failed to load',
                                                          style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : Text(
                                          opt.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                selected ||
                                                    showCorrect ||
                                                    showWrong
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          )
                          .animate(target: showCorrect ? 1 : 0)
                          .scale(
                            duration: 400.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(1, 1),
                            end: const Offset(1.05, 1.05),
                          )
                          .shimmer(duration: 1000.ms, color: Colors.white)
                          .animate(target: showWrong ? 1 : 0)
                          .shake(duration: 400.ms, hz: 5)
                          .shimmer(
                            delay: (400 + (i * 100)).ms,
                            duration: 800.ms,
                            color: Colors.white.withOpacity(0.4),
                          ),
                ),
              );
            }),
            if (_submittedValue != null)
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Center(child: Text('Answer locked')),
              ),
          ],
        );
      case QuestionType.numeric:
        return _NumericAnswerForm(
          answering: answering,
          submittedValue: _submittedValue,
          onSubmit: (val) async {
            setState(() => _submittedValue = val);
            await _answerCtrl.submitAnswer(
              sessionId: widget.sessionId,
              qIndex: q.index,
              value: val,
            );
          },
        );
      case QuestionType.order:
        return _OrderAnswerForm(
          q: q,
          answering: answering,
          submittedValue: _submittedValue,
          onSubmit: (val) async {
            setState(() => _submittedValue = val);
            await _answerCtrl.submitAnswer(
              sessionId: widget.sessionId,
              qIndex: q.index,
              value: val,
            );
          },
        );
    }
  }

  List<Color> _getGameModeColors(String gameMode) {
    switch (gameMode) {
      case 'uniqueAnswer':
        return [Colors.purple[400]!, Colors.deepPurple[600]!];
      case 'majorityRules':
        return [Colors.green[400]!, Colors.teal[600]!];
      case 'liar':
        return [Colors.amber[600]!, Colors.orange[700]!];
      case 'truthOrDare':
        return [Colors.pink[400]!, Colors.purple[500]!];
      case 'hrissa':
        return [Colors.orange[600]!, Colors.red[600]!];
      default:
        return [Colors.blue[400]!, Colors.blue[600]!];
    }
  }

  String _getGameModeIcon(String gameMode) {
    switch (gameMode) {
      case 'uniqueAnswer':
        return '🧠';
      case 'majorityRules':
        return '👥';
      case 'liar':
        return '🤥';
      case 'truthOrDare':
        return '🎭';
      case 'hrissa':
        return '🌶️';
      default:
        return '🎯';
    }
  }

  String _getGameModeName(String gameMode) {
    switch (gameMode) {
      case 'uniqueAnswer':
        return 'UNIQUE ANSWER MODE';
      case 'majorityRules':
        return 'الأغلبية - MAJORITY RULES';
      case 'liar':
        return 'الكذاب - THE LIAR';
      case 'truthOrDare':
        return 'TRUTH OR DARE';
      case 'hrissa':
        return 'HRISSA HOT SEAT';
      default:
        return 'STANDARD';
    }
  }
}

class _NumericAnswerForm extends StatefulWidget {
  final bool answering;
  final dynamic submittedValue;
  final ValueChanged<num> onSubmit;
  const _NumericAnswerForm({
    required this.answering,
    required this.submittedValue,
    required this.onSubmit,
  });

  @override
  State<_NumericAnswerForm> createState() => _NumericAnswerFormState();
}

class _NumericAnswerFormState extends State<_NumericAnswerForm> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.submittedValue != null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _ctrl,
            enabled: widget.answering && !locked,
            decoration: const InputDecoration(labelText: 'Your number'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (!widget.answering || locked)
                ? null
                : () {
                    final raw = num.tryParse(_ctrl.text.trim());
                    if (raw == null) return;
                    widget.onSubmit(raw);
                  },
            child: Text(locked ? 'Submitted' : 'Submit'),
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text('Answer locked'),
            ),
        ],
      ),
    );
  }
}

/// Order Question Answer Form with Drag-and-Drop Reordering
class _OrderAnswerForm extends StatefulWidget {
  final QuizQuestion q;
  final bool answering;
  final String? submittedValue;
  final Future<void> Function(String) onSubmit;

  const _OrderAnswerForm({
    required this.q,
    required this.answering,
    required this.submittedValue,
    required this.onSubmit,
  });

  @override
  State<_OrderAnswerForm> createState() => _OrderAnswerFormState();
}

class _OrderAnswerFormState extends State<_OrderAnswerForm> {
  late List<String> _currentOrder;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with shuffled order (or preserve submitted order if already answered)
    if (widget.submittedValue != null && widget.submittedValue!.isNotEmpty) {
      try {
        // Parse submitted order (format: "0,2,1,3")
        _currentOrder = widget.submittedValue!.split(',').map((idx) {
          final index = int.parse(idx);
          return widget.q.options[index] as String;
        }).toList();
      } catch (e) {
        _currentOrder = List<String>.from(widget.q.options);
      }
    } else {
      _currentOrder = List<String>.from(widget.q.options)..shuffle();
    }
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    // Convert current order to indices (format: "0,2,1,3")
    final indices = _currentOrder
        .map((item) {
          return widget.q.options.indexOf(item).toString();
        })
        .join(',');

    await widget.onSubmit(indices);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubmitted = widget.submittedValue != null;

    return Column(
      children: [
        if (!hasSubmitted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Drag items to reorder them correctly',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
            ),
          ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _currentOrder.length,
            onReorder: hasSubmitted
                ? (oldIndex, newIndex) {}
                : (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final item = _currentOrder.removeAt(oldIndex);
                      _currentOrder.insert(newIndex, item);
                    });
                  },
            buildDefaultDragHandles: !hasSubmitted,
            itemBuilder: (context, index) {
              final item = _currentOrder[index];
              return Card(
                key: ValueKey('order_item_$item'),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: hasSubmitted ? 1 : 2,
                color: hasSubmitted ? Colors.grey[200] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasSubmitted
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item,
                    style: TextStyle(
                      color: hasSubmitted ? Colors.grey[700] : null,
                    ),
                  ),
                  trailing: hasSubmitted
                      ? const Icon(Icons.lock, color: Colors.grey)
                      : const Icon(Icons.drag_handle),
                ),
              );
            },
          ),
        ),
        if (!hasSubmitted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.answering && !_isSubmitting
                    ? _submitOrder
                    : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Answer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        if (hasSubmitted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Answer Submitted!',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Player Live Timer with Progress Bar
class _PlayerLiveTimer extends StatefulWidget {
  final DateTime endAt;

  const _PlayerLiveTimer({required this.endAt});

  @override
  State<_PlayerLiveTimer> createState() => _PlayerLiveTimerState();
}

class _PlayerLiveTimerState extends State<_PlayerLiveTimer> {
  late Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _timerStream = Stream.periodic(const Duration(milliseconds: 100), (_) {
      final remaining = widget.endAt.difference(DateTime.now().toUtc());
      return remaining.inMilliseconds.clamp(0, double.infinity).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _timerStream,
      builder: (context, snapshot) {
        final milliseconds = snapshot.data ?? 0;
        final seconds = (milliseconds / 1000).ceil();
        final isLow = seconds <= 5 && seconds > 0;
        final isVeryLow = seconds <= 3 && seconds > 0;

        // Calculate progress (assume 30 seconds max for demo)
        final totalSeconds = 30;
        final progress = (milliseconds / (totalSeconds * 1000)).clamp(0.0, 1.0);

        return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isVeryLow
                            ? Icons.warning_amber_rounded
                            : Icons.timer_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLow ? '⏰ Hurry!' : 'Time Remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${seconds}s',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isLow ? Colors.white : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            )
            .animate(target: isVeryLow ? 1 : 0)
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 400.ms,
            )
            .then()
            .scale(
              begin: const Offset(1.05, 1.05),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
            );
      },
    );
  }
}
