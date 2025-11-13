import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/repositories/session_repository.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/state/session_controller.dart';
import 'package:lamaplay/core/router.dart';
import 'package:lamaplay/widgets/player_list_widget.dart';

class SessionLobbyScreen extends StatefulWidget {
  final String sessionId;
  const SessionLobbyScreen({super.key, required this.sessionId});

  @override
  State<SessionLobbyScreen> createState() => _SessionLobbyScreenState();
}

class _SessionLobbyScreenState extends State<SessionLobbyScreen> {
  bool _hasNavigated = false;
  bool _hostPlays = false; // Host participation toggle

  @override
  Widget build(BuildContext context) {
    final repo = SessionRepository();
    final quizRepo = QuizRepository();
    final auth = AuthService();
    final controller = SessionController();
    return StreamBuilder(
      stream: repo.watchSession(widget.sessionId),
      builder: (context, snap) {
        final session = snap.data;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('Loading session...')),
          );
        }

        // Auto-navigate when session starts
        if (session.status == 'running' && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final isHost = session.hostId == auth.uid;
            Navigator.pushReplacementNamed(
              context,
              isHost ? AppRouter.questionHost : AppRouter.questionPlayer,
              arguments: widget.sessionId,
            );
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              '🎮 Game Lobby',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[600]!, Colors.purple[500]!],
                ),
              ),
            ),
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder(
            future: quizRepo.getQuiz(session.quizId),
            builder: (context, qSnap) {
              final quiz = qSnap.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[100]!, Colors.blue[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple[300]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz?.title ?? 'Quiz',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[900],
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple[400]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin,
                                color: Colors.purple[700],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'PIN: ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SelectableText(
                                session.pin,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[800],
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Players',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: PlayerListWidget(sessionId: widget.sessionId),
                  ),
                  if (session.hostId == auth.uid)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.purple[200]!),
                              ),
                              child: CheckboxListTile(
                                value: _hostPlays,
                                onChanged: (value) {
                                  setState(() {
                                    _hostPlays = value ?? false;
                                  });
                                },
                                title: const Text(
                                  'I want to play too',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Join as a participant and compete for points',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.green.withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  await controller.startSession(
                                    sessionId: widget.sessionId,
                                    hostPlays: _hostPlays,
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow, size: 28),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Quiz',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
