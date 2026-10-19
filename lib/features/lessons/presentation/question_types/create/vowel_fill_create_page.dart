import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class VowelFillCreatePage extends StatefulWidget {
  final WordEntry word;
  final String question;
  final String answer;
  final List<String> choices;
  final bool showAppBar;
  final Function(String field, dynamic value)? onEdit;

  const VowelFillCreatePage({
    super.key,
    required this.word,
    required this.question,
    required this.answer,
    required this.choices,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<VowelFillCreatePage> createState() => _VowelFillCreatePageState();
}

class _VowelFillCreatePageState extends State<VowelFillCreatePage> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late final TextEditingController _thaiController;
  late final TextEditingController _imageUrlController;
  final List<TextEditingController> _choiceControllers = [];

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question);
    _answerController = TextEditingController(text: widget.answer);
    _thaiController = TextEditingController(text: widget.word.thai);
    _imageUrlController = TextEditingController(text: widget.word.imageUrl);

    for (int i = 0; i < 4; i++) {
      _choiceControllers.add(
        TextEditingController(
          text: widget.choices.length > i ? widget.choices[i] : "",
        ),
      );
    }
  }

  void _syncTextFields() {
    if (_questionController.text != widget.question) {
      _questionController.text = widget.question;
    }
    if (_answerController.text != widget.answer) {
      _answerController.text = widget.answer;
    }
    if (_thaiController.text != widget.word.thai) {
      _thaiController.text = widget.word.thai;
    }
    if (_imageUrlController.text != widget.word.imageUrl) {
      _imageUrlController.text = widget.word.imageUrl;
    }

    for (int i = 0; i < 4; i++) {
      String text = widget.choices.length > i ? widget.choices[i] : "";
      if (_choiceControllers[i].text != text) _choiceControllers[i].text = text;
    }
  }

  @override
  void didUpdateWidget(VowelFillCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTextFields();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _thaiController.dispose();
    _imageUrlController.dispose();
    for (var c in _choiceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    int correctIndex = -1;
    for (int i = 0; i < widget.choices.length; i++) {
      if (widget.choices[i] == widget.answer && widget.answer.isNotEmpty) {
        correctIndex = i;
        break;
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Vowel Fill Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.spellcheck_rounded,
              title: "Vowel Configuration",
              description:
                  "Create a word with a missing vowel for users to fill.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "IMAGE OR EMOJI",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _imageUrlController,
                    field: 'imageUrl',
                    label: 'Link or Emoji',
                    icon: Icons.image_outlined,
                  ),
                  const ThaiSectionLabel(
                    label: "FULL WORD (FOR AUDIO)",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _thaiController,
                    field: 'thai',
                    label: 'Full Thai word (e.g., แกะ)',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "QUESTION CONTENT",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _questionController,
                    field: 'question',
                    label: 'Word with gap (e.g., ...ก...)',
                    icon: Icons.text_fields_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "ANSWER CHOICES",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 32, bottom: 8),
                  ),
                  Text(
                    "Tap the switch to mark a vowel as correct.",
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(
                    4,
                    (index) => _buildEditableChoice(index, correctIndex),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableChoice(int index, int correctIndex) {
    final isCorrect = correctIndex == index;
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
        if (val) {
          widget.onEdit?.call('answer', _choiceControllers[index].text);
        }
      },
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String field,
    required String label,
    required IconData icon,
  }) {
    return ThaiEditableFieldCard(
      controller: controller,
      label: label,
      icon: icon,
      onChanged: (val) => widget.onEdit?.call(field, val),
    );
  }
}
