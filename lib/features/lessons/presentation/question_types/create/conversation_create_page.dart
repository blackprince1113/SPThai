import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ConversationCreatePage extends StatefulWidget {
  final List<ChatMessage> initialMessages;
  final String initialLeftSpeakerUrl;
  final String initialRightSpeakerUrl;
  final Function(String field, dynamic value)? onEdit;

  const ConversationCreatePage({
    super.key,
    required this.initialMessages,
    this.initialLeftSpeakerUrl = '',
    this.initialRightSpeakerUrl = '',
    this.onEdit,
  });

  @override
  State<ConversationCreatePage> createState() => _ConversationCreatePageState();
}

class _ConversationCreatePageState extends State<ConversationCreatePage> {
  late List<ChatMessage> _messages;
  late TextEditingController _leftSpeakerController;
  late TextEditingController _rightSpeakerController;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.initialMessages);
    if (_messages.isEmpty) {
      _messages.add(ChatMessage(text: "", translation: "", isLeft: true));
    }
    _leftSpeakerController =
        TextEditingController(text: widget.initialLeftSpeakerUrl);
    _rightSpeakerController =
        TextEditingController(text: widget.initialRightSpeakerUrl);
  }

  @override
  void didUpdateWidget(ConversationCreatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLeftSpeakerUrl != _leftSpeakerController.text) {
      _leftSpeakerController.text = widget.initialLeftSpeakerUrl;
    }
    if (widget.initialRightSpeakerUrl != _rightSpeakerController.text) {
      _rightSpeakerController.text = widget.initialRightSpeakerUrl;
    }
  }

  @override
  void dispose() {
    _leftSpeakerController.dispose();
    _rightSpeakerController.dispose();
    super.dispose();
  }

  void _addMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: "",
          translation: "",
          phonetic: "",
          isLeft: !_messages.last.isLeft,
        ),
      );
    });
    _notifyUpdate();
  }

  void _removeMessage(int index) {
    if (_messages.length <= 1) return;
    setState(() {
      _messages.removeAt(index);
    });
    _notifyUpdate();
  }

  void _updateMessage(
    int index, {
    String? text,
    String? translation,
    String? phonetic,
    bool? isLeft,
  }) {
    setState(() {
      final old = _messages[index];
      _messages[index] = ChatMessage(
        text: text ?? old.text,
        translation: translation ?? old.translation,
        phonetic: phonetic ?? old.phonetic,
        isLeft: isLeft ?? old.isLeft,
      );
    });
    _notifyUpdate();
  }

  void _notifyUpdate() {
    widget.onEdit?.call('conversation', _messages);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ThaiCreateHeader(
              icon: Icons.forum_rounded,
              title: "Conversation Configuration",
              description:
                  "Build a dialogue by adding messages from left and right speakers.",
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ThaiSectionLabel(
                    label: "SPEAKER ICONS (OPTIONAL)",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  _buildSpeakerUrlCard(
                    controller: _leftSpeakerController,
                    label: "Left Speaker Icon",
                    field: "leftSpeakerUrl",
                    isLeft: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSpeakerUrlCard(
                    controller: _rightSpeakerController,
                    label: "Right Speaker Icon",
                    field: "rightSpeakerUrl",
                    isLeft: false,
                  ),
                  const SizedBox(height: 24),
                  const ThaiSectionLabel(
                    label: "MESSAGES",
                    fontSize: 12,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  ..._messages.asMap().entries.map((entry) {
                    return _buildMessageEditor(entry.key, entry.value);
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addMessage,
                      icon: const Icon(Icons.add_comment_rounded),
                      label: const Text("ADD MESSAGE"),
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

  Widget _buildSpeakerUrlCard({
    required TextEditingController controller,
    required String label,
    required String field,
    required bool isLeft,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
            children: [
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final url = value.text.trim();
                  final hasImage = url.isNotEmpty;
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: isLeft
                        ? Colors.blue.shade100
                        : Colors.orange.shade100,
                    backgroundImage: hasImage ? NetworkImage(url) : null,
                    onBackgroundImageError: hasImage ? (_, __) {} : null,
                    child: !hasImage
                        ? Icon(
                            isLeft
                                ? Icons.person_rounded
                                : Icons.person_outline_rounded,
                            size: 18,
                            color: isLeft ? Colors.blue : Colors.orange,
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyLarge?.color,
            ),
            decoration: editableInputDecoration(theme, primaryColor).copyWith(
              hintText: "Image URL...",
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
            ),
            onChanged: (val) => widget.onEdit?.call(field, val),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageEditor(int index, ChatMessage msg) {
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
              Row(
                children: [
                  ThaiSectionLabel(label: "SIDE:", color: primaryColor),
                  const SizedBox(width: 8),
                  ToggleButtons(
                    isSelected: [msg.isLeft, !msg.isLeft],
                    onPressed: (i) => _updateMessage(index, isLeft: i == 0),
                    borderRadius: BorderRadius.circular(10),
                    constraints: const BoxConstraints(
                      minHeight: 30,
                      minWidth: 60,
                    ),
                    selectedColor: Colors.white,
                    fillColor: primaryColor,
                    children: const [
                      Text(
                        "LEFT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "RIGHT",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _removeMessage(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTinyField(
            initialValue: msg.text,
            label: "Thai Text",
            onChanged: (v) => _updateMessage(index, text: v),
          ),
          const SizedBox(height: 12),
          _buildTinyField(
            initialValue: msg.phonetic,
            label: "Phonetic",
            onChanged: (v) => _updateMessage(index, phonetic: v),
          ),
          const SizedBox(height: 12),
          _buildTinyField(
            initialValue: msg.translation,
            label: "Translation",
            onChanged: (v) => _updateMessage(index, translation: v),
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
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color,
          ),
          decoration: editableInputDecoration(theme, primaryColor),
        ),
      ],
    );
  }
}
