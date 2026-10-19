import 'package:flutter/material.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/category_picker.dart';

class LessonSettingsSheet extends StatefulWidget {
  final String initialTitle;
  final String initialCategory;
  final String initialCategoryEmoji;
  final String initialLessonEmoji;
  final Function({
    required String title,
    required String category,
    required String categoryEmoji,
    required String lessonEmoji,
  })
  onSave;

  const LessonSettingsSheet({
    super.key,
    required this.initialTitle,
    required this.initialCategory,
    required this.initialCategoryEmoji,
    required this.initialLessonEmoji,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String category,
    required String categoryEmoji,
    required String lessonEmoji,
    required Function({
      required String title,
      required String category,
      required String categoryEmoji,
      required String lessonEmoji,
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
        initialLessonEmoji: lessonEmoji,
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
  late final TextEditingController _emojiController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _categoryController = TextEditingController(text: widget.initialCategory);
    _categoryEmojiController = TextEditingController(
      text: widget.initialCategoryEmoji,
    );
    _emojiController = TextEditingController(text: widget.initialLessonEmoji);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _categoryEmojiController.dispose();
    _emojiController.dispose();
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  title: _titleController.text,
                  category: _categoryController.text,
                  categoryEmoji: _categoryEmojiController.text,
                  lessonEmoji: _emojiController.text,
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
