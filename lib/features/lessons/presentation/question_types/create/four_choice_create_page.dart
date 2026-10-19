import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/four_choice_controller.dart';

class FourChoiceCreatePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final String category;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const FourChoiceCreatePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    required this.category,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<FourChoiceCreatePage> createState() => _FourChoiceCreatePageState();
}

class _FourChoiceCreatePageState extends State<FourChoiceCreatePage> {
  late final FourChoiceController _controller;
  final List<TextEditingController> _choiceControllers = [];
  late TextEditingController _questionController;

  @override
  void initState() {
    super.initState();
    _controller = FourChoiceController(
      word: widget.word,
      category: widget.category,
      initialChoices: widget.choices,
      correctAnswer: widget.correctAnswer,
    );
    _questionController = TextEditingController(text: widget.word.thai);

    for (int i = 0; i < 4; i++) {
      String initialText = "";
      if (i < widget.choices.length) {
        initialText = widget.choices[i];
      }
      _choiceControllers.add(TextEditingController(text: initialText));
    }
  }

  @override
  void didUpdateWidget(FourChoiceCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.thai != _questionController.text) {
      _questionController.text = widget.word.thai;
    }
    for (int i = 0; i < 4; i++) {
      String choiceText = "";
      if (i < widget.choices.length) {
        choiceText = widget.choices[i];
      }

      if (i < _choiceControllers.length &&
          choiceText != _choiceControllers[i].text) {
        _choiceControllers[i].text = choiceText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _questionController.dispose();
    for (var c in _choiceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Quiz Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.quiz_rounded,
              title: "Quiz Configuration",
              description: "Customize how this question appears to users",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "QUESTION CONTENT",
                    color: AppTheme.editModeColor,
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableCard(
                    controller: _questionController,
                    field: 'thai',
                    label: 'Question Content (Thai)',
                    icon: Icons.text_fields_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "ANSWER CHOICES",
                    color: AppTheme.editModeColor,
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 32, bottom: 8),
                  ),
                  Text(
                    "Tap the switch to mark a choice as correct.",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.editModeColor.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(4, (index) => _buildEditableChoice(index)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableChoice(int index) {
    final choiceText = index < widget.choices.length
        ? widget.choices[index]
        : "";
    final isCorrect =
        widget.correctAnswer == choiceText && choiceText.isNotEmpty;

    return ThaiEditableChoiceTile(
      key: ValueKey('choice_container_$index'),
      index: index,
      controller: _choiceControllers[index],
      isCorrect: isCorrect,
      onChanged: (val) {
        if (isCorrect) {
          widget.onEdit?.call('answer', val);
        }
        widget.onEdit?.call('choice_$index', val);
      },
      onCorrectChanged: (val) {
        if (!val) return;
        final currentText = _choiceControllers[index].text;
        _controller.setCorrectIndex(index, currentText);
        widget.onEdit?.call('answer', currentText);
      },
    );
  }

  Widget _buildEditableCard({
    required TextEditingController controller,
    required String field,
    required String label,
    required IconData icon,
  }) {
    return ThaiEditableFieldCard(
      controller: controller,
      label: label,
      icon: icon,
      maxLines: null,
      onChanged: (val) => widget.onEdit?.call(field, val),
    );
  }
}
