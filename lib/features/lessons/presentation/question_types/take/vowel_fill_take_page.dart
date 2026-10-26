import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/vowel_fill_controller.dart';

class VowelFillTakePage extends StatefulWidget {
  final WordEntry word;
  final String question;
  final String answer;
  final List<String> choices;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const VowelFillTakePage({
    super.key,
    required this.word,
    required this.question,
    required this.answer,
    required this.choices,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<VowelFillTakePage> createState() => _VowelFillTakePageState();
}

class _VowelFillTakePageState extends State<VowelFillTakePage> {
  late final VowelFillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VowelFillController(widget.word);
    if (widget.isActive) _controller.init();
  }

  @override
  void didUpdateWidget(VowelFillTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.updateWord(widget.word);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.init();
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
                ThaiSectionLabel(
                  label: "FILL THE VOWEL",
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  padding: const EdgeInsets.only(bottom: 16),
                ),
                const SizedBox(height: 16),
                if (widget.word.imageUrl.isNotEmpty)
                  ThaiIllustration(
                    source: widget.word.imageUrl,
                    height: 120,
                    iconSize: 60,
                  ),
                if (widget.word.imageUrl.isNotEmpty)
                  const SizedBox(height: 12),
                Text(
                  widget.question,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      widget.question,
                      48,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ThaiSpeakIconButton(
                      icon: Icons.volume_up_rounded,
                      label: "NORMAL",
                      color: AppTheme.primaryColor,
                      onTap: _controller.speakThaiNormal,
                      padding: 12,
                      iconSize: 26,
                    ),
                    const SizedBox(width: 40),
                    ThaiSpeakIconButton(
                      icon: Icons.slow_motion_video_rounded,
                      label: "SLOW",
                      color: Colors.pink.shade300,
                      onTap: _controller.speakThaiSlow,
                      padding: 12,
                      iconSize: 26,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5,
                  children: widget.choices
                      .map((choice) => _buildChoiceButton(choice))
                      .toList(),
                ),
                const SizedBox(height: 32),
                if (_controller.answered) _buildFeedbackArea(),
              ],
            ),
          ),
        );

        if (!widget.showAppBar) body = SafeArea(child: body);

        return Scaffold(
          appBar: widget.showAppBar ? const ThaiAppBar(title: "Quiz") : null,
          body: body,
        );
      },
    );
  }

  Widget _buildChoiceButton(String choice) {
    return ThaiAnswerChoiceButton(
      text: choice,
      answered: _controller.answered,
      selected: _controller.selectedAnswer == choice,
      correct: choice == widget.answer,
      onTap: () => _controller.selectChoice(choice, widget.answer),
      height: double.infinity,
      fontSize: 24,
      borderRadius: 16,
      margin: EdgeInsets.zero,
    );
  }

  Widget _buildFeedbackArea() {
    return ThaiFeedbackCard(
      correct: _controller.isCorrect,
      correctTitle: "EXCELLENT!",
      incorrectTitle: "NOT QUITE...",
      answerLabel: "Correct Vowel:",
      answerText: widget.answer,
      onContinue: () =>
          StepResultNotification(_controller.isCorrect).dispatch(context),
    );
  }
}
