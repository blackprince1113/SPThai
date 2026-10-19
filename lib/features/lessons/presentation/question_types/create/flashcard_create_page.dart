import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class FlashcardCreatePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const FlashcardCreatePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<FlashcardCreatePage> createState() => _FlashcardCreatePageState();
}

class _FlashcardCreatePageState extends State<FlashcardCreatePage> {
  late TextEditingController _thaiController;
  late TextEditingController _phoneticController;
  late TextEditingController _englishController;
  late TextEditingController _imageUrlController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _thaiController = TextEditingController(text: widget.word.thai);
    _phoneticController = TextEditingController(text: widget.word.phonetic);
    _englishController = TextEditingController(text: widget.word.english);
    _imageUrlController = TextEditingController(text: widget.word.imageUrl);
  }

  @override
  void didUpdateWidget(FlashcardCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.thai != _thaiController.text) {
      _thaiController.text = widget.word.thai;
    }
    if (widget.word.phonetic != _phoneticController.text) {
      _phoneticController.text = widget.word.phonetic;
    }
    if (widget.word.english != _englishController.text) {
      _englishController.text = widget.word.english;
    }
    if (widget.word.imageUrl != _imageUrlController.text) {
      _imageUrlController.text = widget.word.imageUrl;
    }
  }

  @override
  void dispose() {
    _thaiController.dispose();
    _phoneticController.dispose();
    _englishController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Flashcard Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.style_rounded,
              title: "Flashcard Configuration",
              description: "Edit the word, phonetic guide, and translation.",
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
                    label: "THAI WORD",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _thaiController,
                    field: 'thai',
                    label: 'Thai Word',
                    icon: Icons.translate_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "PHONETIC",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _phoneticController,
                    field: 'phonetic',
                    label: 'Phonetic Pronunciation',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "ENGLISH MEANING",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _englishController,
                    field: 'english',
                    label: 'Meaning in English',
                    icon: Icons.language_rounded,
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
      onChanged: (val) => widget.onEdit?.call(field, val),
    );
  }
}
