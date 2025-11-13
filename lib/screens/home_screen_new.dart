import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamaplay/core/design_tokens.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/state/session_controller.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/widgets/session_settings_dialog.dart';

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

  Future<void> _loadQuizzes() async {
    try {
      final quizzes = await _quizRepo.getAllQuizzes();
      setState(() => _quizzes = quizzes);
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
        _showSuccess('Session created successfully!');
        Navigator.pushNamed(context, '/sessionLobby', arguments: sessionId);
      }
    } catch (e) {
      _showError('Failed to create session: $e');
      setState(() => _loading = false);
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
        setState(() => _loading = false);
        return;
      }

      // Prompt for nickname
      if (mounted) {
        final nickname = await _showNicknameDialog();
        if (nickname == null || nickname.trim().isEmpty) {
          setState(() => _loading = false);
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
              'joinedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          _showSuccess('Joined session successfully!');
          Navigator.pushNamed(context, '/sessionLobby', arguments: sessionId);
        }
      }
    } catch (e) {
      _showError('Failed to join session: $e');
      setState(() => _loading = false);
    }
  }

  Future<String?> _showNicknameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., PlayerOne',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
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

    try {
      await _quizRepo.deleteQuiz(quiz.id);
      _showSuccess('Quiz deleted successfully');
      await _loadQuizzes();
      if (_selectedQuiz?.id == quiz.id) {
        setState(() => _selectedQuiz = null);
      }
    } catch (e) {
      _showError('Failed to delete quiz: $e');
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
        decoration: BoxDecoration(gradient: DesignTokens.primaryGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo and title
                    Icon(
                      Icons.quiz_rounded,
                      size: 80,
                      color: Colors.white,
                    ).animate().scale(delay: 100.ms, duration: 600.ms),
                    const SizedBox(height: 16),
                    Text(
                      'LammaQuiz',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time multiplayer quiz battles',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 48),

                    // Mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModeButton(
                              label: 'Host',
                              icon: Icons.cast,
                              isSelected: _isHost,
                              onTap: () => setState(() {
                                _isHost = true;
                                _error = null;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _ModeButton(
                              label: 'Play',
                              icon: Icons.person,
                              isSelected: !_isHost,
                              onTap: () => setState(() {
                                _isHost = false;
                                _error = null;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 32),

                    // Content card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
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
                                style: TextStyle(color: Colors.red.shade700),
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
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/quizBuilder');
            },
            icon: const Icon(Icons.add),
            label: const Text('Create New Quiz'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],

        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _createSession,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Session', style: TextStyle(fontSize: 18)),
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

        FilledButton(
          onPressed: _loading ? null : _joinByPin,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join Session', style: TextStyle(fontSize: 18)),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? DesignTokens.primaryColor : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? DesignTokens.primaryColor : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? DesignTokens.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: DesignTokens.secondaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.quiz, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${quiz.totalQuestions} questions',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: DesignTokens.primaryColor),
                ],
              ),
            ),
          ),
          // Action buttons row
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
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
