import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class SentenceExampleCreatePage extends StatefulWidget {
  final List<ChatMessage> initialSentences;
  final bool showAppBar;
  final Function(String field, dynamic value)? onEdit;

  const SentenceExampleCreatePage({
    super.key,
    required this.initialSentences,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<SentenceExampleCreatePage> createState() =>
      _SentenceExampleCreatePageState();
}

class _SentenceExampleCreatePageState extends State<SentenceExampleCreatePage> {
  late List<ChatMessage> _sentences;

  @override
  void initState() {
    super.initState();
    _sentences = List.from(widget.initialSentences);
    if (_sentences.isEmpty) {
      _sentences.add(
        ChatMessage(text: "", translation: "", phonetic: "", isLeft: true),
      );
    }
  }

  void _addSentence() {
    setState(() {
      _sentences.add(
        ChatMessage(text: "", translation: "", phonetic: "", isLeft: true),
      );
    });
    _notifyUpdate();
  }

  void _removeSentence(int index) {
    if (_sentences.length <= 1) return;
    setState(() {
      _sentences.removeAt(index);
    });
    _notifyUpdate();
  }

  void _updateSentence(
    int index, {
    String? text,
    String? translation,
    String? phonetic,
  }) {
    setState(() {
      final old = _sentences[index];
      _sentences[index] = ChatMessage(
        text: text ?? old.text,
        translation: translation ?? old.translation,
        phonetic: phonetic ?? old.phonetic,
        isLeft: true,
      );
    });
    _notifyUpdate();
  }

  void _notifyUpdate() {
    widget.onEdit?.call('conversation', _sentences);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Sentence Example Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.notes_rounded,
              title: "Sentence Example Configuration",
              description:
                  "Add multiple Thai sentences with phonetic guides and translations.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ..._sentences.asMap().entries.map((entry) {
                    return _buildSentenceEditor(entry.key, entry.value);
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addSentence,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text("ADD ANOTHER SENTENCE"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceEditor(int index, ChatMessage msg) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SENTENCE #${index + 1}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              if (_sentences.length > 1)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: () => _removeSentence(index),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTinyField(
            initialValue: msg.text,
            label: "Thai Sentence",
            onChanged: (v) => _updateSentence(index, text: v),
          ),
          const SizedBox(height: 12),
          _buildTinyField(
            initialValue: msg.phonetic,
            label: "Phonetic Pronunciation",
            onChanged: (v) => _updateSentence(index, phonetic: v),
          ),
          const SizedBox(height: 12),
          _buildTinyField(
            initialValue: msg.translation,
            label: "English Meaning",
            onChanged: (v) => _updateSentence(index, translation: v),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyField({
    required String initialValue,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
          decoration: editableInputDecoration(theme, primaryColor),
        ),
      ],
    );
  }
}
