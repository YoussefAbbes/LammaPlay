import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:lamaplay/models/question.dart';
import 'package:lamaplay/repositories/quiz_repository.dart';
import 'package:lamaplay/services/auth_service.dart';
import 'package:lamaplay/models/quiz.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simplified quiz builder for quick quiz creation
class QuizBuilderScreenSimple extends StatefulWidget {
  const QuizBuilderScreenSimple({super.key});

  @override
  State<QuizBuilderScreenSimple> createState() =>
      _QuizBuilderScreenSimpleState();
}

class _QuizBuilderScreenSimpleState extends State<QuizBuilderScreenSimple> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quizRepo = QuizRepository();
  final _auth = AuthService();

  final List<GlobalKey<_QuestionBuilderState>> _questionKeys = [];
  int _keyCounter = 0; // Counter to ensure unique keys
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Add 3 pre-filled sample questions
    _addSampleQuestions();
  }

  void _addSampleQuestions() {
    // Question 1: Multiple Choice
    final key1 = GlobalKey<_QuestionBuilderState>(
      debugLabel: 'question_${_keyCounter++}',
    );
    _questionKeys.add(key1);

    // Question 2: True/False
    final key2 = GlobalKey<_QuestionBuilderState>(
      debugLabel: 'question_${_keyCounter++}',
    );
    _questionKeys.add(key2);

    // Question 3: Numeric
    final key3 = GlobalKey<_QuestionBuilderState>(
      debugLabel: 'question_${_keyCounter++}',
    );
    _questionKeys.add(key3);

    // Pre-fill data after widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Question 1: MCQ
      key1.currentState?.prefillSampleData(
        questionText: 'What is the capital of France?',
        type: QuestionType.mcq,
        options: ['London', 'Paris', 'Berlin', 'Madrid'],
        correctIndex: 1, // Paris
      );

      // Question 2: True/False
      key2.currentState?.prefillSampleData(
        questionText: 'The Earth is round',
        type: QuestionType.tf,
        correctIndex: 0, // True
      );

      // Question 3: Numeric
      key3.currentState?.prefillSampleData(
        questionText: 'What is 2 + 2?',
        type: QuestionType.numeric,
        numericAnswer: '4',
      );
    });
  }

  void _addQuestion() {
    setState(() {
      _questionKeys.add(
        GlobalKey<_QuestionBuilderState>(
          debugLabel: 'question_${_keyCounter++}',
        ),
      );
    });
  }

  void _removeQuestion(int index) {
    if (_questionKeys.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz must have at least one question')),
      );
      return;
    }
    setState(() {
      _questionKeys.removeAt(index);
    });
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all questions
    final questionsData = <Map<String, dynamic>>[];
    for (final key in _questionKeys) {
      final state = key.currentState;
      if (state == null) continue;
      final data = state.toJson();
      if (data == null) {
        setState(() => _error = 'Please complete all questions');
        return;
      }
      questionsData.add(data);
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final meta = QuizMeta(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        totalQuestions: questionsData.length,
        createdBy: _auth.uid ?? 'anonymous',
        createdAt: DateTime.now(),
        visibility: 'public',
      );

      await _quizRepo.createQuiz(meta, questionsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Quiz created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save quiz: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Quiz'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _saveQuiz,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save Quiz'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Quiz metadata
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Title *',
                        hintText: 'e.g., World Geography Challenge',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        hintText: 'Brief description of your quiz',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Questions header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (${_questionKeys.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Questions
            ..._questionKeys.asMap().entries.map((entry) {
              final index = entry.key;
              final questionKey = entry.value;
              return Padding(
                key: ValueKey(questionKey),
                padding: const EdgeInsets.only(bottom: 24),
                child: _QuestionBuilder(
                  key: questionKey,
                  index: index,
                  onRemove: () => _removeQuestion(index),
                ),
              );
            }),

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionBuilder extends StatefulWidget {
  final int index;
  final VoidCallback onRemove;

  const _QuestionBuilder({
    super.key,
    required this.index,
    required this.onRemove,
  });

  @override
  State<_QuestionBuilder> createState() => _QuestionBuilderState();
}

class _QuestionBuilderState extends State<_QuestionBuilder>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _questionController;
  late QuestionType _selectedType;
  late final List<TextEditingController> _optionControllers;
  late int _correctIndex;
  late final TextEditingController _numericAnswerController;
  late final TextEditingController _timeLimitController;

  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  final List<File?> _selectedImages = [null, null, null, null];
  final List<Uint8List?> _selectedImageBytes = [
    null,
    null,
    null,
    null,
  ]; // For web
  final List<String?> _uploadedImageUrls = [null, null, null, null];
  final List<bool> _uploadingImages = [false, false, false, false];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _selectedType = QuestionType.mcq;
    _optionControllers = List.generate(4, (_) => TextEditingController());
    _correctIndex = 0;
    _numericAnswerController = TextEditingController();
    _timeLimitController = TextEditingController(text: '30');
  }

  // Method to pre-fill sample data
  void prefillSampleData({
    required String questionText,
    required QuestionType type,
    List<String>? options,
    int? correctIndex,
    String? numericAnswer,
  }) {
    _questionController.text = questionText;
    _selectedType = type;

    if (options != null) {
      for (int i = 0; i < options.length && i < 4; i++) {
        _optionControllers[i].text = options[i];
      }
    }

    if (correctIndex != null) {
      _correctIndex = correctIndex;
    }

    if (numericAnswer != null) {
      _numericAnswerController.text = numericAnswer;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final ctrl in _optionControllers) {
      ctrl.dispose();
    }
    _numericAnswerController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes[index] = bytes;
            _uploadedImageUrls[index] = null;
          });
        } else {
          // For mobile, use File
          setState(() {
            _selectedImages[index] = File(pickedFile.path);
            _uploadedImageUrls[index] = null;
          });
        }

        await _uploadImage(index, pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _uploadImage(int index, XFile pickedFile) async {
    setState(() {
      _uploadingImages[index] = true;
    });

    try {
      print('Starting upload for image $index...');

      // Read image as base64
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('Image converted to base64: ${bytes.length} bytes');

      // Upload to ImgBB (free image hosting)
      // You can get a free API key from https://api.imgbb.com/
      const apiKey =
          '768811de7df5e3b1d6435eafb7a9749e'; // Replace with your ImgBB API key

      final response = await http
          .post(
            Uri.parse('https://api.imgbb.com/1/upload'),
            body: {'key': apiKey, 'image': base64Image},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Upload timed out after 30 seconds');
            },
          );

      print('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final imageUrl = jsonResponse['data']['url'] as String;
        print('Image uploaded successfully: $imageUrl');

        setState(() {
          _uploadedImageUrls[index] = imageUrl;
          _uploadingImages[index] = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to upload: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('ERROR uploading image: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _uploadingImages[index] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Map<String, dynamic>? toJson() {
    if (_questionController.text.trim().isEmpty) return null;

    final data = <String, dynamic>{
      'text': _questionController.text.trim(),
      'type': _selectedType.name,
      'timeLimitSeconds': int.tryParse(_timeLimitController.text) ?? 30,
    };

    switch (_selectedType) {
      case QuestionType.mcq:
      case QuestionType.tf:
        final options = _selectedType == QuestionType.tf
            ? ['True', 'False']
            : _optionControllers
                  .map((c) => c.text.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        data['correctIndex'] = _correctIndex;
        break;
      case QuestionType.numeric:
        final answer = num.tryParse(_numericAnswerController.text);
        if (answer == null) return null;
        data['numericAnswer'] = answer;
        break;
      case QuestionType.image:
        final options = _uploadedImageUrls
            .where((url) => url != null && url.isNotEmpty)
            .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        data['correctIndex'] = _correctIndex;
        break;
      case QuestionType.poll:
        final options = _optionControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        break;
      case QuestionType.order:
        final items = _optionControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (items.length < 2) return null;
        data['orderSolution'] = items;
        data['options'] = [...items]..shuffle();
        break;
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${widget.index + 1}')),
                const SizedBox(width: 12),
                Text(
                  'Question ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove question',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question text
            TextFormField(
              key: ValueKey('question_text_${widget.index}'),
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Text *',
                hintText: 'Enter your question here',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // Question type selector
            DropdownButtonFormField<QuestionType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Question Type',
                border: OutlineInputBorder(),
              ),
              items: QuestionType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    // Clear image data when switching away from image type
                    if (value != QuestionType.image) {
                      for (int i = 0; i < 4; i++) {
                        _selectedImages[i] = null;
                        _selectedImageBytes[i] = null;
                        _uploadedImageUrls[i] = null;
                        _uploadingImages[i] = false;
                      }
                    }
                    // Clear text data when switching to image type
                    if (value == QuestionType.image) {
                      for (var controller in _optionControllers) {
                        controller.clear();
                      }
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // Type-specific fields
            KeyedSubtree(
              key: ValueKey('type_${widget.index}_$_selectedType'),
              child: _buildTypeSpecificFields(),
            ),

            const SizedBox(height: 20),

            // Time limit
            SizedBox(
              width: 200,
              child: TextFormField(
                key: ValueKey('time_limit_${widget.index}'),
                controller: _timeLimitController,
                decoration: const InputDecoration(
                  labelText: 'Time Limit (seconds)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case QuestionType.mcq:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Options (select correct answer)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                key: ValueKey('option_${widget.index}_$i'),
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctIndex,
                      onChanged: (v) => setState(() => _correctIndex = v!),
                    ),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('option_field_${widget.index}_$i'),
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );

      case QuestionType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Image Options',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Select 4 images from gallery. Players will choose the correct one.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _correctIndex == i
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: _correctIndex == i ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: _correctIndex,
                            onChanged: (v) =>
                                setState(() => _correctIndex = v!),
                          ),
                          Text(
                            'Option ${i + 1}',
                            style: TextStyle(
                              fontWeight: _correctIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _correctIndex == i ? Colors.green : null,
                            ),
                          ),
                          if (_correctIndex == i)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      if (_selectedImages[i] != null ||
                          _selectedImageBytes[i] != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.memory(
                                      _selectedImageBytes[i]!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _selectedImages[i]!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            if (_uploadingImages[i])
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (_uploadedImageUrls[i] != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Uploaded',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickImage(i),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Change'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(i),
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                            ),
                            label: const Text('Select Image from Gallery'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(24),
                              minimumSize: const Size(double.infinity, 120),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mark the correct answer with the radio button above each image',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case QuestionType.tf:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correct Answer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    value: 0,
                    groupValue: _correctIndex,
                    onChanged: (v) => setState(() => _correctIndex = v!),
                    title: const Text('True'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RadioListTile<int>(
                    value: 1,
                    groupValue: _correctIndex,
                    onChanged: (v) => setState(() => _correctIndex = v!),
                    title: const Text('False'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case QuestionType.numeric:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correct Answer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              child: TextFormField(
                key: ValueKey('numeric_answer_${widget.index}'),
                controller: _numericAnswerController,
                decoration: const InputDecoration(
                  labelText: 'Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ],
        );

      case QuestionType.poll:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poll Options (no correct answer)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                key: ValueKey('poll_option_${widget.index}_$i'),
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  key: ValueKey('poll_field_${widget.index}_$i'),
                  controller: _optionControllers[i],
                  decoration: InputDecoration(
                    labelText: 'Option ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
          ],
        );

      case QuestionType.order:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (enter in correct order)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                key: ValueKey('order_item_${widget.index}_$i'),
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, child: Text('${i + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('order_field_${widget.index}_$i'),
                        controller: _optionControllers[i],
                        decoration: InputDecoration(
                          labelText: 'Item ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
    }
  }

  String _getTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        return '📝 Multiple Choice';
      case QuestionType.tf:
        return '✓✗ True/False';
      case QuestionType.image:
        return '🖼️ Image Choice';
      case QuestionType.numeric:
        return '🔢 Numeric Answer';
      case QuestionType.poll:
        return '📊 Poll (no scoring)';
      case QuestionType.order:
        return '📑 Order Items';
    }
  }
}
