import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class CompleteSentenceCreatePage extends StatefulWidget {
  final ExampleSentence sentence;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const CompleteSentenceCreatePage({
    super.key,
    required this.sentence,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<CompleteSentenceCreatePage> createState() =>
      _CompleteSentenceCreatePageState();
}

class _CompleteSentenceCreatePageState
    extends State<CompleteSentenceCreatePage> {
  late TextEditingController _questionController;
  late TextEditingController _answerController;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.sentence.sentence);
    _answerController = TextEditingController(text: widget.sentence.gapAnswer);
  }

  @override
  void didUpdateWidget(CompleteSentenceCreatePage oldWidget) {
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
          ? const ThaiAppBar(title: "⚙️ Complete Sentence Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.edit_note_rounded,
              title: "Sentence Configuration",
              description:
                  "Create a sentence with a missing word for users to fill.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "SENTENCE WITH GAP",
                    color: AppTheme.editModeColor,
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _questionController,
                    field: 'question',
                    label: 'Sentence (use .... for gap)',
                    icon: Icons.short_text_rounded,
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
                    label: 'The missing word',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(height: 40),
                  const ThaiInfoBox(
                    icon: Icons.lightbulb_outline_rounded,
                    text:
                        "Pro-tip: Make sure the sentence has exactly '....' where you want the blank to appear.",
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
