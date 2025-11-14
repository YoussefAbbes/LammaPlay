import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/state/session_controller.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/widgets/session_settings_dialog.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/screens/templates_browser_screen.dart';
import 'package:lamaplay/screens/hrissa_cards_menu_screen.dart';

/// Modern home screen: Host (create quiz/start session) or Player (join by PIN).
class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  final _auth = AuthService();
  final _sessionCtrl = SessionController();
  final _quizRepo = QuizRepository();
  final _pinController = TextEditingController();

  bool _isHost = true; // Toggle between host/player mode
  bool _loading = false;
  String? _error;
  List<QuizMeta> _quizzes = [];
  QuizMeta? _selectedQuiz;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _auth.ensureSignedInAnonymously();
    _loadQuizzes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset state when returning to this screen
    if (!_loading) {
      _resetState();
    }
  }

  void _resetState() {
    setState(() {
      _loading = false;
      _error = null;
      _pinController.clear();
    });
  }

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _quizRepo.getAllQuizzes();
      if (mounted) {
        setState(() => _quizzes = quizzes);
      }
    } catch (e) {
      _showError('Failed to load quizzes: $e');
    }
  }

  Future<void> _createSession() async {
    if (_selectedQuiz == null) {
      _showError('Please select a quiz');
      return;
    }

    // Show settings dialog
    final settings = await showDialog<SessionSettings>(
      context: context,
      builder: (context) => const SessionSettingsDialog(),
    );

    if (settings == null) return; // User cancelled

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessionId = await _sessionCtrl.createSession(
        _selectedQuiz!.id,
        settings: settings.toJson(),
      );
      if (mounted) {
        setState(() => _loading = false);
        SoundService().play(SoundEffect.success);
        _showSuccess('Session created successfully!');
        await Navigator.pushNamed(
          context,
          '/sessionLobby',
          arguments: sessionId,
        );
        // Reset state when returning
        if (mounted) _resetState();
      }
    } catch (e) {
      _showError('Failed to create session: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinByPin() async {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      _showError('PIN must be 6 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessionId = await _sessionCtrl.joinByPin(pin);
      if (sessionId == null) {
        _showError('Invalid PIN. Session not found.');
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Prompt for nickname
      if (mounted) {
        final nickname = await _showNicknameDialog();
        if (nickname == null || nickname.trim().isEmpty) {
          if (mounted) setState(() => _loading = false);
          return; // User cancelled
        }

        // Create player document
        await FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .collection('players')
            .doc(_auth.uid)
            .set({
              'nickname': nickname.trim(),
              'score': 0,
              'streak': 0,
              'correctAnswers': 0,
              'totalAnswers': 0,
              'joinedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          setState(() => _loading = false);
          _showSuccess('Joined session successfully!');
          await Navigator.pushNamed(
            context,
            '/sessionLobby',
            arguments: sessionId,
          );
          // Reset state when returning
          if (mounted) _resetState();
        }
      }
    } catch (e) {
      _showError('Failed to join session: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showNicknameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.purple[50]!.withOpacity(0.3)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.person_add, color: Colors.white, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Enter Your Nickname',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a name that other players will see',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'e.g., PlayerOne',
                        prefixIcon: Icon(
                          Icons.badge,
                          color: Colors.purple[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.purple[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF667eea),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLength: 20,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          Navigator.pop(context, value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.trim().isNotEmpty) {
                            Navigator.pop(context, controller.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.login, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Join Quiz',
                              style: TextStyle(
                                color: Colors.white,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    SoundService().play(SoundEffect.success);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    SoundService().play(SoundEffect.error);
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _deleteQuiz(QuizMeta quiz) async {
    // Check if user is the creator
    final currentUid = _auth.uid;
    if (currentUid == null || currentUid != quiz.createdBy) {
      _showError(
        'You can only delete quizzes you created. This quiz was created by another user.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text(
          'Are you sure you want to delete "${quiz.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);

    try {
      await _quizRepo.deleteQuiz(quiz.id);
      SoundService().play(SoundEffect.success);
      _showSuccess('Quiz deleted successfully');
      await _loadQuizzes();
      if (_selectedQuiz?.id == quiz.id) {
        setState(() => _selectedQuiz = null);
      }
    } catch (e) {
      SoundService().play(SoundEffect.error);
      if (e.toString().contains('permission-denied')) {
        _showError(
          'Permission denied. You can only delete quizzes you created.',
        );
      } else {
        _showError('Failed to delete quiz: $e');
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _duplicateQuiz(QuizMeta quiz) async {
    try {
      setState(() => _loading = true);

      // Get the full quiz data
      final questions = await _quizRepo.getQuestions(quiz.id);
      final questionsData = questions.map((q) => q.toJson()).toList();

      // Create a copy with modified title
      final newMeta = QuizMeta(
        id: '',
        title: '${quiz.title} (Copy)',
        description: quiz.description,
        totalQuestions: quiz.totalQuestions,
        createdBy: _auth.uid ?? 'anonymous',
        createdAt: DateTime.now(),
        visibility: quiz.visibility,
        gameMode: quiz.gameMode,
      );

      await _quizRepo.createQuiz(newMeta, questionsData);
      _showSuccess('Quiz duplicated successfully');
      await _loadQuizzes();
    } catch (e) {
      _showError('Failed to duplicate quiz: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editQuiz(QuizMeta quiz) async {
    final result = await Navigator.pushNamed(
      context,
      '/quizBuilder',
      arguments: quiz.id,
    );

    if (result == true) {
      _showSuccess('Quiz updated successfully');
      await _loadQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
              const Color(0xFF4facfe),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Top bar with global leaderboard and Hrissa Cards buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Hrissa Cards button
                        ElevatedButton.icon(
                              onPressed: () {
                                SoundService().play(SoundEffect.buttonTap);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const HrissaCardsMenuScreen(),
                                  ),
                                );
                              },
                              icon: const Text(
                                '🌶️',
                                style: TextStyle(fontSize: 20),
                              ),
                              label: const Text(
                                'الهريسة 2',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.25),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.red.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: -0.3, end: 0),
                        // Global Rankings button
                        ElevatedButton.icon(
                              onPressed: () {
                                SoundService().play(SoundEffect.buttonTap);
                                Navigator.pushNamed(
                                  context,
                                  '/globalLeaderboard',
                                );
                              },
                              icon: const Icon(Icons.leaderboard, size: 20),
                              label: const Text(
                                'Global Rankings',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.25),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: 0.3, end: 0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo and title with playful animation
                              Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.4),
                                          blurRadius: 40,
                                          spreadRadius: 15,
                                        ),
                                        BoxShadow(
                                          color: Colors.amber.withOpacity(0.3),
                                          blurRadius: 30,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.amber[300]!,
                                            Colors.amber[600]!,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.emoji_events,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true),
                                  )
                                  .scale(
                                    delay: 100.ms,
                                    duration: 800.ms,
                                    begin: const Offset(0.95, 0.95),
                                  )
                                  .shimmer(
                                    duration: 2000.ms,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                              const SizedBox(height: 24),
                              ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Colors.yellow,
                                            Colors.orange,
                                            Colors.pink,
                                          ],
                                        ).createShader(bounds),
                                    child: Text(
                                      '🎮 LammaQuiz',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 48,
                                            letterSpacing: 2,
                                          ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(
                                    begin: -0.3,
                                    end: 0,
                                    duration: 600.ms,
                                  ),
                              const SizedBox(height: 12),
                              Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '⚡ Real-time multiplayer quiz battles',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 300.ms)
                                  .scale(delay: 300.ms),
                              const SizedBox(height: 48),

                              // Mode toggle with fun design
                              Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _ModeButton(
                                            label: '🎯 Host',
                                            icon: Icons.stars,
                                            isSelected: _isHost,
                                            onTap: () {
                                              SoundService().play(
                                                SoundEffect.buttonTap,
                                              );
                                              setState(() {
                                                _isHost = true;
                                                _error = null;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _ModeButton(
                                            label: '🎮 Play',
                                            icon: Icons.sports_esports,
                                            isSelected: !_isHost,
                                            onTap: () {
                                              SoundService().play(
                                                SoundEffect.buttonTap,
                                              );
                                              setState(() {
                                                _isHost = false;
                                                _error = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .scale(delay: 400.ms),
                              const SizedBox(height: 32),

                              // Content card with enhanced shadow and glow
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.2),
                                      blurRadius: 40,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(32),
                                child: _isHost
                                    ? _buildHostContent()
                                    : _buildPlayerContent(),
                              ).animate().slideY(
                                begin: 0.2,
                                delay: 500.ms,
                                duration: 600.ms,
                                curve: Curves.easeOutCubic,
                              ),

                              // Error message
                              if (_error != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().shake(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostContent() {
    // Filter quizzes based on search query
    final filteredQuizzes = _searchQuery.isEmpty
        ? _quizzes
        : _quizzes.where((quiz) {
            final titleMatch = quiz.title.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            final descMatch =
                quiz.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false;
            return titleMatch || descMatch;
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select a Quiz',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Search bar
        if (_quizzes.isNotEmpty)
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search quizzes...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),

        if (_quizzes.isNotEmpty) const SizedBox(height: 16),

        if (_quizzes.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No quizzes available yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/quizBuilder');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Your First Quiz'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (filteredQuizzes.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No quizzes match your search',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else ...[
          ...filteredQuizzes.map(
            (quiz) => _QuizCard(
              quiz: quiz,
              isSelected: _selectedQuiz?.id == quiz.id,
              onTap: () => setState(() => _selectedQuiz = quiz),
              onEdit: () => _editQuiz(quiz),
              onDelete: () => _deleteQuiz(quiz),
              onDuplicate: () => _duplicateQuiz(quiz),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple[100]!, Colors.blue[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      OutlinedButton.icon(
                            onPressed: () async {
                              SoundService().play(SoundEffect.buttonTap);
                              await Navigator.pushNamed(
                                context,
                                '/quizBuilder',
                              );
                              _loadQuizzes(); // Refresh after creating
                            },
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: Colors.purple[700],
                            ),
                            label: Text(
                              'Create New',
                              style: TextStyle(
                                color: Colors.purple[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.purple[300]!,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            duration: 2000.ms,
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.02, 1.02),
                          ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[100]!, Colors.pink[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      SoundService().play(SoundEffect.buttonTap);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TemplatesBrowserScreen(userQuizzes: _quizzes),
                        ),
                      );
                      if (result != null) {
                        _loadQuizzes(); // Refresh after importing
                      }
                    },
                    icon: Icon(Icons.library_books, color: Colors.orange[700]),
                    label: Text(
                      'Templates',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.orange[300]!, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _createSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.rocket_launch, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Create Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Join a Quiz',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Enter the 6-digit PIN from your host:',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),

        TextField(
          controller: _pinController,
          decoration: InputDecoration(
            hintText: '000000',
            prefixIcon: const Icon(Icons.pin),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          onSubmitted: (_) => _joinByPin(),
        ),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _joinByPin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.login, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Join Session',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.deepPurple : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(0.95, 0.95), duration: 200.ms);
  }
}

class _QuizCard extends StatelessWidget {
  final QuizMeta quiz;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const _QuizCard({
    required this.quiz,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(colors: [Colors.purple[50]!, Colors.blue[50]!])
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF667eea) : Colors.grey[200]!,
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFF667eea).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 16 : 8,
            offset: Offset(0, isSelected ? 6 : 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.quiz,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.question_answer,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${quiz.totalQuestions} questions',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.2, 1.2),
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeInOut,
                        ),
                ],
              ),
            ),
          ),
          // Action buttons row
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[50]!, Colors.grey[100]!],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                Expanded(
                  child: InkWell(
                    onTap: onDuplicate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.copy,
                            size: 18,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Duplicate',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                Expanded(
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
