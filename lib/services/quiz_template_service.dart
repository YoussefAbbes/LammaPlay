import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/services/auth_service.dart';

/// Model for quiz template metadata
class QuizTemplate {
  final String fileName;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int totalQuestions;
  final String icon;

  QuizTemplate({
    required this.fileName,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.totalQuestions,
    required this.icon,
  });
}

/// Service for managing pre-built quiz templates
class QuizTemplateService {
  static final QuizTemplateService _instance = QuizTemplateService._internal();
  factory QuizTemplateService() => _instance;
  QuizTemplateService._internal();

  final _quizRepo = QuizRepository();
  final _auth = AuthService();

  /// Get all available quiz templates
  List<QuizTemplate> getAvailableTemplates() {
    return [
      QuizTemplate(
        fileName: 'football_legends.json',
        title: '⚽ Football Legends Quiz',
        description:
            'Test your knowledge about the beautiful game! From legendary players to historic moments.',
        category: 'Sports',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '⚽',
      ),
      QuizTemplate(
        fileName: 'general_knowledge.json',
        title: '🧠 General Knowledge Challenge',
        description:
            'A mix of trivia questions to test your overall knowledge across various topics!',
        category: 'General',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🧠',
      ),
      QuizTemplate(
        fileName: 'science_nature.json',
        title: '🔬 Science & Nature Quiz',
        description:
            'Explore the wonders of science, biology, chemistry, and the natural world!',
        category: 'Science',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🔬',
      ),
      QuizTemplate(
        fileName: 'pop_culture.json',
        title: '🎬 Pop Culture & Entertainment',
        description:
            'Movies, music, celebrities, and everything trending in pop culture!',
        category: 'Entertainment',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🎬',
      ),
      QuizTemplate(
        fileName: 'geography.json',
        title: '🌍 Geography Master',
        description:
            'Journey around the world! Test your knowledge of countries, capitals, and landmarks.',
        category: 'Geography',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🌍',
      ),
      QuizTemplate(
        fileName: 'history.json',
        title: '📚 History Through Time',
        description:
            'Travel back in time and test your knowledge of historical events and figures!',
        category: 'History',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '📚',
      ),
      QuizTemplate(
        fileName: 'technology.json',
        title: '💻 Technology & Innovation',
        description:
            'Test your tech knowledge! From programming to gadgets and innovations.',
        category: 'Technology',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '💻',
      ),
      QuizTemplate(
        fileName: 'arts_literature.json',
        title: '🎨 Arts & Literature',
        description:
            'Explore the world of art, books, and creative masterpieces!',
        category: 'Arts',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🎨',
      ),
      QuizTemplate(
        fileName: 'football_champions_league.json',
        title: '🏆 UEFA Champions League Masters',
        description:
            'Expert-level quiz about the most prestigious club competition in European football!',
        category: 'Sports',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '🏆',
      ),
      QuizTemplate(
        fileName: 'football_world_cup.json',
        title: '🌍 World Cup Legends & Records',
        description:
            'Deep dive into FIFA World Cup history, records, and legendary moments!',
        category: 'Sports',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '🌍',
      ),
      QuizTemplate(
        fileName: 'football_premier_league.json',
        title: '⚡ Premier League Expert Challenge',
        description:
            'Ultimate test for true Premier League enthusiasts - records, history, and trivia!',
        category: 'Sports',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '⚡',
      ),
      QuizTemplate(
        fileName: 'football_tactics.json',
        title: '🎯 Football Tactics & Positions',
        description:
            'Advanced quiz about tactical formations, player positions, and strategic concepts!',
        category: 'Sports',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '🎯',
      ),
      QuizTemplate(
        fileName: 'unique_minds_challenge.json',
        title: '🧠 Unique Minds Challenge',
        description:
            'Think different! Only unique answers score points. Avoid what others choose!',
        category: 'Strategy',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '🧠',
      ),
      QuizTemplate(
        fileName: 'truth_or_dare_party.json',
        title: '🎭 Truth or Dare - Party Edition',
        description:
            'Classic party game with spicy truths and fun dares! Perfect for groups!',
        category: 'Party',
        difficulty: 'Medium',
        totalQuestions: 10,
        icon: '🎭',
      ),
      QuizTemplate(
        fileName: 'hrissa_hot_seat.json',
        title: '🌶️ Hrissa - Hot Seat Challenge',
        description:
            'Tunisian-style hot seat! Face spicy questions and reveal your secrets!',
        category: 'Party',
        difficulty: 'Hard',
        totalQuestions: 10,
        icon: '🌶️',
      ),
    ];
  }

  /// Get templates by category
  List<QuizTemplate> getTemplatesByCategory(String category) {
    return getAvailableTemplates()
        .where((t) => t.category == category)
        .toList();
  }

  /// Get all categories
  List<String> getCategories() {
    return getAvailableTemplates().map((t) => t.category).toSet().toList()
      ..sort();
  }

  /// Load template JSON from assets
  Future<Map<String, dynamic>> loadTemplate(String fileName) async {
    final jsonString = await rootBundle.loadString('assets/quizzes/$fileName');
    return json.decode(jsonString);
  }

  /// Import a template to user's quiz library
  Future<String> importTemplate(QuizTemplate template) async {
    // Load template data
    final templateData = await loadTemplate(template.fileName);

    // Parse metadata
    final meta = templateData['meta'] as Map<String, dynamic>?;
    if (meta == null) {
      throw Exception('Template ${template.fileName} is missing "meta" field');
    }

    final questions = templateData['questions'] as List<dynamic>?;
    if (questions == null) {
      throw Exception(
        'Template ${template.fileName} is missing "questions" field',
      );
    }

    // Create quiz metadata
    final quizMeta = QuizMeta(
      id: '', // Will be set by Firestore
      title: meta['title'] as String? ?? 'Untitled Quiz',
      description: meta['description'] as String? ?? '',
      totalQuestions: questions.length,
      createdBy: _auth.uid ?? 'anonymous',
      createdAt: DateTime.now(),
      visibility: 'public',
      gameMode: meta['gameMode'] as String? ?? 'standard',
    );

    // Transform questions to match the expected format
    final questionsData = questions.map((q) {
      final questionMap = Map<String, dynamic>.from(q);

      // Ensure index is set
      if (!questionMap.containsKey('index')) {
        questionMap['index'] = questions.indexOf(q);
      }

      // Set default values if missing
      questionMap['pointsMode'] = questionMap['pointsMode'] ?? 'standard';
      questionMap['timeLimitSeconds'] = questionMap['timeLimitSeconds'] ?? 20;

      // Convert options to list if needed
      if (questionMap['options'] != null) {
        questionMap['options'] = List<String>.from(questionMap['options']);
      }

      return questionMap;
    }).toList();

    // Create quiz in Firestore
    final quizId = await _quizRepo.createQuiz(quizMeta, questionsData);

    return quizId;
  }

  /// Preview template without importing
  Future<Map<String, dynamic>> previewTemplate(QuizTemplate template) async {
    return await loadTemplate(template.fileName);
  }

  /// Check if user has already imported a template
  Future<bool> isTemplateImported(
    QuizTemplate template,
    List<QuizMeta> userQuizzes,
  ) async {
    // Check if any user quiz has the same title
    return userQuizzes.any((quiz) => quiz.title == template.title);
  }
}
