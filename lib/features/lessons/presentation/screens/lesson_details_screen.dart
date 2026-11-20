import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/editor/category_picker.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/widgets/common/lesson_icon_widget.dart';
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
  late TextEditingController _categoryLottieUrlController;
  late TextEditingController _categoryBackgroundImageUrlController;
  late TextEditingController _emojiController;
  late TextEditingController _lottieUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lessonPlan.title);
    _categoryController = TextEditingController(
      text: widget.lessonPlan.category,
    );

    final catMeta = DataService.instance.getCategoryMetadata(
      widget.lessonPlan.category,
    );
    final initialCatEmoji = widget.lessonPlan.categoryEmoji.isNotEmpty &&
            widget.lessonPlan.categoryEmoji != '🎯'
        ? widget.lessonPlan.categoryEmoji
        : (catMeta['emoji'] ?? widget.lessonPlan.categoryEmoji);
    final initialCatLottie =
        widget.lessonPlan.categoryLottieUrl?.trim().isNotEmpty == true
            ? widget.lessonPlan.categoryLottieUrl!.trim()
            : catMeta['lottieUrl'];
    final initialCatBg =
        widget.lessonPlan.categoryBackgroundImageUrl?.trim().isNotEmpty == true
            ? widget.lessonPlan.categoryBackgroundImageUrl!.trim()
            : catMeta['bgUrl'];

    _categoryEmojiController = TextEditingController(text: initialCatEmoji);
    _categoryLottieUrlController = TextEditingController(
      text: initialCatLottie ?? '',
    );
    _categoryBackgroundImageUrlController = TextEditingController(
      text: initialCatBg ?? '',
    );
    _emojiController = TextEditingController(text: widget.lessonPlan.emoji);
    _lottieUrlController = TextEditingController(
      text: widget.lessonPlan.lottieUrl ?? '',
    );

    _categoryController.addListener(() {
      _onCategoryNameChanged(_categoryController.text);
    });
  }

  void _onCategoryNameChanged(String catName) {
    if (catName.trim().isEmpty) return;
    final meta = DataService.instance.getCategoryMetadata(catName);
    if (meta['emoji'] != null &&
        meta['emoji']!.isNotEmpty &&
        (_categoryEmojiController.text.isEmpty ||
            _categoryEmojiController.text == '🎯')) {
      _categoryEmojiController.text = meta['emoji']!;
    }
    if (meta['lottieUrl'] != null &&
        meta['lottieUrl']!.isNotEmpty &&
        _categoryLottieUrlController.text.trim().isEmpty) {
      _categoryLottieUrlController.text = meta['lottieUrl']!;
    }
    if (meta['bgUrl'] != null &&
        meta['bgUrl']!.isNotEmpty &&
        _categoryBackgroundImageUrlController.text.trim().isEmpty) {
      _categoryBackgroundImageUrlController.text = meta['bgUrl']!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _categoryEmojiController.dispose();
    _categoryLottieUrlController.dispose();
    _categoryBackgroundImageUrlController.dispose();
    _emojiController.dispose();
    _lottieUrlController.dispose();
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

    final confirm = await ThaiDialogs.showConfirmDialog(
      context,
      title: "Confirm Save",
      content: "Do you want to save and publish this lesson?",
      confirmLabel: "Yes",
      cancelLabel: "No",
    );
    if (!confirm) return;

    setState(() => _isSaving = true);

    final finalPlan = LessonPlan(
      id: widget.lessonPlan.id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      categoryEmoji: _categoryEmojiController.text.trim().isEmpty
          ? '🎯'
          : _categoryEmojiController.text.trim(),
      categoryLottieUrl: _categoryLottieUrlController.text.trim().isEmpty
          ? null
          : _categoryLottieUrlController.text.trim(),
      categoryBackgroundImageUrl:
          _categoryBackgroundImageUrlController.text.trim().isEmpty
              ? null
              : _categoryBackgroundImageUrlController.text.trim(),
      emoji: _emojiController.text.trim().isEmpty
          ? '📚'
          : _emojiController.text.trim(),
      lottieUrl: _lottieUrlController.text.trim().isEmpty
          ? null
          : _lottieUrlController.text.trim(),
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
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    _emojiController,
                    _lottieUrlController,
                  ]),
                  builder: (context, child) => Container(
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
                      child: LessonIconWidget(
                        emoji: _emojiController.text,
                        lottieUrl: _lottieUrlController.text,
                        size: 70,
                        emojiSize: 50,
                      ),
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

              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Lottie Animation URL (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lottieUrlController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "https://.../animation.lottie",
                      hintStyle: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.animation_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _lottieUrlController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () => _lottieUrlController.clear(),
                                )
                              : const SizedBox.shrink();
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
                                  _categoryController.text =
                                      result['name'] ?? '';
                                  _categoryEmojiController.text =
                                      result['emoji'] ?? '🎯';
                                  if (result['lottieUrl'] != null &&
                                      result['lottieUrl']!.isNotEmpty) {
                                    _categoryLottieUrlController.text =
                                        result['lottieUrl']!;
                                  }
                                  if (result['bgUrl'] != null &&
                                      result['bgUrl']!.isNotEmpty) {
                                    _categoryBackgroundImageUrlController.text =
                                        result['bgUrl']!;
                                  }
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

              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Lottie Animation URL (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryLottieUrlController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "https://.../animation.lottie",
                      hintStyle: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.animation_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _categoryLottieUrlController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _categoryLottieUrlController.clear(),
                                )
                              : const SizedBox.shrink();
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Category Background Image URL (Optional)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _categoryBackgroundImageUrlController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: "https://.../image.png",
                      hintStyle: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.image_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _categoryBackgroundImageUrlController,
                        builder: (context, value, child) {
                          return value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _categoryBackgroundImageUrlController.clear(),
                                )
                              : const SizedBox.shrink();
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

              const SizedBox(height: 16),

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
