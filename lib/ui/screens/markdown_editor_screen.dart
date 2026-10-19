import 'package:flutter/material.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/info_take_page.dart';

class MarkdownEditorScreen extends StatefulWidget {
  final String initialContent;
  final String editorTitle;
  final String infoTitle;
  final String infoImageUrl;

  const MarkdownEditorScreen({
    super.key,
    required this.initialContent,
    this.editorTitle = 'Edit Content',
    this.infoTitle = '',
    this.infoImageUrl = '',
  });

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _formatText(String prefix, String suffix) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length + selectedText.length + suffix.length,
      );
    } else {
      final currentPos = selection.start;
      final newText = text.replaceRange(currentPos, currentPos, '$prefix$suffix');
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
        offset: currentPos + prefix.length,
      );
    }
    setState(() {});
  }

  void _previewInInfoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoTakePage(
          title: widget.infoTitle,
          content: _controller.text,
          imageUrl: widget.infoImageUrl,
          showAppBar: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editorTitle,
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () => Navigator.pop(context, _controller.text),
              child: Text(
                "Save",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: Theme(
              data: theme.copyWith(
                textSelectionTheme: TextSelectionThemeData(
                  selectionColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  selectionHandleColor: AppTheme.primaryColor,
                  cursorColor: AppTheme.primaryColor,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color),
                  decoration: const InputDecoration(
                    hintText: "Write your content here...",
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarIcon(icon: Icons.format_bold, onPressed: () => _formatText('**', '**')),
                  _ToolbarIcon(icon: Icons.format_italic, onPressed: () => _formatText('*', '*')),
                  _ToolbarIcon(icon: Icons.format_underlined, onPressed: () => _formatText('<u>', '</u>')),
                  const SizedBox(width: 8),
                  _ToolbarIcon(icon: Icons.format_size, onPressed: () => _formatText('# ', '')),
                  _ToolbarIcon(icon: Icons.format_list_bulleted, onPressed: () => _formatText('\n- ', '')),
                  _ToolbarIcon(icon: Icons.format_quote, onPressed: () => _formatText('\n> ', '')),
                ],
              ),
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.withValues(alpha: 0.2),
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          TextButton.icon(
            onPressed: _previewInInfoPage,
            icon: Icon(
              Icons.remove_red_eye_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              "Preview",
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ToolbarIcon({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, color: theme.iconTheme.color?.withValues(alpha: 0.7)),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      iconSize: 22,
    );
  }
}
