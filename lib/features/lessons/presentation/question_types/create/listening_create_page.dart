import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ListeningCreatePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const ListeningCreatePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<ListeningCreatePage> createState() => _ListeningCreatePageState();
}

class _ListeningCreatePageState extends State<ListeningCreatePage> {
  late TextEditingController _thaiController;

  @override
  void initState() {
    super.initState();
    _thaiController = TextEditingController(text: widget.word.thai);
  }

  @override
  void didUpdateWidget(ListeningCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.thai != _thaiController.text) {
      _thaiController.text = widget.word.thai;
    }
  }

  @override
  void dispose() {
    _thaiController.dispose();
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
              description:
                  "Configure the word that users need to listen and type.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "CORRECT THAI WORD",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _thaiController,
                    field: 'thai',
                    label: 'Thai Word',
                    icon: Icons.record_voice_over_rounded,
                  ),
                  const SizedBox(height: 40),
                  ThaiInfoBox(
                    icon: Icons.info_outline_rounded,
                    text:
                        "Note: This word will be played as audio and the user must type it exactly to pass.",
                    color: primaryColor,
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
