import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class SentenceExampleTakePage extends StatefulWidget {
  final List<ChatMessage> sentences;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const SentenceExampleTakePage({
    super.key,
    required this.sentences,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<SentenceExampleTakePage> createState() =>
      _SentenceExampleTakePageState();
}

class _SentenceExampleTakePageState extends State<SentenceExampleTakePage> {
  final AudioService _audio = AudioService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.isActive && widget.sentences.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) speakThaiNormal(widget.sentences.first.text);
      });
    }
  }

  @override
  void didUpdateWidget(SentenceExampleTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && widget.sentences.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) speakThaiNormal(widget.sentences.first.text);
      });
    }
  }

  Future<void> speakThaiNormal(String text) async {
    await _audio.speakThai(text);
  }

  Future<void> speakThaiSlow(String text) async {
    await _audio.speakThai(text, rate: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            ThaiLessonProgress(
              currentIndex: widget.currentIndex,
              totalSteps: widget.totalSteps,
            ),
            const SizedBox(height: 32),
            Center(
              child: ThaiSectionLabel(
                label: "EXAMPLE SENTENCES",
                color: AppTheme.primaryColor,
                fontSize: 12,
                padding: const EdgeInsets.only(bottom: 24),
              ),
            ),
            ...widget.sentences.asMap().entries.map((entry) {
              final index = entry.key;
              final sentence = entry.value;
              return _buildSentenceItem(index, sentence);
            }),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  StepResultNotification(true).dispatch(context);
                },
                child: const Text(
                  "CONTINUE",
                  style: TextStyle(fontSize: 18, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? const ThaiAppBar(title: "Example Sentences")
          : null,
      body: content,
    );
  }

  Widget _buildSentenceItem(int index, ChatMessage sentence) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sentence.text,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color:
                          theme.textTheme.headlineLarge?.color ??
                          AppTheme.textColor,
                      height: 1.2,
                    ),
                  ),
                  if (sentence.phonetic.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      sentence.phonetic,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    sentence.translation,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color:
                          theme.textTheme.bodyLarge?.color?.withValues(
                            alpha: 0.8,
                          ) ??
                          Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                _buildSmallIconButton(
                  icon: Icons.volume_up_rounded,
                  color: primaryColor,
                  onTap: () => speakThaiNormal(sentence.text),
                ),
                const SizedBox(height: 12),
                _buildSmallIconButton(
                  icon: Icons.slow_motion_video_rounded,
                  color: Colors.pink.shade300,
                  onTap: () => speakThaiSlow(sentence.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}
