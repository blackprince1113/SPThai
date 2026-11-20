import 'package:flutter/material.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/editor/category_picker.dart';

class LessonSettingsSheet extends StatefulWidget {
  final String initialTitle;
  final String initialCategory;
  final String initialCategoryEmoji;
  final String? initialCategoryLottieUrl;
  final String? initialCategoryBackgroundImageUrl;
  final String initialLessonEmoji;
  final String? initialLottieUrl;
  final Function({
    required String title,
    required String category,
    required String categoryEmoji,
    String? categoryLottieUrl,
    String? categoryBackgroundImageUrl,
    required String lessonEmoji,
    String? lottieUrl,
  })
  onSave;

  const LessonSettingsSheet({
    super.key,
    required this.initialTitle,
    required this.initialCategory,
    required this.initialCategoryEmoji,
    this.initialCategoryLottieUrl,
    this.initialCategoryBackgroundImageUrl,
    required this.initialLessonEmoji,
    this.initialLottieUrl,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String category,
    required String categoryEmoji,
    String? categoryLottieUrl,
    String? categoryBackgroundImageUrl,
    required String lessonEmoji,
    String? lottieUrl,
    required Function({
      required String title,
      required String category,
      required String categoryEmoji,
      String? categoryLottieUrl,
      String? categoryBackgroundImageUrl,
      required String lessonEmoji,
      String? lottieUrl,
    })
    onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => LessonSettingsSheet(
        initialTitle: title,
        initialCategory: category,
        initialCategoryEmoji: categoryEmoji,
        initialCategoryLottieUrl: categoryLottieUrl,
        initialCategoryBackgroundImageUrl: categoryBackgroundImageUrl,
        initialLessonEmoji: lessonEmoji,
        initialLottieUrl: lottieUrl,
        onSave: onSave,
      ),
    );
  }

  @override
  State<LessonSettingsSheet> createState() => _LessonSettingsSheetState();
}

class _LessonSettingsSheetState extends State<LessonSettingsSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _categoryEmojiController;
  late final TextEditingController _categoryLottieUrlController;
  late final TextEditingController _categoryBackgroundImageUrlController;
  late final TextEditingController _emojiController;
  late final TextEditingController _lottieUrlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _categoryController = TextEditingController(text: widget.initialCategory);

    final catMeta = DataService.instance.getCategoryMetadata(
      widget.initialCategory,
    );
    final initialCatEmoji = widget.initialCategoryEmoji.isNotEmpty &&
            widget.initialCategoryEmoji != '🎯'
        ? widget.initialCategoryEmoji
        : (catMeta['emoji'] ?? widget.initialCategoryEmoji);
    final initialCatLottie =
        widget.initialCategoryLottieUrl?.trim().isNotEmpty == true
            ? widget.initialCategoryLottieUrl!.trim()
            : catMeta['lottieUrl'];
    final initialCatBg =
        widget.initialCategoryBackgroundImageUrl?.trim().isNotEmpty == true
            ? widget.initialCategoryBackgroundImageUrl!.trim()
            : catMeta['bgUrl'];

    _categoryEmojiController = TextEditingController(text: initialCatEmoji);
    _categoryLottieUrlController = TextEditingController(
      text: initialCatLottie ?? '',
    );
    _categoryBackgroundImageUrlController = TextEditingController(
      text: initialCatBg ?? '',
    );
    _emojiController = TextEditingController(text: widget.initialLessonEmoji);
    _lottieUrlController = TextEditingController(
      text: widget.initialLottieUrl ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Lesson Settings",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.editModeColor,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Lesson Title',
                    labelStyle: const TextStyle(color: AppTheme.editModeColor),
                    prefixIcon: const Icon(
                      Icons.title_rounded,
                      color: AppTheme.editModeColor,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppTheme.editModeColor,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _emojiController,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: 'Icon',
                    labelStyle: const TextStyle(color: AppTheme.editModeColor),
                    counterText: "",
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppTheme.editModeColor,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    labelStyle: const TextStyle(color: AppTheme.editModeColor),
                    prefixIcon: const Icon(
                      Icons.category_rounded,
                      color: AppTheme.editModeColor,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.manage_search_rounded,
                        color: AppTheme.editModeColor,
                      ),
                      tooltip: "Browse Categories",
                      onPressed: () async {
                        final result = await showCategoryPicker(context);
                        if (result != null) {
                          setState(() {
                            _categoryController.text = result['name'] ?? '';
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
                          });
                        }
                      },
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppTheme.editModeColor,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _categoryEmojiController,
                  textAlign: TextAlign.center,
                  maxLength: 2,
                  decoration: InputDecoration(
                    labelText: 'Cat Icon',
                    labelStyle: const TextStyle(color: AppTheme.editModeColor),
                    counterText: "",
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: AppTheme.editModeColor,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryLottieUrlController,
            decoration: InputDecoration(
              labelText: 'Category Lottie Animation URL (Optional)',
              labelStyle: const TextStyle(color: AppTheme.editModeColor),
              hintText: 'https://.../animation.lottie',
              prefixIcon: const Icon(
                Icons.animation_rounded,
                color: AppTheme.editModeColor,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppTheme.editModeColor,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryBackgroundImageUrlController,
            decoration: InputDecoration(
              labelText: 'Category Background Image URL (Optional)',
              labelStyle: const TextStyle(color: AppTheme.editModeColor),
              hintText: 'https://.../image.png',
              prefixIcon: const Icon(
                Icons.image_rounded,
                color: AppTheme.editModeColor,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppTheme.editModeColor,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lottieUrlController,
            decoration: InputDecoration(
              labelText: 'Lottie Animation URL (Optional)',
              labelStyle: const TextStyle(color: AppTheme.editModeColor),
              hintText: 'https://.../animation.lottie',
              prefixIcon: const Icon(
                Icons.animation_rounded,
                color: AppTheme.editModeColor,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: AppTheme.editModeColor,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  title: _titleController.text,
                  category: _categoryController.text,
                  categoryEmoji: _categoryEmojiController.text,
                  categoryLottieUrl:
                      _categoryLottieUrlController.text.trim().isEmpty
                          ? null
                          : _categoryLottieUrlController.text.trim(),
                  categoryBackgroundImageUrl:
                      _categoryBackgroundImageUrlController.text.trim().isEmpty
                          ? null
                          : _categoryBackgroundImageUrlController.text.trim(),
                  lessonEmoji: _emojiController.text,
                  lottieUrl: _lottieUrlController.text.trim().isEmpty
                      ? null
                      : _lottieUrlController.text.trim(),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.editModeColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Save Settings"),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
