import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ListeningChoiceCreatePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const ListeningChoiceCreatePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<ListeningChoiceCreatePage> createState() =>
      _ListeningChoiceCreatePageState();
}

class _ListeningChoiceCreatePageState extends State<ListeningChoiceCreatePage> {
  final List<TextEditingController> _choiceControllers = [];
  late TextEditingController _thaiController;
  int _correctIndex = -1;

  @override
  void initState() {
    super.initState();
    _thaiController = TextEditingController(text: widget.word.thai);

    for (int i = 0; i < 4; i++) {
      String initialText = "";
      if (i < widget.choices.length) {
        initialText = widget.choices[i];
        if (initialText == widget.correctAnswer && initialText.isNotEmpty) {
          _correctIndex = i;
        }
      }
      _choiceControllers.add(TextEditingController(text: initialText));
    }
  }

  @override
  void didUpdateWidget(ListeningChoiceCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.thai != _thaiController.text) {
      _thaiController.text = widget.word.thai;
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

      if (choiceText == widget.correctAnswer && choiceText.isNotEmpty) {
        _correctIndex = i;
      }
    }
  }

  @override
  void dispose() {
    _thaiController.dispose();
    for (var c in _choiceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Listening Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.headphones_rounded,
              title: "Listening Configuration",
              description: "Configure the audio word and the four choices.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "AUDIO WORD (THAI)",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _thaiController,
                    field: 'thai',
                    label: 'Word to speak (Thai)',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "ANSWER CHOICES",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 32, bottom: 8),
                  ),
                  Text(
                    "Tap the switch to mark a choice as correct.",
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryColor.withValues(alpha: 0.7),
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
    final isCorrect = _correctIndex == index;
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
        setState(() => _correctIndex = index);
        widget.onEdit?.call('answer', _choiceControllers[index].text);
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
