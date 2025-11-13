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

/// Rich quiz builder with drag-and-drop, live preview, and validation.
class QuizBuilderScreen extends StatefulWidget {
  const QuizBuilderScreen({super.key});

  @override
  State<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quizRepo = QuizRepository();
  final _auth = AuthService();

  final List<GlobalKey<_QuestionBuilderState>> _questionKeys = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _addQuestion(); // Start with one question
  }

  void _addQuestion() {
    setState(() {
      _questionKeys.add(GlobalKey<_QuestionBuilderState>());
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
          const SnackBar(content: Text('Quiz created successfully!')),
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
            label: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Row(
          children: [
            // Left panel: Quiz metadata and question list
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey.shade50,
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
                              ),
                              validator: (v) =>
                                  v!.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description (optional)',
                                hintText: 'Brief description of your quiz',
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Questions list
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

                    ..._questionKeys.asMap().entries.map((entry) {
                      final index = entry.key;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text('Question ${index + 1}'),
                          subtitle: const Text('Click to edit'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _removeQuestion(index),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Right panel: Question editor
            Expanded(
              flex: 3,
              child: _questionKeys.isEmpty
                  ? Center(
                      child: Text(
                        'No questions yet',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _questionKeys.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _QuestionBuilder(
                            key: _questionKeys[index],
                            initialIndex: index,
                            onRemove: () => _removeQuestion(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _error != null
          ? Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }
}

class _QuestionBuilder extends StatefulWidget {
  final int initialIndex;
  final VoidCallback onRemove;

  const _QuestionBuilder({
    super.key,
    required this.initialIndex,
    required this.onRemove,
  });

  @override
  State<_QuestionBuilder> createState() => _QuestionBuilderState();
}

class _QuestionBuilderState extends State<_QuestionBuilder> {
  late final TextEditingController questionController;
  late QuestionType selectedType;
  late final List<TextEditingController> optionControllers;
  late int correctIndex;
  late final TextEditingController numericAnswerController;
  late final TextEditingController timeLimitController;

  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  final List<File?> _selectedImages = [null, null, null, null];
  final List<Uint8List?> _selectedImageBytes = [null, null, null, null];
  final List<String?> _uploadedImageUrls = [null, null, null, null];
  final List<bool> _uploadingImages = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController();
    selectedType = QuestionType.mcq;
    optionControllers = List.generate(4, (_) => TextEditingController());
    correctIndex = 0;
    numericAnswerController = TextEditingController();
    timeLimitController = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    questionController.dispose();
    for (final ctrl in optionControllers) {
      ctrl.dispose();
    }
    numericAnswerController.dispose();
    timeLimitController.dispose();
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
      const apiKey = '768811de7df5e3b1d6435eafb7a9749e';

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
    if (questionController.text.trim().isEmpty) return null;

    final data = <String, dynamic>{
      'text': questionController.text.trim(),
      'type': selectedType.name,
      'timeLimitSeconds': int.tryParse(timeLimitController.text) ?? 30,
    };

    switch (selectedType) {
      case QuestionType.mcq:
      case QuestionType.tf:
        final options = selectedType == QuestionType.tf
            ? ['True', 'False']
            : optionControllers
                  .map((c) => c.text.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        data['correctIndex'] = correctIndex;
        break;
      case QuestionType.numeric:
        final answer = num.tryParse(numericAnswerController.text);
        if (answer == null) return null;
        data['numericAnswer'] = answer;
        break;
      case QuestionType.image:
        // Use uploaded image URLs instead of text
        final options = _uploadedImageUrls
            .where((url) => url != null && url.isNotEmpty)
            .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        data['correctIndex'] = correctIndex;
        break;
      case QuestionType.poll:
        final options = optionControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (options.length < 2) return null;
        data['options'] = options;
        break;
      case QuestionType.order:
        final items = optionControllers
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${widget.initialIndex + 1}')),
                const SizedBox(width: 12),
                Text(
                  'Question ${widget.initialIndex + 1}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Question text
            TextFormField(
              controller: questionController,
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
              value: selectedType,
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
                    selectedType = value;
                    // Clear image data when switching types
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
                      for (var controller in optionControllers) {
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
              key: ValueKey(selectedType),
              child: _buildTypeSpecificFields(),
            ),

            const SizedBox(height: 20),

            // Time limit
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: timeLimitController,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (selectedType) {
      case QuestionType.mcq:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Options', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: correctIndex,
                      onChanged: (v) => setState(() => correctIndex = v!),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: optionControllers[i],
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
            Text(
              'Select the correct answer',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
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
                      color: correctIndex == i
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: correctIndex == i ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Radio button for correct answer
                      Row(
                        children: [
                          Radio<int>(
                            value: i,
                            groupValue: correctIndex,
                            onChanged: (v) => setState(() => correctIndex = v!),
                          ),
                          Text(
                            'Option ${i + 1}',
                            style: TextStyle(
                              fontWeight: correctIndex == i
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: correctIndex == i ? Colors.green : null,
                            ),
                          ),
                          if (correctIndex == i)
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

                      // Image preview or upload button
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
                            // Change image button
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
                    groupValue: correctIndex,
                    onChanged: (v) => setState(() => correctIndex = v!),
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
                    groupValue: correctIndex,
                    onChanged: (v) => setState(() => correctIndex = v!),
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
        return TextFormField(
          controller: numericAnswerController,
          decoration: const InputDecoration(
            labelText: 'Correct Answer (number)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.numbers),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: optionControllers[i],
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
              'Items (in correct order)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...List.generate(4, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, child: Text('${i + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: optionControllers[i],
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
        return 'Multiple Choice';
      case QuestionType.tf:
        return 'True/False';
      case QuestionType.image:
        return 'Image Choice';
      case QuestionType.numeric:
        return 'Numeric Answer';
      case QuestionType.poll:
        return 'Poll';
      case QuestionType.order:
        return 'Order Items';
    }
  }
}
