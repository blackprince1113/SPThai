import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/four_choice_controller.dart';

class FourChoiceTakePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final String category;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;

  const FourChoiceTakePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    required this.category,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
  });

  @override
  State<FourChoiceTakePage> createState() => _FourChoiceTakePageState();
}

class _FourChoiceTakePageState extends State<FourChoiceTakePage> {
  late final FourChoiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FourChoiceController(
      word: widget.word,
      category: widget.category,
      initialChoices: widget.choices,
      correctAnswer: widget.correctAnswer,
    );
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
        final theme = Theme.of(context);
        Widget body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                ThaiLessonProgress(
                  currentIndex: widget.currentIndex,
                  totalSteps: widget.totalSteps,
                ),
                const SizedBox(height: 32),
                ThaiQuestionCard(
                  header: "CHOOSE THE CORRECT MEANING",
                  illustrationSource: widget.word.imageUrl,
                  illustrationHeight: 120,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.word.thai,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTheme.getResponsiveFontSize(
                            widget.word.thai,
                            38,
                          ),
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(
                                context,
                              ).textTheme.headlineLarge?.color ??
                              AppTheme.textColor,
                        ),
                      ),
                      if (widget.word.phonetic.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.word.phonetic,
                          style: TextStyle(
                            fontSize: 18,
                            color: theme.disabledColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ..._controller.choices.map(
                  (choice) => ThaiAnswerChoiceButton(
                    text: choice.english,
                    answered: _controller.answered,
                    selected: _controller.selectedAnswer == choice.english,
                    correct: _controller.isCorrect(choice),
                    onTap: () => _controller.selectChoice(choice),
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.answered) _buildFeedbackArea(),
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

  Widget _buildFeedbackArea() {
    return ThaiFeedbackCard(
      correct: _controller.answerCorrect,
      correctTitle: "AMAZING!",
      incorrectTitle: "NOT QUITE",
      answerLabel: "The correct answer was:",
      answerText: widget.correctAnswer,
      onContinue: () =>
          StepResultNotification(_controller.answerCorrect).dispatch(context),
    );
  }
}
