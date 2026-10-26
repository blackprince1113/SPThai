import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/speaking_controller.dart';

class SpeakingTakePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const SpeakingTakePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<SpeakingTakePage> createState() => _SpeakingTakePageState();
}

class _SpeakingTakePageState extends State<SpeakingTakePage> {
  late final SpeakingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SpeakingController(widget.word);
    if (widget.isActive) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _controller.speakThaiNormal();
      });
    }
  }

  @override
  void didUpdateWidget(SpeakingTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _controller.speakThaiNormal();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        Widget body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 24),
                ThaiLessonProgress(
                  currentIndex: widget.currentIndex,
                  totalSteps: widget.totalSteps,
                ),
                const SizedBox(height: 36),
                _buildTargetCard(),
                const SizedBox(height: 40),
                _buildRecognizedTextArea(),
                const SizedBox(height: 40),
                if (!_controller.answered)
                  _buildMicSection()
                else
                  _buildFeedbackSection(),
              ],
            ),
          ),
        );

        if (!widget.showAppBar) {
          body = SafeArea(child: body);
        }

        return Scaffold(
          appBar: widget.showAppBar ? const ThaiAppBar(title: "Quiz") : null,
          body: body,
        );
      },
    );
  }

  Widget _buildTargetCard() {
    final theme = Theme.of(context);
    return Column(
      children: [
        ThaiSectionLabel(
          label: "SPEAK THIS WORD",
          color: AppTheme.primaryColor,
          fontSize: 12,
          padding: const EdgeInsets.only(bottom: 16),
        ),
          const SizedBox(height: 16),
          if (widget.word.imageUrl.isNotEmpty) ...[
            ThaiIllustration(
              source: widget.word.imageUrl,
              height: 100,
              iconSize: 50,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            widget.word.thai,
            style: TextStyle(
              fontSize: AppTheme.getResponsiveFontSize(widget.word.thai, 32),
              fontWeight: FontWeight.bold,
              color: theme.textTheme.headlineLarge?.color ?? AppTheme.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            widget.word.phonetic,
            style: TextStyle(
              fontSize: AppTheme.getResponsiveFontSize(
                widget.word.phonetic,
                18,
              ),
              color: theme.disabledColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ThaiSpeakIconButton(
                icon: Icons.volume_up_rounded,
                label: "LISTEN",
                color: AppTheme.primaryColor,
                onTap: _controller.speakThaiNormal,
                padding: 16,
                iconSize: 30,
              ),
              const SizedBox(width: 48),
              ThaiSpeakIconButton(
                icon: Icons.slow_motion_video_rounded,
                label: "SLOW",
                color: Colors.pink.shade300,
                onTap: _controller.speakThaiSlow,
                padding: 16,
                iconSize: 30,
              ),
            ],
          ),
        ],
      );
  }

  Widget _buildRecognizedTextArea() {
    if (_controller.recognizedText.isEmpty) return const SizedBox.shrink();
    final isCorrect = _controller.answerCorrect ?? false;
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _controller.answered
                    ? (isCorrect ? Colors.green : Colors.red)
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "YOU SAID",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _controller.recognizedText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMicSection() {
    return Column(
      children: [
        GestureDetector(
          onLongPressStart: (_) => _controller.startListening(),
          onLongPressEnd: (_) => _controller.stopListening(),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _controller.isListening
                      ? Colors.red
                      : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_controller.isListening
                                  ? Colors.red
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                      blurRadius: _controller.isListening ? 30 : 20,
                      spreadRadius: _controller.isListening ? 10 : 5,
                    ),
                  ],
                ),
                child: Icon(
                  _controller.isListening
                      ? Icons.mic_rounded
                      : Icons.mic_none_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _controller.isListening
                    ? "I'M LISTENING..."
                    : "HOLD BUTTON TO SPEAK",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _controller.isListening
                      ? Colors.red
                      : AppTheme.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    final correct = _controller.answerCorrect!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: correct ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: correct ? Colors.green.shade300 : Colors.red.shade300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      correct
                          ? Icons.stars_rounded
                          : Icons.sentiment_very_dissatisfied_rounded,
                      color: correct
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      correct ? "EXCELLENT!" : "ALMOST THERE!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: correct
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: correct ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => StepResultNotification(
                      _controller.answerCorrect ?? false,
                    ).dispatch(context),
                    child: const Text(
                      "CONTINUE",
                      style: TextStyle(letterSpacing: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
