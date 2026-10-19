import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/category_picker.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/core/utils/error_handler.dart';

class LessonDetailsScreen extends StatefulWidget {
  final LessonPlan lessonPlan;
  const LessonDetailsScreen({super.key, required this.lessonPlan});

  @override
  State<LessonDetailsScreen> createState() => _LessonDetailsScreenState();
}

class _LessonDetailsScreenState extends State<LessonDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _categoryEmojiController;
  late TextEditingController _emojiController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lessonPlan.title);
    _categoryController = TextEditingController(
      text: widget.lessonPlan.category,
    );
    _categoryEmojiController = TextEditingController(
      text: widget.lessonPlan.categoryEmoji,
    );
    _emojiController = TextEditingController(text: widget.lessonPlan.emoji);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _categoryEmojiController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _finalizeSave() async {
    if (_titleController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields!")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final finalPlan = LessonPlan(
      id: widget.lessonPlan.id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      categoryEmoji: _categoryEmojiController.text.trim().isEmpty
          ? '🎯'
          : _categoryEmojiController.text.trim(),
      emoji: _emojiController.text.trim().isEmpty
          ? '📚'
          : _emojiController.text.trim(),
      steps: widget.lessonPlan.steps,
      creatorId: widget.lessonPlan.creatorId,
      createdAt: widget.lessonPlan.createdAt,
      index: widget.lessonPlan.index,
    );

    try {
      await DataService.instance.addLessonPlan(finalPlan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lesson published successfully! 🚀")),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ThaiAppBar(
        title: "Lesson Details",
        showProfile: false,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.light
                              ? 0.1
                              : 0.3,
                        ),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _emojiController.text,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Finalize Your Lesson",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.headlineSmall?.color,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "Give your lesson a catchy title and category",
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lesson Title",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ThaiTextField(
                          controller: _titleController,
                          label: "e.g., Thai Street Food 101",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Emoji",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emojiController,
                          textAlign: TextAlign.center,
                          maxLength: 2,
                          onChanged: (val) => setState(() {}),
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: "",
                            counterText: "",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            hintText: "e.g., Vocabulary, Grammar",
                            prefixIcon: Icon(
                              Icons.category_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.manage_search_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () async {
                                final result = await showCategoryPicker(
                                  context,
                                );
                                if (result != null) {
                                  setState(() {
                                    _categoryController.text =
                                        result['name'] ?? '';
                                    _categoryEmojiController.text =
                                        result['emoji'] ?? '🎯';
                                  });
                                }
                              },
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Cat Emoji",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _categoryEmojiController,
                          textAlign: TextAlign.center,
                          maxLength: 2,
                          onChanged: (val) => setState(() {}),
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: "",
                            counterText: "",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ThaiInfoBox(
                icon: Icons.info_outline_rounded,
                text:
                    "This lesson contains ${widget.lessonPlan.steps.length} steps.",
              ),

              const SizedBox(height: 60),

              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ThaiButton(
                      text: "Publish Lesson",
                      onPressed: _finalizeSave,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
