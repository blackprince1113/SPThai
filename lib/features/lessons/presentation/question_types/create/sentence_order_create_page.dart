import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class SentenceOrderCreatePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final String category;
  final bool showAppBar;
  final Function(String field, dynamic value)? onEdit;

  const SentenceOrderCreatePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    required this.category,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<SentenceOrderCreatePage> createState() =>
      _SentenceOrderCreatePageState();
}

class _SentenceOrderCreatePageState extends State<SentenceOrderCreatePage> {
  late final TextEditingController _sentenceController;
  late final TextEditingController _englishController;
  final List<TextEditingController> _tokenControllers = [];

  @override
  void initState() {
    super.initState();
    _sentenceController = TextEditingController(text: widget.correctAnswer);
    _englishController = TextEditingController(text: widget.word.english);

    for (var choice in widget.choices) {
      _tokenControllers.add(TextEditingController(text: choice));
    }
  }

  void _syncTextFields() {
    if (_sentenceController.text != widget.correctAnswer) {
      _sentenceController.text = widget.correctAnswer;
    }
    if (_englishController.text != widget.word.english) {
      _englishController.text = widget.word.english;
    }

    if (_tokenControllers.length != widget.choices.length) {
      for (var c in _tokenControllers) {
        c.dispose();
      }
      _tokenControllers.clear();
      for (var choice in widget.choices) {
        _tokenControllers.add(TextEditingController(text: choice));
      }
    } else {
      for (int i = 0; i < widget.choices.length; i++) {
        if (_tokenControllers[i].text != widget.choices[i]) {
          _tokenControllers[i].text = widget.choices[i];
        }
      }
    }
  }

  @override
  void didUpdateWidget(SentenceOrderCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTextFields();
  }

  @override
  void dispose() {
    _sentenceController.dispose();
    _englishController.dispose();
    for (var c in _tokenControllers) {
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
          ? const ThaiAppBar(title: "⚙️ Sentence Order Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.sort_rounded,
              title: "Sentence Order Configuration",
              description:
                  "Split the sentence into words for the user to arrange.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "FULL SENTENCE (THAI)",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableCard(
                    controller: _sentenceController,
                    field: 'answer',
                    label: 'Target Sentence',
                    icon: Icons.text_fields_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "MEANING (ENGLISH)",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableCard(
                    controller: _englishController,
                    field: 'english',
                    label: 'English Translation',
                    icon: Icons.translate_rounded,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ThaiSectionLabel(
                        label: "WORDS / TOKENS",
                        fontSize: 12,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final newList = _tokenControllers
                                .map((e) => e.text)
                                .toList();
                            newList.add("");
                            widget.onEdit?.call('choices', newList);
                          });
                        },
                        icon: Icon(Icons.add, size: 18, color: primaryColor),
                        label: Text(
                          "Add Word",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tokenControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: ThaiEditableFieldCard(
                                controller: _tokenControllers[index],
                                label: "Word ${index + 1}",
                                icon: Icons.extension_rounded,
                                onChanged: (val) {
                                  final newList = _tokenControllers
                                      .map((e) => e.text)
                                      .toList();
                                  widget.onEdit?.call('choices', newList);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  final newList = _tokenControllers
                                      .map((e) => e.text)
                                      .toList();
                                  newList.removeAt(index);
                                  widget.onEdit?.call('choices', newList);
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: Colors.red,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
