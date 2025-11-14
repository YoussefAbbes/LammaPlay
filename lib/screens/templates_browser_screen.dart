import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lamaplay/services/quiz_template_service.dart';
import 'package:lamaplay/services/sound_service.dart';
import 'package:lamaplay/models/quiz.dart';

class TemplatesBrowserScreen extends StatefulWidget {
  final List<QuizMeta> userQuizzes;

  const TemplatesBrowserScreen({super.key, required this.userQuizzes});

  @override
  State<TemplatesBrowserScreen> createState() => _TemplatesBrowserScreenState();
}

class _TemplatesBrowserScreenState extends State<TemplatesBrowserScreen> {
  final _templateService = QuizTemplateService();
  String _selectedCategory = 'All';
  bool _loading = false;
  String? _importedQuizId;

  @override
  Widget build(BuildContext context) {
    final templates = _selectedCategory == 'All'
        ? _templateService.getAvailableTemplates()
        : _templateService.getTemplatesByCategory(_selectedCategory);

    final categories = ['All', ..._templateService.getCategories()];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              Colors.purple[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        SoundService().play(SoundEffect.buttonTap);
                        Navigator.pop(context, _importedQuizId);
                      },
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📚 Quiz Templates',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Ready-to-play quiz collections',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2, end: 0),

              // Category filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(category),
                        onSelected: (selected) {
                          SoundService().play(SoundEffect.buttonTap);
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white.withOpacity(0.2),
                        selectedColor: Colors.white.withOpacity(0.4),
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // Templates grid
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            return _TemplateCard(
                              template: templates[index],
                              index: index,
                              onImport: () => _importTemplate(templates[index]),
                              onPreview: () =>
                                  _previewTemplate(templates[index]),
                              isImported: widget.userQuizzes.any(
                                (quiz) => quiz.title == templates[index].title,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importTemplate(QuizTemplate template) async {
    setState(() => _loading = true);

    try {
      SoundService().play(SoundEffect.whoosh);
      final quizId = await _templateService.importTemplate(template);

      setState(() {
        _loading = false;
        _importedQuizId = quizId;
      });

      if (mounted) {
        SoundService().play(SoundEffect.celebration);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('✅ "${template.title}" imported successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      SoundService().play(SoundEffect.error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import template: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _previewTemplate(QuizTemplate template) async {
    SoundService().play(SoundEffect.buttonTap);
    showDialog(
      context: context,
      builder: (context) => _PreviewDialog(template: template),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final QuizTemplate template;
  final int index;
  final VoidCallback onImport;
  final VoidCallback onPreview;
  final bool isImported;

  const _TemplateCard({
    required this.template,
    required this.index,
    required this.onImport,
    required this.onPreview,
    required this.isImported,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onPreview,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _getCategoryColor(template.category).withOpacity(0.1),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              template.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              template.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          template.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              template.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            template.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getCategoryColor(template.category),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Questions count
                        Row(
                          children: [
                            Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${template.totalQuestions} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Import button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isImported ? null : onImport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isImported
                                  ? Colors.grey[400]
                                  : _getCategoryColor(template.category),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: Text(
                              isImported ? 'Imported ✓' : 'Import',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Imported badge
                  if (isImported)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 400.ms)
        .slideY(begin: 0.3, end: 0);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sports':
        return Colors.orange;
      case 'Science':
        return Colors.blue;
      case 'Entertainment':
        return Colors.pink;
      case 'Geography':
        return Colors.green;
      case 'History':
        return Colors.brown;
      case 'Technology':
        return Colors.indigo;
      case 'Arts':
        return Colors.purple;
      case 'General':
      default:
        return Colors.teal;
    }
  }
}

class _PreviewDialog extends StatelessWidget {
  final QuizTemplate template;

  const _PreviewDialog({required this.template});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      template.icon,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        template.category,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              template.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                _StatChip(
                  icon: Icons.quiz,
                  label: '${template.totalQuestions} Questions',
                ),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.speed, label: template.difficulty),
              ],
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  SoundService().play(SoundEffect.buttonTap);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOut);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.purple[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }
}
