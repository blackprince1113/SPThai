import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ConversationTakePage extends StatefulWidget {
  final List<ChatMessage> messages;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const ConversationTakePage({
    super.key,
    required this.messages,
    required this.currentIndex,
    required this.totalSteps,
    this.isActive = false,
  });

  @override
  State<ConversationTakePage> createState() => _ConversationTakePageState();
}

class _ConversationTakePageState extends State<ConversationTakePage> {
  final AudioService _audio = AudioService.instance;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 1;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _playFirstMessage();
    }
  }

  @override
  void didUpdateWidget(ConversationTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _playFirstMessage();
    }
  }

  void _playFirstMessage() {
    if (widget.messages.isNotEmpty) {
      _speak(widget.messages[0].text);
    }
  }

  Future<void> _speak(String text) async {
    await _audio.speakThai(text);
  }

  void _showNext() {
    if (_visibleCount < widget.messages.length) {
      setState(() {
        _visibleCount++;
      });
      _speak(widget.messages[_visibleCount - 1].text);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMore = _visibleCount < widget.messages.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ThaiLessonProgress(
                currentIndex: widget.currentIndex,
                totalSteps: widget.totalSteps,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "PRACTICE CONVERSATION",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: _visibleCount,
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  return _ChatBubble(
                    message: msg,
                    onSpeak: () => _speak(msg.text),
                  );
                },
              ),
            ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ThaiButton(
                    text: "NEXT MESSAGE",
                    onPressed: _showNext,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onSpeak;

  const _ChatBubble({required this.message, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLeft = message.isLeft;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLeft) _buildAvatar(isLeft),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLeft
                          ? theme.cardColor
                          : AppTheme.primaryColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isLeft ? 0 : 20),
                        topRight: Radius.circular(isLeft ? 20 : 0),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      border: Border.all(
                        color: isLeft
                            ? theme.dividerColor.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isLeft
                                ? theme.textTheme.bodyLarge?.color
                                : AppTheme.primaryColor,
                          ),
                        ),
                        if (message.phonetic.isNotEmpty)
                          Text(
                            message.phonetic,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isLeft
                                  ? theme.disabledColor
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.7,
                                    ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message.translation,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                theme.textTheme.bodyMedium?.color?.withValues(
                                  alpha: 0.6,
                                ) ??
                                theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isLeft) _buildAvatar(isLeft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isLeft) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: isLeft ? Colors.blue.shade100 : Colors.orange.shade100,
      child: Icon(
        isLeft ? Icons.person_rounded : Icons.person_outline_rounded,
        size: 20,
        color: isLeft ? Colors.blue : Colors.orange,
      ),
    );
  }
}
