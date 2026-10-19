import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class MeaningCreatePage extends StatefulWidget {
  final ExampleSentence sentence;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const MeaningCreatePage({
    super.key,
    required this.sentence,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<MeaningCreatePage> createState() => _MeaningCreatePageState();
}

class _MeaningCreatePageState extends State<MeaningCreatePage> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.sentence.sentence);
    _answerController = TextEditingController(text: widget.sentence.gapAnswer);
  }

  @override
  void didUpdateWidget(MeaningCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sentence.sentence != _questionController.text) {
      _questionController.text = widget.sentence.sentence;
    }
    if (widget.sentence.gapAnswer != _answerController.text) {
      _answerController.text = widget.sentence.gapAnswer;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Meaning Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.translate_rounded,
              title: "Meaning Configuration",
              description:
                  "Enter a question and the correct meaning or answer.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "QUESTION",
                    color: AppTheme.editModeColor,
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _questionController,
                    field: 'question',
                    label: 'Enter question (e.g. Thai word)',
                    icon: Icons.help_outline_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "CORRECT ANSWER",
                    color: AppTheme.editModeColor,
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 32, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _answerController,
                    field: 'answer',
                    label: 'Enter correct answer (e.g. English meaning)',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: 40),
                  const ThaiInfoBox(
                    icon: Icons.lightbulb_outline_rounded,
                    text:
                        "Pro-tip: Enter clear questions and answers to help users learn effectively.",
                    color: Colors.amber,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      maxLines: null,
      onChanged: (val) => widget.onEdit?.call(field, val),
    );
  }
}
