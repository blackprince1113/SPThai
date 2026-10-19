import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class SpeakingCreatePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const SpeakingCreatePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<SpeakingCreatePage> createState() => _SpeakingCreatePageState();
}

class _SpeakingCreatePageState extends State<SpeakingCreatePage> {
  late TextEditingController _thaiController;
  late TextEditingController _phoneticController;
  late TextEditingController _englishController;

  @override
  void initState() {
    super.initState();
    _thaiController = TextEditingController(text: widget.word.thai);
    _phoneticController = TextEditingController(text: widget.word.phonetic);
    _englishController = TextEditingController(text: widget.word.english);
  }

  @override
  void didUpdateWidget(SpeakingCreatePage oldWidget) {
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
  }

  @override
  void dispose() {
    _thaiController.dispose();
    _phoneticController.dispose();
    _englishController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Speaking Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.mic_rounded,
              title: "Speaking Configuration",
              description: "Customize the word and pronunciation guide",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "THAI WORD",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _thaiController,
                    field: 'thai',
                    label: 'Thai Word',
                    icon: Icons.translate_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "PRONUNCIATION",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _phoneticController,
                    field: 'phonetic',
                    label: 'Phonetic Guide',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "MEANING",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _englishController,
                    field: 'english',
                    label: 'English Meaning',
                    icon: Icons.info_outline_rounded,
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
