import 'package:flutter/material.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/screens/markdown_editor_screen.dart';

class InfoCreatePage extends StatefulWidget {
  final String title;
  final String content;
  final String imageUrl;
  final bool showAppBar;
  final Function(String field, String value)? onEdit;

  const InfoCreatePage({
    super.key,
    required this.title,
    required this.content,
    required this.imageUrl,
    this.showAppBar = true,
    this.onEdit,
  });

  @override
  State<InfoCreatePage> createState() => _InfoCreatePageState();
}

class _InfoCreatePageState extends State<InfoCreatePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _imageController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
    _imageController = TextEditingController(text: widget.imageUrl);
  }

  @override
  void didUpdateWidget(InfoCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != _titleController.text) {
      _titleController.text = widget.title;
    }
    if (widget.content != _contentController.text) {
      _contentController.text = widget.content;
    }
    if (widget.imageUrl != _imageController.text) {
      _imageController.text = widget.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _openFullEditor() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => MarkdownEditorScreen(
          initialContent: _contentController.text,
          editorTitle: "Edit Info Content",
          infoTitle: _titleController.text,
          infoImageUrl: _imageController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _contentController.text = result;
      });
      widget.onEdit?.call('answer', result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "⚙️ Info Note Settings")
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.article_rounded,
              title: "Info Note Configuration",
              description:
                  "Create an informative card with a title, image, and detailed content.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "TITLE",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _titleController,
                    field: 'question',
                    label: 'Headline',
                    icon: Icons.title_rounded,
                  ),
                  const ThaiSectionLabel(
                    label: "IMAGE URL",
                    fontSize: 12,
                    padding: EdgeInsets.only(top: 24, bottom: 12),
                  ),
                  _buildEditableField(
                    controller: _imageController,
                    field: 'imageUrl',
                    label: 'Link or Emoji',
                    icon: Icons.image_rounded,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ThaiSectionLabel(label: "CONTENT", fontSize: 12),
                      TextButton.icon(
                        onPressed: _openFullEditor,
                        icon: Icon(
                          Icons.fullscreen_rounded,
                          size: 18,
                          color: primaryColor,
                        ),
                        label: Text(
                          "Open Full Editor",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _openFullEditor,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light
                            ? primaryColor.withValues(alpha: 0.05)
                            : theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _contentController.text.isEmpty
                            ? "Tap to add content..."
                            : _contentController.text,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _contentController.text.isEmpty
                              ? primaryColor.withValues(alpha: 0.5)
                              : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tips: Use the Full Editor for formatting and writing long content.",
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
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
